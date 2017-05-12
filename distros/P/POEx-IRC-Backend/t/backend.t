use Test::More;
use strict; use warnings;

use POE;

use_ok( 'POEx::IRC::Backend' );
use_ok( 'IRC::Message::Object', 'ircmsg' );

my $expected = {
  'got registered'       => 1,
  'got listener_created' => 1,
  'got connector_open'   => 1,
  'got listener_open'    => 1,
  'got listener_removed' => 1,
  'got ircsock_input'    => 3,
};
my $got = {};


POE::Session->create(
  package_states => [
    main => [ qw/
      _start
      shutdown
      ircsock_registered

      ircsock_connector_open
      ircsock_listener_created
      ircsock_listener_removed
      ircsock_listener_failure
      ircsock_listener_open
      ircsock_input
    / ],
  ],
);

sub _start {
  $_[HEAP] = new_ok( 'POEx::IRC::Backend' );

  my ($k, $backend) = @_[KERNEL, HEAP];

  $k->delay( shutdown => 30 => 'timeout' );

  $backend->spawn;
  $k->post( $backend->session_id, 'register' );

  $backend->create_listener(
    bindaddr => '127.0.0.1',
    port     => 0,

    foo      => 1,
  );
}

sub shutdown {
  my ($k, $backend) = @_[KERNEL, HEAP];
  $k->alarm_remove_all;
  $k->post( $backend->session_id, 'shutdown' );
  if ($_[ARG0] && $_[ARG0] eq 'timeout') {
    fail("Timed out")
  }
}

sub ircsock_registered {
  $got->{'got registered'}++;
  isa_ok( $_[ARG0], 'POEx::IRC::Backend' );
}

sub ircsock_listener_created {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $listener = $_[ARG0];

  $got->{'got listener_created'}++;

  isa_ok( $listener, 'POEx::IRC::Backend::Listener' );

  $backend->create_connector(
    remoteaddr => $listener->addr,
    remoteport => $listener->port,
    tag        => 'foo',
  );
}

sub ircsock_connector_open {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $conn = $_[ARG0];

  ## OK, technically a Connector that acts like a client
  ## ought to have a backend with a 'colonify => 0' filter

  $got->{'got connector_open'}++;

  isa_ok( $conn, 'POEx::IRC::Backend::Connect' );
  is_deeply $conn->args, +{ tag => 'foo' },
    'args passed along ok';

  # Testing against Connect wheel_id:
  $backend->send(
    {
      command => 'CONNECTOR',
      params  => [ 'testing' ],
    },
    $conn->wheel_id
  );

  # Testing against Connect obj:
  $backend->send( ircmsg( raw_line => ':test CONNECTOR :testing' ),
    $conn
  );

  ok $conn->get_socket, 'get_socket ok';
  cmp_ok $conn->ssl_cipher, 'eq', '', 'ssl_cipher returns empty string ok';
  ok !$conn->ssl_object, '! ssl_object ok';
}

sub ircsock_listener_removed {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $listener = $_[ARG0];

  isa_ok( $listener, 'POEx::IRC::Backend::Listener' );

  $got->{'got listener_removed'}++;

  $k->yield( shutdown => 1 )
}

sub ircsock_listener_failure {
  my ($op, $errno, $errstr) = @_[ARG1 .. ARG3];
  BAIL_OUT("Failed listener creation: $op ($errno) $errstr");
}

sub ircsock_listener_open {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my ($conn, $listener) = @_[ARG0 .. $#_];

  $got->{'got listener_open'}++;

  is_deeply $conn->args, +{ foo => 1 },
    "listener's Connector has correct args";
  is_deeply $listener->args, $conn->args,
    "extra args passed along ok";

  isa_ok( $conn, 'POEx::IRC::Backend::Connect' );

  cmp_ok $conn->sockaddr, 'eq', '127.0.0.1', 'sockaddr ok';
  cmp_ok $conn->sockport, '==', $listener->port, 'sockport ok';
  cmp_ok $conn->peeraddr, 'eq', '127.0.0.1', 'peeraddr ok';
  ok $conn->peerport, 'peerport ok';
  ok !$conn->is_disconnecting, 'is_disconnecting ok';
  ok !$conn->compressed, 'compressed ok';

  $backend->send(
    ircmsg(
      prefix  => 'listener',
      command => 'test',
      params  => [ 'testing', 'stuff' ],
    ),
    $conn->wheel_id
  );
}

sub ircsock_input {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my ($conn, $ev)   = @_[ARG0 .. $#_];

  isa_ok( $conn, 'POEx::IRC::Backend::Connect' );
  isa_ok( $ev, 'IRC::Message::Object' );

  if ($ev->params->[0] eq 'testing') {
    $got->{'got ircsock_input'}++;
  }

  ## FIXME test ->disconnect() behavior with both blessed wheel & ID

  if ($got->{'got ircsock_input'} == $expected->{'got ircsock_input'}) {
    ## Call for a listener removal to test listener_removed
    $backend->remove_listener(
      addr => '127.0.0.1',
    );
  }
}


$poe_kernel->run;

TEST: for my $name (keys %$expected) {
  ok( defined $got->{$name}, "have result for '$name'")
    or next TEST;
  cmp_ok( $got->{$name}, '==', $expected->{$name}, 
    "correct result for '$name'"
  );
}

done_testing;
