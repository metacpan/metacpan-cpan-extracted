package Net::Peep::BC;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Socket;
use Sys::Hostname;
use Net::Peep::Parser;
use Net::Peep::Conf;
use Net::Peep::Log;
use Net::Peep::Scheduler;

use vars qw{ %Leases %Servers %Defaults $Scheduler $Alarmtime };

%Leases = %Servers = ();

%Defaults = (
	type => 0,
	location => 128,
	priority => 0,
	volume => 128,
	dither => 0,
	sound => 0
);

$Scheduler = new Net::Peep::Scheduler;

$Alarmtime = 30;

# Peep protocol constants
use constant PROT_MAJORVER => 1;
use constant PROT_MINORVER => 0;
use constant PROT_BCSERVER => 0;
use constant PROT_BCCLIENT => 1;
use constant PROT_SERVERSTILLALIVE => 2;
use constant PROT_CLIENTSTILLALIVE => 3;
use constant PROT_CLIENTEVENT => 4;
use constant PROT_CLASSDELIM => '!';

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

	$this->initialize(@_);

	return $this;

} # end sub new

sub initialize {

	my $self = shift;
	my $client = shift || confess "Error:  Client not found";
	my $configuration = shift || confess "Error:  Configuration not found";

	# put the configuration object in a place where all the other
	# methods can find it
	$self->setConfiguration($configuration);

	my %options = $configuration->getOptionsHash($client);

	# FIXIT: This is silly and redundant.  The object that instantiates
	# the Net::Peep::BC object already has all of the options set and a
	# configuration object.  Net::Peep::BC shouldn't need to build its own
	# stable of options.  Deal with it later ....

	# Populate the object attributes either by the class default
	# attributes or the options arguments passed in

	for my $key (keys %Defaults) {
		if ($key ne 'dither') {
			if (exists $options{$key}) {
				$self->setOption($key,$options{$key});
			} else {
				$self->setOption($key,$Defaults{$key});
			}
		}
	}

	# Make allowances for the two possible meanings of dither
	# dither is based exclusively on the value of 'type'
	$self->getOption('type') ? $self->setOption('dither',255) : $self->setOption('dither',0);

	# Now initialize our socket
	my $port = $configuration->getClientPort($client);
	$self->logger()->debug(7,"Initializing socket on port $port ...");
	my $addr = INADDR_ANY;
	my $proto = getprotobyname('udp');
	my $paddr = sockaddr_in($port, $addr);
	socket(SOCKET, PF_INET, SOCK_DGRAM, $proto) or confess "Socket error: $!";
	if ($configuration->getOption($client,'autodiscovery')) {
		bind(SOCKET, $paddr)                        or confess "Bind error: $!";
	}
	$self->logger()->debug(7,"\tSocket initialized.");

	#Set the socket option for the broadcast
	setsockopt SOCKET, SOL_SOCKET, SO_BROADCAST | SO_REUSEADDR, 1;

	#Let everyone know we're alive
	$self->hello( PROT_BCCLIENT );

	#Start up the alarm. Once this handler gets started, we'll have it
	#work concurrently with the program to handle host lists
	if ($configuration->getOption($client,'autodiscovery')) {
		$Scheduler->schedulerAddEvent(
			$self->getConfiguration()->client(),
			$Alarmtime,
			0.0,
			'client',
			sub { $self->handlealarm( PROT_CLIENTSTILLALIVE ) },
			'',
			1 # 1 => repeated event, 0 => single event
		);
	}

} # end sub initialize

