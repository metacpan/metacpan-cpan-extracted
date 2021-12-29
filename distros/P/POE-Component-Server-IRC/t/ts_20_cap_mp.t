use strict;
use warnings;
use Test::More 'no_plan';
use POE qw[Filter::Stackable Filter::Line Filter::IRCD];
use POE::Component::Server::IRC;
use Test::POE::Client::TCP;

my $ts = time();

my $uidts;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    config => { servername  => 'listen.server.irc', sid => '1FU' },
);

my $CAPS = join ' ', sort keys %{ $pocosi->{state}{caps} };

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            _terminate
            _join
            ircd_listener_add
            testc_registered
            testc_connected
            testc_input
            testc_disconnected
        )],
    ],
    heap => { ircd => $pocosi, registered => 0, end => {}, shutdown => 0, 315 => 0, mode => 0 },
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
  $_->terminate() for @{ $heap->{testc} };
  return;
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Started a listener on $port");
    $heap->{port} = $port;
    my $bots = {
      'teapot' => 'Short and stout',
      'muffet' => 'Sat on a tuffet',
      'horner' => 'Eating a Christmas pie',
    };
    foreach my $bot ( sort keys %$bots ) {
      my $filter = POE::Filter::Stackable->new();
      $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
                POE::Filter::IRCD->new( debug => 0 ), );
      push @{ $heap->{testc} }, Test::POE::Client::TCP->spawn( filter => $filter, address => '127.0.0.1', port => $port, context => [ $bot, '*', '*', $bots->{$bot} ] );
    }
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
  my $context = $sender->get_heap()->{context};
  $kernel->post( $sender, 'send_to_server', { command => 'CAP', params => [ 'LS' ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'NICK', params => [ $context->[0] ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'USER', params => $context } );
  return;
}

sub testc_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  my $reg = $heap->{registered};
  my $context = $sender->get_heap()->{context};
  #diag($in->{raw_line}, "\n");
  my $nick = $context->[0];
  if ( $in->{command} eq 'MODE' && $in->{params}[0] eq '#nursery' ) {
    $heap->{mode}++;
    return;
  }
  if ( $in->{command} eq '315' ) {
    $heap->{315}++;
    $poe_kernel->yield('_terminate') if $heap->{315} == 2;
    return;
  }
  if ( $in->{command} eq 'CAP' ) {
    SWITCH: {
      if ( !$reg && $in->{params}[0] eq '*' ) {
        pass('Not registered so NICK is *');
      }
      if ( $in->{params}[1] eq 'LS' ) {
        is( $in->{params}[2], $CAPS, qq{LS listed "$CAPS"} );
        $poe_kernel->post( $sender, 'send_to_server', { command => 'CAP', params => [ 'REQ', 'multi-prefix' ], colonify => 1 } );
        last SWITCH;
      }
      if ( $in->{params}[1] eq 'ACK' ) {
        is( $in->{params}[2], 'multi-prefix', 'ACK for capability' );
        $poe_kernel->post( $sender, 'send_to_server', { command => 'CAP', params => [ 'END' ], colonify => 0 } );
        $heap->{end}{$nick}++;
        last SWITCH;
      }
    }
  }
  if ( $in->{command} eq '001' ) {
    $heap->{registered} = $reg = 1;
    is( $heap->{end}{$nick}, 1, 'Got registered after sending CAP END');
    if ( $nick eq 'teapot' ) {
      $poe_kernel->post( $sender, 'send_to_server', { command => 'JOIN', params => [ '#nursery' ], colonify => 0 } );
      return;
    }
    else {
      #diag("Delay JOIN for $nick\n");
      $poe_kernel->delay_add( '_join', int(rand(10)), $sender->ID(), $nick );
      return;
    }
  }
  if ( $in->{command} eq 'JOIN' && $nick eq 'teapot' ) {
    $poe_kernel->post( $sender, 'send_to_server', { command => 'MODE', params => [ '#nursery', '+hv', 'teapot', 'teapot' ], colonify => 0 } );
    return;
  }
  if ( $in->{command} eq '353' && $nick ne 'teapot' ) {
    like( $in->{params}[-1], qr/^\Q@%+teapot\E/, 'We have the correct prefix for teapot');
    $poe_kernel->post( $sender, 'send_to_server', { command => 'WHO', params => [ '#nursery' ], colonify => 0 } );
    return;
  }
  if ( $in->{command} eq '352' && $nick ne 'teapot' ) {
    return if $in->{params}[5] ne 'teapot';
    is( $in->{params}[6], 'H@%+', 'Have correct prefix for teapot' );
    return;
  }
  return;
}

sub _join {
  my ($kernel,$heap,$sess,$nick) = @_[KERNEL,HEAP,ARG0,ARG1];
  my $sender = $kernel->alias_resolve( $sess );
  if ( !$heap->{mode} ) {
    #diag("Delay JOIN for $nick\n");
    $poe_kernel->delay_add( '_join', int(rand(10)), $sess, $nick );
  }
  else {
    $kernel->post( $sender, 'send_to_server', { command => 'JOIN', params => [ '#nursery' ], colonify => 0 } );
  }
  return;
}

sub testc_disconnected {
  my ($heap,$state) = @_[HEAP,STATE];
  pass($state);
  return if $heap->{shutdown} != 0;
  $heap->{shutdown}++;
  $_->shutdown() for @{ $heap->{testc} };
  $heap->{ircd}->yield('shutdown');
  $poe_kernel->delay('_shutdown');
  return;
}
