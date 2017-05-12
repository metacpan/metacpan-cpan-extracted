#! -*- perl -*-

my $script = <<'EOF';
~startperl~ -w
#
#
#   SNMP::Monitor - a Perl package for monitoring remote hosts via SNMP
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#

use strict;


require Getopt::Long;
require SNMP::Monitor;
require Socket;


############################################################################
#
#   Constant variables
#
############################################################################

my $VERSION = 'snmpmon, 13-Jun-1998, Copyright (C) 1998 by Jochen Wiedmann';
my $ETC_DIR = "~etc_dir~";
my $CONFIG_FILE = "$ETC_DIR/configuration";
my $PID_FILE = "~pid_file~";
my $FACILITY = "~facility~";


############################################################################
#
#   Global variables
#
############################################################################

use vars qw($debugging);

$debugging = 0;

my $configFile = $CONFIG_FILE;
my $pidFile = $PID_FILE;
my $facility = $FACILITY;


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print usage message and exit
#
############################################################################

sub Usage () {
    print <<"USAGE";
Usage: $0 <action> [options]

Possible actions are:

    --add <router>	Add machine <router> to the list of routers being
			monitored.
    --delete <router>   Remove machine <router> from the list.
    --list		List all routers.
    --start             Start the monitor
    --stop              Stop the monitor
    --help		Show this message.
    --version		Print version number and exit.

General options are:

    --config <file>     Read configuration from <file>, defaults to
                        $CONFIG_FILE.

Options used in conjunction with --start or --stop are:

    --debug             Run in debugging mode; much output will be
	                created and sent to the syslog.
    --facility <f>      Use syslog facility <f> for logging messages;
                        defaults to $FACILITY.
    --nodetach          Don't detach from the Shell, used for debugging
                        purposes.
    --pidfile <file>    Use <file> as PID file; default is $PID_FILE.

$VERSION
USAGE
    exit 1;
}


############################################################################
#
#   Name:    Add
#
#   Purpose: Add a new router to the list of known machines
#
#   Inputs:  Routers short name
#
#   Returns: Nothing
#
############################################################################

sub Add ($) {
    my($name) = @_;
    my $config = SNMP::Monitor->Configuration($configFile);

    require SNMP::Monitor::Install;
    SNMP::Monitor::Install->AddRouter($config, $name);
    SNMP::Monitor::Install->SaveFile($configFile, $config);
}


############################################################################
#
#   Name:    Delete
#
#   Purpose: Deletes a router from the list of known machines
#
#   Inputs:  Routers short name
#
#   Returns: Nothing
#
############################################################################

sub Delete ($) {
    my($name) = @_;
    my $config = SNMP::Monitor->Configuration($configFile);
    if (!exists($config->{hosts}->{$name})) {
	die "A router $name doesn't exist in $configFile.";
    }
    delete $config->{hosts}->{$name};

    require SNMP::Monitor::Install;
    SNMP::Monitor::Install->SaveFile($configFile, $config);
}


############################################################################
#
#   Name:    List
#
#   Purpose: List the known routers.
#
#   Inputs:  None
#
#   Returns: Nothing
#
############################################################################

sub List () {
    my $config = SNMP::Monitor->Configuration($configFile);

    my($var, $val, $len);
    $len = length("Router");
    while (($var, $val) = each %{$config->{hosts}}) {
	if (length($var) > $len) {
	    $len = length($var);
	}
    }
    my $format = sprintf("%%%ds  %s\n", $len);
    printf("$format\n", "Router  Description\n");
    while (($var, $val) = each %{$config->{hosts}}) {
	printf ($format, $var, $val->{description});
    }
}


############################################################################
#
#   Name:    Stop
#
#   Purpose: Stop the running SNMP::Monitor
#
#   Inputs:  None
#
#   Returns: Nothing
#
############################################################################

{
    my $signo;
    my $signame;

    sub SigNo($) {
	my($sig) = @_;
	if (!$signo) {
	    require Config;
	    if (!defined($Config::Config{sig_name})) {
		die "No signals configured?";
	    }
	    $signo = {};
	    $signame = [];
	    my $name;
	    my $i = 0;
	    foreach $name (split(' ', $Config::Config{sig_name})) {
		$signo->{$name} = $i;
		$signame->[$i] = $name;
		++$i;
	    }
	}
	if (!exists($signo->{$sig})) {
	    die "No such signal: $sig";
	}
	$signo->{$sig};
    }
}