sub hello {

	my $self = shift;
	my $constant = shift;
	my $configuration = $self->getConfiguration() || confess "Error:  Configuration not found";

	# Send out our broadcast to let everybody know we're alive
	# Note - we want to send these broadcasts to the servers within
	# the class definition. So, we use getServer() - Mike
	for my $class ($configuration->getClassList()) {
		$self->logger()->debug(7,"Getting broadcast for class [$class]");
		my $broadcasts = $configuration->getServer($class);

		for my $broadcast (@$broadcasts) {
			my ($zone, $port) = ($broadcast->{'name'}, $broadcast->{'port'});
			$self->logger()->debug(7,"Socketing to zone [$zone] and port [$port] ...");
			my $iaddr = inet_aton($zone);
			my $bcaddr = sockaddr_in($port, $iaddr);

			#Assemble the packet and send it
			my $packet = $self->assemble_bc_packet($constant);
			if (defined($constant) && $constant == PROT_CLIENTSTILLALIVE) {
				$self->logger()->debug(7,"Letting [$zone:$port] know we're still alive ...");
			} else {
				$self->logger()->debug(7,"Sending a friendly hello to address [$zone:$port] ...");
			}
			if (defined(send(SOCKET, $packet, 0, $bcaddr))) {
				$self->logger()->debug(9,"\tPacket of length ".length($packet)." sent.");
			} else {
				$self->logger()->log("Send broadcast error: $!");
			}
		}
	}

} # end sub hello

sub getConfiguration {

	my $self = shift;
	confess "Error retrieving configuration:  The configuration has not been set yet."
	unless exists $self->{"__CONFIGURATOR"};
	return $self->{"__CONFIGURATOR"};

} # end sub getConfiguration

sub setConfiguration {

	my $self = shift;
	if (@_) {
		$self->{"__CONFIGURATOR"} = shift;
	} else {
		confess "Cannot set configuration:  No configuration object found.";
	}
	return 1;

} # end sub setConfiguration

# Function to assemble a broadcast packet with an appropriate
# identifier string
sub assemble_bc_packet {

	my $self = shift;
	my $constant = shift;
	my $configuration = $self->getConfiguration();
	my $identifier = join PROT_CLASSDELIM, ($configuration->getClassList());
	$identifier .= PROT_CLASSDELIM;
	return pack("CCCCA128", 
		PROT_MAJORVER,
		PROT_MINORVER,
		$constant, 
		0, 
		$identifier);

} # end sub assemble_bc_packet

# returns a logging object
sub logger {

	my $self = shift;
	if ( ! exists $self->{'__LOGGER'} ) { $self->{'__LOGGER'} = new Net::Peep::Log }
	return $self->{'__LOGGER'};

} # end sub logger

sub close {

	my $self = shift;
	close SOCKET;

} # end sub close

# Send out a packet
sub send {

	my $self = shift;
	my $client = shift;
	my %options = @_;

	$self->logger()->debug(7,"Sending packet to server(s) ...");

	my $configuration = $self->getConfiguration();

	my $type = exists($options{'type'}) ? $options{'type'} : $self->getOption('type');
	my $location = exists($options{'location'}) ? $options{'location'} : $self->getOption('location');
	my $priority = exists($options{'priority'}) ? $options{'priority'} :  $self->getOption('priority');
	my $volume = exists($options{'volume'}) ? $options{'volume'} : $self->getOption('volume');
	my $dither = exists($options{'dither'}) ? $options{'dither'} : $self->getOption('dither');
	my $sound = exists($options{'sound'}) ? $options{'sound'} : $self->getOption('sound');

	$self->logger()->debug(9,"type=[$type] location=[$location] priority=[$priority] volume=[$volume] dither=[$dither] sound=[$sound]");

	#Now convert the sound name into the number if it isn't a number already
	if ($sound !~ /\d+/) {
		my $hash;
		$hash = $configuration->getEvent($sound) if $configuration->isEvent($sound);
		$hash = $configuration->getState($sound) if $configuration->isState($sound);

		if (ref($hash)) {
			my $index = $hash->{'index'};
			$self->logger()->debug(5,"Sound [$sound] reassigned:  Now it is [$index]");
			$sound = $index;
		} else {
			$self->logger()->log(ref($self),": Warning: Asking Peep to play a non existent sound: [$sound]");
			return;
		}
	}

	if ($configuration->getOption($client,'autodiscovery')) {

		# Now sendout to all the servers in our server list
		for my $server (keys %Servers) {
			my ($serverport,$serverip) = unpack_sockaddr_in($server);
			$serverip = inet_ntoa($serverip);
			$self->logger()->debug(7,"Notifying server [$serverip:$serverport] of event or sound [$sound] ...");
			$self->sendout($type, $sound, $location, $priority, $volume, $dither, $server);
		}

	} else {

		# Just send a packet to the server and port specified on the command-line
		my $port = $configuration->getOption($client,'port') || confess "Error:  Expecting nonzero port!";
		my $host = $configuration->getOption($client,'server') || confess "Error:  Expecting nonzero host!";
		$self->logger()->debug(7,"Notifying server [$host:$port] of event or sound [$sound] ...");
		$host = inet_aton($host);
		my $server = sockaddr_in($port,$host);
		$self->sendout($type, $sound, $location, $priority, $volume, $dither, $server);

	}

} # end sub send

