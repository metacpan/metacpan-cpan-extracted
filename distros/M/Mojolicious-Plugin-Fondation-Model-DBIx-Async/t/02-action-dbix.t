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
                },
            ],
            models => {
                user => { source => 'users', backend => 'main' },
            },
        }},
        'Fondation::TestDBIxAsync',
    ],
});

my $c = $app->build_controller;

# 1. Action::DBIx registered the plugin's Result
my $schema = $c->schema;
my $source = eval { $schema->source('users') };
ok($source, 'users source registered by Action::DBIx');
is($source->result_class, 'Mojolicious::Plugin::Fondation::TestDBIxAsync::Schema::Result::User',
    'result_class from plugin');

# 2. Plugin registry has dbic metadata
my $entry = $app->fondation->registry->{'Mojolicious::Plugin::Fondation::TestDBIxAsync'};
ok($entry->{dbic}, 'dbic metadata present');
ok($entry->{dbic}{result_classes}, 'result_classes present');
ok($entry->{dbic}{result_classes}{users}, 'result_classes has users table');
is($entry->{dbic}{total_added}, 2, 'two results added (User + Article)');

# 3. End-to-end: deploy + CRUD via model()
$schema->deploy({ add_drop_table => 0 })->get;

my $rs = $c->model('user');
my $alice = $schema->await($rs->create({ name => 'Alice', email => 'a@e.com' }));
ok($alice->id, 'create via model works');

my $found = $schema->await($rs->find($alice->id));
is($found->name, 'Alice', 'find via model works');

done_testing;
