package Net::Peep::Client;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Data::Dumper;
use Socket;
use Getopt::Long;
use File::Tail;
use Pod::Text;
use Net::Peep::BC;
use Net::Peep::Log;
use Net::Peep::Parser;
use Net::Peep::Notifier;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw( INTERVAL MAX_INTERVAL ADJUST_AFTER ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

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

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

} # end sub new

sub name {

    my $self = shift;
    if (@_) { $self->{'NAME'} = shift; }
    return $self->{'NAME'};

} # end sub name

sub callback {

	my $self = shift;
	my $callback = shift;
	confess "Cannot register callback:  Expecting a code reference.  (Got [$callback].)" 
		unless ref($callback) eq 'CODE';
	$self->{"__CALLBACK"} = $callback;
	return 1;

} # end sub callback

sub getCallback {

	my $self = shift;
	confess "Cannot get callback:  A callback has not been set yet."
		unless exists $self->{"__CALLBACK"};
	return $self->{"__CALLBACK"};

} # end sub getCallback

sub parser {

	my $self = shift;
	my $parser = shift;
	confess "Cannot register parser:  Expecting a code reference.  (Got [$parser].)" 
		unless ref($parser) eq 'CODE';
	$self->{"__PARSER"} = $parser;
	return 1;

} # end sub parser

sub getParser {

	my $self = shift;
	confess "Cannot get parser:  A parser has not been set yet."
		unless exists $self->{"__PARSER"};
	return $self->{"__PARSER"};

} # end sub getParser

sub runParser {

    my $self = shift;
    my @text = @_;

    my $parser = $self->getParser();
    &$parser(@text);

} # end sub runParser

sub loop {

	my $self = shift;
	if (@_) { $self->{"__LOOP"} = shift; }
	return $self->{"__LOOP"};

} # end sub loop

sub peck {

	my $self = shift;
	my $conf = $self->conf();

	unless (exists $self->{"__PEEP"}) {
		if ($conf->getOptions()) {
			$self->{"__PEEP"} = Net::Peep::BC->new( $self->name(), $conf );
		} else {
			confess "Error:  Expecting options to have been parsed by now.";
		}
	}
	return $self->{"__PEEP"};

} # end sub peck

sub initialize {

	my $self = shift;
	my %options = @_;

	my $conf = $self->conf();

	$conf->client($self);

	my (
		$config,
		$logfile,
		$debug,
		$daemon,
		$output,
		$pidfile,
		$autodiscovery,
		$server,
		$port,
		$silent,
		$help) = ('/etc/peep.conf','',0,1,'','',1,'','',0,0);

	my %standardOptions = (
		'config=s' => \$config,
		'logfile=s' => \$logfile,
		'debug=s' => \$debug,
		'daemon!' => \$daemon,
		'output=s' => \$output,
		'pidfile=s' => \$pidfile,
		'autodiscovery!' => \$autodiscovery,
		'server=s' => \$server,
		'port=s' => \$port,
		'silent' => \$silent,
		'help' => \$help
	);

	for my $option (keys %standardOptions) {
		if (exists $options{$option}) {
			delete $standardOptions{$option};
		}
	}

	my %allOptions = (%options,%standardOptions);

	GetOptions(%allOptions);

	# set the debug level first so we can start printing debugging
	# messages
	$Net::Peep::Log::logfile = $output if $output;
	$Net::Peep::Log::debug = $debug if $debug;

	my $found;

	if (-f ${$allOptions{'config=s'}}) {
		$found = ${$allOptions{'config=s'}};
	} else {
		for my $dir ('.','/usr/local/etc','/usr','/usr/local','/opt') {
			if (-f "$dir/peep.conf") {
				$found = "$dir/peep.conf";
				last;
			}
		}
	}

	if ($found) {
		$self->logger()->debug(1,"The Peep configuration file has been identified as [$found]");
	} else {
		$self->logger()->log("No peep configuration file could be found.  Exiting gracefully ....");
		exit 2;
	}

	$conf->setOption('config',$found);
	$conf->setOption('logfile',${$allOptions{'logfile=s'}}) if ${$allOptions{'logfile=s'}} ne '';
	$conf->setOption('debug',${$allOptions{'debug=s'}});
	$conf->setOption('daemon',${$allOptions{'daemon!'}});
	$conf->setOption('output',${$allOptions{'output=s'}});
	$conf->setOption('pidfile',${$allOptions{'pidfile=s'}}) if ${$allOptions{'pidfile=s'}} ne '';
	$conf->setOption('autodiscovery',${$allOptions{'autodiscovery!'}});
	$conf->setOption('server',${$allOptions{'server=s'}}) if ${$allOptions{'server=s'}} ne '';
	$conf->setOption('port',${$allOptions{'port=s'}}) if ${$allOptions{'port=s'}} ne '';
	$conf->setOption('silent',${$allOptions{'silent'}});
	$conf->setOption('help',${$allOptions{'help'}});

	return $help ? 0 : 1;

} # end sub initialize

