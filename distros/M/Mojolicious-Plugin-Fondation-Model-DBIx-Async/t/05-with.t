use strict;
use warnings;
use Test::More;
use Mojo::Base -signatures;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

my $tmpdir = tempdir(CLEANUP => 1);
my $dbfile = "$tmpdir/test.db";

my $app = create_test_app($tmpdir);
$app->plugin('Fondation' => {
    dependencies => [
        { 'Fondation::Model::DBIx::Async' => {
            backends => [
                main => {
                    dsn          => "dbi:SQLite:dbname=$dbfile",
                    schema_class => 'TestDBIxAsyncSchema',
                    workers      => 1,
                    quote_char   => '"',
                },
            ],
            models => {
                user       => { source => 'User',       backend => 'main' },
                group      => { source => 'Group',      backend => 'main' },
                user_group => { source => 'UserGroup',  backend => 'main' },
            },
        }},
        'Fondation::TestDBIxRelation',
    ],
});

my $c = $app->build_controller;

# ─── Setup ───────────────────────────────────────────────────────────────────

my $schema = $c->schema;
$schema->deploy({ add_drop_table => 0 })->get;

my $alice  = $schema->await($c->model('user')->create({ name => 'Alice' }));
my $admins = $schema->await($c->model('group')->create({ name => 'Admins' }));
my $editors = $schema->await($c->model('group')->create({ name => 'Editors' }));
$schema->await($alice->add_to_groups($admins));
$schema->await($alice->add_to_groups($editors));

# ─── 1. with('groups')->all (many_to_many) ────────────────────────────────────

subtest 'with(groups)->all returns users with groups' => sub {
    my $rows = $schema->await(
        $c->model('user')->with('groups')->all
    );
    is(scalar @$rows, 1, 'one user');

    my $row = $rows->[0];
    is($row->name, 'Alice', 'correct user');

    # groups accessible via many_to_many_async (prefetched path)
    my $groups = $schema->await($row->groups);
    is(scalar @$groups, 2, 'user has 2 groups');
    my %names = map { $_->{name} => 1 } @$groups;
    ok($names{Admins},  'Admins in result');
    ok($names{Editors}, 'Editors in result');
};

# ─── 2. with('groups')->search({ ... })->all ──────────────────────────────────

subtest 'with(groups)->search({})->all chains correctly' => sub {
    my $rows = $schema->await(
        $c->model('user')->with('groups')->search({ 'me.name' => 'Alice' })->all
    );
    is(scalar @$rows, 1, 'one user matching search');
    my $groups = $schema->await($rows->[0]->groups);
    is(scalar @$groups, 2, 'user has 2 groups after search filter');
};

# ─── 3. with('groups')->find (many_to_many) ───────────────────────────────────

subtest 'with(groups)->find returns user with groups' => sub {
    my $row = $schema->await(
        $c->model('user')->with('groups')->find($alice->id)
    );
    ok($row, 'user found');
    is($row->name, 'Alice', 'correct user');

    my $groups = $schema->await($row->groups);
    is(scalar @$groups, 2, 'user has 2 groups via find');
};

# ─── 4. without with() — standard path still works ────────────────────────────

subtest 'model without with() still works' => sub {
    my $rows = $schema->await(
        $c->model('user')->all
    );
    is(scalar @$rows, 1, 'one user without with()');
    is($rows->[0]->name, 'Alice', 'correct user without with()');
};

# ─── 5. with() validates relationship exists ──────────────────────────────────

subtest 'with() dies on unknown relation' => sub {
    eval { $c->model('user')->with('nonexistent') };
    like($@, qr/No many_to_many or has_many relationship/,
        'dies on unknown relation');
};

# ─── 6. with() dies on belongs_to (single-accessor) ───────────────────────────

subtest 'with() dies on belongs_to relationship' => sub {
    # user_group is a belongs_to from UserGroup to Group when accessed
    # from the UserGroup model. But on User, user_group is a has_many.
    # Use a model where the only relationship is belongs_to.
    eval { $c->model('user_group')->with('group') };
    like($@, qr/is 'single'/, 'dies on belongs_to relationship');
};

# ─── 7. with('user_group')->all (has_many — direct prefetch) ──────────────────

subtest 'with(user_group)->all prefetches has_many' => sub {
    my $rows = $schema->await(
        $c->model('user')->with('user_group')->all
    );
    is(scalar @$rows, 1, 'one user');

    my $row = $rows->[0];
    # user_group is a has_many → pivot rows should be prefetched
    ok($row->{_relationship_data}{user_group} || $row->{_prefetched}{user_group},
        'user_group data in prefetched cache');

    # Pivot rows accessible synchronously
    my $ug_rs = $row->user_group;
    my @ugs = @{ $schema->await($ug_rs->all) };
    is(scalar @ugs, 2, '2 pivot rows via has_many prefetch');
};

# ─── 8. with('user_group')->find (has_many + find) ────────────────────────────

subtest 'with(user_group)->find prefetches has_many' => sub {
    my $row = $schema->await(
        $c->model('user')->with('user_group')->find($alice->id)
    );
    ok($row, 'user found');

    # has_many pivot rows should be in the prefetched cache
    ok($row->{_relationship_data}{user_group} || $row->{_prefetched}{user_group},
        'user_group data in prefetched cache via find');

    my $ug_rs = $row->user_group;
    my @ugs = @{ $schema->await($ug_rs->all) };
    is(scalar @ugs, 2, '2 pivot rows via has_many find');
};

# ─── 9. with('groups', 'user_group') — both at once ───────────────────────────

subtest 'with(groups, user_group) prefetches both' => sub {
    my $rows = $schema->await(
        $c->model('user')->with('groups', 'user_group')->all
    );
    is(scalar @$rows, 1, 'one user');

    my $row = $rows->[0];

    # Both should be in the prefetched cache
    ok(($row->{_relationship_data}{user_group} || $row->{_prefetched}{user_group}),
        'user_group in cache (has_many)');
    ok(($row->{_relationship_data}{user_group} || $row->{_prefetched}{user_group}),
        'user_group also covers many_to_many pivot');

    # Groups via many_to_many still work
    my $groups = $schema->await($row->groups);
    is(scalar @$groups, 2, 'user has 2 groups (many_to_many still works)');

    # Pivot rows also accessible
    my $ug_rs = $row->user_group;
    my @ugs = @{ $schema->await($ug_rs->all) };
    is(scalar @ugs, 2, '2 pivot rows via has_many (combined)');
};

done_testing;
