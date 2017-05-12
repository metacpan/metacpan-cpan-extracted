#!/usr/bin/perl -w

use POE;
use POE::Component::IRC::Service;
use Getopt::Long;
use Data::Dumper;

my ($servername) = "";
my ($servernumeric) = 0;
my ($serverdesc) = "";
my ($password) = "";
my ($remoteserver) = "";
my ($serverport) = 0;
my ($nickname) = "";
my ($help) = 0;
my ($version) = "LogServ-2.1";
my ($his_servername);
my ($his_serverinfo);

GetOptions("servername=s"  => \$servername,
	   "numeric=s"     => \$servernumeric,
	   "description=s" => \$serverdesc,
	   "password=s"    => \$password,
	   "remote=s"      => \$remoteserver,
	   "port=s"        => \$serverport,
	   "nickname=s"    => \$nickname,
	   "hisservername=s" => \$his_servername,
	   "hisserverinfo=s" => \$his_serverinfo,
	   "help"          => \$help);

if ($help) {
  print STDERR <<EOF;

Logserv-P10.pl <options>
--servername	the name this service will take on the IRC network
--numeric	the unique number for this service on the IRC network
--description	a brief string describing the service
--password	the password required to authenticate with uplink server
--remote	the hostname or ip address of our uplink server
--port		port to connect to on our uplink server
--nickname	the nickname for our client
--help		display this help text

EOF
exit 1;
}

if (not $servername and not $servernumeric and not $serverdesc and not $password and not $remoteserver and not $serverport and not $nickname) {
  die ("Missing option. Try LogServ-P10.pl --help\n");
}

open (LOGFILE,">>LogServ-P10.log") or die;
select LOGFILE;
$|=1;


my ($object) = POE::Component::IRC::Service->new('Service','P10', { ServerNumeric => $servernumeric, ServerName => $servername, ServerDesc => $serverdesc, Password => $password, RemoteServer => $remoteserver, ServerPort => $serverport, Version => $version, Debug => 1, HIS_SERVERNAME => $his_servername, HIS_SERVERINFO => $his_serverinfo } ) or die "OOps: $!\n";

POE::Session->create
(
	inline_states => 
	{
		_start => \&client_start,
		_default => \&default,

		irc_p10_invite    => \&on_invite,
		irc_p10_nick	  => \&on_nick,
		irc_p10_join      => \&on_join,
		irc_p10_connected => \&on_connected,
		irc_p10_disconnected => \&on_disconnected,
		irc_p10_server_link => \&on_server_link,
		irc_p10_squit	  => \&on_squit,
		irc_p10_create    => \&on_create,
		irc_p10_eob_ack   => \&on_ack,
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

  foreach ( $_[HEAP]->{Object}->_dump_state() ) {
    print STDERR "$_\n";
  }
  $_[HEAP]->{start_time} = time();
  print LOGFILE "Registering events\n";
  $_[KERNEL]->post( Service => register => "all" );
  print LOGFILE "Adding Service client\n";
  $_[KERNEL]->post( Service => addnick =>
  {
	NickName => $_[HEAP]->{NickName},
	Umode    => "odkr"
  });
  $_[HEAP]->{connected} = 0;
}

sub on_ack {
  my ($heap) = $_[HEAP];

  print LOGFILE Dumper($heap->{Object});
}

sub on_server_link {
  $_[HEAP]->{linkserver} = $_[ARG0];
}

sub on_squit {
  my ($kernel,$heap,$what) = @_[KERNEL,HEAP,ARG1];

  my ($server) = ( split / /, $what )[0];

  print STDERR "$server\n";
  print STDERR $heap->{linkserver} . "\n";
}

sub on_connected {

  print LOGFILE "Connected\n";
  $_[HEAP]->{connected} = 1;
}

sub on_disconnected {

  print LOGFILE "Disconnected\n";
  print LOGFILE "Reconnecting\n";
  $_[HEAP]->{connected} = 0;
  $_[KERNEL]->post( Service => 'connect' );
}

sub default {
  my ($state, $event, $args, $heap) = @_[ STATE, ARG0, ARG1, HEAP ];
  $args ||= [];
  print LOGFILE "$state = $event (@$args)\n";
  return 0;
}

sub on_invite {
  my ($kernel, $channel) = @_[KERNEL,ARG2];

  $kernel->post( Service => join => $_[HEAP]->{BotNumeric} => $channel );
}

sub on_join {
  my ($kernel, $who, $where) = @_[KERNEL,ARG0,ARG1];

  if ($who eq $_[HEAP]->{BotNumeric}) {
	$kernel->post(Service => opmode => $where => "+o" => $who );
  }
}

sub on_nick {
  my ($heap,$state,$who,$args) = @_[HEAP,STATE,ARG0,ARG1];

  if ($who =~ /^.{2}$/ and not defined ($heap->{BotNumeric}) ) {
    my ($oper,$authname);
    my ($first,$second) = split(/ :/,$args,2);
    my (@args) = split(/ /,$first);
    if ($#args > 1 and $args[0] eq $heap->{NickName}) {
        $heap->{BotNumeric} = $args[$#args];
        $_[KERNEL]->post( Service => join => $heap->{BotNumeric} => "#BingosNET" );
    }
  }
  print LOGFILE "$state = $who : $args\n";
}

sub on_create {
  my ($kernel,$heap,$who) = @_[KERNEL,HEAP,ARG0];

  if ( $who eq $heap->{BotNumeric} and not $heap->{connected} ) {
      print LOGFILE Dumper($heap->{Object});
      print LOGFILE "Connecting to IRC Network (Hopefully)\n";
      $kernel->post( Service => 'connect' );
  }
}