sub MainLoop {

	my $self = shift;
	my $sleep = shift;

	my $client = $self->name() || confess "Cannot begin main loop:  Client name not specified.";
	my $conf = $self->conf() || confess "Cannot begin main loop:  Configuration object not found.";

	my $fork = $conf->getOption('daemon');

	if ($fork) {

		$self->logger()->debug(7,"Running in daemon mode.  Forking ...");

		if (fork()) {
			# If we're here, then we're the parent
			close (STDIN);
			close (STDOUT);
			close (STDERR);
			exit(0);
		}

		$self->logger()->debug(7,"\tForked.");

		# Else we're the child. Let's write out our pid
		my $pid = 0;
		if ($conf->optionExists('pidfile')) {
			my $pidfile = $conf->getOption('pidfile') || confess "Cannot fork:  Pidfile not found.";
			if (open PIDFILE, ">$pidfile") {
				select (PIDFILE); $| = 1;  # autoflush
				select (STDERR);
				print PIDFILE "$$\n";
				close PIDFILE;
				$pid = 1;
			} else {
				$self->logger()->log("Warning:  Couldn't open pid file:  No pidfile option.");
				$self->logger()->log("\tContinuing anyway ...");
			}
		} else {
			$self->logger()->log("Warning:  Couldn't open pid file: Pidfile option not specified.");
			$self->logger()->log("\tContinuing anyway ...");
		}

	}

	my $sub = $self->getCallback();
	if ($sleep) {
		while (1) {
			$self->logger()->debug(9,"Executing callback from within infinite loop ...");
			&$sub();
			$self->logger()->debug(9,"\tSleeping [$sleep] seconds ...");
			sleep($sleep);
		}
	} else {
		$self->logger()->debug(9,"Executing callback ...");
		&$sub();
	}

} # end sub MainLoop

