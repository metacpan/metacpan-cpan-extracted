use strict;
use warnings;
use Test::More;
use Mojo::Base -signatures;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);
use DBIxTestHelper qw(build_dbtest_app);

my $tmpdir = tempdir(CLEANUP => 1);

my ($app) = build_dbtest_app($tmpdir);

my $c = $app->build_controller;

# 1. schema_class
is($c->schema_class, 'TestDBIxAsyncSchema', 'schema_class helper');

# 2. schema
my $schema = $c->schema;
isa_ok($schema, 'DBIx::Class::Async::Schema', 'schema helper');

# 3. model helper
my $rs = $c->model('user');
isa_ok($rs, 'DBIx::Class::Async::ResultSet', 'model returns ResultSet');

# 4. Deploy + CRUD
$schema->deploy({ add_drop_table => 0 })->get;

# Create
my $created = $schema->await($rs->create({ name => 'Alice', email => 'alice@e.com' }));
ok($created->id, 'create works');
is($created->name, 'Alice', 'create name');

# Find
my $found = $schema->await($rs->find($created->id));
is($found->name, 'Alice', 'find works');

# Search
my $results = $schema->await($rs->search({ name => 'Alice' })->all);
is(scalar @$results, 1, 'search finds one');

# Delete
$schema->await($found->delete);
my $gone = $schema->await($rs->find($created->id));
is($gone, undef, 'delete works');

# 5. Error on unknown model
eval { $c->model('nonexistent') };
like($@, qr/is not configured/, 'dies on unknown model');

# 6. default_backend_name helper — cascade tests
# 6a. No explicit, no default_backend config → first backend
is($c->default_backend_name, 'main', 'default_backend_name falls back to first backend');

# 6b. Explicit param wins over everything
is($c->default_backend_name('custom'), 'custom',
    'default_backend_name respects explicit param');

# 6c. With default_backend configured
{
    my $tmpdir2 = tempdir(CLEANUP => 1);
    my $app2 = create_test_app($tmpdir2);
    $app2->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                default_backend => 'logs',
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$tmpdir2/main.db",
                        schema_class => 'TestDBIxAsyncSchema',
                    },
                    logs => {
                        dsn          => "dbi:SQLite:dbname=$tmpdir2/logs.db",
                        schema_class => 'TestDBIxAsyncSchema',
                    },
                ],
            }},
            'Fondation::TestDBIxAsync',
        ],
    });
    my $c2 = $app2->build_controller;
    is($c2->default_backend_name, 'logs',
        'default_backend_name uses default_backend config');
    is($c2->default_backend_name('main'), 'main',
        'default_backend_name explicit overrides default_backend config');
}

# 7. Models without explicit backend fall back to default
{
    my $tmpdir3 = tempdir(CLEANUP => 1);
    my $app3 = create_test_app($tmpdir3);
    $app3->plugin('Fondation' => {
        dependencies => [
            { 'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$tmpdir3/modeldef.db",
                        schema_class => 'TestDBIxAsyncSchema',
                    },
                ],
                models => {
                    user    => { source => 'User',   backend => 'main' },
                    article => { source => 'Article' },              # no backend
                },
            }},
            'Fondation::TestDBIxAsync',
        ],
    });

    my $c3 = $app3->build_controller;
    # Model with explicit backend still works
    isa_ok($c3->model('user'), 'DBIx::Class::Async::ResultSet',
        'model with explicit backend works');
    # Model without backend resolves to default
    isa_ok($c3->model('article'), 'DBIx::Class::Async::ResultSet',
        'model without backend falls back to default');
}

done_testing;
