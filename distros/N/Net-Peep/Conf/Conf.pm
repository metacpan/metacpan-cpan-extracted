package Net::Peep::Conf;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Socket;
use Data::Dumper;
use Sys::Hostname;
use Net::Peep::Log;
use Net::Peep::Host;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

} # end sub new

sub logger {

    # returns a logging object
    my $self = shift;
    if ( ! exists $self->{'__LOGGER'} ) { $self->{'__LOGGER'} = new Net::Peep::Log }
    return $self->{'__LOGGER'};

} # end sub logger

sub client {

    my $self = shift;
    if (@_) { $self->{'CLIENT'} = shift; }
    return $self->{'CLIENT'};

} # end sub client

sub setVersion {

	my $self = shift;
	my $version = shift || confess "Cannot set version:  No version information found";
	$self->{"__VERSION"} = $version;
	$self->logger()->debug(1,"Configuration file version [$version] identified.");
	return 1;

} # end sub setVersion

sub getVersion {

	my $self = shift;

	if (exists $self->{"__VERSION"}) {
		return $self->{"__VERSION"};
	} else {
		confess "Cannot get version:  No version information has been set.";
	}

} # end sub getVersion

sub versionExists {

	my $self = shift;
	return exists $self->{"__VERSION"};

} # end sub versionExists

sub setSoundPath {

	my $self = shift;
	my $soundpath = shift || confess "Cannot set sound path:  No sound path information found";
	$self->{"__SOUNDPATH"} = $soundpath;
	$self->logger()->debug(1,"Configuration file soundpath [$soundpath] identified.");
	return 1;

} # end sub setSoundPath

sub getSoundPath {

	my $self = shift;

	if (exists $self->{"__SOUNDPATH"}) {
		return $self->{"__SOUNDPATH"};
	} else {
		confess "Cannot get sound path:  No sound path information has been set.";
	}

} # end sub getSoundPath

sub soundPathExists {

	my $self = shift;
	return exists $self->{"__SOUNDPATH"};

} # end sub soundPathExists

sub setApp {

	my $self = shift;
	my $app = shift || confess "Cannot set app:  No app information found";
	$self->{"__APP"} = $app;
	$self->logger()->debug(1,"The application [$app] identified itself.");
	return 1;

} # end sub setApp

sub getApp {

	my $self = shift;

	if (exists $self->{"__APP"}) {
		return $self->{"__APP"};
	} else {
		confess "Cannot get app:  No app information has been set.";
	}

} # end sub getApp

sub setClientPort {

	my $self = shift;
	my $client = shift || confess "Cannot set port:  No client information found";
	my $port = shift || confess "Cannot set port:  No port information found";
	$self->{"__PORT"}->{$client} = $port;
	return 1;

} # end sub setClientPort

sub getClientPort {

	my $self = shift;
	my $client = shift || confess "Cannot get port:  No client information found";

	if (exists $self->{"__PORT"}->{$client}) {
		return $self->{"__PORT"}->{$client};
	} elsif ($self->optionExists($client,'port')) {
		return $self->getOption($client,'port');
	} else {
		confess "Cannot get port:  No port information has been defined for the client [$client].";
	}

} # end sub getClientPort

sub addBroadcast {

	my $self = shift;
	my $class = shift || confess "Cannot add broadcast:  No class identifier found";
	my $value = shift || confess "Cannot add broadcast:  No broadcast information found";

	confess "Cannot add broadcast for class [$class]:  Either the IP or port number has not been identified."
		unless ref($value) eq 'HASH' and exists $value->{'ip'} and exists $value->{'port'};

	my $broadcast = $value->{'ip'} . ':' . $value->{'port'};

	push @{$self->{"__BROADCAST"}->{$class}}, $value;

	return 1;

} # end sub addBroadcast

sub getBroadcastList {

	my $self = shift;

	confess "Cannot get broadcast list:  No broadcast information has been set." 
		unless exists $self->{"__BROADCAST"};

	my @broadcasts = sort keys % { $self->{"__BROADCAST"} };

	my @return;

	for my $class (@broadcasts) {
		push @return, @{$self->{"__BROADCAST"}->{$class}};
	}

	return wantarray ? @return : [@return];

} # end sub getBroadcastList

sub getBroadcast {

	my $self = shift;
	my $class = shift || confess "Cannot get broadcast:  No class identifier found";

	confess "Cannot get information for the broadcast class [$class]:  No information has been set."
		unless exists $self->{"__BROADCAST"} && exists $self->{"__BROADCAST"}->{$class};

	return wantarray ? @{$self->{"__BROADCAST"}->{$class}} : $self->{"__BROADCAST"}->{$class};

} # end sub getBroadcast