sub sendout {

	my $self = shift;
	my ($type,$sound,$location,$priority,$volume,$dither,$server) 
	    = @_;
	my $mix_in_time = 0;

	my ($serverport,$serverip) = unpack_sockaddr_in($server);
	$serverip = inet_ntoa($serverip);
	$self->logger()->debug(7,"type=[$type] sound=[$sound] location=[$location] priority=[$priority] volume=[$volume] dither=[$dither] server=[$serverip:$serverport]") ;

	#Now we need to build the appropriate network packet
	my $packet = pack("CCCCC8",
		PROT_MAJORVER,
		PROT_MINORVER,
		PROT_CLIENTEVENT,
		0,
		$type, $sound, $location, $priority, $volume, $dither);

	if (not defined(CORE::send(SOCKET, $packet, 0, $server))) {
		$self->logger()->debug(7,"Error sending packet to [$serverip:$serverport]:  $!");
		$self->logger()->debug(7,"You may want to check that the server is accepting connections on port [$serverport].");
	}

	return 1;

} # end sub sendout

sub setOption {

	my $self = shift;
	my $option = shift || confess "option not found";
	my $value = shift;
	confess "value not found" unless defined $value;
	$self->{"__OPTIONS"}->{$option} = $value;
	return 1;

} # end sub setOption

sub getOption {

	my $self = shift;
	my $option = shift || confess "option not found";

	if (exists $self->{"__OPTIONS"}->{$option}) {
		return $self->{"__OPTIONS"}->{$option};
	} else {
		confess "Cannot get the option '$option':  It has not yet been set.";
	}

	return 0;

} # end sub setOption

sub handlealarm {

	#Every tick, we wait until we have some input to respond to, then update
	#our server list. Finally, we purge the server list of any impurities and
	#carry on with out business
	my $self = shift;
	my $constant = shift;

	$self->hello($constant);
	$self->updateserverlist();
	$self->purgeserverlist();

	if (scalar(keys %Servers)) {
		$self->logger()->debug(9,"Known servers:");
		for my $server (sort keys %Servers) {
			my ($serverport,$serverip) = unpack_sockaddr_in($server);
			$serverip = inet_ntoa($serverip);
			$self->logger()->debug(9,"\t[$serverip:$serverport]");
		}
	} else {
		$self->logger()->debug(9,"There are currently no known servers.");
	}

	return 1;

} # end sub handlealarm

sub updateserverlist {

	#Poll to see if we've received anything so we can update the server list 
	#before we send. Then, send out the packet.
	my $self = shift;

	$self->logger()->debug(9,"Updating server list ...");

	my $rin = "";
	my $rout;
	vec($rin, fileno(SOCKET), 1) = 1;

	if (select($rout = $rin, undef, undef, 0.1)) {
		my $packet;

		$self->logger()->debug(9,"\tReading from socket ...");

		my $server = recv(SOCKET, $packet, 256, 0);  # 256 is safe amount to read
		# Adding a defined argument here because recv can produce errors if
		# a broadcast isn't responded to. Plus, we want to continue anyway.
		if (defined($server) and $server ne '') {
			my ($serverport,$serverip) = unpack_sockaddr_in($server);
			$serverip = inet_ntoa($serverip);

			$self->logger()->debug(7,"\tJust received a packet from [$serverip:$serverport] ...");

			#Verify that this is a server bc packet
			my ($majorver, $minorver, $type, $padding) = unpack("CCCC", $packet);

			$self->addnewserver($server, $packet) if $type == PROT_BCSERVER;
			$self->logger()->debug(7,"\tUpdating server with profile [$majorver:$minorver:$type]") if $type == PROT_SERVERSTILLALIVE;
			$self->updateserver($server, $packet) if $type == PROT_SERVERSTILLALIVE;
		}
	}

} # end updateserverlist

