use strict;
use warnings;
use Test::More tests => 9;
use POE qw[Filter::Stackable Filter::Line Filter::IRCD];
use POE::Component::Server::IRC;
use Test::POE::Client::TCP;

my $ts = time();

my $uidts;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    config => { servername   => 'listen.server.irc', sid => '1FU' },
);

my $CAPS = join ' ', sort keys %{ $pocosi->{state}{caps} };

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            _terminate
            ircd_listener_add
            testc_registered
            testc_connected
            testc_input
            testc_disconnected
        )],
    ],
    heap => { ircd => $pocosi, registered => 0, end => 0 },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->add_listener();
    $kernel->delay('_shutdown', 60);
}

sub _shutdown {
    my $heap = $_[HEAP];
    $_[KERNEL]->delay('_shutdown');
    $heap->{ircd}->yield('shutdown');
    delete $heap->{ircd};
}

sub _terminate {
  my $heap = $_[HEAP];
  $heap->{testc}->terminate();
  return;
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Started a listener on $port");
    $heap->{port} = $port;
    my $filter = POE::Filter::Stackable->new();
    $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
               POE::Filter::IRCD->new( debug => 0 ), );
    $heap->{testc} = Test::POE::Client::TCP->spawn( filter => $filter, address => '127.0.0.1', port => $port );
    return;
}

sub testc_registered {
  my ($kernel,$sender) = @_[KERNEL,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'connect' );
  return;
}

sub testc_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'CAP', params => [ 'LS' ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'NICK', params => [ 'teapot' ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'USER', params => [ qw[teapot * * teapot ] ] } );
  return;
}

sub testc_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  my $reg = $heap->{registered};
  if ( $in->{command} eq 'CAP' ) {
    SWITCH: {
      if ( !$reg && $in->{params}[0] eq '*' ) {
        pass('Not registered so NICK is *');
      }
      if ( $in->{params}[1] eq 'LS' ) {
        is( $in->{params}[2], $CAPS, qq{LS listed "$CAPS"} );
        $poe_kernel->post( $sender, 'send_to_server', { command => 'CAP', params => [ 'REQ', 'bogus invite-notify' ], colonify => 1 } );
        last SWITCH;
      }
      if ( $in->{params}[1] eq 'NAK' ) {
        is( $in->{params}[2], 'bogus invite-notify', 'NAK because of bogus capability' );
        $poe_kernel->post( $sender, 'send_to_server', { command => 'CAP', params => [ 'REQ', 'invite-notify' ], colonify => 1 } );
        last SWITCH;
      }
      if ( $in->{params}[1] eq 'ACK' ) {
        is( $in->{params}[2], 'invite-notify', 'ACK for capability' );
        $poe_kernel->post( $sender, 'send_to_server', { command => 'CAP', params => [ 'END' ], colonify => 0 } );
        $heap->{end}++;
        last SWITCH;
      }
    }
  }
  if ( $in->{command} eq '001' ) {
    $heap->{registered} = $reg = 1;
    is( $heap->{end}, 1, 'Got registered after sending CAP END');
    $poe_kernel->delay( '_terminate', 5 );
  }
  return;
}

sub testc_disconnected {
  my ($heap,$state) = @_[HEAP,STATE];
  pass($state);
  $heap->{testc}->shutdown();
  $heap->{ircd}->yield('shutdown');
  $poe_kernel->delay('_shutdown');
  return;
}