sub addServer {

	my $self = shift;
	my $class = shift || confess "Cannot add server:  No class identifier found";
	my $value = shift || confess "Cannot add server:  No server information found";

	confess "Cannot add server for class [$class]:  Either the name or port number has not been identified."
		unless ref($value) eq 'HASH' and exists $value->{'name'} and exists $value->{'port'};

	push @{$self->{"__SERVER"}->{$class}}, $value;

	return 1;

} # end sub addServer

sub getServerList {

	my $self = shift;

	confess "Cannot get server list:  No server information has been set." 
		unless exists $self->{"__SERVER"};

	my @servers = keys % { $self->{"__SERVER"} };

	my @return;

	for my $class (@servers) {
		push @return, @{$self->{"__SERVER"}->{$class}};
	}

	return wantarray ? @return : [@return];

} # end sub getServerList

sub getServer {

	my $self = shift;
	my $class = shift || confess "Cannot get server:  No class identifier found";

	confess "Cannot get information for the server in class [$class]:  No information has been set."
		unless exists $self->{"__SERVER"} && exists $self->{"__SERVER"}->{$class};

	return wantarray ? @{$self->{"__SERVER"}->{$class}} : $self->{"__SERVER"}->{$class};

} # end sub getServer

sub addClass {

	my $self = shift;
	my $key = shift || confess "Cannot add class:  No class identifier found";
	my $value = shift || confess "Cannot add class:  No class information found";

	confess "Cannot set class [$key]:  Expecting an array ref (instead of [$value])."
		unless ref($value) eq 'ARRAY';

	$self->{"__CLASS"}->{$key} = $value;

	return 1;

} # end sub addClass

sub getClassList {

	my $self = shift;

	confess "Cannot get class list:  No class information has been set." 
		unless exists $self->{"__CLASS"};

	my @classes = keys % { $self->{"__CLASS"} };

	return wantarray ? @classes : [@classes];

} # end sub getClassList

sub getClass {

	my $self = shift;
	my $key = shift || confess "no class identifier found";

	confess "Cannot get information for the class [$key]:  No information has been set."
		unless exists $self->{"__CLASS"} && exists $self->{"__CLASS"}->{$key};

	return wantarray ? @ { $self->{"__CLASS"}->{$key} } : $self->{"__CLASS"}->{$key};

} # end sub getClass

sub addClientClass {

	my $self = shift;
	my $client = shift || confess "Cannot add client class:  No client identifier found";
	my $value = shift || confess "Cannot add client class:  No class identifier found";

	push @ { $self->{"__CLIENTCLASS"}->{$client} }, $value;

	return 1;

} # end sub addClientClasses

sub getClientClassList {

	my $self = shift;
	my $client = shift || confess "Cannot add client classes:  No client identifier found";

	confess "Cannot get class list:  No class information has been set." 
		unless exists $self->{"__CLIENTCLASS"}->{$client};

	my @classes = @ { $self->{"__CLIENTCLASS"}->{$client} };

	return wantarray ? @classes : [@classes];

} # end sub getClientClasses

sub addEvent {

	my $self = shift;
	my $name = shift || confess "Cannot add event:  No event identifier found";
	my $value = shift || confess "Cannot add event:  No event information found";

	confess "Cannot set event [$name]:  Expecting a hash ref (instead of [$value])."
		unless ref($value) eq 'HASH';

	$self->{"__EVENT"}->{$name} = $value;

	return 1;

} # end sub addEvent

sub getEventList {

	my $self = shift;

	confess "Cannot get event list:  No event information has been set." 
		unless exists $self->{"__EVENT"};

	my @events = keys % { $self->{"__EVENT"} };

	return wantarray ? @events : [@events];

} # end sub getEventList

sub getEvent {

	my $self = shift;
	my $name = shift || confess "Cannot get event:  No event identifier found";

	confess "Cannot get information for the event [$name]:  No information has been set."
		unless exists $self->{"__EVENT"} && exists $self->{"__EVENT"}->{$name};

	return wantarray ? @ { $self->{"__EVENT"}->{$name} } : $self->{"__EVENT"}->{$name};

} # end sub getEvent

sub isEvent {

	my $self = shift;
	my $name = shift || confess "Cannot check event:  No event identifier found";

	return exists $self->{"__EVENT"} && exists $self->{"__EVENT"}->{$name};

} # end sub isEvent