sub purgeserverlist {

	my $self = shift;

	$self->logger()->debug(9,"Purging server list ...");

	for my $server (keys %Servers) {
		if ($Servers{$server}->{'expires'} <= time()) {
			delete $Servers{$server};
			$self->logger()->debug(7,"\tServer purged. Number of known servers: " . scalar (keys %Servers));

			for my $known (keys %Net::Peep::Servers) {
				my ($serverport,$serverip) = unpack_sockaddr_in($server);
				$serverip = inet_ntoa($serverip);
				$self->logger()->debug(7,"\t\t$serverip:$serverport");
			}
		}
	}

} # end sub purgeserverlist

sub addnewserver {

	my $self = shift;

	my ($server, $packet) = @_;

	my $configuration = $self->getConfiguration();

	my ($serverport,$serverip) = unpack_sockaddr_in($server);

	$serverip = inet_ntoa($serverip);

	# Check if this server already exists - because then we shouldn't be
	# doing an add... so abort. This can happen because when the client
	# registers with the server, the server always sends a BC response
	# directly back to the client to make sure that the client really
	# has the server in its hostlist
	if (exists $Servers{$server}) {
		$self->logger()->debug(7,"\tServer [$serverip:$serverport] won't be added to the server list:  It is already in the list.");
		return;
	}

	my ($majorver, $minorver, $type, $padding, $min, $sec, $id) = unpack("CCCCCCA128", $packet);
	my $delim = PROT_CLASSDELIM;

	#Clean up the ID string
	$id =~ /([A-Za-z0-9!\-]*)/;
	my $realid = $1;

	foreach my $class ($configuration->getClassList()) {
		my $str = quotemeta($class.$delim);
		$self->logger()->debug(7,"\tChecking server id [$realid] against class descriptor [$class$delim] ....");

		if ($realid =~ /$str/) {
			$self->logger()->debug(7,"\tMatch found:  Adding server [$serverip:$serverport] to the server list.");
			$self->addserver($server, $min, $sec);
		} else {
			$self->logger()->debug(7,"\tNo match found.  Nothing added to server list.");
		}
	}

	return 1;

} # end sub addnewserver

sub addserver {

	my $self = shift;
	my ($server,$leasemin,$leasesec) = @_;

	$Servers{$server}->{'IP'} = $server;
	$Servers{$server}->{'expires'} = time() + $leasemin*60 + $leasesec;

	$self->logger()->debug(7,"\tServer added. Number of known servers: " . scalar(keys %Servers));
	for my $known (keys %Net::Peep::Servers) {
		my ($serverport,$serverip) = unpack_sockaddr_in($known);
		$serverip = inet_ntoa($serverip);
		$self->logger()->debug(7,"\t\t$serverip:$serverport");
	}

	#Let's send it a "BC" to tell it to add us as well
	my ($serverport,$serverip) = unpack_sockaddr_in($server);
	$serverip = inet_ntoa($serverip);
	$self->logger()->debug(7,"\tSending client BC packet to [$serverip:$serverport] ...");
	defined(CORE::send(SOCKET, $self->assemble_bc_packet(PROT_BCCLIENT), 0, $server)) or confess "Send clientbc error: $!";
	$self->logger()->debug(7,"\tClient BC packet sent successfully.");

	return 1;

} # end sub addserver

sub updateserver {

	my $self = shift;
	my $server = shift;
	my $packet = shift;
	my ($majorver, $minorver, $type, $padding, $min, $sec) = unpack("CCCCCC", $packet);

	$self->logger()->debug(7,"\tServer updated. Number of known servers: " . scalar(keys %Servers));

	$Servers{$server}->{'expires'} = time() + $min*60 + $sec;

	# New send out a client alive
	my $net_packet = pack ("CCCC",
		PROT_MAJORVER,
		PROT_MINORVER,
		PROT_CLIENTSTILLALIVE, 
		0);

	$self->logger()->debug(7,"\tSending client still alive packet ...");
	defined(CORE::send(SOCKET, $net_packet, 0, $server)) or confess "Send client still alive error: $!"; 
	$self->logger()->debug(7,"\tClient still alive packet sent successfully.");

	return 1;

} # end sub updateserver

