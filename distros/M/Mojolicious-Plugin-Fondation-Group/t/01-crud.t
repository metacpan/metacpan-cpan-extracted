use strict;
use warnings;
use Test::More;
use Mojo::Base -signatures;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Mojolicious;
use Cwd 'abs_path';
use lib abs_path("$FindBin::Bin/lib");  # absolute for forked workers
use File::Temp qw(tempdir);

my $tmpdir = tempdir(CLEANUP => 1);

# Load schema class BEFORE Fondation so Action::DBIx can discover
# and register plugin Result classes on it during startup.
require TestGroupSchema;

# Build app with Fondation + DBIx::Async + Group
my $app = Mojolicious->new;
$app->moniker('GroupTest');
$app->log->level('fatal');

$app->config->{'Fondation'} = {
    dependencies => [
        {
            'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$tmpdir/test.db",
                        schema_class => 'TestGroupSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    group      => { source => 'Group',     backend => 'main' },
                    user_group => { source => 'UserGroup', backend => 'main' },
                },
            },
        },
        'Fondation::Group',
    ],
};

$app->plugin('Fondation');

# Deploy the tables
my $c     = $app->build_controller;
my $schema = $c->schema;
$schema->deploy->get;

my $rs = $c->model('group');
isa_ok($rs, 'DBIx::Class::Async::ResultSet', 'model helper returns ResultSet');

# --- CRUD via model helper ---

# Create
my $created = $schema->await($rs->create({
    name   => 'admins',
    active => 1,
}));
ok($created->id, 'create works');
is($created->name,   'admins', 'create sets name');
is($created->active, 1,        'create sets active');

# Read (find)
my $found = $schema->await($rs->find($created->id));
is($found->name,   'admins', 'find returns correct group');
is($found->active, 1,        'find returns active');

# Search
my $results = $schema->await($rs->search({ name => 'admins' })->all);
is(scalar @$results, 1, 'search finds one');

# Update
$schema->await($found->update({ name => 'administrators' }));
my $updated = $schema->await($rs->find($created->id));
is($updated->name, 'administrators', 'update changes name');

# Delete
$schema->await($found->delete);
my $gone = $schema->await($rs->find($created->id));
is($gone, undef, 'delete removes group');

done_testing;
