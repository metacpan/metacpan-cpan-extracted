use strict;
use warnings;
use Test::More 'no_plan';
use POE qw[Filter::Stackable Filter::Line Filter::IRCD];
use POE::Component::Server::IRC;
use Test::POE::Client::TCP;
use IRC::Utils qw[BOLD YELLOW NORMAL unparse_mode_line];

my @types = qw[b e I];

my %bmasks;
$bmasks{$_} = [ ] for @types;

while (<DATA>) {
  chomp;
  my $type = $types[ int(rand(3)) ];
  push @{ $bmasks{$type} }, $_ unless scalar @{ $bmasks{$type} } > 49;
}

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
            _launch_groucho
            _launch_harpo
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
    $poe_kernel->yield( '_launch_client' );
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
  my $chants = $heap->{ircd}{state}{chans}{'#MARXBROS'}{ts};
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'PASS', params => [ 'foo', 'TS', '6', '7UP' ], } );
  $kernel->post( $sender, 'send_to_server', { command => 'CAPAB', params => [ 'KNOCK UNDLN DLN TBURST GLN ENCAP UNKLN KLN CHW IE EX HOPS SVS CLUSTER EOB QS' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SERVER', params => [ 'groucho.server.irc', '1', 'Open the door and come in!!!!!!' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SVINFO', params => [ '6', '6', '0', time() ], colonify => 1 } );
  $uidts = time() - 20;
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'SID', params => [ 'fake.server.irc', 2, '4AK', 'This is a fake server' ] } );
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'UID', params => [ 'groucho', '1', $uidts, '+aiow', 'groucho', 'groucho.marx', '0', '7UPAAAAAA', '0', 'Groucho Marx' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'SJOIN', params => [ $chants, '#marxbros', '+nt', '@7UPAAAAAA' ], colonify => 1 } );
  my @output_modes;
  foreach my $btype ( @types ) {
        my @mask_list = @{ $bmasks{$btype} };
        my @btypes;
        push @btypes, "+$btype" for @mask_list;
        my $server = '7UP';
        my $length = length($server) + 4
                     + length('#marxbros') + 4 + length($chants) + 1;
        my @buffer = ('', '');
        for my $bt (@btypes) {
            my $arg = shift @mask_list;
            my $mode_line = unparse_mode_line($buffer[0].$bt);
            if (length(join ' ', 1, $buffer[1],
                       $arg) + $length > 510) {
               push @output_modes, {
                  prefix   => $server,
                  command  => 'BMASK',
                  colonify => 1,
                  params   => [
                    $chants,
                    '#marxbros',
                    $btype,
                    $buffer[1],
                  ],
               };
               $buffer[0] = $bt;
               $buffer[1] = $arg;
               next;
            }
            $buffer[0] = $mode_line;
            if ($buffer[1]) {
               $buffer[1] = join ' ', $buffer[1], $arg;
            }
            else {
               $buffer[1] = $arg;
            }
        }
        push @output_modes, {
            prefix   => $server,
            command  => 'BMASK',
            colonify => 1,
            params   => [
               $chants,
               '#marxbros',
               $btype,
               $buffer[1],
            ],
        };
        $kernel->post( $sender, 'send_to_server', $_ )
               for @output_modes;
  }
  $kernel->post( $sender, 'send_to_server', { command => 'EOB', prefix => '7UP' } );
  $kernel->post( $sender, 'send_to_server', { command => 'EOB', prefix => '4AK' } );
  $kernel->post( $sender, 'send_to_server', { command => 'PING', params => [ '7UP' ], colonify => 1 } );
  return;
}

