#!/usr/bin/perl -w

use POE;
use POE::Component::IRC::Service;
use Getopt::Long;

my ($servername) = "";
my ($serverdesc) = "";
my ($password) = "";
my ($remoteserver) = "";
my ($serverport) = 0;
my ($nickname) = "";
my ($help) = 0;

GetOptions("servername=s"  => \$servername,
           "description=s" => \$serverdesc,
           "password=s"    => \$password,
           "remote=s"      => \$remoteserver,
           "port=s"        => \$serverport,
           "nickname=s"    => \$nickname,
           "help"          => \$help);

if ($help) {
  print STDERR <<EOF;

Logserv-Hyb.pl <options>
--servername    the name this service will take on the IRC network
--description   a brief string describing the service
--password      the password required to authenticate with uplink server
--remote        the hostname or ip address of our uplink server
--port          port to connect to on our uplink server
--nickname      the nickname for our client
--help          display this help text

EOF
exit 1;
}

if (not $servername and not $serverdesc and not $password and not $remoteserver and not $serverport and
 not $nickname) {
  die ("Missing option. Try LogServ-Hyb.pl --help\n");
}

open (LOGFILE,">>LogServ-Hyb.log") or die;
select LOGFILE;
$|=1;

POE::Component::IRC::Service->new('Service','Hybrid') or die "OOps: $!\n";

POE::Session->create
(
	inline_states => 
	{
		_start => \&client_start,
		_default => \&default,

		irc_hyb_invite    => \&on_invite,
		irc_hyb_sjoin      => \&on_join,
		irc_hyb_connected => \&on_connected
	},
	heap => { NickName => $nickname,
		  ServerName => $servername,
		  ServerDesc => $serverdesc,
		  Password => $password,
		  RemoteServer => $remoteserver,
		  ServerPort => $serverport
	 },
);

$poe_kernel->run();
exit 0;

sub client_start {
  my ($heap) = $_[HEAP];

  print LOGFILE "Registering events\n";
  $_[KERNEL]->post( Service => register => "all" );
  print LOGFILE "Connecting to IRC network\n";
  $_[KERNEL]->post( Service => connect => 
  {
	ServerName    => $heap->{ServerName},
	ServerDesc    => $heap->{ServerDesc},
	Password      => $heap->{Password},
	RemoteServer  => $heap->{RemoteServer},
	ServerPort    => $heap->{ServerPort}
  });
}

sub on_connected {
  my ($heap) = $_[HEAP];

  print LOGFILE "Connected\n";
  $_[KERNEL]->post( Service => addnick =>
  {
	NickName => $heap->{NickName}
  });
}

sub default {
  my ($state, $event, $args, $heap) = @_[ STATE, ARG0, ARG1, HEAP ];
  $args ||= [];
  print LOGFILE "$state = $event (@$args)\n";
  return 0;
}

sub on_invite {
  my ($kernel, $heap, $channel) = @_[KERNEL,HEAP,ARG1];

  $kernel->post( Service => join => $heap->{NickName} => $channel );
}

sub on_join {
  my ($kernel, $heap, $who, $where) = @_[KERNEL,HEAP,ARG0,ARG1];

  my ($first,$second) = split (/:/,$where);
  my (@args) = split (/ /,$first);
  if ( lc ($second) eq lc ($heap->{NickName}) ) {
	$kernel->post(Service => 'sl_server' => "MODE $args[1] +o $heap->{NickName}" );
  }
}
