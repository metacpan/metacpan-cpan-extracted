use strict;
use warnings;
use Test::More tests => 11;
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
  $kernel->post( $sender, 'send_to_server', { command => 'NICK', params => [ 'teapot' ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'USER', params => [ qw[teapot * * teapot ] ] } );
  return;
}

sub testc_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $cmd = $in->{command};
  my $pre = $in->{prefix};
  my $par = $in->{params};
  if ( $cmd eq 'MODE' ) {
    pass($cmd);
    $poe_kernel->post( $sender, 'send_to_server', { command => 'AWAY', params => [ 'Do not bother me!' ] } );
  }
  if ( $cmd eq '306' ) {
    pass("IRC_$cmd");
    is( $par->[0], 'teapot', 'Correct NICK in response' );
    is( $par->[1], 'You have been marked as being away', 'We are well away' );
    $poe_kernel->post($sender, 'send_to_server', { command => 'AWAY' } );
    return;
  }
  if ( $cmd eq '305' ) {
    pass("IRC_$cmd");
    is( $par->[0], 'teapot', 'Correct NICK in response' );
    is( $par->[1], 'You are no longer marked as being away', 'We are back' );
    $poe_kernel->post($sender, 'send_to_server', { command => 'QUIT' } );
    return;
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
