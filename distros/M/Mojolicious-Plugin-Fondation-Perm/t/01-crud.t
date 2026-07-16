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
require TestPermSchema;

# Build app with Fondation + DBIx::Async + Perm
my $app = Mojolicious->new;
$app->moniker('PermTest');
$app->log->level('fatal');

$app->config->{'Fondation'} = {
    dependencies => [
        {
            'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$tmpdir/test.db",
                        schema_class => 'TestPermSchema',
                        workers      => 1,
                    },
                ],
                models => {
                    perm       => { source => 'Perm',      backend => 'main' },
                    group_perm => { source => 'GroupPerm', backend => 'main' },
                },
            },
        },
        'Fondation::Perm',
    ],
};

$app->plugin('Fondation');

# Deploy the tables
my $c     = $app->build_controller;
my $schema = $c->schema;
$schema->deploy->get;

my $rs = $c->model('perm');
isa_ok($rs, 'DBIx::Class::Async::ResultSet', 'model helper returns ResultSet');

# --- CRUD via model helper ---

# Create
my $created = $schema->await($rs->create({
    name        => 'admin',
    description => 'Full access',
}));
ok($created->id, 'create works');
is($created->name,        'admin',       'create sets name');
is($created->description, 'Full access', 'create sets description');

# Read (find)
my $found = $schema->await($rs->find($created->id));
is($found->name,        'admin',       'find returns correct perm');
is($found->description, 'Full access', 'find returns description');

# Search
my $results = $schema->await($rs->search({ name => 'admin' })->all);
is(scalar @$results, 1, 'search finds one');

# Update
$schema->await($found->update({ description => 'Administrative access' }));
my $updated = $schema->await($rs->find($created->id));
is($updated->description, 'Administrative access', 'update changes description');

# Delete
$schema->await($found->delete);
my $gone = $schema->await($rs->find($created->id));
is($gone, undef, 'delete removes perm');

# --- group_perm pivot table ---

my $gp_rs = $c->model('group_perm');
isa_ok($gp_rs, 'DBIx::Class::Async::ResultSet', 'group_perm model helper returns ResultSet');

# Create a perm first, then link it
my $perm = $schema->await($rs->create({
    name        => 'read',
    description => 'Read access',
}));

my $link = $schema->await($gp_rs->create({
    group_id => 1,
    perm_id  => $perm->id,
}));
ok($link->id, 'group_perm link created');
is($link->group_id, 1,          'group_id correct');
is($link->perm_id,  $perm->id,  'perm_id correct');

# Search group_perm by perm_id
my $links = $schema->await($gp_rs->search({ perm_id => $perm->id })->all);
is(scalar @$links, 1, 'found one link for perm');

# Delete link
$schema->await($link->delete);
my $gone_link = $schema->await($gp_rs->find($link->id));
is($gone_link, undef, 'delete removes link');

done_testing;
