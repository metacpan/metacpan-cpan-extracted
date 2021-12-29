use strict;
use warnings;
use Test::More 'no_plan';
use POE qw[Filter::Stackable Filter::Line Filter::IRCD];
use POE::Component::Server::IRC;
use Test::POE::Client::TCP;
use IRC::Utils qw[BOLD YELLOW NORMAL];

my $ts = time;

my $uidts;

my %servers = (
 'listen.server.irc'   => '1FU',
 'groucho.server.irc'  => '7UP',
 'harpo.server.irc'    => '9T9',
 'fake.server.irc'     => '4AK',
);

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    config => { servername => 'listen.server.irc', sid => '1FU', anti_spam_exit_message_time => 0 },
);

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            _launch_client
            ircd_listener_add
            ircd_daemon_nick
            ircd_daemon_dline
            ircd_daemon_undline
            ircd_daemon_eob
            client_connected
            client_input
            client_disconnected
            groucho_connected
            groucho_input
            groucho_disconnected
            harpo_connected
            harpo_input
            harpo_disconnected
        )],
        'main' => {
            client_registered  => 'testc_registered',
            groucho_registered => 'testc_registered',
            harpo_registered   => 'testc_registered',
        },
    ],
    heap => {
      ircd  => $pocosi,
      eob   => 0,
      topic => 0,
    },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->add_listener();
    $kernel->delay('_shutdown', 60, 'timeout');
}

sub _shutdown {
    my $heap = $_[HEAP];
    if ( $_[ARG0] && $_[ARG0] eq 'timeout' ) {
      fail('We timed out');
    }
    exit;
    return;
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];
    pass("Started a listener on $port");
    $heap->{port} = $port;
    $heap->{ircd}->add_peer(
        name  => 'groucho.server.irc',
        pass  => 'foo',
        rpass => 'foo',
        type  => 'c',
        zip   => 1,
    );
    $heap->{ircd}->add_peer(
        name  => 'harpo.server.irc',
        pass  => 'foo',
        rpass => 'foo',
        type  => 'c',
        zip   => 1,
    );
    $heap->{ircd}->yield(
        'add_spoofed_nick',
        {
            nick  => 'OperServ',
            umode => 'o',
        },
    );
    return;
}

sub ircd_daemon_nick {
    my ($heap,@args) = @_[HEAP,ARG0..$#_];

    is($args[0], 'OperServ', 'Spoof Test 1: Nick');
    is($args[4], 'OperServ', 'Spoof Test 1: User');
    is($args[5], 'listen.server.irc', 'Spoof Test 1: Host');
    is($args[6], 'listen.server.irc', 'Spoof Test 1: Server');
    is($args[3], '+o', 'Spoof Test 1: Umode');
    is($args[7], "* I'm too lame to read the documentation *", 'Spoof Test 1: GECOS');
    is( scalar keys %{ $pocosi->{state}{uids} }, 1, 'Spoof generated a UID' );

    foreach my $tag ( qw[groucho harpo] ) {
      my $filter = POE::Filter::Stackable->new();
      $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
                POE::Filter::IRCD->new( debug => 0 ), );
      push @{ $heap->{testc} }, Test::POE::Client::TCP->spawn( alias => $tag, filter => $filter, address => '127.0.0.1', port => $heap->{port}, prefix => $tag );
    }
    $poe_kernel->state($_[STATE]);
    return;
}

