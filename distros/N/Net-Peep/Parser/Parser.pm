package Net::Peep::Parser;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Data::Dumper;
use Net::Peep::Log;
use Net::Peep::Conf;
use Net::Peep::Notifier;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

} # end sub new

# On spawning a new configuration file parser, we expect to get
# a reference to a hash that contains:
#   'config' => Which is a pointer to the configuration file
#   'app'    => The application for which to get the configuration
sub load {
	my $self = shift;
	my $conf = shift || confess "Cannot parse configuration file:  No configuration object found.";
	$self->conf($conf);
	confess "Peep couldn't find the configuration file [", $conf->getOption('config'), "]: $!" 
		unless -e $conf->getOption('config');
	$self->parseConfig();

} # end sub load

sub conf {

    my $self = shift;
    if (@_) { $self->{'CONF'} = shift; }
    return $self->{'CONF'};

} # end sub conf

sub parseConfig {

	my $self = shift;
	my $conf = $self->conf()->getOption('config');

	open FILE, "<$conf" || confess "Could not open [$conf]:  $!";
	while (my $line = <FILE>) {
		my $msg = $line;
		chomp $msg;
		$msg = substr $msg, 0, 40;
		$self->logger()->debug(9,"Parsing [$conf] line [$msg ...]");
		next if $line =~ /^\s*#/;
		# version 0.4.3 had a standalone version tag
		$self->parseVersion(\*FILE, $1)      if $line =~ /^\s*version (.*)/;
		$self->parseGeneral(\*FILE, $1)      if $line =~ /^\s*general/;
		$self->parseNotification(\*FILE, $1) if $line =~ /^\s*notification/;
		$self->parseClass(\*FILE, $1)        if $line =~ /^\s*class (.*)/;
		$self->parseClient(\*FILE, $1)       if $line =~ /^\s*client (.*)/;
		$self->parseEvents(\*FILE, $1)       if $line =~ /^\s*events/;
		$self->parseStates(\*FILE, $1)       if $line =~ /^\s*states/;
#		$self->parseHosts(\*FILE, $1)        if $line =~ /^\s*hosts/;
	}
	close FILE;

} # end sub parseConfig