sub setConfigurationText {

	my $self = shift;
	my $client = shift;
	my @text = @_;

	confess "Cannot set configuration text:  No client found."
		unless $client;

	confess "Cannot set configuration text:  No text found."
		unless @text;

	$self->{"__CONFIGURATIONTEXT"}->{$client} = join '', @text;

	$self->logger()->debug(1,"\tConfiguration text of length " .
		length($self->{"__CONFIGURATIONTEXT"}->{$client}) .
		" added to client [$client].");

	return 1;

} # end sub setConfigurationText

sub getConfigurationText {

	my $self = shift;
	my $client = shift;

	confess "Cannot get configuration text:  It has not been set yet."
		unless exists $self->{"__CONFIGURATIONTEXT"}->{$client};

	return $self->{"__CONFIGURATIONTEXT"}->{$client};

} # end sub getConfigurationText

sub setNotificationText {

	my $self = shift;
	my $client = shift;
	my @text = @_;

	confess "Cannot set notification text:  No client found."
		unless $client;

	confess "Cannot set notification text:  No text found."
		unless @text;

	$self->{"__NOTIFICATIONTEXT"}->{$client} = join '', @text;

	$self->logger()->debug(1,"Notification text of length " .
		length($self->{"__NOTIFICATIONTEXT"}->{$client}) .
		" added to client [$client].");

	return 1;

} # end sub setNotificationText

sub getNotificationText {

	my $self = shift;
	my $client = shift;

	confess "Cannot get notification text:  It has not been set yet."
		unless exists $self->{"__NOTIFICATIONTEXT"}->{$client};

	return $self->{"__NOTIFICATIONTEXT"}->{$client};

} # end sub getNotificationText

sub addState {

	my $self = shift;
	my $name = shift || confess "Cannot add state:  No state identifier found";
	my $value = shift || confess "Cannot add state:  No state information found";

	confess "Cannot set state [$name]:  Expecting a hash ref (instead of [$value])."
		unless ref($value) eq 'HASH';

	$self->{"__STATE"}->{$name} = $value;

	return 1;

} # end sub addState

sub getStateList {

	my $self = shift;

	confess "Cannot get state list:  No state information has been set." 
		unless exists $self->{"__STATE"};

	my @states = keys % { $self->{"__STATE"} };

	return wantarray ? @states : [@states];

} # end sub getStateList

sub getState {

	my $self = shift;
	my $name = shift || confess "Cannot get state:  No state identifier found";

	confess "Cannot get information for the state [$name]:  No information has been set."
		unless exists $self->{"__STATE"} && exists $self->{"__STATE"}->{$name};

	return wantarray ? @ { $self->{"__STATE"}->{$name} } : $self->{"__STATE"}->{$name};

} # end sub getState

sub isState {

	my $self = shift;
	my $name = shift || confess "Cannot check state:  No state identifier found";

	return exists $self->{"__STATE"} && exists $self->{"__STATE"}->{$name};

} # end sub isState

sub addClientEvent {

	my $self = shift;
	my $name = shift || confess "Cannot add client event:  No client event identifier found";
	my $value = shift || confess "Cannot add client event:  No client event information found";

	confess "Cannot set client event [$name]:  Expecting a hash ref (instead of [$value])."
		unless ref($value) eq 'HASH';

	my $clientevent = $value->{'name'};

	push @ { $self->{"__CLIENTEVENT"}->{$name} }, $value;

	return 1;

} # end sub addClientEvent

sub getClientEventList {

	my $self = shift;

	confess "Cannot get clientevent list:  No clientevent information has been set." 
		unless exists $self->{"__CLIENTEVENT"};

	my @clientevents;

	for my $client (keys % { $self->{"__CLIENTEVENT"} }) {
		push @clientevents, @ { $self->{"__CLIENTEVENT"}->{$client} };
	}

	return wantarray ? @clientevents : [@clientevents];

} # end sub getClientEventList

sub getClientEvents {

	my $self = shift;
	my $name = shift || confess "Cannot get clientevent:  No clientevent identifier found";

	confess "Cannot get information for the clientevent [$name]:  No information has been set."
		unless exists $self->{"__CLIENTEVENT"} && exists $self->{"__CLIENTEVENT"}->{$name};

	return wantarray ? @ { $self->{"__CLIENTEVENT"}->{$name} } : $self->{"__CLIENTEVENT"}->{$name};

} # end sub getClientEvents

