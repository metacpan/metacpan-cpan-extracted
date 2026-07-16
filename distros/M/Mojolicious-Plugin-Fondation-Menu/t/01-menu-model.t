use strict;
use warnings;
use Test::More;
use Mojo::Base -signatures;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Mojolicious;
use Cwd 'abs_path';
use lib abs_path("$FindBin::Bin/lib");
use File::Temp qw(tempdir);

my $tmpdir = tempdir(CLEANUP => 1);

require TestMenuSchema;

my $app = Mojolicious->new;
$app->moniker('MenuTest');
$app->log->level('fatal');

$app->config->{'Fondation'} = {
    dependencies => [
        {
            'Fondation::Model::DBIx::Async' => {
                backends => [
                    main => {
                        dsn          => "dbi:SQLite:dbname=$tmpdir/test.db",
                        schema_class => 'TestMenuSchema',
                        workers      => 1,
                    },
                ],
            },
        },
        'Fondation::Menu',
    ],
};

$app->plugin('Fondation');

my $c = $app->build_controller;
my $schema = $c->schema;
$schema->deploy->get;

my $rs = $schema->resultset('Menu');
isa_ok($rs, 'DBIx::Class::Async::ResultSet', 'resultset returns ResultSet');

# --- CRUD ---

my $root = $schema->await($rs->create({
    title       => 'Administration',
    link        => '/admin',
    name        => 'admin_menu',
    sort_order  => 1,
    parent_id   => 0,
    description => 'Admin panel',
}));
ok($root->id, 'create root menu works');
is($root->title,       'Administration', 'create sets title');
is($root->description, 'Admin panel',    'create sets description');

# Create child
my $child = $schema->await($rs->create({
    title      => 'Users',
    link       => '/users',
    name       => 'admin_menu',
    sort_order => 1,
    parent_id  => $root->id,
}));
ok($child->id, 'create child menu works');
is($child->parent_id, $root->id, 'child has correct parent_id');

# Read
my $found = $schema->await($rs->find($child->id));
is($found->title, 'Users', 'find returns correct menu');

# Update
$schema->await($found->update({ title => 'Manage Users' }));
my $updated = $schema->await($rs->find($child->id));
is($updated->title, 'Manage Users', 'update changes title');

# Delete
$schema->await($child->delete);
is($schema->await($rs->find($child->id)), undef, 'delete removes child');
$schema->await($root->delete);
is($schema->await($rs->find($root->id)), undef, 'delete removes root');

# --- Helpers: condition system ---
# No Authorization plugin loaded in this test, so:
#   check_perm/check_group → Fondation no-op fallback → always returns 1
#   is_user_authenticated  → Fondation no-op fallback → always returns 0

ok($c->check_menu_condition(''),           'empty condition always passes');
ok($c->check_menu_condition(undef),        'undef condition always passes');
ok($c->check_menu_condition('group:admin'), 'group: passes (no Authorization loaded, fallback allows all)');
ok($c->check_menu_condition('perm:secret'),'perm: passes (no Authorization loaded, fallback allows all)');
ok(!$c->check_menu_condition('auth'),      'auth: fails (not logged in)');
ok($c->check_menu_condition('!auth'),      '!auth: passes (not logged in)');

is_deeply($c->menu_by_name('left_menu'), [], 'menu_by_name returns empty without cache');

done_testing;