1;

__END__

=head1 NAME

Net::Peep::BC - Perl extension for Peep: The Network Auralizer

=head1 SYNOPSIS

  use Net::Peep::BC;
  my $bc = new Net::Peep::BC;

=head1 DESCRIPTION

Net::Peep::BC is a library for Peep: The Network Auralizer.

=head2 EXPORT

None by default.

=head2 CONSTANTS

  PROT_MAJORVER

  PROT_MINORVER

  PROT_BCSERVER

  PROT_BCCLIENT

  PROT_SERVERSTILLALIVE

  PROT_CLIENTSTILLALIVE

  PROT_CLIENTEVENT

  PROT_CLASSDELIM

=head2 CLASS ATTRIBUTES

  %Leases - Deprecated

  %Servers - A hash the keys of which are the servers found by
  autodiscovery methods (i.e., methods in which clients and servers
  notify each other of their existence) and the values of which are
  anonymous hashes containing information about the server, including
  an expiration time after which if the client has not heard from the
  server, the server is deleted from the %Servers hash.

  %Defaults - Default values for options such as 'priority', 'volume',
  'dither', 'sound'.

  $Alarmtime - The amount of time (in seconds) between when the alarm
  handler (see the handlealarm method) is set and the SIGALRM signal
  is sent.

=head2 PUBLIC METHODS

Note that this section is somewhat incomplete.  More
documentation will come soon.

    new($client,$conf,%options) - Net::Peep::BC constructor.  $client
    is the name of the client; e.g., 'logparser' or 'sysmonitor' and
    $conf is a Net::Peep::Conf object.  If an option is not specified
    in the %options argument, the equivalent value in the %Defaults
    class attributes is used.

    assemble_bc_packet() - Assembles the broadcast packet.  Duh.

    logger() - Returns a Net::Peep::Log object used for log messages and
    debugging output.

    send() - Sends a packet including information on sound, location,
    priority, volume etc. to each server specified in the %Servers
    hash.

    sendout() - Used by send() to send the packet.

    handlealarm() - Refreshes and purges the server list.  Schedules
    the next SIGALRM signal to be issued in another $Alarmtime
    seconds.

    updateserverlist() - Polls to see if any of the servers have sent
    alive broadcasts so that the server list can be updated.

    purgeserverlist() - Removes servers from the server list if they
    have not sent an alive broadcast within their given expiration
    time.

    addnewserver($server,$packet) - Adds the server $server based on
    information provided in the packet $packet.  The server is only
    added if it does not exist in the %Servers hash.  The server is
    pysically added by a call to the addserver method.

    addserver($server,$leasemin,$leasesec) - Adds the server $server.
    The server is expired $leasemin minutes and $leasesec seconds
    after being added if it has not sent an alive message in the
    meantime.  Sends the server a client BC packet.

    updateserver($server,$packet) - Updates the expiration time for
    server $server.  Sends the server a client still alive message.

=head2 PRIVATE METHODS

    initialize(%options) - Net::Peep::BC initializer.  Called from the
    constructor.  Performs the following actions:

      o Sets instance attributes via the %options argument
      o Loads configuration information from configuration file
        information passed in through the %options argument
      o Opens a socket and broadcasts an 'alive' message
      o Starts up the alarm.  Every $Alarmtime seconds, the 
        alarm handler updates the server list.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu> Copyright (C) 2000

Collin Starkweather <collin.starkweather@colorado.edu> Copyright (C) 2000

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::Dumb, Net::Peep::Log, Net::Peep::Parser, Net::Peep::Log.

http://peep.sourceforge.net

=head1 TERMS AND CONDITIONS

You should have received a file COPYING containing license terms
along with this program; if not, write to Michael Gilfix
(mgilfix@eecs.tufts.edu) for a copy.

This version of Peep is open source; you can redistribute it and/or
modify it under the terms listed in the file COPYING.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 CHANGE LOG

$Log: BC.pm,v $
Revision 1.10  2001/10/01 05:20:05  starky
Hopefully the final commit before release 0.4.4.  Tied up some minor
issues, did some beautification of the log messages, added some comments,
and made other minor changes.