sub checkClientEvent {

	my $self = shift;
	my $client = shift || confess "Client not found";
	my $event = shift || confess "Event not found";

	my $return = 0;

	my ($group,$letter) = ('','');

	$group = $event->{'group'} if exists $event->{'group'};
	$letter = $event->{'option-letter'} if exists $event->{'option-letter'};

	my @groups = ();
	my @exclude = ();
	my @events = ();

	@events = split //, $self->getOption($client,'events') if $self->optionExists($client,'events');
	@groups = @{ $self->getOption($client,'groups') } if $self->optionExists($client,'groups');
	@exclude = @{ $self->getOption($client,'exclude') } if $self->optionExists($client,'exclude');

	# first check the events option
	
	for my $letter_option (@events) {
		$return = 1 if $letter eq $letter_option;
	}

	if (grep /^all$/, @groups) {
		$return = 1;
		for my $exclude_option (@exclude) {
			$return = 0 if $group eq $exclude_option;
		}
	} else {
		for my $group_option (@groups) {
			$return = 1 if $group eq $group_option;
		}
	}

	return $return;

} # end sub checkClientEvent

sub checkClientHost {

	my $self = shift;
	my $client = shift || confess "Client not found";
	my $host = shift || confess "Host not found";

	my $return = 0;

	my $event = $host->getEvent();

	return $self->checkClientEvent($client,$event);

} # end sub checkClientHost

sub addClientHost {

	my $self = shift;
	my $client = shift || confess "Cannot add client host:  No client identifier found";
	my $value = shift || confess "Cannot add client host:  No client host information found";

	confess "Cannot set client host for client [$client]:  Expecting a hash ref (instead of [$value])."
		unless ref($value) eq 'HASH';

	my $identifier = $value->{'host'};

	my ($iaddr,$host,$ip);
	if ($identifier =~ /^(\d+\.)+\d+$/) {
	    # we were given an IP address
	    $ip = $identifier;
	    $host = inet_aton($ip);
	    $host = gethostbyaddr($host,AF_INET) if $host;
	    $self->logger()->log("\t\tThe host name for IP [$ip] could not be found.  This host will be ignored.")
		and return 0 unless $host;
	    $self->logger()->debug(9,"\t\tThe host name [$host] was found for host [$identifier].");
	} elsif ($identifier =~ /^([\w-]+\.)+\w+$/) {
	    # we were given a host name
	    $host = $identifier;
	    $ip = gethostbyname($identifier);
	    # funny that the next line and previous line can't be combined ... but Socket complains!
	    $ip = inet_ntoa($ip) if $ip;
	    $self->logger()->log("\t\tThe IP address for host [$identifier] could not be found.  This host will be ignored.")
		and return 0 unless $ip;
	    $self->logger()->debug(9,"\t\tThe IP address [$ip] was found for host [$identifier].");
	} else {
	    $self->logger()->log("The host name or IP [$identifier] does not appear to be valid.  This host will be ignored.");
	    return;
	}
	    
	my $event = {
	    name => $value->{'name'},
	    group => $value->{'group'},
	    'option-letter' => $value->{'option-letter'},
	    location => $value->{'location'},
	    priority => $value->{'priority'},
	    status => $value->{'status'},

	};

	my $clienthost = new Net::Peep::Host;
	$clienthost->setName($host);
	$clienthost->setIP($ip);
	$clienthost->setEvent($event);
	$clienthost->setNotificationLevel($value->{'status'});

	push @ { $self->{"__CLIENTHOST"}->{$client} }, $clienthost;

	return 1;

} # end sub addClientHost

sub getClientHostList {

	my $self = shift;

	confess "Cannot get clienthost list:  No client host information has been set." 
		unless exists $self->{"__CLIENTHOST"};

	my @clienthosts;

	for my $client (keys % { $self->{"__CLIENTHOST"} }) {
		push @clienthosts, @ { $self->{"__CLIENTHOST"}->{$client} };
	}

	return wantarray ? @clienthosts : [@clienthosts];

} # end sub getClientHostList

sub getClientHosts {

	my $self = shift;
	my $client = shift || confess "Cannot get client host:  No client identifier found";

	$self->logger()->log("Cannot get host information for the client [$client]:  No information has been set.")
	    and return
		unless exists $self->{"__CLIENTHOST"} && exists $self->{"__CLIENTHOST"}->{$client};

	return wantarray ? @{$self->{"__CLIENTHOST"}->{$client}} : $self->{"__CLIENTHOST"}->{$client};

} # end sub getClientHosts

sub addClientUptime {

	my $self = shift;
	my $client = shift || confess "Cannot add client uptime:  No client identifier found";
	my $value = shift || confess "Cannot add client uptime:  No client uptime information found";

	confess "Cannot set client uptime setting for client [$client]:  Expecting a hash ref (instead of [$value])."
		unless ref($value) eq 'HASH';

	confess "Cannot set client uptime setting for client [$client]:  The hash ref is missing important keys."
	    unless exists($value->{'name'}) && exists($value->{'value'}) && exists($value->{'status'});

	push @ { $self->{"__CLIENTUPTIME"}->{$client} }, $value;

	return 1;

} # end sub addClientUptime

