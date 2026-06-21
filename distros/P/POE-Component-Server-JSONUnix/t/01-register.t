use strict;
use warnings;
use Test::More;
use POE::Component::Server::JSONUnix;

# These tests exercise the registration logic directly on a bare object,
# without spawning a session or running the POE kernel.

my $srv = bless { commands => {} }, 'POE::Component::Server::JSONUnix';

$srv->register( foo => sub {'foo'}, bar => sub {'bar'} );
is_deeply( $srv->command_names, [ 'bar', 'foo' ],
    'register() adds commands and command_names() is sorted' );

# returns the object, for chaining
is( $srv->register( baz => sub {'baz'} ), $srv, 'register() returns the server' );

# later registration overrides an existing command
$srv->register( foo => sub {'foo2'} );
is( $srv->{commands}{foo}->(), 'foo2', 'register() overrides an existing command' );

# non-coderef handlers are rejected
eval { $srv->register( bad => 'not a coderef' ) };
like( $@, qr/code reference/, 'register() rejects a non-coderef handler' );

# cmd_* discovery across a subclass
{
    package My::Test::Server;
    use parent -norequire, 'POE::Component::Server::JSONUnix';
    sub cmd_alpha { 'A' }
    sub cmd_beta  { 'B' }
}

my $sub = bless { commands => {} }, 'My::Test::Server';
$sub->_register_cmd_methods;

my %have = map { $_ => 1 } @{ $sub->command_names };
ok( $have{alpha} && $have{beta},
    'cmd_* methods are auto-discovered in a subclass' );

# the generated wrapper dispatches to the cmd_ method as a method call
is( $sub->{commands}{alpha}->($sub), 'A',
    'discovered command dispatches to its cmd_ method' );

done_testing();
