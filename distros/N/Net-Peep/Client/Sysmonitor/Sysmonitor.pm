package Net::Peep::Client::Sysmonitor;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Net::Peep::Notifier;
use Net::Peep::Notification;
use Net::Peep::Client;
use Net::Peep::Client::Sysmonitor::Uptime;
use Net::Peep::Client::Sysmonitor::Proc;
use Net::Peep::Client::Sysmonitor::Disk;
use Proc::ProcessTable;
use Filesys::DiskFree;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw( Exporter Net::Peep::Client );
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use constant DEFAULT_PID_FILE => "/var/run/sysmonitor.pid";

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = $class->SUPER::new();
	bless $this, $class;
	$this->{'UPTIMES'} = [];
	$this->{'PROCS'} = [];
	$this->{'DISKS'} = [];
	$this->name('sysmonitor');
	$this;

} # end sub new

sub Start {

	my $self = shift;

	# command-line options

	my $loadsound = '';
	my $userssound = '';
	my $loadloc = '';
	my $usersloc = '';
	my $sleep = 60;
	my $maxload = 2.0;
	my $maxusers = 5;
	my $pidfile = '/var/run/sysmonitor.pid';

	my %options = (
		'loadsound=s' => \$loadsound,       # the load sound
		'userssound=s' => \$userssound,     # The users sound
		'loadloc=s' => \$loadloc,           # The location of the load sound
		'usersloc=s' => \$usersloc,         # The location of the users sound
		'sleep=s' => \$sleep,               # sleep time
		'maxload=s' => \$maxload,           # What to consider a high load
		'maxusers=s' => \$maxusers,         # What to consider a high number of users
		'pidfile=s' => \$pidfile,           # Path to write the pid out to
	);

	# let the client know what command-line options to expect
	# and ask the client to parse the command-line
	$self->initialize(%options) || $self->pods();

	# register a parser for the sysmonitor section of the configuration file

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

	# Check whether the pidfile option was set. If not, use the default
	unless ($conf->optionExists('pidfile')) {
		$self->logger()->debug(3,"No pid file specified. Using default [" . DEFAULT_PID_FILE . "]");
		$conf->setOption('pidfile', DEFAULT_PID_FILE);
	}

	# use the options defined in the configuration file if they were
	# not explicitly defined from the command-line
	$loadsound = $conf->getOption('loadsound') if ! $loadsound && $conf->optionExists('loadsound');
	$userssound = $conf->getOption('userssound') if ! $userssound && $conf->optionExists('userssound');
	$loadloc = $conf->getOption('loadloc') if ! $loadloc && $conf->optionExists('loadloc');
	$usersloc = $conf->getOption('usersloc') if ! $usersloc && $conf->optionExists('usersloc');
	$sleep = $conf->getOption('sleep') if ! $sleep && $conf->optionExists('sleep');
	$maxload = $conf->getOption('maxload') if ! $maxload && $conf->optionExists('maxload');
	$maxusers = $conf->getOption('maxusers') if ! $maxusers && $conf->optionExists('maxusers');

	$self->logger()->debug(9,"loadsound=[$loadsound] userssound=[$userssound] loadloc=[$loadloc] usersloc=[$usersloc] sleep=[$sleep] maxload=[$maxload] maxusers=[$maxusers] ...");

	# Register a callback from the main loop

	$self->logger()->debug(9,"Registering callback ...");
	$self->callback(sub { $self->loop(); });
	$self->logger()->debug(9,"\tCallback registered ...");

	$self->MainLoop($sleep);

	return 1;

} # end sub Start

