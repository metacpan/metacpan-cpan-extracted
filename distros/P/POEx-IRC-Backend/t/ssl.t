BEGIN {
  unless (eval {; require POE::Component::SSLify; 1 } && !$@) {
    require Test::More;
    Test::More::plan(skip_all =>
      'these tests require POE::Component::SSLify'
    );
  }
}

use Test::More;
use strict; use warnings;


my $key_path = 't/inc/test.key';
my $crt_path = 't/inc/test.crt';


use POE;
use POEx::IRC::Backend;
use IRC::Message::Object 'ircmsg';

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

  $backend->spawn(
    ssl_opts => [ $key_path, $crt_path ],
  );
  $k->post( $backend->session_id, 'register' );

  $backend->create_listener(
    ssl      => 1,
    bindaddr => '127.0.0.1',
    port     => 0,

    foo      => 1,
  );
}

sub shutdown {
  my ($k, $backend) = @_[KERNEL, HEAP];
  $k->alarm_remove_all;
  $backend->shutdown;
  if ($_[ARG0] && $_[ARG0] eq 'timeout') {
    fail("Timed out")
  }
}

sub ircsock_listener_created {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $listener = $_[ARG0];

  $got->{'got listener_created'}++;
  ok $listener->ssl, 'SSL enabled';

  $backend->create_connector(
    ssl        => 1,
    remoteaddr => $listener->addr,
    remoteport => $listener->port,
    tag        => 'foo',
  );
}

sub ircsock_connector_open {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my $conn = $_[ARG0];

  $got->{'got connector_open'}++;
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

  is_deeply $conn->args, +{ foo => 1 },
    "listener's Connector has correct args";
  is_deeply $listener->args, $conn->args,
    "extra args passed along ok";

  $backend->send(
    ircmsg(
      prefix  => 'listener',
      command => 'test',
      params  => [ 'testing', 'stuff' ],
    ),
    $conn->wheel_id
  );
}

my $ssl_checked = 0;
sub ircsock_input {
  my ($k, $backend) = @_[KERNEL, HEAP];
  my ($conn, $ev)   = @_[ARG0 .. $#_];

  my $cipher = POE::Component::SSLify::SSLify_GetCipher(
    $conn->wheel->get_output_handle
  );
  cmp_ok $cipher, 'ne', '(NONE)', 'SSL enabled on handle';
  unless ($ssl_checked++) {
    diag "GetCipher: $cipher";
    cmp_ok $conn->ssl_cipher, 'eq', $cipher, 'ssl_cipher ok';
    ok $conn->ssl_object, 'ssl_object ok';
    diag Net::SSLeay::dump_peer_certificate( $conn->ssl_object );
    ok $conn->get_socket, 'sslified get_socket ok';
  }

  isa_ok( $conn, 'POEx::IRC::Backend::Connect' );
  isa_ok( $ev, 'IRC::Message::Object' );

  if ($ev->params->[0] eq 'testing') {
    $got->{'got ircsock_input'}++;
  }

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