sub ircd_daemon_dline {
    my ($heap,@args) = @_[HEAP,ARG0..$#_];
    is($args[0], 'OperServ!OperServ@listen.server.irc', 'Setter is okay' );
    is($args[1], '127.0.0.1/32', 'The mask is right' );
    is($args[2], 10, 'Duration should be zero' );
    is($args[3], 'Banhammer', 'The reasoning is sound' );
    my $result = $heap->{ircd}->denied('127.0.0.1');
    is($result,'You have been D-lined.','Denial should return correct value');
    $poe_kernel->yield('_launch_client');
    return;
}

sub ircd_daemon_undline {
    my ($heap,@args) = @_[HEAP,ARG0..$#_];
    is($args[0], 'OperServ!OperServ@listen.server.irc', 'unsetter is okay' );
    is($args[1], '127.0.0.1/32', 'The mask is right' );
    my $result = $heap->{ircd}->denied('127.0.0.1');
    is( $result, undef, 'Not denied' );
    $poe_kernel->post('client','connect');
    return;
}

sub _launch_client {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $filter = POE::Filter::Stackable->new();
  $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
             POE::Filter::IRCD->new( debug => 0 ), );
  my $tag = 'client';
  $heap->{client} = Test::POE::Client::TCP->spawn( alias => $tag, filter => $filter, address => '127.0.0.1', port => $heap->{port}, prefix => $tag );
  return;
}

sub testc_registered {
  my ($kernel,$sender) = @_[KERNEL,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'connect' );
  return;
}

sub client_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'NICK', params => [ 'bobbins' ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'USER', params => [ 'bobbins', '*', '*', 'bobbins along' ], colonify => 1 } );
  return;
}

sub groucho_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'PASS', params => [ 'foo', 'TS', '6', '7UP' ], } );
  $kernel->post( $sender, 'send_to_server', { command => 'CAPAB', params => [ 'KNOCK UNDLN DLN TBURST GLN ENCAP UNKLN KLN CHW IE EX HOPS SVS CLUSTER EOB QS' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SERVER', params => [ 'groucho.server.irc', '1', 'Open the door and come in!!!!!!' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SVINFO', params => [ '6', '6', '0', time() ], colonify => 1 } );
  $uidts = time() - 20;
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'SID', params => [ 'fake.server.irc', 2, '4AK', 'This is a fake server' ] } );
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'UID', params => [ 'groucho', '1', $uidts, '+aiow', 'groucho', 'groucho.marx', '0', '7UPAAAAAA', '0', 'Groucho Marx' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'EOB', prefix => '7UP' } );
  $kernel->post( $sender, 'send_to_server', { command => 'EOB', prefix => '4AK' } );
  $kernel->post( $sender, 'send_to_server', { command => 'PING', params => [ '7UP' ], colonify => 1 } );
  return;
}

sub harpo_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'PASS', params => [ 'foo', 'TS', '6', '9T9' ], } );
  $kernel->post( $sender, 'send_to_server', { command => 'CAPAB', params => [ 'KNOCK UNDLN DLN TBURST GLN ENCAP UNKLN KLN CHW IE EX HOPS SVS CLUSTER EOB QS' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SERVER', params => [ 'harpo.server.irc', '1', 'Open the door and come in!!!!!!' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SVINFO', params => [ '6', '6', '0', time() ], colonify => 1 } );
  $uidts = time() - 20;
  $kernel->post( $sender, 'send_to_server', { prefix => '9T9', command => 'UID', params => [ 'harpo', '1', $uidts, '+aiow', 'harpo', 'harpo.marx', '0', '9T9AAAAAA', '0', 'Harpo Marx' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'EOB', prefix => '9T9' } );
  $kernel->post( $sender, 'send_to_server', { command => 'PING', params => [ '9T9' ], colonify => 1 } );
  return;
}


sub client_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  #diag($in->{raw_line}, "\n");
  is( $cmd, 'ERROR', 'ERROR ERROR!' );
  is( $params->[0], 'You have been D-lined.', 'You have been D-lined.' );
  return;
}

sub client_input2 {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  #diag($in->{raw_line}, "\n");
  pass("IRC_$cmd");
  if ( $cmd eq 'MODE' && $params->[0] eq 'bobbins' ) {
    $poe_kernel->post( $sender, 'send_to_server', { command => 'QUIT', params => [ 'Connection reset by fear' ] } );
    return;
  }
  if ( $cmd eq 'ERROR' ) {
    like( $params->[0], qr/Closing Link/, 'Closing Link' );
    return;
  }
  return;
}