sub CommandOfPid ($) {
    my($pid) = @_;
    my $cmd;
    if ($^O =~ /linux/) {
	$cmd = "ps p $pid 2>&1";
    } elsif($^O =~ /solaris/) {
	$cmd = "ps -fp $pid 2>&1";
    } else {
	die "Unknown operarting system: $^O\n"
	    . "You need to configure the 'CommmandOfPid' function.\n";
    }

    my $line;
    if (open(PID, "$cmd |")) {
	while (defined($line = <PID>)) {
	    if ($line =~ /\d+.*\d+\:\d+\s+(.*)/) {
		return $1;
	    }
	}
    }
}

sub PidOfProc ($) {
    my($proc) = @_;
    my $cmd;
    if ($^O =~ /linux/) {
	$cmd = 'ps axuw';
    } elsif ($^O =~ /solaris/) {
	$cmd = 'ps -ef';
    } else {
	die "Unknown operarting system: $^O\n"
	    . "You need to configure the 'ProcList' function.\n";	
    }

    my $line;
    if (open(PID, "$cmd |")) {
	while (defined($line = <PID>)) {
	    if ($line =~ /\S+\s+(\d+).*\d+\:\d+\s+(.*)/) {
		my $p = $1;
		my $c = $2;
		if ($c =~ /$proc/  &&  $p != $$) {
		    return $p;
		}
	    }
	}
    }
    undef;
}

sub Stop () {
    my $line;
    my $pid;

    if (open(PID, "<$pidFile")  &&  defined($line = <PID>)  &&  close(PID)
	&&  $line =~ /(\d+)/) {
	$pid = $1;
	if (CommandOfPid($pid) !~ /snmpmon/) {
	    undef $pid;
	}
    }

    if (!defined($pid)  &&  !($pid = PidOfProc('snmpmon'))) {
	print STDERR "A process 'snmpmon' is not running.\n";
	return;
    }

    kill SigNo('TERM'), $pid;
}


############################################################################
#
#   Name:    Start
#
#   Purpose: Enter the systems main loop.
#
#   Inputs:  None
#
#   Returns: Nothing
#
############################################################################

sub Start ($) {
    my($detach) = @_;
    my $config = SNMP::Monitor->Configuration($configFile);
    if ($debugging) {
	$config->{debug} = 1;
    }

    if (!defined($detach)  ||  $detach) {
	# Detach from the shell.
	my $pid;
	if (!defined($pid = fork())) {
	    die "Cannot fork(): $!";
	} elsif ($pid) {
	    # This is the parent
	    exit(0);
	}
	if ($^O =~ /linux/) {
	    require "ioctls.ph";
	    if (!open(FILE, ">/dev/tty")) {
		die "Cannot open /dev/tty: $!";
	    }
	    my $status = 1;
	    if (!ioctl(FILE, TIOCNOTTY(), $status)) {
		die "Cannot detach from tty: $!";
	    }
	} elsif ($^O =~ /solaris/) {
	    require POSIX;
	    if (!($pid = POSIX::setsid())) {
		die "setsid: $!";
	    }
	} else {
	    die "Unknown operating system " . $^O
		. ": You need to configure Start()."
	}
	chdir("/");
	if (!open(STDIN, "</dev/null")  ||  !open(STDOUT, ">/dev/null")
	    ||  !open(STDERR, ">/dev/null")) {
	    die "Cannot reopen file handles: $!";
	}
	if (!defined($pid = fork())) {
	    die "Cannot fork(): $!";
	} elsif ($pid) {
	    # This is the parent.
	    exit(0);
	}
    }

    my $monitor = SNMP::Monitor->new($config);

    if (open(PID, ">$pidFile")) { print PID "$$\n"; close(PID); }
    $monitor->Loop();
}


############################################################################
#
#   This is main().
#
############################################################################

