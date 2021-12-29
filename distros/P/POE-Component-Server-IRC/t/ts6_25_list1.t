package Poco::Server::IRC::UID;

use strict;
use warnings;
use base qw[POE::Component::Server::IRC];

sub spawn {
    my ($package, %args) = @_;
    $args{lc $_} = delete $args{$_} for keys %args;
    my $config = delete $args{config};
    my $self = bless {}, $package;
    $self->configure($config ? $config : ());
    $self->_state_create();
    return $self;
}

package main;

use strict;
use warnings;
use Test::More 'no_plan';
use POE qw[Filter::Stackable Filter::Line Filter::IRCD];
use POE::Component::Server::IRC;
use Test::POE::Client::TCP;
use IRC::Utils qw[BOLD YELLOW NORMAL];

my $g_gen = Poco::Server::IRC::UID->spawn( config => { sid => '7UP' } );
my $h_gen = Poco::Server::IRC::UID->spawn( config => { sid => '9T9' } );

my %servers = (
 'listen.server.irc'   => '1FU',
 'groucho.server.irc'  => '7UP',
 'harpo.server.irc'    => '9T9',
 'fake.server.irc'     => '4AK',
);

my $ts = time();

my @users;

while (<DATA>) {
  chomp;
  push @users, $_;
}

my %channels = (
'#anamaria' => { ts => $ts - ( 60 * 3 ), users => 100, topic => 'Here be pirates', tts => $ts - ( 60 * 2 ), setby => shift @users },
'#angelica' => { ts => $ts - ( 60 * 3 ), users => 100, topic => 'We have pirates here', tts => $ts - ( 60 * 1 ), setby => shift @users },
'#angler' => { ts => $ts - ( 60 * 3 ), users => 15 },
'#blackbeard' => { ts => $ts - ( 60 * 3 ), users => 15 },
'#bosun' => { ts => $ts - ( 60 * 60 * 60 ), users => 72, mode => '+nst' },
'#clanker' => { ts => $ts - ( 60 * 60 * 60 ), users => 24 },
'#davyjones' => { ts => $ts - ( 60 * 60 * 60 ), users => 6 },
'#elizabeth' => { ts => $ts - ( 60 * 60 * 20 ), users => 3 },
'#guarddog' => { ts => $ts - ( 60 * 60 * 20 ), users => 7 },
'#jacksparrow' => { ts => $ts - ( 60 * 60 * 20 ), users => 2, topic => 'Welcome to the black pearl', tts => $ts - ( 60 * 60 * 19 ), setby => shift @users },
'#jimmylegs' => { ts => $ts - ( 60 * 40 * 20 ), users => 1 },
'#maccus' => { ts => $ts - ( 60 * 40 * 20 ), users => 75 },
'#mallot' => { ts => $ts - ( 60 * 40 * 20 ), users => 41 },
'#marty' => { ts => $ts - ( 60 * 40 * 20 ), users => 56 },
'#mercer' => { ts => $ts - ( 30 * 40 * 20 ), users => 27 },
'#norrington' => { ts => $ts - ( 10 * 40 * 20 ), users => 39 },
'#penrod' => { ts => $ts - ( 10 * 40 * 20 ), users => 11, mode => '+npt' },
'#pintel' => { ts => $ts - ( 10 * 40 * 20 ), users => 29 },
'#ragetti' => { ts => $ts - ( 10 * 40 * 20 ), users => 66 },
'#salaman' => { ts => $ts - ( 10 * 70 * 20 ), users => 14 },
'#scratch' => { ts => $ts - ( 10 * 70 * 20 ), users => 99, topic => 'Cat fever', tts => $ts - ( 10 * 70 * 19 ), setby => shift @users },
'#scrum' => { ts => $ts - ( 10 * 70 * 20 ), users => 32 },
'#syrena' => { ts => $ts - ( 10 * 70 * 20 ), users => 76 },
'#thespaniard' => { ts => $ts - ( 80 * 70 * 20 ), users => 1 },
'#twigg' => { ts => $ts - ( 80 * 70 * 20 ), users => 1 },
'#willturner' => { ts => $ts - ( 80 * 70 * 20 ), users => 19 },
'#wyvern' => { ts => $ts - ( 80 * 70 * 20 ), users => 47 },
);

