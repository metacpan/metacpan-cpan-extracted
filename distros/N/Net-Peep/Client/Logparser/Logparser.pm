package Net::Peep::Client::Logparser;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Data::Dumper;
use File::Tail;
use Sys::Hostname;
use Net::Peep::Client;
use Net::Peep::Client::Logparser::Event;
use Net::Peep::BC;
use Net::Peep::Notifier;
use Net::Peep::Notification;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter Net::Peep::Client);
%EXPORT_TAGS = ( 'all' => [ qw( INTERVAL MAX_INTERVAL ADJUST_AFTER ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.11 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# These are in seconds and are the parameters for File::Tail

# File Tail uses the idea of intervals and predictions to try to keep
# blocking time at a maximum. These three parameters are the ones that
# people will want to tune for performance vs. load. The smaller the
# interval, the higher the load but faster events are picked up.

# The interval that File::Tail waits before checking the log
use constant INTERVAL => 0.1;
# The maximum interval that File::Tail will wait before checking the
# log
use constant MAX_INTERVAL => 1;
# The time after which File::Tail adjusts its predictions
use constant ADJUST_AFTER => 2;

use constant DEFAULT_PID_FILE => "/var/run/logparser.pid";

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = $class->SUPER::new();
	bless $this, $class;
	$this->{'EVENTS'} = [];
	$this->name('logparser');
	$this;

} # end sub new

sub getLogFiles {

	my $self = shift;
	my $conf = $self->conf();
	my $logfiles = $conf->optionExists('logfile') ? $conf->getOption('logfile') : '';
	my @logfiles = split ',\s*', $logfiles;
	return wantarray ? @logfiles : [@logfiles];

} # sub getLogFiles

sub getLogFileTails {

	my $self = shift;
	if ( ! exists $self->{"__LOGFILETAILS"} ) {

	my @logfiles = $self->getLogFiles();
	my @tailfiles;
	for my $logfile (@logfiles) {
		if (-e $logfile) {
			my $tail;
			eval { $tail =
				File::Tail->new(
						name => $logfile,
						interval => INTERVAL,
						maxinterval => MAX_INTERVAL,
						adjustafter => ADJUST_AFTER
						);
			};
			if ($@) {
				chomp $@;
				$self->logger()->log("Warning:  Error creating tail of logfile '$logfile':  $@");
			} else {
				push @tailfiles, $tail;
			}
		} else {
			$self->logger()->log("Warning:  Can't tail the log file '$logfile':  It doesn't exist.");
		}
	}

	$self->{"__LOGFILETAILS"} = \@tailfiles;

	}

	return wantarray ? @{$self->{"__LOGFILETAILS"}} : $self->{"__LOGFILETAILS"};

} # sub getLogFileTails

sub Start {

	my $self = shift;

	my $events = '';
	my $logfile = '';
	my $pidfile = DEFAULT_PID_FILE;
	my @groups = ();
	my @exclude = ();

	my %options = ( 
		'events=s' => \$events, 
		'logfile=s' => \$logfile, 
		'pidfile=s' => \$pidfile,
		'groups=s' => \@groups,
		'exclude=s' => \@exclude );

	$self->initialize(%options) || $self->pods();

	# register a parser for the logparser section of the configuration file

	$self->logger()->debug(9,"Registering parser ...");
	$self->parser(sub { my @text = @_; $self->parse(@text); });
	$self->logger()->debug(9,"\tParser registered ...");

	# have the client parse the configuration file and 
	# get the configuration object which should be populated with the
	# standard command-line options and configuration information
	my $conf = $self->configure();

	unless ($conf->getOption('autodiscovery')) {
		$self->pods("Error:  Without autodiscovery you must provide a server and port option.")
			unless $conf->optionExists('server') && $conf->optionExists('port') &&
			       $conf->getOption('server') && $conf->getOption('port');
	}

	my @gotgroups = $self->getGroups();
	my @gotexclude = $self->getExcluded();
	$self->logger()->debug(1,"Recognized event groups are [@gotgroups]");
	$self->logger()->debug(1,"Excluded event groups are [@gotexclude]");

	# Check whether the pidfile option was set. If not, use the default
	unless ($conf->optionExists('pidfile')) {
		$self->logger()->debug(3,"No pid file specified. Using default [" . DEFAULT_PID_FILE . "]");
		$conf->setOption('pidfile', DEFAULT_PID_FILE);
	}

	$self->logger()->log("Scanning logs:");

	for my $logfile ($self->getLogFiles()) {
		$self->logger()->log("\t$logfile");
	}

	# Register a callback for the main loop
	$self->logger()->debug(9,"Registering callback ...");
	$self->callback(sub { $self->loop(); });
	$self->logger()->debug(9,"\tCallback registered ...");

	$self->MainLoop();

	return 1;

} # end sub Start

sub loop {

	my $self = shift;

	select(STDOUT);

	$| = 1; # autoflush

	my $nfound;

	my @logFileTails = $self->getLogFileTails();

	# call the peck method which, the first time it is called, will
	# instantiate a Net::Peep::BC object as necessary

	$self->peck();

	while (1) {

		$nfound = File::Tail::select(undef,undef,undef,60,@logFileTails);
		# hmmm ... don't quite understand what interval does ... [collin]
		unless ($nfound) {
			for my $filetail (@logFileTails) {
				$filetail->interval;
			}
		}

		for my $filetail (@logFileTails) {
			$self->tail($filetail->read) unless $filetail->predict;
		}
	}

	return 1;

} # end sub loop

sub peck {

	my $self = shift;

	my $configuration = $self->conf();

	unless (exists $self->{"__PEEP"}) {
		if ($configuration->getOptions()) {
			$self->{"__PEEP"} = Net::Peep::BC->new( $self->name(), $configuration );
		} else {
			confess "Error:  Expecting options to have been parsed by now.";
		}
	}

	return $self->{"__PEEP"};

} # end sub peck

sub tail {

    my $self = shift;
    my $line = shift;
    
    chomp $line;
    
    $self->logger()->debug(9,"Checking [$line] ...");
    
    my $conf = $self->conf();
    
    my $found = 0;
    
    # filter the events based on which groups or option letters
    # are specified
    my @events = grep $self->filter($_), $self->events();
    
    for my $event (@events) {
	
	# if we've already matched an event ignore the remaining events
	
	unless ($found) {
	    
	    my $name = $event->name();
	    my $location = $event->location();
	    my $priority = $event->priority();
	    my $status = $event->notification();
	    my $regex = $event->regex();
	    
	    $self->logger()->debug(9,"\tTrying to match regex [$regex] for event [$name]");
	    
	    if ($line =~ /$regex/) {
		
		$self->logger()->debug(5,"$name:  $line");
		
		$self->peck()->send(
				    'logparser',
				    'type'       => 0,
				    'sound'      => $name,
				    'location'   => $location,
				    'priority'   => $priority,
				    'volume'     => 255
				    );
		
		my $notifier = new Net::Peep::Notifier;
		my $notification = new Net::Peep::Notification;
		
		$notification->client($self->name());
		$notification->hostname($Net::Peep::Notifier::HOSTNAME);
		$notification->status($status);
		$notification->datetime(time());
		$notification->message("${Net::Peep::Notifier::HOSTNAME}:  $name:  $line");
		
		$notifier->notify($notification);
		
		$found++;
		
	    }
	}
    }
    
    return 1;

} # end sub tail

sub parse {

    my $self = shift;
    my $client = $self->name() || confess "Cannot parse logparser events:  Client name attribute not set.";
    my @text = @_;

    my $conf = $self->conf() || confess "Cannot parse logparser events:  Configuration object not found.";

    $self->logger()->debug(1,"\t\tParsing events for client [$client] ...");

    $self->tempParseDefaults(@text);

    my @events = $self->getConfigSection('events',@text);

    my @version = $self->conf()->versionExists() 
	? split /\./, $self->conf()->getVersion()
	    : ();

    if (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {

	while (my $line = shift @events) {
	    next if $line =~ /^\s*#/ || $line =~ /^\s*$/;

	    my $name;
	    if ($line =~ /^\s*([\w-]+)\s+([\w-]+)\s+(\d+)\s+(\d+)\s+(\w+)\s+"(.*)"\s+([\w\-\.]+)/) {

		my $event = new Net::Peep::Client::Logparser::Event;
		$event->name($1);
		$event->group($2);
		$event->location($3);
		$event->priority($4);
		$event->notification($5);
		$event->regex($6);
		$event->hosts($7);
	    
		$self->addEvent($event);
		$self->logger()->debug(1,"\t\t\tClient event [$1] added.");

	    }

	}

    } elsif (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 1) {

	while (my $line = shift @events) {
	    next if $line =~ /^\s*#/ || $line =~ /^\s*$/;

	    my $name;
	    if ($line =~ /^\s*([\w-]+)\s+([\w-]+)\s+([a-zA-Z])\s+(\d+)\s+(\d+)\s+"(.*)"/) {

		my $event = new Net::Peep::Client::Logparser::Event;
		$event->name($1);
		$event->group($2);
		$event->letter($3);
		$event->location($4);
		$event->priority($5);
		$event->regex($7);
	    
		$self->addEvent($event);
		$self->logger()->debug(1,"\t\t\tClient event [$1] added.");

	    }

	}

    } else {

	while (my $line = shift @events) {
	    next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
	    
	    my $name;
	    if ($line =~ /([\w-]+)\s+([a-zA-Z])\s+(\d+)\s+(\d+)\s+"(.*)"/) {

		my $event = new Net::Peep::Client::Logparser::Event;
		$event->name($1);
		$event->letter($3);
		$event->location($4);
		$event->priority($5);
		$event->regex($7);
	    
		$self->addEvent($event);
		$self->logger()->debug(1,"\t\t\tClient event [$1] added.");

	    }

	}

    }

    return @text;

} # end sub parse

sub addEvent {

    my $self = shift;
    my $event = shift || confess "Cannot add logparser event:  No event was provided.";
    push @{$self->{'EVENTS'}}, $event;
    return 1;

} # end sub addEvent

sub events {

    # return an array of events identified by calls to the event
    # method

    my $self = shift;
    return wantarray ? @{$self->{'EVENTS'}} : $self->{'EVENTS'};

} # events

1;

__END__

=head1 NAME

Net::Peep::Client::Logparser - Perl extension for the logparser, the event
generator for Peep.

=head1 SYNOPSIS

  require 5.005_62;
  use Net::Peep::Client::Logparser;
  $logparser = new Net::Peep::Client::Logparser;
  $SIG{'INT'} = $SIG{'TERM'} = sub { $logparser->shutdown(); exit 0; };
  $logparser->Start();

=head1 DESCRIPTION

Provides support methods and utilities for logparser, the event
generator for Peep.  Inherits Net::Peep::Client.

=head2 EXPORT

None by default.

=head1 METHODS

Note that this section is somewhat incomplete.  More
documentation will come later.

    new() - The constructor

    Start() - Begins tailing log files and signaling events.
    Terminates by entering the Net::Peep::Client->MainLoop() method.

    loop() - The callback called by the Net::Peep::Client->MainLoop()
    method.  See Net::Peep::Client for more information.

    parse(@text) - Callback given to the Net::Peep::Client->parser() method
    which parses the logparser client config section of the Peep
    configuration file.

    addEvent($event) - Adds a Net::Peep::Client::Logparser::Event
    object to an array.

    events() - Retrieves an array of
    Net::Peep::Client::Logparser::Event objects added by the addEvent method.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu> Copyright (C) 2001

Collin Starkweather <collin.starkweather@colorado.edu>

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::BC, Net::Peep::Log, Net::Peep::Parser,
Net::Peep::Client, logparser.

http://peep.sourceforge.net

=head1 CHANGE LOG

$Log: Logparser.pm,v $
Revision 1.11  2001/10/02 19:09:44  starky
Removed superfluous event() and events() method.

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

Revision 1.7  2001/07/23 20:17:44  starky
Fixed a minor bug in setting groups and exclude flags from the command-line
with the logparser.

Revision 1.6  2001/07/23 17:46:29  starky
Added versioning to the configuration file as well as the ability to
specify groups in addition to / as a replacement for event letters.
Also changed the Net::Peep::Parse namespace to Net::Peep::Parser.
(I don't know why I ever named an object by a verb!)

Revision 1.5  2001/06/04 08:37:27  starky
Prep work for the 0.4.2 release.  The wake-up for autodiscovery packets
to be sent is now scheduled through Net::Peep::Scheduler.  Also modified
some docs in Net::Peep slightly.

Revision 1.4  2001/05/07 02:39:19  starky
A variety of bug fixes and enhancements:
o Fixed bug 421729:  Now the --output flag should work as expected and the
--logfile flag should not produce any unexpected behavior.
o Documentation has been updated and improved, though more improvements
and additions are pending.
o Removed print STDERRs I'd accidentally left in the last commit.
o Other miscellaneous and sundry bug fixes in anticipation of a 0.4.2
release.

Revision 1.3  2001/05/06 21:33:17  starky
Bug 421248:  The --help flag should now work as expected.

Revision 1.2  2001/05/05 19:25:53  starky
Bug 421699:  Logparser now stops searching the regex list after the
first match is found.

Revision 1.1  2001/04/23 10:13:19  starky
Commit in preparation for release 0.4.1.

o Altered package namespace of Peep clients to Net::Peep
  at the suggestion of a CPAN administrator.
o Changed Peep::Client::Log to Net::Peep::Client::Logparser
  and Peep::Client::System to Net::Peep::Client::Sysmonitor
  for clarity.
o Made adjustments to documentation.
o Fixed miscellaneous bugs.

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

Revision 1.8  2001/04/04 05:40:00  starky
Made a more intelligent option parser, allowing a user to more easily
override the default options.  Also moved all error messages that arise
from client options (e.g., using noautodiscovery without specifying
a port and server) from the parseopts method to being the responsibility
of each individual client.

Also made some minor and transparent changes, such as returning a true
value on success for many of the methods which have no explicit return
value.

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

Revision 1.1  2001/03/16 21:26:12  starky
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
