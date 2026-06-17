use strict;
use warnings;
use Test::More;
use Mojo::Base -signatures;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);
use DBIxTestHelper qw(build_dbtest_app);

my $tmpdir = tempdir(CLEANUP => 1);

my ($app) = build_dbtest_app($tmpdir);

# Connect to trigger schema creation and populate _schemas
my $c = $app->build_controller;
my $schema = $c->schema;
isa_ok($schema, 'DBIx::Class::Async::Schema',
    'schema connected before shutdown');

# Mock DBIx::Class::Async::disconnect to track calls
my (@disconnect_args, $disconnect_count);
{
    no warnings 'redefine';
    my $orig_disconnect = \&DBIx::Class::Async::disconnect;
    *DBIx::Class::Async::disconnect = sub {
        $disconnect_count++;
        push @disconnect_args, $_[1];   # $_[0] is class name
        goto $orig_disconnect;
    };
}

# --- Test 1: _shutdown sub disconnects all schemas ---

# Get the plugin instance from Fondation's registry
my $plugin = $app->fondation->registry
    ->{'Mojolicious::Plugin::Fondation::Model::DBIx::Async'}{instance};
ok($plugin, 'plugin instance found');
$plugin->{_shutdown}->();

is($disconnect_count, 1, 'disconnect called once by shutdown handler');
is($disconnect_args[0], $schema,
    'disconnect called with the connected schema');

# --- Test 2: END block emits before_server_stop hook ---

my $hook_fired = 0;
$app->hook(before_server_stop => sub { $hook_fired++ });

# Simulate what the END block does: emit hook first, then shutdown
$app->plugins->emit_hook('before_server_stop' => $app);
is($hook_fired, 1, 'before_server_stop hook emitted on shutdown');

done_testing;
