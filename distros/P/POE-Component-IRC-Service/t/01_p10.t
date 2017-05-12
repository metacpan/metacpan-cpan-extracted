use POE;
use POE::Component::IRC::Service;

my ($servername) = "test.testnet.local";
my ($servernumeric) = 1;
my ($serverdesc) = "POE::Component::IRC::Service Test";
my ($password) = "poco";
my ($remoteserver) = "localhost";
my ($serverport) = 6969;
my ($nickname) = "bobbins";
my (@tests) = ( "not ok 2", "not ok 3" );

$|=1;
print "# Testing P10 module\n";
print "1..3\n";

my ($object) = POE::Component::IRC::Service->new('Service','P10', { ServerNumeric => $servernumeric, ServerName => $servername, ServerDesc => $serverdesc, Password => $password, RemoteServer => $remoteserver, ServerPort => $serverport } );
if ( not $object ) {
  print "not ok 1";
  exit 1;
} else {
  print "ok 1\n";
}

POE::Session->create
(
	inline_states => 
	{
		_start => \&client_start,
		_stop  => \&client_stop,
		squit  => \&on_squit,

		irc_p10_nick	  => \&on_nick,
		irc_p10_create    => \&on_create,
	},
	heap =>
	{
		Object => $object,
		NickName => $nickname,
		ServerNumeric => $servernumeric,
		ServerName => $servername,
		ServerDescription => $serverdesc,
		ServerPassword => $password,
		RemoteServer => $remoteserver,
		ServerPort => $serverport
	},

);

$poe_kernel->run();
exit 0;

sub client_start {

  $_[HEAP]->{start_time} = time();
  $_[KERNEL]->post( Service => register => "all" );
  $_[KERNEL]->post( Service => addnick =>
  {
	NickName => $_[HEAP]->{NickName},
	Umode    => "odkr"
  });
  # If the tests do not work terminate after 20 seconds
  $_[KERNEL]->delay ( squit => 20 );
}

sub client_stop {

  foreach ( @tests ) {
    print "$_\n";
  }
 
}

sub on_squit {
  $_[KERNEL]->post( Service => unregister => "all" );
  $_[KERNEL]->delay( squit => undef );
  $_[KERNEL]->post( Service => 'shutdown' );
}

sub on_nick {
  my ($heap,$state,$who,$args) = @_[HEAP,STATE,ARG0,ARG1];

  if ($who =~ /^.{2}$/ and not defined ($heap->{BotNumeric}) ) {
    my ($oper,$authname);
    my ($first,$second) = split(/ :/,$args,2);
    my (@args) = split(/ /,$first);
    if ($#args > 1 and $args[0] eq $heap->{NickName}) {
        $tests[0] = "ok 2";
        $heap->{BotNumeric} = $args[$#args];
        $_[KERNEL]->post( Service => join => $heap->{BotNumeric} => "#TestChannel" );
    }
  }
}

sub on_create {
  my ($kernel,$heap,$who) = @_[KERNEL,HEAP,ARG0];

  if ( $who eq $heap->{BotNumeric} ) {
    $tests[1] = "ok 3";
    $kernel->yield ( 'squit' );
  }
}
