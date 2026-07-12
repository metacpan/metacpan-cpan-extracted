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

# ─── Build app with TestDBIxRelation plugin ──────────────────────────────────

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
                user       => { source => 'User',      backend => 'main' },
                group      => { source => 'Group',     backend => 'main' },
                user_group => { source => 'UserGroup', backend => 'main' },
            },
        }},
        'Fondation::TestDBIxRelation',
    ],
});

my $c = $app->build_controller;

# ─── 1. Schema has relationships registered ──────────────────────────────────

subtest 'schema relationships registered' => sub {
    my $schema = $c->schema;

    my $user_class = 'Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::User';
    my $ug_class = 'Mojolicious::Plugin::Fondation::TestDBIxRelation::Schema::Result::UserGroup';

    ok($user_class->has_relationship('user_group'),
        'user has_many user_group');
    ok($ug_class->has_relationship('group'),
        'user_group belongs_to group');
    ok($ug_class->has_relationship('user'),
        'user_group belongs_to user');
};

# ─── 2. Deploy and test many_to_many_async accessors ─────────────────────────

subtest 'many_to_many_async accessors (add_to / groups / remove_from / set)' => sub {
    my $schema = $c->schema;
    $schema->deploy({ add_drop_table => 0 })->get;

    my $u_rs = $c->model('user');
    my $g_rs = $c->model('group');

    # Create user and groups
    my $alice  = $schema->await($u_rs->create({ name => 'Alice' }));
    my $admin  = $schema->await($g_rs->create({ name => 'Admins' }));
    my $editor = $schema->await($g_rs->create({ name => 'Editors' }));

    ok($alice->id,  'user created');
    ok($admin->id,  'group Admins created');
    ok($editor->id, 'group Editors created');

    # add_to_groups (returns Future)
    $schema->await($alice->add_to_groups($admin));
    $schema->await($alice->add_to_groups($editor));

    # groups accessor (returns Future → arrayref)
    $alice = $schema->await($u_rs->find($alice->id));
    my @groups = @{ $schema->await($alice->groups) };
    is(scalar @groups, 2, 'user has 2 groups');
    my %names = map { $_->name => 1 } @groups;
    ok($names{Admins},  'user is in Admins');
    ok($names{Editors}, 'user is in Editors');

    # remove_from_groups (returns Future)
    $schema->await($alice->remove_from_groups($editor));
    $alice = $schema->await($u_rs->find($alice->id));  # re-fetch after delete
    my @remaining = @{ $schema->await($alice->groups) };
    is(scalar @remaining, 1, 'user has 1 group after removal');
    is($remaining[0]->name, 'Admins', 'remaining group is Admins');

    # set_groups (replaces all, returns Future)
    my $viewer = $schema->await($g_rs->create({ name => 'Viewers' }));
    $schema->await($alice->set_groups([$viewer]));
    $alice = $schema->await($u_rs->find($alice->id));  # re-fetch after set
    my @final = @{ $schema->await($alice->groups) };
    is(scalar @final, 1, 'user has 1 group after set_groups');
    is($final[0]->name, 'Viewers', 'user is now in Viewers');
};

done_testing;