sub loop {

    my $self = shift;

    my $conf = $self->conf() || confess "Cannot execute loop:  Configuration object not found.";

    my ($loadsound,$userssound,$loadloc,$usersloc,$sleep,$maxload,$maxusers);

    $sleep = $conf->optionExists('sleep') 
	? $conf->getOption('sleep') : undef;

    my @uptimes;

    my @version = $self->conf()->versionExists() 
	? split /\./, $self->conf()->getVersion()
	    : ();

    my ($users,$load);

    my ($checkload,$checkusers) = (1,1);

    my $notifier = new Net::Peep::Notifier;

    if (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {
	# get information from the new configuration file format
	@uptimes = $self->uptimes();
	for my $uptime (@uptimes) {
	    if ($uptime->name() eq 'maxload') {
		$maxload = $uptime->value();
		$loadloc = $uptime->location();
		$loadsound = $uptime->state();
		$load = $uptime;
		my $hosts = $uptime->hosts();
		unless ($self->filter($uptime,1)) {
		    $checkload = 0;
		}
	    } elsif ($uptime->name() eq 'maxusers') {
		$maxusers = $uptime->value();
		$usersloc = $uptime->location();
		$userssound = $uptime->state();
		$users = $uptime;
		my $hosts = $uptime->hosts();
		unless ($self->filter($uptime,1)) {
		    $checkusers = 0;
		}
	    } else {
		# do nothing
	    }
	}
    } else {
	# get information from the old configuration file format
	$loadsound = $conf->optionExists('loadsound') 
	    ? $conf->getOption('loadsound') : undef;
	$userssound = $conf->optionExists('userssound') 
	    ? $conf->getOption('userssound') : undef;
	$loadloc = $conf->optionExists('loadloc') 
	    ? $conf->getOption('loadloc') : undef;
	$usersloc = $conf->optionExists('usersloc') 
	    ? $conf->getOption('usersloc') : undef;
	$maxload = $conf->optionExists('maxload') 
	    ? $conf->getOption('maxload') : undef;
	$maxusers = $conf->optionExists('maxusers') 
	    ? $conf->getOption('maxusers') : undef;
    }

    confess "Error:  You didn't define the sleep time [$sleep], ".
	"load sound [$loadsound], user sound [$userssound], max load [$maxload], ".
	    "or max users [$maxusers] properly.\n".
		"        You may want to check peep.conf.\n"
		    unless $sleep > 0 
			and $loadsound and $userssound 
			    and $maxload and $maxusers;
    
    my ($in, $avg, $nusers, $uptime);
    confess "Error:  Can't find uptime: $!" unless $uptime = `which uptime`;
    chomp($uptime);
    confess "Error:  $uptime returned no output: $!" unless $in = `$uptime`;
    
    $self->logger()->debug(3,"$uptime: $in");
    
    $nusers = $1 if $in =~ /(\d+) users/; 
    $avg = $1   if $in =~ /load average. ([\d\.]+)/;
    
    if ($checkload) {

	$self->logger()->debug(6,"The 1 minute load average is [$avg].  (Max load is [$maxload].)");
	$self->logger()->debug(6,"The number of users is [$nusers].  (Max users is [$maxusers].)");
	# Scale relative to maximum value with max volume being 255
	my $loadvol = $maxload < $avg ? 255.0 : int(255.0 * $avg / $maxload);
	if ($maxload > 0) {
	    $self->peck()->send(
				$self->name(),
				'type' => 1,
				'sound'    => $loadsound,
				'location' => $loadloc,
				'volume'   => $loadvol,
				);
	}
    
	if (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {
	    # check whether we should send notifications based on load
	    if ($avg > $maxload) {
		my $notification = new Net::Peep::Notification;
		$notification->client($self->name());
		$notification->hostname($Net::Peep::Notifier::HOSTNAME);
		$notification->status($load->notification());
		$notification->datetime(time());
		$notification->message("${Net::Peep::Notifier::HOSTNAME}:  load:  ".
				       "1 minute Load average is [$avg].  It should be at most [$maxload].");
		$notifier->notify($notification);
	    }
	}
    }

    if ($checkusers) {

	my $uservol = $maxusers < $nusers ? 255.0 : int(255.0 * $nusers / $maxusers);
	if ($maxusers > 0) {
	    $self->peck()->send(
				$self->name(),
				'type' => 1,
				'sound'    => $userssound,
				'location' => $usersloc,
				'volume'   => $uservol,
				);
	}
	
	if (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {
	    # check whether we should send notifications based on users
	    if ($nusers > $maxusers) {
		$self->logger()->debug(6,"Sending notification based on load observation.");
		my $notification = new Net::Peep::Notification;
		$notification->client($self->name());
		$notification->hostname($Net::Peep::Notifier::HOSTNAME);
		$notification->status($users->notification());
		$notification->datetime(time());
		$notification->message("${Net::Peep::Notifier::HOSTNAME}:  maxusers:  ".
				       "Number of users is [$nusers].  It should be at most [$maxusers].");
		$notifier->notify($notification);
	    }
	}
    }
	    
    # now for the procs ...
    my @procs = grep $self->filter($_,1), $self->procs();

    my $table = new Proc::ProcessTable;

    for my $proc (@procs) {
	my $name = $proc->name();
	my $hosts = $proc->hosts();
	my $max = $proc->max();
	my $min = $proc->min();
	my $count = 0;
	my $p = $table->table();
	$self->logger()->debug(6,"Checking process [$name] ...");
	map { $count++ if $_->cmndline() =~ /$name/ } @$p;
	$self->logger()->debug(6,"\t[$count] processes whose command line matches [$name] are running.");
	if ( ( $max ne 'inf' && $count > $max ) || 
	     ( $count < $min ) ) {
	    
	    $self->logger()->debug(6,"\tSending notification because too many [$name] processes are running.")
		if $max ne 'inf' && $count > $max;
	    $self->logger()->debug(6,"\tSending notification because too few [$name] processes are running.")
		if $count < $min;
	    $self->peck()->send(
				$self->name(),
				'type' => 0,
				'sound' => $proc->event(),
				'location' => 128, # FIXIT:  This should be taken from peep.conf
				'priority' => 0,
				'volume'   => 255
				);
	    
	    my $notification = new Net::Peep::Notification;
	    $notification->client($self->name());
	    $notification->hostname($Net::Peep::Notifier::HOSTNAME);
	    $notification->status($proc->notification());
	    $notification->datetime(time());
	    if ($max ne 'inf' && $count > $max) {
		$notification->message("${Net::Peep::Notifier::HOSTNAME}:  $name:  ".
				       "There are [$count] instances of processes that match the pattern [$name]\n".
				       "whereas at most [$max] should be running.");
	    } elsif ($count < $min) {
		$notification->message("${Net::Peep::Notifier::HOSTNAME}:  $name:  ".
				       "There are [$count] instances of processes that match the pattern [$name]\n".
				       "whereas a minimum of [$min] should be running.");
	    } else {
		confess "Error:  Bad evaluation of process count for [$name].";
	    }
	    $notifier->notify($notification);
	}
    } 

    # now for the disk utilization
    my @disks = grep $self->filter($_,1), $self->disks();
    my $handle = new Filesys::DiskFree;
    $handle->df();
    my @d = $handle->disks();
    for my $disk (@disks) {
	my $name = $disk->name();
	my $hosts = $disk->hosts();
	my $name = $disk->name();
	my $max = $disk->max();
	$self->logger()->debug(6,"Checking disk pattern [$name] ...");
	my $regex = quotemeta($name);
	for my $d (@d) {
	    my $mount = $handle->mount($d);
	    my $used = $handle->used($d);
	    my $total = $handle->total($d);
	    my $device = $handle->device($d);
	    my $utilization = ( $used / $total ) * 100;
	    $self->logger()->debug(8,"\tChecking disk [$mount] on device [$device] ...");
	    if ($device =~ /$regex/) {
		$self->logger()->debug(8,"\t\tDisk [$mount] matches.");
		if ( $utilization > $max ) {
		    $self->logger()->debug(6,sprintf "\t\tDisk [$mount] is at [%5.2f\%] capacity.  It should be at most [$max\%].", $utilization);
		    $self->peck()->send(
					$self->name(),
					'type' => 0,
					'sound'    => $disk->event(),
					'location' => 128, # FIXIT:  This should be taken from peep.conf
					'priority' => 0,
					'volume'   => 255
					);
		    my $notification = new Net::Peep::Notification;
		    $notification->client($self->name());
		    $notification->hostname($Net::Peep::Notifier::HOSTNAME);
		    $notification->status($disk->notification());
		    $notification->datetime(time());
		    $notification->message(sprintf "${Net::Peep::Notifier::HOSTNAME}:  $name:  ".
					   "Device [$device] mounted at [$mount] is at [%5.2f\%] capacity.\n".
					   "It should be at most [$max\%].", $utilization);
		    $notifier->notify($notification);
		}
	    }
	} 
    }
		    
} # end sub loop

sub parse {

    my $self = shift;
    my $client = $self->name() || confess "Cannot parse logparser events:  Client name attribute not set.";
    my @text = @_;

    my $conf = $self->conf() || confess "Cannot parse logparser events:  Configuration object not found.";

    $self->logger()->debug(1,"\t\tParsing events for client [$client] ...");

    my @version = $self->conf()->versionExists() 
	? split /\./, $self->conf()->getVersion()
	    : ();

    if (@version && $version[0] >= 0 && $version[1] >= 4 && $version[2] > 3) {

	$self->tempParseDefaults(@text);

	my @uptime = $self->getConfigSection('uptime',@text);
	my @procs = $self->getConfigSection('procs',@text);
	my @disk = $self->getConfigSection('disk',@text);

	$self->parseUptime(@uptime);
	$self->parseProcs(@procs);
	$self->parseDisk(@disk);

    } else {

	$self->tempParseOldConfig(@text);

    }

} # end sub parse

sub tempParseOldConfig {

    my $self = shift;
    my @text = @_;

    my $conf = $self->conf() || confess "Cannot parse old-style config file:  Configuration object not found.";

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

} # end sub tempParseOldConfig

sub parseUptime {

	my $self = shift;
	my @text = @_;

	my $client = $self->name() || confess "Cannot process uptime definitions:  No client name found.";

	$self->logger()->debug(1,"\t\tParsing uptime settings for client [$client] ...");

	while (my $line = shift @text) {
		next if $line =~ /^\s*$/ or $line =~ /^\s*#/;

		if ($line =~ /^\s*([\w]+)\s+([\w]+)\s+([\d\.]+)\s+(\d+)\s+(\d+)\s+(info|warn|crit)\s+([\w\-\.]+)/) {

		    my ($name,$state,$value,$location,$priority,$notification,$hosts) = 
			($1,$2,$3,$4,$5,$6,$7);

		    my $uptime = new Net::Peep::Client::Sysmonitor::Uptime;

		    $uptime->name($name);
		    $uptime->state($state);
		    $uptime->value($value);
		    $uptime->location($location);
		    $uptime->priority($priority);
		    $uptime->notification($notification);
		    $uptime->hosts($hosts);
		    $self->addUptime($uptime);
		    $self->logger()->debug(1,"\t\t\tClient uptime setting [$name] added.");

		}

	}

	return @text;

} # end sub parseUptime

sub parseProcs {

    my $self = shift;
    my @text = @_;
    
    my $client = $self->name() || confess "Cannot process proc definitions:  No client name found.";

    $self->logger()->debug(1,"\t\tParsing proc list for client [$client] ...");
    
    while (my $line = shift @text) {
	next if $line =~ /^\s*$/ or $line =~ /^\s*#/;
	
	if ($line =~ /^\s*([\w\-\.]+)\s+([\w\-]+)\s+(\d+|inf)\s+(\d+)\s+(\d+)\s+(\d+)\s+(info|warn|crit)\s+(.*)$/) {
	    
	    my ($name,$event,$max,$min,$location,$priority,$notification,$hosts) = 
		($1,$2,$3,$4,$5,$6,$7,$8);
	    
	    my @hosts = split /\s*,\s*/, $hosts;
	    
	    my $proc = new Net::Peep::Client::Sysmonitor::Proc;
	    $proc->name($name);
	    $proc->event($event);
	    $proc->max($max);
	    $proc->min($min);
	    $proc->location($location);
	    $proc->priority($priority);
	    $proc->notification($notification);
	    $proc->hosts($hosts);
	    
	    $self->addProc($proc);
	    $self->logger()->debug(1,"\t\t\tClient proc [$name] added.");
	    
	}
	
    }
    
    return @text;

} # end sub parseProcs

sub parseDisk {

    my $self = shift;
    my @text = @_;

    my $client = $self->name() || confess "Cannot process disk definitions:  No client name found.";

    $self->logger()->debug(1,"\t\tParsing disks for client [$client] ...");

    while (my $line = shift @text) {
	next if $line =~ /^\s*$/ or $line =~ /^\s*#/;
		
	if ($line =~ /^\s*(\w+)\s+([\w-]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(info|crit|warn)\s+([\w\-\.]+)/) {

	    my ($name,$event,$max,$location,$priority,$notification,$hosts) = 
		($1,$2,$3,$4,$5,$6,$7);

	    my $disk = new Net::Peep::Client::Sysmonitor::Disk;

	    $disk->name($name);
	    $disk->event($event);
	    $disk->max($max);
	    $disk->location($location);
	    $disk->priority($priority);
	    $disk->notification($notification);
	    $disk->hosts($hosts);
	    
	    $self->addDisk($disk);
	    $self->logger()->debug(1,"\t\t\tClient disk [$name] added.");

	}

    }

    return @text;

} # end sub parseDisk

sub addUptime {

    my $self = shift;
    my $uptime = shift || confess "Cannot add sysmonitor uptime:  No uptime was provided.";
    push @{$self->{'UPTIMES'}}, $uptime;
    return 1;

} # end sub addUptime

sub uptimes {

    # returns the list of uptimes built with the addUptime method
    my $self = shift;
    return wantarray ? @{$self->{'UPTIMES'}} : $self->{'UPTIMES'};

} # end sub uptimes

sub addProc {

    my $self = shift;
    my $proc = shift || confess "Cannot add sysmonitor proc:  No proc was provided.";
    push @{$self->{'PROCS'}}, $proc;
    return 1;

} # end sub addProc

sub procs {

    # returns the list of procs built with the addProc method
    my $self = shift;
    return wantarray ? @{$self->{'PROCS'}} : $self->{'PROCS'};

} # end sub procs

sub addDisk {

    my $self = shift;
    my $disk = shift || confess "Cannot add sysmonitor disk:  No disk was provided.";
    push @{$self->{'DISKS'}}, $disk;
    return 1;

} # end sub addDisk

sub disks {

    # returns the list of disks built with the addDisk method
    my $self = shift;
    return wantarray ? @{$self->{'DISKS'}} : $self->{'DISKS'};

} # end sub disks

1;

__END__

=head1 NAME

Net::Peep::Client::Sysmonitor - Perl extension for a client to monitor
system statistics.

=head1 SYNOPSIS

  require 5.005_62;
  use Net::Peep::Client::Sysmonitor;
  $sysmonitor = new Net::Peep::Client::Sysmonitor;
  $SIG{'INT'} = $SIG{'TERM'} = sub { $sysmonitor->shutdown(); exit 0; };
  $sysmonitor->Start();

=head1 DESCRIPTION

Monitors uptime, load, user statistics, processes, and disk
utilization.

=head2 EXPORT

None by default.

=head1 METHODS

Note that this section is somewhat incomplete.  More
documentation will come soon.

    new() - The constructor

    Start() - Begins monitoring system stats.  Terminates by entering
    the Net::Peep::Client->MainLoop() method.

    loop() - The callback called by the Net::Peep::Client->MainLoop()
    method.  See Net::Peep::Client for more information.

    parse(@text) - Callback given to the Net::Peep::Client->parser()
    method which parses the sysmonitor client config section of the
    Peep configuration file.

    parseUptime(@text) - Parses the uptime section of the sysmonitor
    client config section of the Peep configuration file.

    parseProcs(@text) - Parses the procs section of the sysmonitor
    client config section of the Peep configuration file.

    parseDisk(@text) - Parses the disk section of the sysmonitor
    client config section of the Peep configuration file.

    tempParseOldConfig(@text) - Parses the pre-0.4.4 style of
    sysmonitor client config section.  Added for backwards
    compatibility.  Will likely be deprecated with 0.5.0.

    addUptime($uptime) - Adds a Net::Peep::Client::Sysmonitor::Uptime
    object to an array.

    uptimes() - Retrieves an array of
    Net::Peep::Client::Sysmonitor::Uptime objects added by the addUptime method.

    addProc($proc) - Adds a Net::Peep::Client::Sysmonitor::Proc
    object to an array.

    procs() - Retrieves an array of
    Net::Peep::Client::Sysmonitor::Proc objects added by the addProc method.

    addDisk($disk) - Adds a Net::Peep::Client::Sysmonitor::Disk
    object to an array.

    disks() - Retrieves an array of
    Net::Peep::Client::Sysmonitor::Disk objects added by the addDisk method.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu> Copyright (C) 2001

Collin Starkweather <collin.starkweather@colorado.edu>

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::BC, Net::Peep::Log, Net::Peep::Parser, Net::Peep::Client, sysmonitor.

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

$Log: Sysmonitor.pm,v $
Revision 1.7  2001/10/01 05:20:05  starky
Hopefully the final commit before release 0.4.4.  Tied up some minor
issues, did some beautification of the log messages, added some comments,
and made other minor changes.

Revision 1.6  2001/09/23 08:53:52  starky
The initial checkin of the 0.4.4 release candidate 1 clients.  The release
includes (but is not limited to):
o A new client:  pinger
o A greatly expanded sysmonitor client
o An API for creating custom clients
o Extensive documentation on creating custom clients
o Improved configuration file format
o E-mail notifications
Contact Collin at collin.starkweather@colorado with any questions.

Revision 1.5  2001/08/08 20:17:57  starky
Check in of code for the 0.4.3 client release.  Includes modifications
to allow for backwards-compatibility to Perl 5.00503 and a critical
bug fix to the 0.4.2 version of Net::Peep::Conf.

Revision 1.4  2001/07/23 17:46:29  starky
Added versioning to the configuration file as well as the ability to
specify groups in addition to / as a replacement for event letters.
Also changed the Net::Peep::Parse namespace to Net::Peep::Parser.
(I don't know why I ever named an object by a verb!)

Revision 1.3  2001/05/07 02:39:19  starky
A variety of bug fixes and enhancements:
o Fixed bug 421729:  Now the --output flag should work as expected and the
--logfile flag should not produce any unexpected behavior.
o Documentation has been updated and improved, though more improvements
and additions are pending.
o Removed print STDERRs I'd accidentally left in the last commit.
o Other miscellaneous and sundry bug fixes in anticipation of a 0.4.2
release.

Revision 1.2  2001/05/06 21:33:17  starky
Bug 421248:  The --help flag should now work as expected.

Revision 1.1  2001/04/23 10:13:19  starky
Commit in preparation for release 0.4.1.

o Altered package namespace of Peep clients to Net::Peep
  at the suggestion of a CPAN administrator.
o Changed Peep::Client::Log to Net::Peep::Client::Logparser
  and Peep::Client::System to Net::Peep::Client::Sysmonitor
  for clarity.
o Made adjustments to documentation.
o Fixed miscellaneous bugs.

Revision 1.5  2001/04/07 08:01:05  starky
Corrected some errors in and made some minor changes to the documentation.

Revision 1.4  2001/04/04 05:40:00  starky
Made a more intelligent option parser, allowing a user to more easily
override the default options.  Also moved all error messages that arise
from client options (e.g., using noautodiscovery without specifying
a port and server) from the parseopts method to being the responsibility
of each individual client.

Also made some minor and transparent changes, such as returning a true
value on success for many of the methods which have no explicit return
value.

Revision 1.3  2001/03/31 07:51:35  mgilfix


  Last major commit before the 0.4.0 release. All of the newly rewritten
clients and libraries are now working and are nicely formatted. The server
installation has been changed a bit so now peep.conf is generated from
the template file during a configure - which brings us closer to having
a work-out-of-the-box system.

Revision 1.3  2001/03/31 02:17:00  mgilfix
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

=cut