sub harpo_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  my $chants = $heap->{ircd}{state}{chans}{'#MARXBROS'}{ts};
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', { command => 'PASS', params => [ 'foo', 'TS', '6', '9T9' ], } );
  $kernel->post( $sender, 'send_to_server', { command => 'CAPAB', params => [ 'KNOCK UNDLN DLN TBURST GLN ENCAP UNKLN KLN CHW IE EX HOPS SVS CLUSTER EOB QS' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SERVER', params => [ 'harpo.server.irc', '1', 'Open the door and come in!!!!!!' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { command => 'SVINFO', params => [ '6', '6', '0', time() ], colonify => 1 } );
  $uidts = time() - 50;
  $kernel->post( $sender, 'send_to_server', { prefix => '9T9', command => 'UID', params => [ 'harpo', '1', $uidts, '+aiow', 'harpo', 'harpo.marx', '0', '9T9AAAAAA', '0', 'Harpo Marx' ], colonify => 1 } );
  $kernel->post( $sender, 'send_to_server', { prefix => '7UP', command => 'SJOIN', params => [ $chants, '#marxbros', '+nt', '@9T9AAAAAA' ], colonify => 1 } );
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
    $poe_kernel->post( $sender, 'send_to_server', { command => 'JOIN', params => [ '#marxbros' ] } );
    return;
  }
  if ( $cmd eq 'ERROR' ) {
    pass($cmd);
    my $state = $heap->{ircd}{state};
    is( scalar keys %{ $state->{chans} }, 1, 'One channel' );
    is( scalar keys %{ $state->{conns} }, 2, 'Should only be 2 connections' );
    is( scalar keys %{ $state->{uids} }, 2, 'Two UIDs' );
    is( scalar keys %{ $state->{users} }, 2, 'Two users' );
    is( scalar keys %{ $state->{peers}{'LISTEN.SERVER.IRC'}{users} }, 0, 'No local users' );
    is( scalar keys %{ $state->{sids}{'1FU'}{uids} }, 0, 'No local UIDs' );
    $poe_kernel->post( $sender, 'shutdown' );
    $poe_kernel->post( 'harpo', 'terminate' );
    return;
  }
  if ( $cmd eq 'JOIN' && $prefix =~ m!^bobbins! ) {
    pass($cmd);
    is( $prefix, 'bobbins!~bobbins@listen.server.irc', 'It is I, bobbins' );
    is( $params->[0], '#marxbros', 'Channel is #marxbros' );

    my $state = $heap->{ircd}{state};
    is( scalar keys %{ $state->{chans} }, 1, 'Should be 1 channels' );
    is( scalar keys %{ $state->{conns} }, 1, 'Should be 1 connections' );
    is( scalar keys %{ $state->{uids} }, 1, 'One UID' );
    is( scalar keys %{ $state->{users} }, 1, 'One user' );
    is( scalar keys %{ $state->{peers}{'LISTEN.SERVER.IRC'}{users} }, 1, 'One local user' );
    is( scalar keys %{ $state->{sids}{'1FU'}{uids} }, 1, 'One local UID' );

    return;
  }
  if ( $cmd eq 'JOIN' && $prefix =~ m!^groucho! ) {
    pass($cmd);
    is( $prefix, 'groucho!groucho@groucho.marx', 'It is groucho!' );
    is( $params->[0], '#marxbros', 'Channel is #marxbros' );

    my $state = $heap->{ircd}{state};
    is( scalar keys %{ $state->{chans} }, 1, 'Should be 1 channels' );
    is( scalar keys %{ $state->{conns} }, 2, 'Should be 2 connections' );
    is( scalar keys %{ $state->{uids} }, 2, 'Two UIDs' );
    is( scalar keys %{ $state->{users} }, 2, 'Two users' );
    is( scalar keys %{ $state->{peers}{'LISTEN.SERVER.IRC'}{users} }, 1, 'One local user' );
    is( scalar keys %{ $state->{sids}{'1FU'}{uids} }, 1, 'One local UID' );
    unlike( $state->{chans}{'#MARXBROS'}{'7UPAAAAAA'}, qr/o/, 'Should not be chanop' );
    $poe_kernel->yield( '_launch_harpo' );
    return;
  }
  if ( $cmd eq '353' ) {
    pass("IRC$cmd");
    is( $params->[0], 'bobbins', 'It is me, bobbins' );
    is( $params->[1], '=', 'Correct arg =' );
    is( $params->[2], '#marxbros', 'Channel name is #marxbros' );
    is( $params->[3], '@bobbins', 'I am chanop' );
    return;
  }
  if ( $cmd eq '366' ) {
    pass("IRC$cmd");
    is( $params->[0], 'bobbins', 'It is me, bobbins' );
    is( $params->[1], '#marxbros', 'Channel name is #marxbros' );
    is( $params->[2], 'End of NAMES list', 'End of NAMES list' );
    $poe_kernel->yield( '_launch_groucho' );
    return;
  }
  if ( $cmd eq 'MODE' && $prefix eq 'listen.server.irc' ) {
    pass(join ' ', $cmd, @$params);
    if ( $params->[1] eq '+o' && $params->[2] eq 'harpo' ) {
      $poe_kernel->post( $sender, 'send_to_server', { command => 'QUIT', params => [ 'Connection reset by fear' ] } );
    }
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
    return;
  }
  return;
}

sub client_disconnected {
  my ($heap,$state,$sender) = @_[HEAP,STATE,SENDER];
  pass($state);
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
  return;
}

__DATA__
cornelius!kingsleysha@nymphdora.tonks.fr
binns!seamusfinni@marietta.edgecombe.fr
kreacher!charityburb@professor.mcgonnagal.ru
slytherin!vincentcrab@amos.diggory.uk
amycus_ca!professorum@tom.riddle.usa
bogrod!hufflepuffg@gregorovitch.ru
hestia_jo!gabriellede@ron.weasley.fr
madam_pom!lunalovegoo@emmeline.vance.ch
skeleton!angelinajoh@hufflepuff.prefect.com
mrs_mason!slytherinpr@ravenclaw.prefect.ru
vernon_du!padmapatil@lord.voldemort.net
slytherin!professorfl@professor.slughorn.net
durmstran!mafaldahopk@milk.man.uk
madam_hoo!madamrosmer@the.grey.lady.uk
penelope_!michaelcorn@fang.in
hufflepuf!charlieweas@trolley.witch.ch
shifty_wi!madeyemood@percy.weasley.in
millicent!mrsblack@argus.filch.in
grubbly_p!drummer@peter.pettigrew.ru
doris_cro!viktorkrum@hannah.abbott.com
petunia_d!lavenderbro@the.bloody.baron.net
cedric_di!professortr@professor.mcgonagall.uk
madam_mal!bellatrixle@marcus.flint.com
madam_pin!professorsi@sirius.black.fr
madam_irm!fredweasley@narcissas.malfoy.uk
parvati_p!professordu@wormtail.net
tom_the_i!elphiasdoge@barty.crouch.senior.uk
zacharias!piusthickne@slytherin.twin.1.uk
aleeto_ca!macnair@ravenclaw.girl.ru
scabior!dragonhandl@antoin.dolohov.org
neville_l!professorsn@igor.karkaroff.org
ernie_pra!dedalusdigg@gryffindor.girl.fr
dean_thom!professortr@anthony.goldstein.org
ernie_mac!mrollivande@susan.bones.uk
rita_skee!ravenclawbo@gregory.goyle.ch
harry_pot!fenrirgreyb@reg.cattermole.org
nearly_he!thorfinrowl@moaning.myrtle.com
mr_mason!madamemalki@dobby.com
vector!ministrygua@remus.lupin.org
rufus_scr!hermionegra@ginny.weasley.uk
muggle_or!bartycrouch@colin.creevey.net
cho_chang!leejordan@bassist.net
mrs_cole!dudleydursl@dudleys.gang.member.uk
the_fat_f!vocalist@james.potter.com
quirrell!mrsfigg@death.eater.ru
dragomir_!mollyweasle@professor.sprout.net
cormac_mc!aberforthdu@marcus.belby.in
katie_bel!olverwood@krum.shark.ru
slytherin!arthurweasl@lily.potter.fr
fleur_del!aliciaspinn@fat.lady.uk
albert_ru!xenophilius@blaise.zabini.in
mundungus!filch@draco.malfoy.uk
mary_catt!griphook@yaxley.org
gilderoy_!snatcher@justin.finch.fletchley.usa
dirk_cres!luciusmalfo@professor.lupin.ru
regulus_b!hagrid@guitarist.com
george_we!gryffindorb@stan.shunpike.com
station_g!dudleysgang@vocalist.usa
trelawney!hufflepuffb@fat.lady.ch
madam_hoo!mrscole@professor.quirrell.usa
harry_pot!thefatfria@dean.thomas.org
trelawny!elphiasdoge@shifty.wizard.ch
ravenclaw!stationguar@katie.bell.ch
michael_c!aliciaspinn@mrs.black.ch
hagrid!gregorovitch@sirius.black.in
cho_chang!nevillelong@vernon.dursley.net
slytherin!padmapatil@rufus.scrimgeour.ru
cornelius!tomtheinnk@krum.shark.in
durmstran!marcusbelby@peter.pettigrew.uk
hufflepuf!madampomfre@barty.crouch.senior.org
yaxley!skeleton@filch.fr
draco_mal!charityburb@aleeto.carrow.uk
vincent_c!penelopecle@hermione.granger.ch
madam_ros!luciusmalfo@marietta.edgecombe.net
slytherin!professorbi@professor.snape.fr
slytherin!argusfilch@mafalda.hopkirk.ch
antoin_do!nearlyheadl@olver.wood.ru
percy_wea!gregorygoyl@anthony.goldstein.usa
mary_catt!professorfl@kreacher.com
mcgonagal!dragomirdes@moaning.myrtle.in
milk_man!slytheringi@lee.jordan.uk
arthur_we!ravenclawbo@lily.potter.in
sprout!professorum@griphook.usa
hufflepuf!thorfinrowl@muggle.orphan.org
lupin!fenrirgreyb@lord.voldemort.net
slytherin!gabriellede@narcissas.malfoy.usa
dirk_cres!zachariassm@stan.shunpike.uk
lavender_!madammalkin@gryffindor.boy.ru
tom_riddl!mundungusfl@professor.sinistra.in
angelina_!parvatipati@xenophilius.lovegood.com
dumbledor!aberforthdu@professor.vector.com
wormtail!ravenclawpr@viktor.krum.com
hestia_jo!jamespotter@remus.lupin.com
mad_eye_m!emmelinevan@ernie.macmillan.ch
kingsley_!dragonhandl@george.weasley.in
reg_catte!gilderoyloc@dedalus.diggle.ru
colin_cre!thegreylad@madame.malkin.uk
guitarist!lunalovegoo@nymphdora.tonks.com
ron_weasl!hannahabbot@susan.bones.usa
bellatrix!snatcher@macnair.ru
mcgonnaga!deatheater@professor.slughorn.ch
blaise_za!madampince@seamus.finnigan.org
fred_weas!drummer@ginny.weasley.ru
mr_mason!bartycrouch@pius.thicknesse.in
dobby!bassist@scabior.uk
fleur_del!amosdiggory@cedric.diggory.fr
gryffindo!mrsmason@amycus.carrow.org
millicent!petuniadurs@rita.skeeter.org
igor_kark!regulusblac@professor.grubbly.plank.ch
ernie_pra!mrollivande@justin.finch.fletchley.org
mrs_figg!albertrunco@cormac.mclaggen.ch
madam_irm!charlieweas@dudley.dursley.org
the_blood!ministrygua@molly.weasley.ch
fang!doriscrockf@marcus.flint.ru
trolley_w!bogrod@the.bloody.baron.org
krum_shar!lavenderbro@lily.potter.usa
zacharias!milkman@dudleys.gang.member.uk
nymphdora!fatlady@drummer.uk
mrs_mason!nevillelong@elphias.doge.ch
katie_bel!blaisezabin@olver.wood.com
parvati_p!charityburb@mr.ollivander.in
thorfin_r!leejordan@anthony.goldstein.usa
sinistra!viktorkrum@justin.finch.fletchley.ch
petunia_d!wormtail@mrs.figg.com
durmstran!hannahabbot@millicent.bulstrode.ru
rita_skee!marycatterm@moaning.myrtle.org
lupin!gregorygoyl@vincent.crabbe.fr
ravenclaw!muggleorpha@emmeline.vance.ch
skeleton!lordvoldemo@filch.fr
ernie_mac!hufflepuffp@alicia.spinnet.net
luna_love!penelopecle@dudley.dursley.uk
kreacher!vocalist@trolley.witch.net
trelawny!bogrod@gabrielle.delacour.uk
slytherin!thefatfria@nearly.headless.nick.in
mafalda_h!griphook@remus.lupin.fr
barty_cro!professorsl@harry.potter.fr
aberforth!slytherintw@gryffindor.girl.org
amycus_ca!arthurweasl@hestia.jones.in
yaxley!bassist@cedric.diggory.net
binns!ginnyweasle@james.potter.org
narcissas!ministrygua@susan.bones.in
cho_chang!gilderoyloc@seamus.finnigan.in
draco_mal!professordu@marcus.flint.ch
snape!dragomirdes@dean.thomas.org
argus_fil!professortr@molly.weasley.com
tom_the_i!slytherintw@madam.hooch.com
stan_shun!bellatrixle@dedalus.diggle.ch
xenophili!professorqu@fang.org
hufflepuf!madeyemood@slytherin.boy.ru
vector!gryffindorb@charlie.weasley.fr
padma_pat!aleetocarro@albert.runcorn.in
igor_kark!ravenclawpr@mr.mason.net
cormac_mc!ronweasley@madam.pince.ru
station_g!piusthickne@death.eater.fr
kingsley_!professorsp@michael.corner.fr
ernie_pra!hufflepuffg@regulus.black.fr
mrs_cole!tomriddle@amos.diggory.usa
madam_pom!doriscrockf@percy.weasley.uk
guitarist!mariettaedg@peter.pettigrew.uk
mcgonnaga!fenrirgreyb@scabior.fr
reg_catte!mrsblack@madam.irma.pince.ch
snatcher!dragonhandl@mundungus.fletcher.uk
madam_ros!vernondursl@rufus.scrimgeour.org
slytherin!luciusmalfo@shifty.wizard.org
barty_cro!hermionegra@ravenclaw.girl.net
gregorovi!hagrid@madam.malkin.org
grubbly_p!corneliusfu@antoin.dolohov.in
fred_weas!angelinajoh@professor.umbridge.fr
colin_cre!macnair@professor.flitwick.usa
the_grey_!professormc@madame.malkin.in
fleur_del!georgeweasl@dobby.org
dirk_cres!siriusblack@marcus.belby.uk
argus_fil!amosdiggory@professor.dumbledore.ch
lupin!slytheringi@charlie.weasley.in
madam_pom!marcusflint@amycus.carrow.org
fat_lady!arthurweasl@petunia.dursley.ru
bassist!trolleywitc@percy.weasley.com
lee_jorda!madeyemood@penelope.clearwater.ru
zacharias!erniemacmil@gryffindor.girl.com
flitwick!cormacmclag@harry.potter.uk
narcissas!professorbi@dirk.cresswell.ru
katie_bel!professortr@lily.potter.in
grubbly_p!aleetocarro@tom.riddle.ru
millicent!tomtheinnk@stan.shunpike.fr
kingsley_!dragonhandl@george.weasley.fr
neville_l!remuslupin@aberforth.dumbledore.fr
sirius_bl!colincreeve@guitarist.fr
antoin_do!deatheater@seamus.finnigan.in
mrs_cole!gabriellede@regulus.black.net
gregory_g!hufflepuffg@fenrir.greyback.net
slytherin!madamemalki@ginny.weasley.ru
gilderoy_!snatcher@professor.snape.org
reg_catte!gryffindorb@dean.thomas.fr
griphook!hagrid@madam.rosmerta.com
albert_ru!jamespotter@madam.malkin.usa
slytherin!professorsp@molly.weasley.fr
vincent_c!bellatrixle@mary.cattermole.uk
lucius_ma!mrsblack@elphias.doge.usa
ernie_pra!vocalist@luna.lovegood.in
mcgonnaga!mrmason@nearly.headless.nick.usa
cornelius!hestiajones@cedric.diggory.org
anthony_g!xenophilius@the.fat.friar.ch
dedalus_d!emmelinevan@barty.crouch.junior.com
hufflepuf!ravenclawbo@susan.bones.usa
barty_cro!chochang@rufus.scrimgeour.ch
padma_pat!madampince@the.bloody.baron.uk
ron_weasl!mrollivande@gregorovitch.in
vector!durmstrangs@professor.umbridge.net
charity_b!professorsi@nymphdora.tonks.in
madam_hoo!muggleorpha@ministry.guard.uk
marietta_!fredweasley@slytherin.twin.2.in
fang!fleurdelaco@lavender.brown.uk
mundungus!dragomirdes@mafalda.hopkirk.ru
moaning_m!doriscrockf@parvati.patil.ru
kreacher!ravenclawgi@milk.man.com
scabior!blaisezabin@thorfin.rowle.uk
mcgonagal!slytherintw@dobby.uk
hufflepuf!yaxley@madam.irma.pince.fr
hermione_!stationguar@igor.karkaroff.in
skeleton!marcusbelby@pius.thicknesse.net
vernon_du!peterpettig@justin.finch.fletchley.ru
angelina_!dudleysgang@rita.skeeter.net
hannah_ab!professorsl@bogrod.fr
drummer!professorqu@professor.trelawny.ch
shifty_wi!aliciaspinn@ravenclaw.prefect.uk
dudley_du!wormtail@mrs.figg.net
olver_woo!viktorkrum@the.grey.lady.uk
draco_mal!mrsmason@krum.shark.net
lord_vold!michaelcorn@filch.org
macnair!madeyemood@nearly.headless.nick.in
hestia_jo!professorfl@professor.umbridge.com
sirius_bl!aleetocarro@marcus.flint.usa
marcus_be!muggleorpha@amycus.carrow.fr
hufflepuf!antoindoloh@thorfin.rowle.com
blaise_za!milkman@professor.dumbledore.ch
wormtail!mrsblack@barty.crouch.senior.com
rita_skee!lunalovegoo@elphias.doge.in
mundungus!leejordan@igor.karkaroff.ru
gregory_g!hufflepuffp@peter.pettigrew.com
remus_lup!bartycrouch@rufus.scrimgeour.com
slytherin!penelopecle@mafalda.hopkirk.ru
dirk_cres!bogrod@madam.pince.ru
hannah_ab!marycatterm@emmeline.vance.ru
scabior!kreacher@xenophilius.lovegood.fr
reg_catte!justinfinch@aberforth.dumbledore.org
drummer!vocalist@madam.rosmerta.fr
tom_riddl!padmapatil@bassist.ch
ron_weasl!charityburb@katie.bell.usa
griphook!mrmason@mrs.figg.com
snape!stanshunpik@gryffindor.girl.in
gabrielle!luciusmalfo@ernie.macmillan.com
slughorn!professorve@professor.trelawny.net
viktor_kr!professorgr@ravenclaw.prefect.ch
ginny_wea!dudleysgang@hermione.granger.in
michael_c!dobby@narcissas.malfoy.in
madam_irm!kingsleysha@lavender.brown.net
colin_cre!slytherinbo@pius.thicknesse.org
durmstran!deanthomas@trolley.witch.net
fleur_del!anthonygold@cedric.diggory.uk
lily_pott!professorsi@shifty.wizard.org
binns!fatlady@ravenclaw.boy.fr
marietta_!skeleton@the.fat.friar.net
vernon_du!jamespotter@ministry.guard.net
guitarist!regulusblac@susan.bones.org
madam_mal!chochang@zacharias.smith.ch
harry_pot!ravenclawgi@professor.mcgonnagal.in
mrs_mason!filch@george.weasley.usa
bellatrix!vincentcrab@albert.runcorn.ch
dragon_ha!fang@hagrid.usa
parvati_p!nevillelong@madam.pomfrey.fr
cornelius!mollyweasle@gregorovitch.ch
hufflepuf!moaningmyrt@professor.quirrell.org
slytherin!professorlu@mrs.cole.in
doris_cro!olverwood@alicia.spinnet.ru
madame_ma!professortr@station.guard.org
cormac_mc!macnair@slytherin.prefect.uk
tom_the_i!dracomalfoy@arthur.weasley.uk
mcgonagal!gilderoyloc@argus.filch.ru
madam_hoo!gryffindorb@the.bloody.baron.in
krum_shar!petuniadurs@percy.weasley.ch
the_grey_!seamusfinni@amos.diggory.ru
dudley_du!professorsp@angelina.johnson.net
dedalus_d!dragomirdes@nymphdora.tonks.ru
millicent!fredweasley@death.eater.in
fenrir_gr!slytherintw@charlie.weasley.in
yaxley!ernieprang@snatcher.net
mr_olliva!lordvoldemo@marcus.flint.fr
grubbly_p!snatcher@reg.cattermole.usa
gabrielle!madampomfre@stan.shunpike.in
slytherin!bartycrouch@ginny.weasley.ru
ministry_!slytherintw@wormtail.uk
pius_thic!rufusscrimg@justin.finch.fletchley.ru
skeleton!gryffindorg@fat.lady.org
hestia_jo!moaningmyrt@charity.burbage.com
madam_hoo!cormacmclag@molly.weasley.com
mr_mason!filch@antoin.dolohov.ch
guitarist!lavenderbro@professor.umbridge.net
vocalist!dedalusdigg@bogrod.ch
padma_pat!percyweasle@ernie.prang.net
dumbledor!albertrunco@ravenclaw.girl.usa
amos_digg!durmstrangs@doris.crockford.net
mcgonagal!michaelcorn@hufflepuff.prefect.com
snape!hermionegra@slytherin.twin.2.in
fang!hagrid@krum.shark.ru
scabior!peterpettig@dragon.handler.ch
fleur_del!igorkarkaro@xenophilius.lovegood.ru
yaxley!kingsleysha@griphook.com
muggle_or!professorsp@regulus.black.in
trolley_w!hufflepuffg@gregorovitch.fr
dobby!colincreeve@professor.binns.ru
aberforth!narcissasma@the.grey.lady.fr
george_we!kreacher@anthony.goldstein.uk
slytherin!professorsi@argus.filch.uk
drummer!fredweasley@the.fat.friar.usa
gregory_g!aliciaspinn@professor.trelawny.uk
vernon_du!lilypotter@james.potter.org
aleeto_ca!zachariassm@mad.eye.moody.com
mafalda_h!gryffindorb@petunia.dursley.ch
the_blood!milkman@luna.lovegood.uk
marietta_!chochang@blaise.zabini.com
madam_ros!marycatterm@olver.wood.org
remus_lup!parvatipati@angelina.johnson.ch
viktor_kr!madamirmap@nearly.headless.nick.org
lucius_ma!ritaskeeter@ron.weasley.fr
gilderoy_!madammalkin@amycus.carrow.com
hannah_ab!corneliusfu@professor.trelawney.fr
station_g!bellatrixle@professor.flitwick.in
quirrell!arthurweasl@elphias.doge.usa
fenrir_gr!susanbones@mr.ollivander.ru
mrs_figg!bassist@professor.vector.com
lee_jorda!dracomalfoy@neville.longbottom.net
slytherin!madamemalki@dudley.dursley.ch
lupin!thorfinrowl@charlie.weasley.ru