my $uidts;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
    debug        => 0,
    config => { servername => 'listen.server.irc', sid => '1FU', anti_spam_exit_message_time => 0 },
);

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            _launch_client
            _launch_groucho
            _launch_harpo
            ircd_listener_add
            ircd_daemon_eob
            ircd_daemon_uid
            groucho_connected
            groucho_input
            groucho_disconnected
            harpo_connected
            harpo_input
            harpo_disconnected
            client_connected
            client_input
            client_disconnected
        )],
        'main' => {
            groucho_registered => 'testc_registered',
            harpo_registered   => 'testc_registered',
            client_registered  => 'testc_registered',
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
    $poe_kernel->yield( '_launch_groucho' );
    return;
}

sub ircd_daemon_uid {
  my ($kernel,$heap,@args) = @_[KERNEL,HEAP,ARG0..$#_];
  return;
}

sub _launch_groucho {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  foreach my $tag ( qw[groucho] ) {
      my $filter = POE::Filter::Stackable->new();
      $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
                POE::Filter::IRCD->new( debug => 0 ), );
      push @{ $heap->{testc} }, Test::POE::Client::TCP->spawn( alias => $tag, filter => $filter, address => '127.0.0.1', port => $heap->{port}, prefix => $tag );
   }
   return;
}

sub _launch_harpo {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  foreach my $tag ( qw[harpo] ) {
      my $filter = POE::Filter::Stackable->new();
      $filter->push( POE::Filter::Line->new( InputRegexp => '\015?\012', OutputLiteral => "\015\012" ),
                POE::Filter::IRCD->new( debug => 0 ), );
      push @{ $heap->{testc} }, Test::POE::Client::TCP->spawn( alias => $tag, filter => $filter, address => '127.0.0.1', port => $heap->{port}, prefix => $tag );
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
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'UID', params => [ 'groucho', '1', $uidts, '+aiow', 'groucho', 'groucho.marx', '0', $g_gen->_state_gen_uid(), '0', 'Groucho Marx' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { prefix => '7UPAAAAAA', command => 'AWAY', params => [ 'A minute and a huff' ], colonify => 1 } );
  my $i = 0;
  my @uids;
  while( $i++ < 150 ) {
    my $str = shift @users;
    next if !$str;
    my ($nick,$usr,$host) = split m/[!@]/, $str;
    my $uid = $g_gen->_state_gen_uid();
    push @uids, $uid;
    $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'UID', params => [ $nick, '1', ($uidts-int(rand(1000))), '+i', $usr, $host, '0', $uid, '0', $usr ], colonify => 1 } );
  }
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'SJOIN', params => [ ( time() - 50 ), '#marxbros', '+nt', '@7UPAAAAAA' ], colonify => 1 } );
  foreach my $chan ( sort keys %channels ) {
    my $len = 28 + length $chan;
    my $mode = ( $channels{$chan}{mode} || '+nt' );
    my $rec = [ $channels{$chan}{ts}, $chan, $mode ];
    my $j = 0; my $buf = '';
    UID: while ( $j < $channels{$chan}{users} ) {
      my $uid = $uids[$j];
      $j++;
      if (length(join ' ', $buf, '1', $uid)+$len+1 > 510) {
         $kernel->post( $sender, 'send_to_server',
                  {
                      prefix   => '7UP',
                      command  => 'SJOIN',
                      params   => [ @$rec, $buf ],
                      colonify => 1,
                  }
          );
          $buf = $uid;
          next UID;
      }
      $buf = join ' ', $buf, $uid;
      $buf =~ s!^\s+!!;
    }
    if ($buf) {
         $kernel->post( $sender, 'send_to_server',
                  {
                      prefix   => '7UP',
                      command  => 'SJOIN',
                      params   => [ @$rec, $buf ],
                      colonify => 1,
                  }
          );
    }
    if ( $channels{$chan}{topic} ) {
        $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'TBURST',
          params => [ $channels{$chan}{ts}, $chan, $channels{$chan}{tts}, $channels{$chan}{setby}, $channels{$chan}{topic} ], colonify => 1 } );
    }
  }
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
  $uidts = time() - 50;
  $kernel->post( $sender, 'send_to_server', { prefix => '9T9', command => 'UID', params => [ 'harpo', '1', $uidts, '+aiow', 'harpo', 'harpo.marx', '0', $h_gen->_state_gen_uid(), '0', 'Harpo Marx' ], colonify => 1 } );
  my $i = 0;
  my @uids;
  while( $i++ < 150 ) {
    my $str = shift @users;
    next if !$str;
    my ($nick,$usr,$host) = split m/[!@]/, $str;
    my $uid = $h_gen->_state_gen_uid();
    push @uids, $uid;
    $kernel->post( $sender, 'send_to_server', { prefix => '9T9', command => 'UID', params => [ $nick, '1', ($uidts-int(rand(1000))), '+i', $usr, $host, '0', $uid, '0', $usr ], colonify => 1 } );
  }
  $kernel->post( $sender, 'send_to_server', { prefix => '9T9', command => 'SJOIN', params => [ ( time() - 50 ), '#marxbros', '+nt', '@9T9AAAAAA' ], colonify => 1 } );
  foreach my $chan ( sort keys %channels ) {
    my $len = 27 + length $chan;
    my $rec = [ $channels{$chan}{ts}, $chan, '+nt' ];
    my $j = 0; my $buf = '';
    UID: while ( $j < $channels{$chan}{users} ) {
      my $uid = $uids[$j];
      $j++;
      if (length(join ' ', $buf, '1', $uid)+$len+1 > 510) {
         $kernel->post( $sender, 'send_to_server',
                  {
                      prefix   => '9T9',
                      command  => 'SJOIN',
                      params   => [ @$rec, $buf ],
                      colonify => 1,
                  }
          );
          $buf = $uid;
          next UID;
      }
      $buf = join ' ', $buf, $uid;
      $buf =~ s!^\s+!!;
    }
    if ($buf) {
         $kernel->post( $sender, 'send_to_server',
                  {
                      prefix   => '9T9',
                      command  => 'SJOIN',
                      params   => [ @$rec, $buf ],
                      colonify => 1,
                  }
          );
    }
    if ( $channels{$chan}{topic} ) {
        $kernel->post( $sender, 'send_to_server', { prefix => '9T9', command => 'TBURST',
          params => [ $channels{$chan}{ts}, $chan, $channels{$chan}{tts}, $channels{$chan}{setby}, $channels{$chan}{topic} ], colonify => 1 } );
    }
  }
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
  if ( $cmd eq 'MODE' && $prefix =~ m!^bobbins! ) {
    pass($cmd);
    $heap->{322} = 0;
    $poe_kernel->post($sender, 'send_to_server', { command => 'LIST' } );
    return;
  }
  if ( $cmd eq '321' ) {
    pass("IRC_$cmd $params->[1]");
    return;
  }
  if ( $cmd eq '322' ) {
    pass("IRC_$cmd $params->[1]");
    $heap->{$cmd}++;
    return;
  }
  if ( $cmd eq '323' ) {
    pass("IRC_$cmd $params->[1]");
    is($heap->{322},26,'There should be 26 channels listed');
    $heap->{322} = 0;
    $poe_kernel->state('client_input',\&client_input2);
    $poe_kernel->post($sender, 'send_to_server', { command => 'LIST' } );
    $poe_kernel->post($sender, 'send_to_server', { command => 'LIST' } );
    return;
  }
  return;
}