Revision 1.9  2001/09/23 08:53:49  starky
The initial checkin of the 0.4.4 release candidate 1 clients.  The release
includes (but is not limited to):
o A new client:  pinger
o A greatly expanded sysmonitor client
o An API for creating custom clients
o Extensive documentation on creating custom clients
o Improved configuration file format
o E-mail notifications
Contact Collin at collin.starkweather@colorado with any questions.

Revision 1.8  2001/08/08 20:17:57  starky
Check in of code for the 0.4.3 client release.  Includes modifications
to allow for backwards-compatibility to Perl 5.00503 and a critical
bug fix to the 0.4.2 version of Net::Peep::Conf.

Revision 1.7  2001/07/23 17:46:29  starky
Added versioning to the configuration file as well as the ability to
specify groups in addition to / as a replacement for event letters.
Also changed the Net::Peep::Parse namespace to Net::Peep::Parser.
(I don't know why I ever named an object by a verb!)

Revision 1.6  2001/07/16 22:24:47  starky
Fix for bug #439881:  Volumes of 0 are now correctly identified.

Revision 1.5  2001/06/05 20:01:20  starky
Corrected bug in which wrong type of broadcast constant was being
sent by the client; i.e., the PROT_BCCLIENT was being sent when
the PROT_CLIENTSTILLALIVE should have been.  The clients and
servers worked as expected despite the bug, so no changes in
functionality will be apparent from the bug fix.  It is, however,
the right way to do things :-)

Revision 1.4  2001/06/04 08:37:27  starky
Prep work for the 0.4.2 release.  The wake-up for autodiscovery packets
to be sent is now scheduled through Net::Peep::Scheduler.  Also modified
some docs in Net::Peep slightly.

Revision 1.3  2001/05/07 02:39:19  starky
A variety of bug fixes and enhancements:
o Fixed bug 421729:  Now the --output flag should work as expected and the
--logfile flag should not produce any unexpected behavior.
o Documentation has been updated and improved, though more improvements
and additions are pending.
o Removed print STDERRs I'd accidentally left in the last commit.
o Other miscellaneous and sundry bug fixes in anticipation of a 0.4.2
release.

Revision 1.2  2001/05/06 08:03:01  starky
Bug 421791:  Clients and servers tend to forget about each other in
autodiscovery mode after a few hours.  The client now sends out a
"hello" packet each time it goes through a server update/purge cycle.

Revision 1.1  2001/04/23 10:13:19  starky
Commit in preparation for release 0.4.1.

o Altered package namespace of Peep clients to Net::Peep
  at the suggestion of a CPAN administrator.
o Changed Peep::Client::Log to Net::Peep::Client::Logparser
  and Peep::Client::System to Net::Peep::Client::Sysmonitor
  for clarity.
o Made adjustments to documentation.
o Fixed miscellaneous bugs.

Revision 1.10  2001/04/18 05:27:04  starky
Fixed bug #416872:   An extra "!" is tacked onto the
identifier list before the client sends out its class
identifier string.

Revision 1.9  2001/04/17 06:46:21  starky
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

Revision 1.8  2001/04/04 05:37:11  starky
Added some debugging and made other transparent changes.

Revision 1.7  2001/03/31 07:51:34  mgilfix


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

Revision 1.6  2001/03/30 18:34:12  starky
Adjusted documentation and made some modifications to Peep::BC to
handle autodiscovery differently.  This is the last commit before the
0.4.0 release.

Revision 1.5  2001/03/28 02:41:48  starky
Created a new client called 'pinger' which pings a set of hosts to check
whether they are alive.  Made some adjustments to the client modules to
accomodate the new client.

Also fixed some trivial pre-0.4.0-launch bugs.

Revision 1.4  2001/03/27 00:44:19  starky
Completed work on rearchitecting the Peep client API, modified client code
to be consistent with the new API, and added and tested the sysmonitor
client, which replaces the uptime client.

This is the last major commit prior to launching the new client code,
though the API or architecture may undergo some initial changes following
launch in response to comments or suggestions from the user and developer
base.

Revision 1.3  2001/03/19 07:47:37  starky
Fixed bugs in autodiscovery/noautodiscovery.  Now both are supported by
Peep::BC and both look relatively bug free.  Wahoo!

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