# :1FUAAAAAA DLINE * 0 127.0.0.1/32 :Banhammer
# :1FUAAAAAA UNDLINE * :127.0.0.1/32


sub groucho_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq 'DLINE' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAA', 'Correct prefix: 1FUAAAAAAA' );
    is( $params->[0], '*', 'Target is all servers' );
    is( $params->[1], 600, 'Duration is 600 seconds' );
    is( $params->[2], '127.0.0.1/32', 'Mask is correct' );
    is( $params->[3], 'Banhammer', 'A sound reason indeed' );
    return;
  }
  if ( $cmd eq 'UNDLINE' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAA', 'Correct prefix: 1FUAAAAAAA' );
    is( $params->[0], '*', 'Target is all servers' );
    is( $params->[1], '127.0.0.1/32', 'Mask is correct' );
    return;
  }
  if ( $cmd eq 'QUIT' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAB', 'Correct prefix: 1FUAAAAAAB' );
    is( $params->[0], q{Quit: "Connection reset by fear"}, 'Correct QUIT message' );
    return;
  }
  if ( $cmd eq 'SQUIT' ) {
    pass($cmd);
    is( $params->[0], '9T9', 'Correct SID: 9T9' );
    like( $params->[1], qr/^(Remote host closed the connection|Connection reset by peer)$/, 'Remote host closed the connection' );
    $poe_kernel->post( $sender, 'terminate' );
    return;
  }
  return;
}

sub harpo_input {
  my ($heap,$in) = @_[HEAP,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq 'DLINE' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAA', 'Correct prefix: 1FUAAAAAAA' );
    is( $params->[0], '*', 'Target is all servers' );
    is( $params->[1], 600, 'Duration is 600 seconds' );
    is( $params->[2], '127.0.0.1/32', 'Mask is correct' );
    is( $params->[3], 'Banhammer', 'A sound reason indeed' );
    return;
  }
  if ( $cmd eq 'UNDLINE' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAA', 'Correct prefix: 1FUAAAAAAA' );
    is( $params->[0], '*', 'Target is all servers' );
    is( $params->[1], '127.0.0.1/32', 'Mask is correct' );
    return;
  }
  if ( $cmd eq 'QUIT' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAB', 'Correct prefix: 1FUAAAAAAB' );
    is( $params->[0], q{Quit: "Connection reset by fear"}, 'Correct QUIT message' );
    return;
  }
  return;
}

sub client_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->state('client_disconnected','main','client_disconnected2');
  $poe_kernel->state('client_input','main','client_input2');
  $heap->{ircd}->yield('daemon_cmd_undline','OperServ','127.0.0.1/32','ON','*');
  return;
}
sub client_disconnected2 {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  $heap->{ircd}->yield('shutdown');
  $poe_kernel->delay('_shutdown');
  return;
}

sub groucho_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  $heap->{ircd}->yield('shutdown');
  $poe_kernel->delay('_shutdown');
  return;
}

sub harpo_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  #$poe_kernel->post( 'groucho', 'terminate' );
  return;
}

sub ircd_daemon_eob {
  my ($kernel,$heap,$sender,@args) = @_[KERNEL,HEAP,SENDER,ARG0..$#_];
  $heap->{eob}++;
  pass($_[STATE]);
  if ( defined $servers{ $args[0] } ) {
    pass('Correct server name in EOB: ' . $args[0]);
    is( $args[1], $servers{ $args[0] }, 'Correct server ID in EOB: ' . $args[1] );
  }
  else {
    fail('No such server expected');
  }
  if ( $heap->{eob} >= 3 ) {
    #$poe_kernel->yield('_launch_client');
    $heap->{ircd}->yield( 'daemon_cmd_dline', 'OperServ', '10', '127.0.0.1', 'ON', '*', 'Banhammer' );
  }
  return;
}