sub client_input2 {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq '321' ) {
    pass("IRC_$cmd $params->[1]");
    return;
  }
  if ( $cmd eq '322' ) {
    pass("IRC_$cmd $params->[1]");
    $heap->{$cmd}++;
    return;
  }
  if ( $cmd eq '323' ) {
    pass("IRC_$cmd $params->[1]");
    isnt($heap->{322},26,'There should NOT be 26 channels listed');
    $heap->{322} = 0;
    $poe_kernel->state('client_input',\&client_input3);
    $poe_kernel->post($sender, 'send_to_server', { command => 'LIST', params => [ 'T:*pirate*' ] } );
    return;
  }
  return;
}

sub client_input3 {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq '321' ) {
    pass("IRC_$cmd $params->[1]");
    return;
  }
  if ( $cmd eq '322' ) {
    pass("IRC_$cmd $params->[1]");
    $heap->{$cmd}++;
    return;
  }
  if ( $cmd eq '323' ) {
    pass("IRC_$cmd $params->[1]");
    is($heap->{322},2,'There should be 2 channels listed');
    $heap->{322} = 0;
    $poe_kernel->state('client_input',\&client_input4);
    $poe_kernel->post($sender, 'send_to_server', { command => 'LIST', params => [ '#*an*' ] } );
    return;
  }
  return;
}

