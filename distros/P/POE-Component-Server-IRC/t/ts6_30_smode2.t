use strict;
use warnings;
use Test::More 'no_plan';
use POE qw[Filter::Stackable Filter::Line Filter::IRCD];
use POE::Component::Server::IRC;
use Test::POE::Client::TCP;
use IRC::Utils qw[BOLD YELLOW NORMAL];

my %servers = (
 'listen.server.irc'   => '1FU',
 'groucho.server.irc'  => '7UP',
 'harpo.server.irc'    => '9T9',
 'fake.server.irc'     => '4AK',
);

my $ts = time();

my $uidts;

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
            _launch_client2
            _launch_client3
            _clients_quit
            ircd_listener_add
            ircd_daemon_eob
            groucho_connected
            groucho_input
            groucho_disconnected
            harpo_connected
            harpo_input
            harpo_disconnected
            client_connected
            client_input
            client_disconnected
            client2_connected
            client2_input
            client2_disconnected
            client3_connected
            client3_input
            client3_disconnected
        )],
        'main' => {
            groucho_registered => 'testc_registered',
            harpo_registered   => 'testc_registered',
            client_registered  => 'testc_registered',
            client2_registered  => 'testc_registered',
            client3_registered  => 'testc_registered',
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
    $heap->{ircd}->add_service('fake.server.irc');
    foreach my $tag ( qw[groucho harpo] ) {
      my $filter = POE::Filter::Stackable->new();
      $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
                POE::Filter::IRCD->new( debug => 0 ), );
      push @{ $heap->{testc} }, Test::POE::Client::TCP->spawn( alias => $tag, filter => $filter, address => '127.0.0.1', port => $port, prefix => $tag );
    }
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

sub _launch_client2 {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $filter = POE::Filter::Stackable->new();
  $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
             POE::Filter::IRCD->new( debug => 0 ), );
  my $tag = 'client2';
  $heap->{client} = Test::POE::Client::TCP->spawn( alias => $tag, filter => $filter, address => '127.0.0.1', port => $heap->{port}, prefix => $tag );
  return;
}

sub _launch_client3 {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $filter = POE::Filter::Stackable->new();
  $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
             POE::Filter::IRCD->new( debug => 0 ), );
  my $tag = 'client3';
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

sub client2_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'NICK', params => [ 'rubbarb' ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'USER', params => [ 'rubbarb', '*', '*', 'rubbarb rubbarb' ], colonify => 1 } );
  return;
}

sub client3_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'NICK', params => [ 'custard' ], colonify => 0 } );
  $kernel->post( $sender, 'send_to_server', { command => 'USER', params => [ 'custard', '*', '*', 'custard cream' ], colonify => 1 } );
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
  $kernel->post( $sender, 'send_to_server', { prefix => '4AK', command => 'UID', params => [ 'NickServ', '2', ($uidts - 50), '+iow', 'nickserv', 'nickserv.server.irc', '0', '4AKAAAAAA', '0', 'NickServ' ], colonify => 1 } );
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
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq 'MODE' && $prefix =~ m'^bobbins' && $params->[1] eq '+i' ) {
    pass($cmd);
    $poe_kernel->post( $sender, 'send_to_server', { command => 'JOIN', params => [ '#floobar' ], colonify => 0 } );
    $poe_kernel->delay('_launch_client2', 2) if !$heap->{client2};
  }
  if ( $cmd eq 'JOIN' ) {
    pass($cmd);
    if ( $prefix =~ m{^rubbarb!} ) {
      return;
    }
    if ( $prefix =~ m{^custard!} ) {
      return;
    }
    return;
  }
  return;
}

sub _clients_quit {
    $poe_kernel->post($_, 'send_to_server', { command => 'QUIT', params => [ 'Connection reset by fear' ] } )
      for qw[client3 client2 client];
    return;
}

sub client2_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq 'MODE' && $prefix =~ m'^rubbarb' && $params->[1] eq '+i' ) {
    pass($cmd);
    $heap->{client2}++;
    $poe_kernel->post( $sender, 'send_to_server', { command => 'JOIN', params => [ '#floobar'], colonify => 0 } );
    return;
  }
  if ( $cmd eq '366' ) {
    $heap->{ircd}->daemon_server_mode('#floobar', '+h', 'rubbarb');
    $poe_kernel->yield('_launch_client3');
    return;
  }
  if ( $cmd eq 'MODE' && $prefix eq 'listen.server.irc' ) {
    pass($cmd);
    is($params->[0],'#floobar','Channel #floobar');
    is($params->[1],'+h','Halfop');
    is($params->[2],'rubbarb','Okay nickname');
    return;
  }
  if ( $cmd eq '441' ) {
    pass("IRC$cmd");
    is($params->[1],'custard','custard');
    is($params->[2],q{They aren't on that channel},q{They aren't on that channel});
    $poe_kernel->post( $sender, 'send_to_server', { command => 'KICK', params => [ '#floobar', 'bobbins', 'Filthy ape' ], colonify => 0 } );
    return;
  }
  if ( $cmd eq '482' ) {
    pass("IRC$cmd");
    is($params->[1],'#floobar','That channel');
    is($params->[2],q{You're not channel operator},q{You're not channel operator});
    $poe_kernel->yield('_clients_quit');
    return;
  }
  return;
}

sub client3_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq 'MODE' && $prefix =~ m'^custard' && $params->[1] eq '+i' ) {
    pass($cmd);
    $poe_kernel->post( $sender, 'send_to_server', { command => 'JOIN', params => [ '#floobar' ], colonify => 0 } );
  }
  if ( $cmd eq '366' ) {
    $heap->{ircd}->daemon_server_kick('#floobar', 'custard', 'Filthy ape');
    return;
  }
  if ( $cmd eq 'KICK' ) {
    pass($cmd);
    is($prefix,'listen.server.irc','listen.server.irc');
    is($params->[0],'#floobar','Channel is correct');
    is($params->[1],'custard','I am being KICKed');
    is($params->[2],'Filthy ape','Pithy comment');
    $poe_kernel->post( 'client2', 'send_to_server', { command => 'KICK', params => [ '#floobar', 'custard', 'Filthy ape' ], colonify => 0 } );
    return;
  }
  return;
}

sub groucho_input {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq 'SQUIT' ) {
    pass($cmd);
    is( $params->[0], '9T9', 'Correct SID: 9T9' );
    like( $params->[1], qr/^(Remote host closed the connection|Connection reset by peer)$/, 'Remote host closed the connection' );
    $poe_kernel->post( $sender, 'terminate' );
    return;
  }
  if ( $cmd eq 'UID' ) {
    pass($cmd);
    return if $params->[0] !~ m!^(rubbarb|bobbins)$!;
    $poe_kernel->post($sender, 'send_to_server', { prefix => '4AK', command => 'SVSMODE', params => [ $params->[7], $params->[2], '+dr', $params->[0] ] } );
    return;
  }
  if ( $cmd eq 'KICK' ) {
    pass($cmd);
    is($prefix,'1FU','1FU');
    is($params->[0],'#floobar','Channel is correct');
    is($params->[1],'1FUAAAAAC','I am being KICKed');
    is($params->[2],'Filthy ape','Pithy comment');
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
  return;
}

sub client_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  $poe_kernel->post( 'harpo', 'terminate' );
  return;
}

sub client2_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  return;
}

sub client3_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  return;
}

sub groucho_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  $heap->{ircd}->yield('shutdown');
  $poe_kernel->alarm_remove_all();
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
      $poe_kernel->yield('_launch_client');
  }
  return;
}
