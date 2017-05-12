use Test::More;
use strict; use warnings FATAL => 'all';

use POE;

use_ok( 'POEx::IRC::Backend' );
use_ok( 'IRC::Message::Object', 'ircmsg' );

my $expected = {
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
    protocol => 6,
    bindaddr => '::0',
    port     => 0,
  );
}

sub shutdown {
  my ($k, $backend) = @_[KERNEL, HEAP];
  $k->alarm_remove_all;
  $k->post( $backend->session_id, 'shutdown' );
  if ($_[ARG0] && $_[ARG0] eq 'timeout') {
    fail("Timed out");
    diag explain $got;
  }
}

sub ircsock_registered {
}

sub ircsock_listener_created {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $listener = $_[ARG0];

  $got->{'got listener_created'}++;

  isa_ok( $listener, 'POEx::IRC::Backend::Listener' );

  $backend->create_connector(
    remoteaddr => $listener->addr,
    remoteport => $listener->port,
  );
}

sub ircsock_connector_open {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $conn = $_[ARG0];

  ## OK, technically a Connector that acts like a client
  ## ought to have a backend with a 'colonify => 0' filter

  $got->{'got connector_open'}++;

  $backend->send(
    {
      command => 'CONNECTOR',
      params  => [ 'testing' ],
    },
    $conn->wheel_id
  );

  $backend->send( ircmsg( raw_line => ':test CONNECTOR :testing' ),
    $conn->wheel_id
  );
}

sub ircsock_listener_removed {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $listener = $_[ARG0];

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

  if ($ev->params->[0] eq 'testing') {
    $got->{'got ircsock_input'}++;
  }

  ## FIXME test ->disconnect() behavior

  if ($got->{'got ircsock_input'} == $expected->{'got ircsock_input'}) {
    ## Call for a listener removal to test listener_removed
    $backend->remove_listener(
      addr => '::0',
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
