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
                user       => { source => 'User',      backend => 'main' },
                group      => { source => 'Group',     backend => 'main' },
                user_group => { source => 'UserGroup', backend => 'main' },
            },
        }},
        'Fondation::TestDBIxRelation',
    ],
});

my $c = $app->build_controller;

# ─── 1. Schema resolves source by class moniker ───────────────────────────

subtest 'schema resolves source by class moniker' => sub {
    my $schema = $c->schema;
    my $source = eval { $schema->source('UserGroup') };
    ok($source, 'schema can find source by class moniker UserGroup');
    is($source->source_name, 'UserGroup',
        'registered source_name is the class moniker');
};

# ─── 3. End-to-end: search_with_prefetch + groups accessor ────────────

subtest 'search_with_prefetch + groups returns data' => sub {
    my $schema = $c->schema;
    $schema->deploy({ add_drop_table => 0 })->get;

    my $u_rs = $c->model('user');
    my $g_rs = $c->model('group');

    my $alice = $schema->await($u_rs->create({ name => 'Alice' }));
    my $admin = $schema->await($g_rs->create({ name => 'Admins' }));
    $schema->await($alice->add_to_groups($admin));

    # Use search_with_prefetch — the controller path
    my $rows = $schema->await(
        $schema->search_with_prefetch('User',
            { 'me.id' => $alice->id },
            { user_group => 'group' })
    );
    is(scalar @$rows, 1, 'one user returned');
    my $row = $rows->[0];
    is($row->name, 'Alice', 'correct user');

    # Verify prefetched data is stored (in _relationship_data or _prefetched)
    ok($row->{_relationship_data} || $row->{_prefetched},
        'prefetched data stored on row');
    ok($row->{_relationship_data}{user_group} || $row->{_prefetched}{user_group},
        'user_group data in prefetched cache');

    # groups accessor via many_to_many_async — should hit prefetched path
    my $groups = $schema->await($row->groups);
    is(scalar @$groups, 1, 'user has 1 group via prefetched path');
    is($groups->[0]{name}, 'Admins', 'group name correct via prefetched');
};

done_testing;