sub parseGeneral {

	my $self = shift;
	my $file = shift || confess "file not found";

	$self->logger()->debug(1,"Parsing general configuration information ...");

	while (my $line = <$file>) {
		next if $line =~ /^\s*#/;
		if ($line =~ /^\s*end/) {
			return;
		} else {
			$line =~ /^\s*([\w-]+)\s+(.*)$/;
			my ($key, $value) = ($1,$2);
			# Remove any leading or trailing whitespace
			for ($key,$value) { s/^\s+//g; s/\s+$//g; }
			if ($key eq 'version') {
				$self->conf()->setVersion($value);
			} elsif ($key eq 'sound-path') {
				$self->conf()->setSoundPath($value);
			} else {
				$self->logger()->log("Configuration option [$key] not recognized.");
			}
		}

	}

} # end sub parseGeneral

sub parseNotification {

	my $self = shift;
	my $file = shift || confess "file not found";

	$self->logger()->debug(1,"Parsing notification configuration information ...");

	while (my $line = <$file>) {
		next if $line =~ /^\s*#/;
		if ($line =~ /^\s*end/) {
			return;
		} else {
			$line =~ /^\s*([\w-]+)\s+(.*)$/;
			my ($key, $value) = ($1,$2);
			# Remove any leading or trailing whitespace
			for ($key,$value) { s/^\s+//; s/\s+$//; }
			if ($key eq 'smtp-relays') {
				my (@relays) = split /[\s,]+/, $value;
				$self->logger()->debug(1,"\tFound SMTP relays [@relays]");
				@Net::Peep::Notifier::SMTP_RELAYS = @relays;
			} elsif ($key eq 'notification-interval') {
				confess "The notification interval must be an integer value!"
				    unless $value =~ /^\d+$/;
				$self->logger()->debug(1,"\tFound notification interval [$value]");
				$Net::Peep::Notifier::NOTIFICATION_INTERVAL = $value;
			} else {
				$self->logger()->log("\tNotification option [$key] not recognized.");
			}
		}

	}

	$self->logger()->debug(1,"\tNotification configuration information parsed.");

} # end sub parseNotification

sub parseVersion {

	my $self = shift;

	my $file      = shift || confess "file not found";
	my $version = shift || confess "version not found";

	$self->logger()->debug(1,"Parsing version [$version] ...");

	$self->conf()->setVersion($version);

	$self->logger()->debug(1,"\tVersion parsed.");

} # end sub parseVersion

sub parseClass {
	my $self = shift;
	my $file      = shift || confess "file not found";
	my $classname = shift || confess "classname not found";
	my (@broadcast, @servers, $newbroadcast);
	my %servports;

	$self->logger()->debug(1,"Parsing class [$classname] ...");

	while (my $line = <$file>) {
		if ($line =~ /^\s*end/) {
			#Then check if we should make an entry
			if (@broadcast && @servers) {
				$self->conf()->addClass($classname,\@servers);

				#We need the same broadcast zones as the servers but
				#We need the different server ports.
				foreach my $server (@servers) {
					my ($name, $port) = split /:/, $server;
					$self->conf()->addServer($classname,{ name => $name, port => $port });
					$self->logger()->debug(1,"\tServer [$name:$port] added.");
					$servports{$port} = 1; #define the key
				}
				foreach my $zone (@broadcast) {
					my ($ip, $port) = split /:/, $zone;
					$self->logger()->debug(1,"\tBroadcast [$ip:$port] added.");
					$self->conf()->addBroadcast($classname,{ ip => $ip, port => $port });
				}
			}
			$self->logger()->debug(1,"\tClass [$classname] parsed.");
			return;
		} else {

			push (@broadcast, split(/\s+/, $1) ) if $line =~ /^\s*broadcast (.*)/;
			push (@servers, split (/\s+/, $1) ) if $line =~ /^\s*server (.*)/;

		}


	}

} # end sub parseClass

sub parseClient {

	my $self = shift;

	my $file   = shift || confess "Cannot parse client:  File not found";
	my $client = shift || confess "Cannot parse client:  Client not found";
	my %classes;

	$self->logger()->debug(1,"Parsing client [$client] ...");

	# Let's figure out which classes we're part of and grab the
	# program's configuration
	while (my $line = <$file>) {

		$self->logger()->debug(1,"\tClient [$client] parsed.") and return if $line =~ /^\s*end client $client/;
		next if $line =~ /^\s*#/ or $line =~ /^\s*$/;

		if ($line =~ /^\s*class(.*)/) {
			my $class = $1;
			$class =~ s/\s+//g;
			my @classes = split /\s+/, $class;
			foreach my $one (@classes) {
				$classes{$one} = $self->conf()->getClass($one);
			}
		}

		if ($line =~ /^\s*port (\d+)/) {
			my $port = $1;
			$port =~ s/\s+//g;
			$self->conf()->setClientPort($client,$port);
			$self->logger()->debug(1,"\tPort [$port] set for client [$client].");
		}

		if ($line =~ /^\s*default/) {
			my @default;

			while (my $line = <$file>) {
				last if $line =~ /^\s*end default/;
				push @default, $line;
			}

			$self->parseClientDefault($client,@default);
		}

		# Note that config specifically looks for "end config" because
		# it may contain several starts and ends
		if ($line =~ /^\s*config/) {
			my @config;

			while (my $line = <$file>) {
				last if $line =~ /^\s*end config/;
				push @config, $line;
			}

			$self->parseClientConfig($client,@config);
			# I believe the parseClientEvents makes this redundant
			$self->conf()->setConfigurationText($client,join '', @config);
		}

		# Note that notification specifically looks for "end
		# notification" because it may contain several starts
		# and ends
		if ($line =~ /^\s*notification/) {
			my @notification;

			while (my $line = <$file>) {
				last if $line =~ /^\s*end notification/;
				push @notification, $line;
			}

			$self->parseClientNotification($client,@notification);
			# I believe the parseClientEvents makes this redundant
			$self->conf()->setNotificationText($client,join '', @notification);
		}

	}

	# Now let's swap in the valid classes
	for my $class (keys %classes) { $self->conf()->addClientClass($client,$class); }

} # end sub parseClient

sub parseEvents {

	my $self = shift;
	my $file = shift || confess "Cannot parse events:  File not found.";

	$self->logger()->debug(1,"Parsing events ...");

	my $i = 0;
	# Skip right to the end
	while (my $line = <$file>) {
		last if $line =~ /^\s*end/;
		next if $line =~ /^\s*#/;
		my ($eventname, $file, $nsounds) = split /\s+/, $line;

		$self->conf()->addEvent($eventname,{
			file => $file,
			sounds => $nsounds,
			index => $i++
		});

		$self->logger()->debug(1,"\tEvent [$eventname] added.");
	}

} # end sub parseEvents

sub parseClientConfig {

	my $self = shift;
	my $who = shift || confess "Cannot parse client configuration:  Client not identified.";
	my @text = @_;

	my $client = $self->conf()->client();
	my $name = $client->name();
	
	if ($who eq $name) {

	    $self->logger()->debug(1,"\tParsing configuration text for client [$name] ...");
	    $client->runParser(@text);
	    $self->logger()->debug(1,"\tDone parsing configuration for client [$name].");

	} 

#	while (my $line = shift @text) {
#		next if $line =~ /^\s*#/;
#		next if $line =~ /^\s*$/;
#		if ($line =~ /^\s*default/) {
#			@text = $self->parseClientDefault($client,@text);
#		} elsif ($line =~ /^\s*events/) {
#			@text = $self->parseClientEvents($client,@text);
#		} elsif ($line =~ /^\s*hosts/) {
#			@text = $self->parseClientHosts($client,@text);
#		} elsif ($line =~ /^\s*uptime/) {
#			@text = $self->parseClientUptime($client,@text);
#		} elsif ($line =~ /^\s*procs/) {
#			@text = $self->parseClientProcs($client,@text);
#		} elsif ($line =~ /^\s*disk/) {
#			@text = $self->parseClientDisk($client,@text);
#		} else {
#			$line =~ /^\s*(\w+)\s+(\S+)/;
#			$self->logger()->debug(1,"\t\tClient option [$1] has been set to value [$2].");
#			$self->conf()->setOption($client,$1,$2);
#		}
#	}

} # end sub parseClientConfig

sub parseClientNotification {

	my $self = shift;
	my $client = shift || confess "Cannot parse client notification:  Client not identified.";
	my @text = @_;

	$self->logger()->debug(1,"\tParsing notification for client [$client] ...");

	while (my $line = shift @text) {
		next if $line =~ /^\s*#/;
		next if $line =~ /^\s*$/;

		if ($line =~ /^\s*(notification-hosts)\s+(.*)$/) {
			my ($key,$value) = ($1,$2);
			for ($key,$value) { s/^\s+//g; s/\s+$//g; }
			my (@hosts) = split /[\s,]+/, $value;
			$self->logger()->debug(1,"\t\tFound notification hosts [@hosts].");
			$Net::Peep::Notifier::NOTIFICATION_HOSTS{$client} = [ @hosts ];
		} elsif ($line =~ /^\s*(notification-recipients)\s+(.*)$/) {
			my ($key,$value) = ($1,$2);
			for ($key,$value) { s/^\s+//g; s/\s+$//g; }
			my (@recipients) = split /[\s,]+/, $value;
			$self->logger()->debug(1,"\t\tFound notification recipients [@recipients].");
			$Net::Peep::Notifier::NOTIFICATION_RECIPIENTS{$client} = [ @recipients ];
		} elsif ($line =~ /^\s*(notification-level)\s+(\S+)/) {
			my ($key,$value) = ($1,$2);
			for ($key,$value) { s/^\s+//g; s/\s+$//g; }
			$self->logger()->debug(1,"\t\tFound notification level [$value].");
			$Net::Peep::Notifier::NOTIFICATION_LEVEL{$client} = $value;
		} else {
			$line =~ /^\s*(\w+)\s+(\S+)/;
			$self->logger()->debug(1,"\t\tClient notification option [$1] not recognized.");
		}
	}

} # end sub parseClientNotification

# this method was deprecated with the move of client config parsing
# into the client objects

#sub parseClientEvents {
#
#	my $self = shift;
#	my $client = shift || confess "Cannot parse client events:  Client not identified.";
#	my @text = @_;
#
#	$self->logger()->debug(1,"\t\tParsing events for client [$client] ...");
#
#	my @version = $self->conf()->versionExists() 
#		? split /\./, $self->conf()->getVersion()
#			: ();
#
#	if (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {
#
#		while (my $line = shift @text) {
#			next if $line =~ /^\s*#/;
#			last if $line =~ /^\s*end/;
#
#			my $name;
#			$line =~ /^\s*([\w-]+)\s+([\w-]+)\s+([a-zA-Z])\s+(\d+)\s+(\d+)\s+(\w+)\s+"(.*)"/;
#
#			my $clientEvent = {
#				'name' => $1,
#				'group' => $2,
#				'option-letter' => $3,
#				'location' => $4,
#				'priority' => $5,
#				'status' => $6,
#				'regex' => $7
#			};
#
#			$self->conf()->addClientEvent($client,$clientEvent);
#			$self->logger()->debug(1,"\t\t\tClient event [$1] added.");
#
#		}
#
#	} elsif (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 1) {
#
#		while (my $line = shift @text) {
#			next if $line =~ /^\s*#/;
#			last if $line =~ /^\s*end/;
#
#			my $name;
#			$line =~ /^\s*([\w-]+)\s+([\w-]+)\s+([a-zA-Z])\s+(\d+)\s+(\d+)\s+"(.*)"/;
#
#			my $clientEvent = {
#				'name' => $1,
#				'group' => $2,
#				'option-letter' => $3,
#				'location' => $4,
#				'priority' => $5,
#				'regex' => $6
#			};
#
#			$self->conf()->addClientEvent($client,$clientEvent);
#			$self->logger()->debug(1,"\t\t\tClient event [$1] added.");
#
#		}
#
#	} else {
#
#		while (my $line = shift @text) {
#			next if $line =~ /^\s*#/;
#			last if $line =~ /^\s*end/;
#
#			my $name;
#			$line =~ /([\w-]+)\s+([a-zA-Z])\s+(\d+)\s+(\d+)\s+"(.*)"/;
#
#			my $clientEvent = {
#				'name' => $1,
#				'option-letter' => $2,
#				'location' => $3,
#				'priority' => $4,
#				'regex' => $5
#			};
#
#			$self->conf()->addClientEvent($client,$clientEvent);
#			$self->logger()->debug(1,"\t\t\tClient event [$1] added.");
#
#		}
#
#	}
#
#	return @text;
#
#} # end sub parseClientEvents

# this method was deprecated with the move of client config parsing
# into the client objects

#sub parseClientHosts {
#
#	my $self = shift;
#	my $client = shift || confess "Cannot parse client hosts:  Client not identified.";
#	my @text = @_;
#
#	$self->logger()->debug(1,"\t\tParsing hosts for client [$client] ...");
#
#	while (my $line = shift @text) {
#		next if $line =~ /^\s*$/;
#		next if $line =~ /^\s*#/;
#		last if $line =~ /^\s*end/;
#
#		$line =~ /^\s*([\w\-\.]+)\s+([\w\-]+)\s+([\w\-]+)\s+([a-zA-Z])\s+(\d+)\s+(\d+)\s+(\w+)/;
#
#		my ($host,$name,$group,$letter,$location,$priority,$status) = 
#		    ($1,$2,$3,$4,$5,$6,$7);
#
#		my $clientHost = {
#		    host => $host,
#		    name => $name,
#		    group => $group,
#		    'option-letter' => $letter,
#		    location => $location,
#		    priority => $priority,
#		    status => $status
#		    };
#
#		$self->logger()->debug(1,"\t\t\tClient host [$host] added.") if
#		    $self->conf()->addClientHost($client,$clientHost);
#
#	}
#
#	return @text;
#
#} # end sub parseClientHosts

sub parseClientDefault {

    my $self = shift;
    my $client = shift || confess "Cannot parse client defaults:  Client not identified.";
    my @text = @_;

    $self->logger()->debug(1,"\tParsing defaults for client [$client] ...");

    my $conf = $self->conf() || confess "Defaults cannot be parsed:  No configuration object found.";

    while (my $line = shift @text) {
	next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
	if ($line =~ /^\s*([\w\-]+)\s+(\S+)/) {
	    my ($option,$value) = ($1,$2);
	    if ($conf->optionExists($option)) {
		$self->logger()->debug(6,"Not setting option [$option]:  It has already been set (possibly from the command-line).");
	    } else {
		$self->logger()->debug(6,"Setting option [$option] to value [$value].");
		$conf->setOption($option,$value) unless $conf->optionExists($option);
	    }
	}
    }

    $self->logger()->debug(1,"\t\tDone.");

    return @text;

} # end sub parseClientDefault

sub parseStates {

	my $self = shift;

	my $file = shift || confess "Cannot parse states:  File not found.";

	$self->logger()->debug(1,"Parsing states ...");

	my $i = 0;
	# Skip right to the end 
	while (my $line = <$file>) {
		last if $line =~ /^\s*end/;
		next if $line =~ /^\s*#/;
		my ($statename, $file, $sounds, $fade) = split /\s+/, $line;

		$self->conf()->addState($statename,{
			file => $file,
			sounds => $sounds,
			fade => $fade,
			index => $i++
		});

		$self->logger()->debug(1,"\tState [$statename] added.");
	}

} # end sub parseStates

# returns a logging object
sub logger {
	my $self = shift;
	if ( ! exists $self->{'__LOGGER'} ) { $self->{'__LOGGER'} = new Net::Peep::Log }
	return $self->{'__LOGGER'};
} # end sub logger

1;

__END__

=head1 NAME

Net::Peep::Parser - Perl extension for parsing configuration files for
Peep: The Network Auralizer.

=head1 SYNOPSIS

  use Net::Peep::Parser;
  my $parser = new Net::Peep::Parser;

  # load returns a Net::Peep::Conf object.  %options conform to
  # the specifications given in Getopt::Long

  my $conf = $parser->load(%options);

  # all of the configuration information in /etc/peep.conf
  # is now available through the observer methods in the
  # Net::Peep::Conf object

=head1 DESCRIPTION

Net::Peep::Parser parses a Peep configuration file and returns a
Net::Peep::Conf object whose accessors contain all the information
found in the configuration file.

=head2 EXPORT

None by default.

=head2 METHODS

  load(%options) - loads configuration information found in the file
  $options{'config'} .  Returns a Net::Peep::Conf object.

  parseConfig($config) - parses the configuration file $config.

  parseClass($filehandle,$classname) - parses the class definition
  section of a configuration file.

  parseClient($filehandle,$client) - parses the client definition
  section of a configuration file.

  parseEvents($filehandle) - parses the event definition section of a
  configuration file.

  parseState($filehandle) - parses the state definition section of a
  configuration file.

  parseClientEvents($filehandle) - parses the client event definition
  section of a configuration file.

  parseClientDefault($filehandle) - parses the client defaults section
  of a configuration file.

  logger() - returns a Net::Peep::Log object for logging and
  debugging.

  conf() - gets/sets a Net::Peep::Conf object for storing and
  retrieving configuration information.

=head1 AUTHOR

Collin Starkweather <collin.starkweather@colorado.edu> Copyright (C) 2001

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::BC, Net::Peep::Log, Net::Peep::Conf.

http://peep.sourceforge.net

=head1 CHANGE LOG

$Log: Parser.pm,v $
Revision 1.6  2001/10/01 05:20:05  starky
Hopefully the final commit before release 0.4.4.  Tied up some minor
issues, did some beautification of the log messages, added some comments,
and made other minor changes.

Revision 1.5  2001/09/23 08:53:57  starky
The initial checkin of the 0.4.4 release candidate 1 clients.  The release
includes (but is not limited to):
o A new client:  pinger
o A greatly expanded sysmonitor client
o An API for creating custom clients
o Extensive documentation on creating custom clients
o Improved configuration file format
o E-mail notifications
Contact Collin at collin.starkweather@colorado with any questions.

Revision 1.4  2001/08/08 20:17:57  starky
Check in of code for the 0.4.3 client release.  Includes modifications
to allow for backwards-compatibility to Perl 5.00503 and a critical
bug fix to the 0.4.2 version of Net::Peep::Conf.

Revision 1.3  2001/08/06 04:20:36  starky
Fixed bug #447844.

Revision 1.2  2001/07/23 17:46:29  starky
Added versioning to the configuration file as well as the ability to
specify groups in addition to / as a replacement for event letters.
Also changed the Net::Peep::Parse namespace to Net::Peep::Parser.
(I don't know why I ever named an object by a verb!)

Revision 1.1  2001/07/23 16:18:35  starky
Changed the namespace of Net::Peep::Parse to Net::Peep::Parser.  (Why did
I ever create an object whose namespace was a verb anyway?!?)  This file
was consequently moved from peep/client/Net/Peep/Parse to its current
location.


=cut