sub configure {

	my $self = shift;
	my $conf = $self->conf() 
	    || confess "Cannot parse configuration object:  Configuration object not found";
	Net::Peep::Parser->new()->load($conf);

	my @version = $self->conf()->versionExists() 
		? split /\./, $self->conf()->getVersion()
			: ();

	my $config = $conf->getOption('config');
	unless (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {

		print STDERR <<"eop";

[$0] Warning:  The configuration file 

  $config

appears to use an old configuration file syntax.  You may want to
update your configuration to be consistent with the 0.4.4 release.
The older syntax may not be supported as of the 0.5.0 release.

eop

		;

	}

	return $conf;

} # end sub configure

sub conf {

	my $self = shift;
	$self->{"__CONF"} = Net::Peep::Conf->new() unless exists $self->{"__CONF"};
	return $self->{"__CONF"};

} # end sub conf

sub pods {

	my $self = shift;
	my $message = shift;

	print "\n$message\n\n" if $message;

	open(POD,$0) || die "Cannot print help text for $0:  $!";
	Pod::Text->new()->parse_from_filehandle(\*POD);
	close POD;

	exit 0;

} # end sub pods

# returns a logging object
sub logger {

	my $self = shift;
	if ( ! exists $self->{'__LOGGER'} ) { $self->{'__LOGGER'} = new Net::Peep::Log }
	return $self->{'__LOGGER'};

} # end sub logger

# Remove our pidfile with garbage collection (if it exists) The client
# needs to call this function explicitly upon receipt of a signal with
# the appropriate reference.
sub shutdown {
	my $self = shift;
	print STDERR "Shutting down ...\n";
	my $notifier = new Net::Peep::Notifier;
	print STDERR "\tFlushing notification buffers ...\n";
	my $n = $notifier->force();
	my $string = $n ? 
	    "\t$n notifications were flushed from the buffers.\n" : 
		"\tNo notifications were flushed from the buffers:  The buffers were empty.\n";
	print STDERR $string;
	my $conf = $self->conf();
	my $pidfile = defined $conf && $conf->optionExists('pidfile') && -f $conf->getOption('pidfile')
	    ? $conf->getOption('pidfile') : '';
	if ($pidfile) {
		print STDERR "\tUnlinking pidfile ", $pidfile, " ...\n";
		unlink $pidfile;
	}
	print STDERR "Done.\n";
}    

sub getConfigSection {

    my $self = shift;
    my $section = shift;
    my @text = @_;

    my @return;
    my $read = 0;
    for my $line (@text) {
	if ($line =~ /^\s*$section/) {
	    $read = 1;
	} elsif ($line =~ /^\s*end events/) {
	    $read = 0;
	} elsif ($read) {
	    next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
	    push @return, $line;
	} else {
	    # do nothing
	}
    }
    return wantarray ? @return : \@return;

} # end sub getConfigSection

sub tempParseDefaults {

    my $self = shift;
    my @text = @_;

    my $conf = $self->conf();

    for my $line ($self->getConfigSection('default',@text)) {

	    if ($line =~ /^\s*([\w\-]+)\s+(\S+)\s*$/) {
		my ($option,$value) = ($1,$2);
		if ($conf->optionExists($option)) {
		    $self->logger()->debug(6,"\t\tNot setting option [$option]:  It has already been set (possibly from the command-line).");
		} else {
		    $self->logger()->debug(6,"\t\tSetting option [$option] to value [$value].");
		    $conf->setOption($option,$value) unless $conf->optionExists($option);
		}
	    }

    }

} # sub tempParseDefaults

sub getGroups {

    my $self = shift;
    my $conf = $self->conf();
    unless (exists $self->{'GROUPS'}) {
	my $groups = $conf->optionExists('groups') ? $conf->getOption('groups') : '';
	my @groups = split /,/, $groups;
	$self->{'GROUPS'} = \@groups;
    }
    return wantarray ? @{$self->{'GROUPS'}} : $self->{'GROUPS'};
    
} # end sub getGroups

sub getExcluded {

    my $self = shift;
    my $conf = $self->conf();
    unless (exists $self->{'EXCLUDED'}) {
	my $excluded = $conf->optionExists('excluded') ? $conf->getOption('excluded') : '';
	my @excluded = split /,/, $excluded;
	$self->{'EXCLUDED'} = \@excluded;
    }
    return wantarray ? @{$self->{'EXCLUDED'}} : $self->{'EXCLUDED'};
    
} # end sub getExcluded

sub filter {

    my $self = shift;
    my $object = shift || confess "Object not found";
    my $nogrp = shift;

    my $conf = $self->conf();
    
    my $return = 0;
    
    my $name = $object->name();

    unless ($nogrp) {

	$self->logger()->debug(9,"Checking group [$name] against group and excluded group lists ...");

	my $group = $object->group();

	my @groups = ();
	my @exclude = ();

	@groups = $self->getGroups('groups');
	@exclude = $self->getExcluded('exclude');
    
	if (grep /^all$/, @groups) {
	    $return = 1;
	} else {
	    for my $group_option (@groups) {
		$return = 1 if $group eq $group_option;
	    }
	}
    
	for my $exclude_option (@exclude) {
	    $return = 0 if $group eq $exclude_option;
	}
    
	$self->logger()->debug(8,"[$name] will be ignored:  The group [$group] is either not in the group ".
			       "list [@groups] or it is in the excluded list [@exclude].") if $return == 0;
    }

    my $hosts = $object->hosts();
    my @version = $conf->versionExists() ? split /\./, $conf->getVersion() : ();
    
    if (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {
	if ($object->pool()->isInHostPool($Net::Peep::Notifier::HOSTNAME)) {
	    $return = 1;
	} else {
	    $return = 0;
	    $self->logger()->debug(8,"[$name] will be ignored:  Host [$Net::Peep::Notifier::HOSTNAME] ".
				   "is not in the host pool [$hosts].");
	}
    }
    
    return $return;
    
} # end sub filter

1;

__END__

=head1 NAME

Net::Peep::Client - Perl extension for client application module
subclasses for Peep: The Network Auralizer.

=head1 SYNOPSIS

See the Net::Peep documentation for information about the usage of the
Net::Peep::Client object.

=head1 DESCRIPTION

Provides support methods for the various Peep clients applications,
can be subclassed to create new client modules, and eases the
creation of generic Peep clients.

See the main Peep client documentation or

  perldoc Net::Peep

for more information on usage of this module.

=head1 OPTIONS

The following options are common to all Peep clients:

  --config=[PATH]       Path to the configuration file to use.
  --debug=[NUMBER]      Enable debugging. (Def:  0)
  --nodaemon            Do not run in daemon mode.  (Def:  daemon)
  --pidfile=[PATH]      The file to write the pid out to.  (Daemon only.)
  --output=[PATH]       The file to log output to. (Def: stderr)
  --noautodiscovery     Disables autodiscovery and enables the server and port options.
                        (Default:  autodiscovery)
  --server=[HOST]       The host (or IP address) to connect to.  
  --port=[PORT NO]      The port to use.
  --help                Prints this documentation.

=head1 EXPORT

None by default.

=head1 METHODS

    new() - The constructor

    name($name) - Sets/gets the name of the client.  All clients must
    have a name.

    initialize(%options) - Sets the value (using the setOption method
    of the Net::Peep::Conf object) of all command-line options parsed
    by Getopt::Long for the client.  Additional options may be
    specified using %options.  For more information on the format of
    the %options hash, see Getopt::Long.

    configure() - Returns a configuration object.  To be called after
    a call to initialize().

    parser($coderef) - Specifies a callback, which must be in the form
    of a code reference, to be used to parse the config ... end config
    block of the Peep configuration file for the client.

    callback($coderef) - Specifies a callback, which must be in the
    form of a code reference, to be used in the MainLoop method.

    MainLoop($sleep) - Starts the main loop.  If $sleep returns false,
    the callback is only called once; otherwise, the main loop sleeps
    $sleep seconds between each call to the callback.

    logger() - Returns a Net::Peep::Log object

    getConfigSection($section,@lines) - Retrieves a section by the
    name of $section from the lines of text @lines.  This is a utility
    method to assist with parsing sections from the Peep configuration
    file client config sections (e.g., the events section from the
    logparser definition in peep.conf).

    tempParseDefaults(@lines) - Parses a defaults section in a client
    config block in the Peep configuration file.  Note that this code
    duplicates the parseClientDefault method in Net::Peep::Parser.  It
    will be deprecated after backwards-compatibility of peep.conf is
    dropped, probably with the release of 0.5.0.

    getGroups() - Parses the 'groups' option and returns an array of groups.

    getExcluded() - Parses the 'excluded' option and returns a list of
    excluded groups.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu> Copyright (C) 2000

Collin Starkweather <collin.starkweather@colorado.edu>

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::Client::Logparser,
Net::Peep::Client::Sysmonitor, Net::Peep::BC, Net::Peep::Log.

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

$Log: Client.pm,v $
Revision 1.12  2001/11/06 03:52:19  starky
Fixed bug in which a client would fatal error in a mysterious way if
the configuration file could not be found.

Revision 1.11  2001/11/05 03:40:56  starky
Commit in preparation for the 0.4.5 release.

Revision 1.10  2001/10/13 07:22:33  starky
Updated documentation to include a description of all default client
command-line options.  Also updated the METHODS section to match the
0.4.4 API.

Revision 1.9  2001/10/05 06:41:19  starky
Fixed a "feature" in which a client would fatal error if it was not in
forking mode (i.e., if the --nodaemon flag was *not* set) and no pidfile
option was specified (e.g., through the --pidfile option).  Also
incremented the release number to 0.4.4.2 for a release to the CPAN.

Revision 1.8  2001/10/01 05:20:05  starky
Hopefully the final commit before release 0.4.4.  Tied up some minor
issues, did some beautification of the log messages, added some comments,
and made other minor changes.

Revision 1.7  2001/09/23 08:53:49  starky
The initial checkin of the 0.4.4 release candidate 1 clients.  The release
includes (but is not limited to):
o A new client:  pinger
o A greatly expanded sysmonitor client
o An API for creating custom clients
o Extensive documentation on creating custom clients
o Improved configuration file format
o E-mail notifications
Contact Collin at collin.starkweather@colorado with any questions.

Revision 1.6  2001/08/08 20:17:57  starky
Check in of code for the 0.4.3 client release.  Includes modifications
to allow for backwards-compatibility to Perl 5.00503 and a critical
bug fix to the 0.4.2 version of Net::Peep::Conf.

Revision 1.5  2001/07/23 17:46:29  starky
Added versioning to the configuration file as well as the ability to
specify groups in addition to / as a replacement for event letters.
Also changed the Net::Peep::Parse namespace to Net::Peep::Parser.
(I don't know why I ever named an object by a verb!)

Revision 1.4  2001/05/07 02:39:19  starky
A variety of bug fixes and enhancements:
o Fixed bug 421729:  Now the --output flag should work as expected and the
--logfile flag should not produce any unexpected behavior.
o Documentation has been updated and improved, though more improvements
and additions are pending.
o Removed print STDERRs I'd accidentally left in the last commit.
o Other miscellaneous and sundry bug fixes in anticipation of a 0.4.2
release.

Revision 1.3  2001/05/06 21:31:22  starky
Bug 421248:  Fixed broken --help for client modules.  Also added the
directory . to the list of directories searched to find peep.conf.

Revision 1.2  2001/05/03 05:45:42  starky
Bug 418680:  Clients no longer terminate with error when unable to open
the pidfile in daemon mode.  Instead, a warning is logged.

Revision 1.1  2001/04/23 10:13:19  starky
Commit in preparation for release 0.4.1.

o Altered package namespace of Peep clients to Net::Peep
  at the suggestion of a CPAN administrator.
o Changed Peep::Client::Log to Net::Peep::Client::Logparser
  and Peep::Client::System to Net::Peep::Client::Sysmonitor
  for clarity.
o Made adjustments to documentation.
o Fixed miscellaneous bugs.

Revision 1.12  2001/04/17 06:46:21  starky
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

Revision 1.11  2001/04/11 04:44:31  starky
Included an intelligent search for the Peep configuration file.  If no file
is specified on the command line or the file specified on the command line
is not found, peep searches the following directories for peep.conf:

  /etc
  /usr/local/etc
  /usr
  /usr/local
  /opt

Revision 1.10  2001/04/07 08:01:05  starky
Corrected some errors in and made some minor changes to the documentation.

Revision 1.9  2001/04/04 05:40:00  starky
Made a more intelligent option parser, allowing a user to more easily
override the default options.  Also moved all error messages that arise
from client options (e.g., using noautodiscovery without specifying
a port and server) from the parseopts method to being the responsibility
of each individual client.

Also made some minor and transparent changes, such as returning a true
value on success for many of the methods which have no explicit return
value.

Revision 1.8  2001/03/31 07:51:34  mgilfix


  Last major commit before the 0.4.0 release. All of the newly rewritten
clients and libraries are now working and are nicely formatted. The server
installation has been changed a bit so now peep.conf is generated from
the template file during a configure - which brings us closer to having
a work-out-of-the-box system.

Revision 1.8  2001/03/31 02:17:00  mgilfix
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

Revision 1.7  2001/03/30 18:34:12  starky
Adjusted documentation and made some modifications to Peep::BC to
handle autodiscovery differently.  This is the last commit before the
0.4.0 release.

Revision 1.6  2001/03/28 02:41:48  starky
Created a new client called 'pinger' which pings a set of hosts to check
whether they are alive.  Made some adjustments to the client modules to
accomodate the new client.

Also fixed some trivial pre-0.4.0-launch bugs.

Revision 1.5  2001/03/27 05:47:55  starky
Forgot to use Pod::Text.

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