sub client_input4 {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq '321' ) {
    pass("IRC_$cmd $params->[1]");
    return;
  }
  if ( $cmd eq '322' ) {
    pass("IRC_$cmd $params->[1]");
    $heap->{$cmd}++;
    return;
  }
  if ( $cmd eq '323' ) {
    pass("IRC_$cmd $params->[1]");
    is($heap->{322},6,'There should be 6 channels listed');
    $heap->{322} = 0;
    $poe_kernel->state('client_input',\&client_input5);
    $poe_kernel->post($sender, 'send_to_server', { command => 'LIST', params => [ '<10' ] } );
    return;
  }
  return;
}

sub client_input5 {
  my ($heap,$sender,$in) = @_[HEAP,SENDER,ARG0];
  #diag($in->{raw_line}, "\n");
  my $prefix = $in->{prefix};
  my $cmd    = $in->{command};
  my $params = $in->{params};
  if ( $cmd eq '321' ) {
    pass("IRC_$cmd $params->[1]");
    return;
  }
  if ( $cmd eq '322' ) {
    pass("IRC_$cmd $params->[1]");
    $heap->{$cmd}++;
    return;
  }
  if ( $cmd eq '323' ) {
    pass("IRC_$cmd $params->[1]");
    is($heap->{322},6,'There should be 6 channels listed');
    $heap->{322} = 0;
    $poe_kernel->post( $sender, 'send_to_server', { command => 'QUIT', params => [ q{Connection reset by fear} ] } );
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
  if ( $cmd eq 'QUIT' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAA', 'Correct prefix: 1FUAAAAAAA' );
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
  if ( $cmd eq 'PART' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAA', 'Correct prefix: 1FUAAAAAAA' );
    is( $params->[0], '#potato', 'Channel is correct: #potato' );
    is( $params->[1], 'Suckers', 'There is a parting messge' );
    return;
  }
  if ( $cmd eq 'QUIT' ) {
    pass($cmd);
    is( $prefix, '1FUAAAAAA', 'Correct prefix: 1FUAAAAAAA' );
    is( $params->[0], q{Quit: "Connection reset by fear"}, 'Correct QUIT message' );
    $poe_kernel->post( 'harpo', 'terminate' );
    return;
  }
  return;
}

sub client_disconnected {
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
  $poe_kernel->delay('_shutdown');
  return;
}

sub harpo_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
  $poe_kernel->call( $sender, 'shutdown' );
  $poe_kernel->post( 'groucho', 'terminate' );
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
  if ( $args[1] eq '4AK' ) {
    $kernel->yield('_launch_harpo');
  }
  if ( $args[1] eq '9T9' ) {
    $kernel->yield('_launch_client');
  }
  return;
}

__DATA__
aayla_sec!aurrasing@ozeer.tenzer.in
adam!theatom@heatwave.com
adam_west!azrael@cheetah.ch
ahsoka_ta!rey@ga.97.fr
air_hoste!popstar@weather.girl.com
airline_a!jessieweing@cacey.ru
albert_ru!professorsl@xenophilius.lovegood.net
ambush_bu!gorillagrod@krypto.the.superdog.org
ammand_th!murtogg@mr.brown.ru
anamaria!ancientsail@eduardo.villanueva.ru
anchor_ma!vinnieclown@sarah.horner.in
angelica!koehler@mr.gibbs.ru
angler!anamaria@lord.cutler.beckett.ch
angry_can!grapple@governor.weatherby.swann.fr
aquaman!supergirl@two.face.ru
argus_fil!emmelinevan@ministry.guard.ru
at_st_pil!lorsantekk@o.mr1.usa
a_wing_pi!battledroid@obi.wan.kenobi.net
barty_cro!mafaldahopk@reg.cattermole.usa
bat_cow!vibe@two.face.goon.com
batgirl!orangeconst@alfred.fr
batman!jokerspace@condiment.king.com
bazine_ne!jjabrams@cratinus.com
becky_bal!rapper@forest.fireman.com
beefy_bak!sumowrestle@crazy.scientist.usa
bith!kananjarrus@teedo.ru
blackbear!lieutenantg@derrick.com
blaise_za!professorqu@professor.binns.com
bootstrap!gunner@twigg.uk
boxer!skatergirl@louise.andrew.org
brad_hogg!submarineca@weightlifter.usa
brainiac!dickgrayson@kelex.ru
brainiac_!plasticman@bruce.wayne.usa
bronze_ti!sinestro@penguin.minion.com
bryony_mu!brantfordcu@waitress.usa
bud_hawki!spaceman@henrik.kowalski.ru
captain_b!kevinsmith@general.zod.usa
captain_e!gunner@syrena.ch
captaine_!taihuang@bootstrap.bill.turner.usa
captain_r!korrsella@r5.d4.usa
carlo_con!chasesuit@blue.whittaker.ch
carlo_jer!disguisedna@lagney.uk
cave_woma!jethrohayes@butcher.ch
cedric_di!durmstrangs@dragon.handler.org
charity_b!viktorkrum@ernie.prang.com
cheshire!zatanna@miss.martian.org
chewbacca!nakalit@yoda.usa
cho_chang!slytheringi@cormac.mclaggen.fr
clanker!cotton@salaman.in
clark_ken!twoface@mad.hatter.ru
clayface!zodagent@superman.in
clockwork!garbageman@mummy.fr
clubba!jacoby@mallot.ru
colin_cre!tomtheinnk@marcus.flint.ru
commander!fn2112@thromba.in
commando_!bossk@gamorrean.guard.net
cook!jimmylegs@lord.cutler.beckett.fr
cornelius!professorsi@ron.weasley.net
cotton!ancientsail@norrington.org
count_doo!laparo@supreme.leader.snoke.com
crash!angler@mistress.ching.in
croll_jen!mantellians@strus.clan.raider.fr
cyborg!larfleeze@doctor.fate.uk
damumbo!gasstation@chase.undercover.uk
darth_mau!oskusstoora@watto.fr
darth_vad!bibfortuna@logray.uk
dasha_pro!otteganwarr@kathleen.kennedy.uk
davy_jone!murtogg@pintel.net
dean_thom!dragomirdes@slytherin.twin.1.net
death_sta!firstorder@tasu.leech.usa
derrick!kinggeorge@classic.alien.ch
detective!policeman@aquaman.fr
dex_starr!frankenstein@captain.cold.in
dick_gray!starsapphir@zoo.sweeper.ch
dirk_cres!fredweasley@professor.snape.org
disco_dud!spikeydon@troublemaker.tom.uk
docks_cra!huladancer@street.skater.org
docks_for!barrysmith@magician.uk
doomsday!catwoman@bane.in
door_man!corneliusbu@karate.guy.fr
dougy_dun!vitustinkle@farm.worker.bob.org
draco_mal!ravenclawgi@professor.slughorn.net
dr_whatsi!viking@ben.moseley.uk
dumbledor!professorsp@pius.thicknesse.org
dutch_dan!paparazzo@chuck.morrison.ch
eduardo_v!scrum@hadras.fr
elf!wardenstone@artist.uk
elizabeth!quartermaste@bosun.fr
ellie_phi!troublemaker@cal.wainwright.fr
ello_asty!chiefpetty@razoo.qin.fee.ru
elphias_d!professorum@dragon.handler.ru
faora!acethebat@giganta.usa
farmer_ba!coastguard@lifeguard.net
fat_friar!siriusblack@professor.vector.fr
fenrir_gr!lunalovegoo@nearly.headless.nick.fr
firestorm!theflash@dex.starr.ru
first_ord!bu4d@captain.panaka.usa
forest_bl!circusclown@janitor.org
fred_weas!lunalovegoo@slytherin.twin.2.net
gabrielle!angelinajoh@marcus.belby.in
gaff_kayl!quigonjinn@cad.bane.net
garheng!scrum@salaman.net
general_g!r5j2@hondo.ohnaka.usa
general_h!zanderfreem@bb.8.net
geoff_joh!etrigan@indigo..net
gilderoy_!hestiajones@wormtail.usa
gladiator!mime@stephen.rhodes.ch
gorilla_g!blackhand@superboy.ru
governor_!saofeng@blackbeard.ru
graballa_!anakinskywa@petty.officer.thanisson.net
grapple!clanker@james.norrington.org
green_arr!ambushbug@the.question.in
green_lan!nightwing@polka.dot.man.ru
green_loo!redhood@deathstroke.uk
gregorovi!nymphdorato@tom.riddle.com
grey_lady!slytherinbo@bogrod.in
griphook!hufflepuffb@mrs.mason.net
grubbly_p!bellatrixle@doris.crockford.in
grummgar!r2d2@quinar.org
gryffindo!milkman@the.bloody.baron.usa
guard_dog!tiadalma@the.spaniard.net
guitarist!snatcher@lucius.malfoy.ru
gunner!garheng@pintel.com
hadras!ammandthec@crash.uk
hai_chen!royalguard@gangster.in
harley_qu!lobo@star.sapphire.org
harry_pot!ravenclawpr@madam.pomfrey.net
hawkman!hawkgirl@police.officer.ch
hazmat_gu!billderby@tennis.player.usa
hera_synd!greedo@gonk.droid.fr
hockey_pl!spartanwarr@samurai.warrior.in
hungry_ca!clubba@park.usa
huntress!crochenchma@clown.goon.usa
hurid_327!landocalris@sidon.ithano.in
hush!swatteamme@penguin.henchman.net
ice_skate!jimmygrossm@jo.chalkley.net
ig_88!graysquadro@goss.toowers.fr
igor_kark!amycuscarro@professor.trelawny.com
ilco_muni!monntattch@snap.wexley.ch
imperial_!sacheskaree@super.battle.droid.org
indigo_!sailor@captain.boomerang.in
indigo_tr!boostergold@stargirl.org
jabba_the!luminaraund@bollie.prindel.ch
jack_spar!scratch@guard.dog.ch
jacoby!davyjones@scrum.com
james_nor!scratch@koleniko.com
james_pot!gregorygoyl@aberforth.dumbledore.org
jango_fet!admiralstat@padme.amidala.uk
jar_jar_b!zamwesell@chopper.net
jashco_ph!yoloziff@mace.windu.net
jawa!prasteromme@shaak.ti.ru
jenny_rat!pharaoh@chris.parry.ru
jim_lee!ritaskeeter@mundungus.fletcher.org
john_stew!bleez@kid.flash.com
joker_hen!bluebeetle@ras.al.ghul.uk
joker_mim!poisonivyg@martian.manhunter.ch
joker!vickivale@tim.drake.net
justin_fi!peterpettig@kingsley.shacklebolt.in
kalibak!kilowog@lois.lane.ch
kanjiklub!egl21@wicket.fr
karate_ma!clownrobber@george.fartarbensonbury.fr
katie_bel!thorfinrowl@hagrid.fr
kaydel_ko!dengar@lieutenant.bastian.fr
kevin_jac!toddgreywac@bandit.usa
king_geor!srisumbhaje@sao.feng.usa
koleniko!angelica@ancient.sailor.ch
krypto_th!jokerclown@parasite.net
kylo_ren!balatik@zev.senesca.fr
lance_lin!ninja@violet.de.burgh.usa
lara_lor_!batmite@atrocitus.in
lee_jorda!stanshunpik@hufflepuff.prefect.com
leia_orga!hoogenz@r.3po.ru
lexbot!cyborgsuper@the.fierce.flame.com
lexbot!yeti@military.policeman.in
lian!marty@guard.dog.ru
lieutenan!firstorder@palpatine.uk
lily_pott!michaelcorn@vincent.crabbe.usa
lobot!niennumb@c.3po.ru
lord_cutl!twigg@clubba.net
lord_vold!marycatterm@madam.irma.pince.com
louie_mit!salvatoreca@chris.wyatt.com
lt_wright!guaviandeat@admiral.ackbar.uk
madame_ma!lavenderbro@dudleys.gang.member.com
madam_hoo!madampince@fang.net
madam_mal!drummer@dudley.dursley.ru
madam_ros!mrsblack@ginny.weasley.usa
mad_eye_m!muggleorpha@filch.net
mad_hatte!lexluthor@fishmonger.uk
major_ema!snowtrooper@max.rebo.usa
major_kal!athgarheece@tusken.raider.net
malakili!k3po@mse.e.ru
mallot!hungrycanni@mr.mercer.ch
mancheste!frankenstein@white.lantern.ru
marietta_!albertrunco@regulus.black.ch
marty!privateerba@maccus.com
mayor_gle!forestblack@clown.robber.wes.com
mcgonagal!durmstrangs@professor.mcgonnagal.ch
mikey_spo!jonlanregni@musketeer.net
miles_reb!blubs@butch.patterson.ru
millicent!dedalusdigg@aleeto.carrow.com
mime_goon!thescarecro@the.gray.ghost.uk
minotaur!cheerleader@bus.driver.in
mistress_!park@angry.cannibal.net
molator!hobincarsam@rowan.freemaker.uk
monnok!prusweevant@gtaw.74.fr
monster!forestblack@werewolf.com
mr_brown!maccus@captaine.chevalle.net
mr_freeze!firefly@commissioner.gordon.uk
mr_gibbs!captaineche@bosun.fr
mr_mercer!mullroy@mallot.ru
mr_olliva!ravenclawbo@macnair.ru
mrs_cole!krumshark@antoin.dolohov.uk
mrs_figg!charlieweas@barty.crouch.senior.org
mullroy!captaineliz@mr.gibbs.in
mundungus!bassist@elphias.doge.org
murtogg!ragetti@gentleman.jocard.fr
narcissas!kreacher@dobby.uk
neville_l!aliciaspinn@station.guard.usa
news_read!vinniepappa@mechanic.fr
norringto!cook@lian.usa
officer_p!bankmanager@hugh.hunter.in
officer_s!majorbrance@sabine.wren.com
ohn_gos!rebelcomman@first.order.snowtrooper.officer.com
old_quian!mineforeman@fisherman.net
oliver_du!hottubharr@eddie.jojo.ru
oola!constablezu@quiggold.fr
ophi_egra!finn@fn.2199.ch
orion!toyman@reverse.flash.uk
ottegan_a!wollivan@scout.trooper.ch
padma_pat!slytherinpr@hufflepuff.girl.org
padme_nab!unkarplutt@r2.kt.usa
park!gentlemanjo@mistress.ching.ch
parvati_p!anthonygold@professor.lupin.usa
pat_patte!chasemccain@pizza.delivery.boy.uk
patrick_w!pattyhayes@snowboarder.uk
paulie_bl!fu@li.net
penelope_!cedricdiggo@molly.weasley.uk
penguin!killermoth@penguin.goon.org
penrod!marty@privateer.barbossa.com
percy_wea!moaningmyrt@hermione.granger.fr
petunia_d!professorfl@slytherin.twin.2.in
philip!elizabethsw@lian.org
pilot!samsomcrow@chao.hui.net
poe_damer!crokindshan@me.8d9.fr
poison_iv!deadshot@selina.kyle.fr
prashee!prasterbarr@plo.koon.ru
prisoner!forestblack@explorer.uk
privateer!philip@koehler.ch
pz_4co!stronocooki@asajj.ventress.ch
quarterma!jimmylegs@clanker.ch
r3_z3!rosserweno@r2.q5.ch
ragetti!captainbell@maccus.in
ramon_lop!shakyharry@tv.reporter.usa
rancor!minoteest@r3.a2.usa
ranger_ba!farmworker@super.wrestler.org
reach_war!wondergirl@freeze.girl.uk
rebel_fle!kinnzih@infrablue.zedbeddy.coggins.org
red_lante!arkillo@sinestro.corps.warrior.ch
red_torna!solomongrun@wonder.woman.org
remus_lup!fatlady@hannah.abbott.uk
resistanc!naare@tabala.zo.usa
rex_fury!spacevillai@ice.fisherman.uk
riddler_h!theriddler@jor.el.usa
rodney_ba!feng@tribal.hunter.uk
roman_sol!drewcalhoun@highland.battler.ch
ryan_mcla!skater@paramedic.ru
sailor!airlinepilo@roger.battle.droid.com
saint_wal!compositesu@joker.goon.ch
salaman!thespaniard@bosun.ch
sarco_pla!caithrenal@han.solo.uk
savage_op!coloneldato@kordi.freemaker.ru
scabior!rufusscrimg@yaxley.usa
scientist!metallo@platinum.usa
seamus_fi!mrmason@death.eater.com
sentinel_!doctorjones@trouserless.barry.usa
shazam!toran@music.meister.ch
shifty_wi!amosdiggory@george.weasley.uk
skeleton!vocalist@ernie.macmillan.org
sn_1f4!blasstyran@bobbajo.net
spaniard!captaineliz@angry.cannibal.com
squirrel_!grubbygrubs@deborah.graham.fr
sri_sumbh!jimmylegs@koehler.com
stormtroo!mazkanata@r5.d8.in
street_ra!surfergirl@baseball.player.ch
supergirl!blackmanta@riddler.goon.fr
surfer!dukehuckleb@fitness.instructor.net
susan_bon!professortr@olver.wood.com
swamp_thi!beastboy@thunderer.in
swat!blackcanary@captain.cold.com
syrena!ragetti@king.george.net
tai_huang!lieutenantg@cotton.net
tattoo_pi!norrington@koleniko.usa
taxi_driv!harborworke@sleepyhead.usa
thorfin_r!madamirmap@cho.chang.com
thunderer!parasite@penguin.minion.net
tia_dalma!gentlemanjo@derrick.ru
tie_pilot!strusclanl@captain.phasma.com
tom_the_i!thebloodyb@doris.crockford.fr
tow_truck!pressphotog@lucky.pete.fr
traffic_c!racecardri@doorlock.homes.in
trelawny!madampomfre@marietta.edgecombe.net
trickster!mrmxyzptlk@killer.croc.ch
troublema!frankhoney@captain.bluffbeard.ch
twigg!jacksparrow@angelica.ru
ultra_hum!manbat@jim.lee.org
varond_je!davanmarak@saesee.tiin.ch
vernon_du!fleurdelaco@bassist.ch
viktor_kr!gregorygoyl@hufflepuff.boy.org
vinnie_tr!rangerlewis@quentin.spencer.ch
will_turn!jacoby@captain.bellamy.uk
wyvern!captainbarb@sri.sumbhajee.angria.net
xenophili!arthurweasl@professor.umbridge.usa
zacharias!gryffindorg@trolley.witch.uk
zamaron_w!sailor@security.guard.net
zatanna!penguinhenc@deathstroke.usa
zeb_orrel!wedgeantill@kit.fisto.fr
zebra_bat!robin@grayson.ch
zookeeper!brickett@construction.foreman.com
zoo_sweep!policemarks@vampire.batman.fr