sub getClientUptimeList {

	my $self = shift;

	confess "Cannot get client uptime settings list:  No client uptime information has been set." 
		unless exists $self->{"__CLIENTUPTIME"};

	my @clientuptimes;

	for my $client (keys % { $self->{"__CLIENTUPTIME"} }) {
		push @clientuptimes, @ { $self->{"__CLIENTUPTIME"}->{$client} };
	}

	return wantarray ? @clientuptimes : [@clientuptimes];

} # end sub getClientUptimeList

sub getClientUptimes {

	my $self = shift;
	my $client = shift || confess "Cannot get client uptime settings:  No client identifier found";

	$self->logger()->log("Cannot get uptime information for the client [$client]:  No information has been set.")
	    and return
		unless exists $self->{"__CLIENTUPTIME"} && exists $self->{"__CLIENTUPTIME"}->{$client};

	return wantarray ? @{$self->{"__CLIENTUPTIME"}->{$client}} : $self->{"__CLIENTUPTIME"}->{$client};

} # end sub getClientUptimes

sub addClientProc {

	my $self = shift;
	my $client = shift || confess "Cannot add client proc:  No client identifier found";
	my $value = shift || confess "Cannot add client proc:  No client proc information found";

	confess "Cannot set client proc setting for client [$client]:  Expecting a hash ref (instead of [$value])."
		unless ref($value) eq 'HASH';

	confess "Cannot set client proc setting for client [$client]:  The hash ref is missing important keys."
	    unless exists($value->{'name'}) && exists($value->{'value'}) && exists($value->{'status'});

	push @ { $self->{"__CLIENTPROC"}->{$client} }, $value;

	return 1;

} # end sub addClientProc

sub getClientProcList {

	my $self = shift;

	confess "Cannot get client proc settings list:  No client proc information has been set." 
		unless exists $self->{"__CLIENTPROC"};

	my @clientprocs;

	for my $client (keys % { $self->{"__CLIENTPROC"} }) {
		push @clientprocs, @ { $self->{"__CLIENTPROC"}->{$client} };
	}

	return wantarray ? @clientprocs : [@clientprocs];

} # end sub getClientProcList

sub getClientProcs {

	my $self = shift;
	my $client = shift || confess "Cannot get client proc settings:  No client identifier found";

	$self->logger()->log("Cannot get proc information for the client [$client]:  No information has been set.")
	    and return
		unless exists $self->{"__CLIENTPROC"} && exists $self->{"__CLIENTPROC"}->{$client};

	return wantarray ? @{$self->{"__CLIENTPROC"}->{$client}} : $self->{"__CLIENTPROC"}->{$client};

} # end sub getClientProcs

sub setOption {

    my $self = shift;

    # The following bit of logic is a bit of a kludge.  If you're
    # wondering why it was done, please contact the author :-)

    if (@_ == 2) {

	my $client = $self->client() || confess "Cannot set client option:  Client not specified.";
	my $name = $client->name() || confess "Cannot set client option:  Client name not specified.";
	my $option = shift || confess "Cannot set client option:  Option name not specified.";
	my $value = shift;
	$self->{"__OPTIONS"}->{$name}->{$option} = $value;
	return 1;

    } elsif (@_ == 3) {

	my $client = shift || confess "Cannot set client option:  Client name not specified.";
	my $option = shift || confess "Cannot set client option:  Option name not specified.";
	my $value = shift;
	$self->{"__OPTIONS"}->{$client}->{$option} = $value;
	return 1;

    } else {

	confess "Cannot set client option:  Wrong number of arguments to setOption method.";

    }

} # end sub setOption

sub getOption {

	my $self = shift;
	my $name;
	my $option;
	if (@_ == 1) {
	    $option = shift || confess "Cannot get client option:  Option name not specified.";
	    my $client = $self->client() || confess "Cannot get client option:  Client not specified.";;
	    $name = $client->name() || confess "Cannot get client option:  Client name not specified.";
	} elsif (@_ == 2) {
	    $name = shift || confess "Cannot get client option:  Client name not specified.";
	    $option = shift || confess "Cannot get client option:  Option name not specified.";
	} else {
	    confess "Cannot get option [$option]:  Incorrect number of arguments to the getOption method.";
	}
#	$self->logger()->debug(9,"Getting option [$option] for client [$name] ...");
	confess "Cannot get option [$option]:  The option value has not been set yet."
	    unless $self->optionExists($name,$option);
	return $self->{"__OPTIONS"}->{$name}->{$option};

} # end sub getOption