$@ = '';
eval {
    my $o = {};

    Getopt::Long::GetOptions($o, 'add=s', 'config=s', 'debug', 'delete=s',
			     'detach!', 'facility', 'help', 'list',
			     'pidfile=s', 'start', 'stop', 'version');

    if (exists($o->{config})) {
	$configFile = $o->{config};
    } elsif (exists($o->{pidfile})) {
	$pidFile = $o->{pidfile};
    } elsif (exists($o->{debug})) {
	$debugging = 1;
    } elsif (exists($o->{facility})) {
	$facility = $o->{facility};
    }

    if (exists($o->{add})) {
	Add($o->{add});
    } elsif (exists($o->{'delete'})) {
	Delete($o->{'delete'});
    } elsif (exists($o->{help})) {
	Usage();
    } elsif (exists($o->{list})) {
	List();
    } elsif (exists($o->{version})) {
	print "\n$VERSION\n";
	exit(0);
    } elsif (exists($o->{start})  ||  (@ARGV > 0  &&  $ARGV[0] eq 'start')) {
	$@ = '';
	eval {
	    require Sys::Syslog;
	    if (defined(&Sys::Syslog::setlogsock)  &&
		defined(&Sys::Syslog::_PATH_LOG)) {
		Sys::Syslog::setlogsock('unix');;
	    }
	    Sys::Syslog::openlog('snmpmon', '', $facility);

	    Start($o->{detach});
	};
	if ($@) {
	    my $errmsg = $@;
	    Sys::Syslog::syslog('crit', "Fatal error: $errmsg\n");
	    my $config = SNMP::Monitor->Configuration($configFile);
	    if ($config) {
		require Mail::Header;
		my $head = Mail::Header->new();
		$head->add("to", $config->{email});
		$head->add("subject", "snmpmon: Critical Alert");
		require Mail::Internet;
		my $mail = Mail::Internet->new([<<"MSG"], Header => $head);

The snmpmon daemon is aborting operation due to a critical condition.
The error message follows:

$errmsg

Please take whatever action appropiate and restart the daemon as soon
as possible.

MSG
		$mail->smtpsend();
	    }
	}
    } elsif (exists($o->{stop})  ||  (@ARGV > 0  &&  $ARGV[0] eq 'stop')) {
	Stop();
    } else {
	Usage();
    }
};

if ($@) {
    die "Fatal error: $@\n";
}

1;


__END__

=head1 NAME

snmpmon - A daemon for monitoring remote hosts via SNMP


=head1 SYNOPSIS

    # Add router <name> to the list of items being monitored
    snmpmon --add <name> [options]

    # Remove router <name> from the list of items being monitored
    snmpmon --delete <name> [options]

    # List all routers being monitored
    snmpmon --list [options]

    # Start the monitor;
    snmpmon --start [options]
    # You might prefer this version for /etc/rc2.d
    snmpmon start
    
    # Stop the monitor
    snmpmon --stop [options]
    # ... and this one for /etc/rc2.d
    snmpmon stop


=head1 DESCRIPTION

The SNMP monitor is a simple tool for monitoring remote routers via SNMP.
Usually it runs in the background, sending SNMP queries to the routers,
logging interface loads or taking action upon interface state changes.
What the program does, depends on the following command line options:


=head2 Adding a router to the list of routers

    snmpmon --add <name>

Adds a new machine to the list of routers being monitored. The I<name>
is a symbolic name, unique within the list. The program will invoke
the I<SNMP::Monitor::Install::AddRouter> method for you which prompts
you a lot of questions so that a raw configuration of the monitor can
be created.

The router list is stored in the configuration file,
~etc_dir~/configuration.


=head2 Removing a router from the list of routers

    snmpmon --delete <name>

Removes the machine I<name> from the list of routers in
~etc_dir~/configuration.


=head2 Printing a list of all routers

    snmpmon --list

This reads a list of all routers from the config file and prints it
to STDOUT.


=head2 Starting the monitor

    snmpmon --start [options]
    snmpmon start [options]

This will start a monitor session; you usually do this when the system
comes up. Available options are in particular

=over 8

=item --debug

Run in debugging mode

=item --config <file>

Read the monitor configuration from <file>, defaults to
C<~etcdir~/configuration>.

=item --facility <f>

Use syslog facility <f> for logging messages; this defaults to ~facility~,
but you can override it in the config file.

=item --nodetach

By default the program will detach from the shell and run in the background.
However, for debugging purposes it is important to suppress this.

=item --pidfile <file>

When the program has detached from the shell, it stores it's PID in the
given file, by default ~pid_file~ (overridable in the config file).

=back


=head2 Stopping the monitor

    snmpmon --stop [options]
    snmpmon stop [options]

Called for shutting the monitor down. The I<pidfile> is used for guessing
the monitor's PID. If such a file doesn't exist or no process with the
given PID is available, the program attempt's to find a running monitor
by looking into the process list.


=head1 FILES

~etc_dir~/configuration		The programs config file.


=head1 AUTHOR AND COPYRIGHT

This program is

    Copyright (C) 1998    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Phone: +49 7123 14887
                          Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<SNMP::Monitor(3)>, L<SNMP(3)>, L<SNMP::Monitor::Install(3)>

EOF

require SNMP::Monitor;
my $config = SNMP::Monitor->Configuration('configuration');

require Config;
$config->{'startperl'} = $Config::Config{'startperl'};
$config->{'startperl'} = $Config::Config{'startperl'}; # Make -w happy ...


$script =~ s/\~(\w+)\~/$config->{$1}/eg;

if (!open(FILE, ">snmpmon")  ||  !print FILE ($script)  ||  !close(FILE)) {
    die "Error while writing snmpmon script: $!";
}