sub optionExists {

    # The following bit of logic is a bit of a kludge.  If you're
    # wondering why it was done, please contact the author :-)

    my $self = shift;

    my $option;
    my $name;
    if (@_ == 1) {
	$option = shift || confess "Cannot evaluate client option:  Option name not specified.";
	my $client = $self->client() || confess "Cannot evaluate client option:  Client not specified.";;
	$name = $client->name() || confess "Cannot evaluate client option:  Client name not specified.";
    } elsif (@_ == 2) {
	$name = shift || confess "Cannot evaluate client option:  Client name not specified.";
	$option = shift || confess "Cannot evaluate client option:  Option name not specified.";
    } else {
	confess "Cannot evaluate client option:  Wrong number of arguments to optionExists method.";
    }
#    $self->logger()->debug(9,"Checking existence of option [$option] for client [$name] ....");
    if (exists $self->{"__OPTIONS"}->{$name}
	and exists $self->{"__OPTIONS"}->{$name}->{$option}) {
	return 1;
    } else {
	return 0;
    }

} # end sub optionExists

sub getOptions {

	# returns the names of all of the currently set options
	my $self = shift;
	my $name;
	if (@_) {
	    $name = shift;
	} else {
	    my $client = $self->client() || confess "Cannot get client options:  Client not specified.";;
	    $name = $client->name() || confess "Cannot get client options:  Client name not specified.";
	}
	return () unless exists $self->{"__OPTIONS"}->{$name};
	return wantarray 
		? ( keys % { $self->{"__OPTIONS"}->{$name} } )
		: [ keys % { $self->{"__OPTIONS"}->{$name} } ];

} # end sub getOptions

sub getOptionsHash {

	# returns the names of all of the currently set options
	my $self = shift;
	my %return;
	my $name;
	if (@_) {
	    $name = shift;
	} else {
	    my $client = $self->client() || confess "Cannot get options hash:  Client not specified.";;
	    $name = $client->name() || confess "Cannot get options hash:  Client name not specified.";
	}
	for my $option (keys % { $self->{"__OPTIONS"}->{$name} }) {
		$return{$option} = $self->getOption($name,$option);
	}
	return %return;

} # end sub getOptionHash

1;

__END__

=head1 NAME

Net::Peep::Conf - Perl extension for providing an object
representation of configuration information for Peep: The Network
Auralizer.

=head1 SYNOPSIS

  use Net::Peep::Conf;
  my $conf = new Net::Peep::Conf;
  $conf->setBroadcast($class0,$value0);
  $conf->setBroadcast($class1,$value1);
  $conf->getBroadcastList();

=head1 DESCRIPTION

Net::Peep::Conf provides an object interface for Peep configuration
information, typically extracted from a Peep configuration file (e.g.,
/etc/peep.conf) by the Net::Peep::Parser module.

=head1 EXPORT

None by default.

=head1 PUBLIC METHODS

  setApp($appname) - A unique identifier associated with a client
  configuration.  Typically the name of the application using the
  configuration information; e.g., logparser.

  getApp() - Returns the identifier set with setApp.

  getPort() - Returns the port set with setPort.

  setPort($port) - Sets a port number.  Typically the client broadcast
  port.

  getBroadcastList() - Returns a list of all broadcast names
  associated with all classes.

  getBroadcast($class) - Gets the broadcast string for the class
  $class.

  addBroadcast($class,$value) - Adds the broadcast string
  (consisting of IP/domain and port) named $name for the class $class.

  getClassList() - Returns a list of all class names that have
  associated server lists.

  getClass($class) - Returns a list of servers associated with the
  class $class.

  setClass($class,$arrayref) - Associates the class $class with the
  list of servers given in $arrayref.

  getEventList() - Returns a list of all event names.

  getEvent($event) - Returns the event information for the event with
  name $event.

  setEvent($event,$hashref) - Associates the event $event with the
  information contained in $hashref.

  getStateList() - Returns a list of all state names.

  getState($state) - Returns the state information associated with the
  state $state.

  setState($event,$hashref) - Associates the state $state with the
  information contained in $hashref.

  setConfigurationText($client,$text) - Sets the configuration text to
  $text for client $client.  For reference and debugging only.  The
  text is not actually used internally for any purpose.

  getNotificationText($client) - Returns the configuration text for
  client $client.

  setNotificationText($client,$text) - Sets the configuration text to
  $text for client $client.  For reference and debugging only.  The
  text is not actually used internally for any purpose.

  getConfigurationText($client) - Returns the configuration text for
  client $client.

  setClientEvent($name,$arrayref) - Sets the events associated with
  the client $name.

  getClientEvents($name) - Returns the events associated with the client $name.

  getClientEventList() - Returns all events associated with all clients.

  checkClientEvent() - The method name is a question: Based on
  command-line or configuration file settings, should this client
  event be considered active in the current client?  For example,
  should the logparser check the regular expression for this event
  against log files?

  setVersion() - Sets the version number.

  getVersion() - Return the version number taken from the Peep configuration
  file (e.g., peep.conf) if it exists.  Confesses if the version has not been
  set yet.  See also versionExists().

  versionExists() - Returns 1 if a version has been set with the setVersion()
  method, 0 otherwise.

  setSoundPath() - Sets the path to the Peep sound respository
  (typically /usr/local/share/peep/sounds).

  getSoundPath() - Returns the sound path.  Confesses if the sound
  path has not been set yet.  See also soundPathExists().

  soundPathExists() - Returns 1 if the sound path has been set with
  the setSoundPath() method, 0 otherwise.

=head1 AUTHOR

Collin Starkweather Copyright (C) 2001

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::BC, Net::Peep::Parser, Net::Peep::Log.

http://peep.sourceforge.net

=head1 CHANGE LOG

$Log: Conf.pm,v $
Revision 1.8  2001/09/23 08:53:56  starky
The initial checkin of the 0.4.4 release candidate 1 clients.  The release
includes (but is not limited to):
o A new client:  pinger
o A greatly expanded sysmonitor client
o An API for creating custom clients
o Extensive documentation on creating custom clients
o Improved configuration file format
o E-mail notifications
Contact Collin at collin.starkweather@colorado with any questions.

Revision 1.7  2001/08/08 20:17:57  starky
Check in of code for the 0.4.3 client release.  Includes modifications
to allow for backwards-compatibility to Perl 5.00503 and a critical
bug fix to the 0.4.2 version of Net::Peep::Conf.

Revision 1.6  2001/08/06 04:20:35  starky
Fixed bug #447844.

Revision 1.5  2001/07/23 20:17:45  starky
Fixed a minor bug in setting groups and exclude flags from the command-line
with the logparser.

Revision 1.4  2001/07/23 17:46:29  starky
Added versioning to the configuration file as well as the ability to
specify groups in addition to / as a replacement for event letters.
Also changed the Net::Peep::Parse namespace to Net::Peep::Parser.
(I don't know why I ever named an object by a verb!)

Revision 1.3  2001/07/20 03:19:58  starky
Some trivial changes.  They normally wouldn't be committed at this stage,
but the code is being prepped for the 0.4.2 release.

Revision 1.2  2001/05/07 02:39:19  starky
A variety of bug fixes and enhancements:
o Fixed bug 421729:  Now the --output flag should work as expected and the
--logfile flag should not produce any unexpected behavior.
o Documentation has been updated and improved, though more improvements
and additions are pending.
o Removed print STDERRs I'd accidentally left in the last commit.
o Other miscellaneous and sundry bug fixes in anticipation of a 0.4.2
release.

Revision 1.1  2001/04/23 10:13:19  starky
Commit in preparation for release 0.4.1.

o Altered package namespace of Peep clients to Net::Peep
  at the suggestion of a CPAN administrator.
o Changed Peep::Client::Log to Net::Peep::Client::Logparser
  and Peep::Client::System to Net::Peep::Client::Sysmonitor
  for clarity.
o Made adjustments to documentation.
o Fixed miscellaneous bugs.

Revision 1.7  2001/04/17 06:46:21  starky
Hopefully the last commit before submission of the Peep client library
to the CPAN.  Among the changes:

o The clients have been modified somewhat to more elagantly
  clean up pidfiles in response to sigint and sigterm signals.
o Minor changes have been made to the documentation.
o The Peep::Client module searches through a host of directories in
  order to find peep.conf if it is not immediately found in /etc or
  provided on the command line.
o The make test script conf.t was modified to provide output during
  the testing process.
o Changes files and test.pl files were added to prevent specious
  complaints during the make process.

Revision 1.6  2001/03/31 07:51:35  mgilfix


  Last major commit before the 0.4.0 release. All of the newly rewritten
clients and libraries are now working and are nicely formatted. The server
installation has been changed a bit so now peep.conf is generated from
the template file during a configure - which brings us closer to having
a work-out-of-the-box system.

Revision 1.6  =head1 CHANGE LOG
 
$Log: Conf.pm,v $
Revision 1.8  2001/09/23 08:53:56  starky
The initial checkin of the 0.4.4 release candidate 1 clients.  The release
includes (but is not limited to):
o A new client:  pinger
o A greatly expanded sysmonitor client
o An API for creating custom clients
o Extensive documentation on creating custom clients
o Improved configuration file format
o E-mail notifications
Contact Collin at collin.starkweather@colorado with any questions.

Revision 1.7  2001/08/08 20:17:57  starky
Check in of code for the 0.4.3 client release.  Includes modifications
to allow for backwards-compatibility to Perl 5.00503 and a critical
bug fix to the 0.4.2 version of Net::Peep::Conf.

Revision 1.6  2001/08/06 04:20:35  starky
Fixed bug #447844.

Revision 1.5  2001/07/23 20:17:45  starky
Fixed a minor bug in setting groups and exclude flags from the command-line
with the logparser.

Revision 1.4  2001/07/23 17:46:29  starky
Added versioning to the configuration file as well as the ability to
specify groups in addition to / as a replacement for event letters.
Also changed the Net::Peep::Parse namespace to Net::Peep::Parser.
(I don't know why I ever named an object by a verb!)

Revision 1.3  2001/07/20 03:19:58  starky
Some trivial changes.  They normally wouldn't be committed at this stage,
but the code is being prepped for the 0.4.2 release.

Revision 1.2  2001/05/07 02:39:19  starky
A variety of bug fixes and enhancements:
o Fixed bug 421729:  Now the --output flag should work as expected and the
--logfile flag should not produce any unexpected behavior.
o Documentation has been updated and improved, though more improvements
and additions are pending.
o Removed print STDERRs I'd accidentally left in the last commit.
o Other miscellaneous and sundry bug fixes in anticipation of a 0.4.2
release.

Revision 1.1  2001/04/23 10:13:19  starky
Commit in preparation for release 0.4.1.

o Altered package namespace of Peep clients to Net::Peep
  at the suggestion of a CPAN administrator.
o Changed Peep::Client::Log to Net::Peep::Client::Logparser
  and Peep::Client::System to Net::Peep::Client::Sysmonitor
  for clarity.
o Made adjustments to documentation.
o Fixed miscellaneous bugs.

Revision 1.7  2001/04/17 06:46:21  starky
Hopefully the last commit before submission of the Peep client library
to the CPAN.  Among the changes:

o The clients have been modified somewhat to more elagantly
  clean up pidfiles in response to sigint and sigterm signals.
o Minor changes have been made to the documentation.
o The Peep::Client module searches through a host of directories in
  order to find peep.conf if it is not immediately found in /etc or
  provided on the command line.
o The make test script conf.t was modified to provide output during
  the testing process.
o Changes files and test.pl files were added to prevent specious
  complaints during the make process.

Revision 1.6  2001/03/31 07:51:35  mgilfix


  Last major commit before the 0.4.0 release. All of the newly rewritten
clients and libraries are now working and are nicely formatted. The server
installation has been changed a bit so now peep.conf is generated from
the template file during a configure - which brings us closer to having
a work-out-of-the-box system.

Revision 1.7  2001/03/31 02:17:00  mgilfix
Made the final adjustments to for the 0.4.0 release so everything
now works. Lots of changes here: autodiscovery works in every
situation now (client up, server starts & vice-versa), clients
now shutdown elegantly with a SIGTERM or SIGINT and remove their
pidfiles upon exit, broadcast and server definitions in the class
definitions is now parsed correctly, the client libraries now
parse the events so they can translate from names to internal
numbers. There's probably some other changes in there but many
were made :) Also reformatted all of the code, so it uses
consistent indentation.

Revision 1.5  2001/03/28 02:41:48  starky
Created a new client called 'pinger' which pings a set of hosts to check
whether they are alive.  Made some adjustments to the client modules to
accomodate the new client.

Also fixed some trivial pre-0.4.0-launch bugs.

Revision 1.4  2001/03/27 05:49:04  starky
Modified the getClientPort method to accept the 'port' option as
specified on the command line if no client has been specified in the
conf file.

Revision 1.3  2001/03/27 00:44:19  starky
Completed work on rearchitecting the Peep client API, modified client code
to be consistent with the new API, and added and tested the sysmonitor
client, which replaces the uptime client.

This is the last major commit prior to launching the new client code,
though the API or architecture may undergo some initial changes following
launch in response to comments or suggestions from the user and developer
base.

Revision 1.2  2001/03/18 17:17:46  starky
Finally got LogParser (now called logparser) running smoothly.

Revision 1.1  2001/03/16 18:31:59  starky
Initial commit of some very broken code which will eventually comprise
a rearchitecting of the Peep client libraries; most importantly, the
Perl modules.

A detailed e-mail regarding this commit will be posted to the Peep
develop list (peep-develop@lists.sourceforge.net).

Contact me (Collin Starkweather) at

  collin.starkweather@colorado.edu

or

  collin.starkweather@collinstarkweather.com

with any questions.


=cut
