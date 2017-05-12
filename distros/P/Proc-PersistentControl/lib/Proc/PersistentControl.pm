package Proc::PersistentControl; # -*-perl-*-
#
# Author: Michael Staats 2014
#
# $Id: PersistentControl.pm 742 2015-08-07 13:30:38Z michael $
#

=head1 NAME

Proc::PersistentControl - Start and Control Background Processes ("jobs", process groups)
    
=head1 SYNOPSIS

    use Proc::PersistentControl;

    my $controller = Proc::PersistentControl->new();

    my $Proc =
        $controller->StartProc({ [ timeout => 42, psynctime => 5,
                                   Key => 'Value', ... ] },
                               "runme args");

    my @Procs = $controller->ProcList(['Key', 'Value']);

    my @Procs = $controller->RipeList();

    my $alive = $Proc->IsAlive();

    my $ripe  = $Proc->IsRipe();

    my $info  = $Proc->Info();

    my $info  = $Proc->Reap();

    $Proc->Kill();

=head1 DESCRIPTION

WARNING: This module (and its pod) is beta.

The method that is used by this module is calling for race conditions all
over the place... Since version 1.0 most of these should be found. But there
will still be bugs.    

This module creates background processes and allows to track
them from multiple invocations of a perl program, i. e. not only
from the parent.

This is done in quite a KISS way: Information about background
processes is stored in one directory per started process.

Special care is taken so that killing processes will also kill
all child processes (i. e. grandchildren).

A timeout for the processes can be specified.    

This module works on Unix and Windows. On Windows, Win32, Win32::Process
and Win32::Job is required.

This module is intended to be as simple as possible. It should have as
few other modules as prerequisites as possible, only modules
that are likely to be installed in a "typical" perl installation (i. e.
core modules, or "standard" Win32 modules on Windows). It should be
usable on any Unix with the perl that comes with the OS.    

The intended typical use cases of this module are things like programs
that need to start and control "a few" background processes (something
like max. 10 per minute or so), but consistently over multiple invocations
of the program (like when they are scheduled by cron).
Probably not a busy web server that needs to start hundreds of CGI
processes per second.
    
=head1 The Controller Object, Process objects, and their Methods

=head2 Methods for the controller object
    
=over 4

=item Proc::PersistentControl->new([directory => $dir]);

Creates a controller object using $dir as place to store the persistent
process information. If 'directory' is not specified, a directory
called "ProcPersCtrl" will be created in "/var/tmp/$>" (Unix with /var/tmp),
or in File::Spec->tmpdir() . "/$>" (Unix without /var/tmp), or in
File::Spec->tmpdir() (Windows). (Note that tmpdir() is not tempdir(),
i. e. the directory will always be the same. For certain values
of 'always'.)    

Note that preferring /var/tmp over tmpdir() allows information to survive
a reboot on systems where /tmp is a tmpfs or similar. (This does not mean that
your jobs will survive a reboot (they won't), and also the controller
information might be corrupt if a reboot (or crash, or kill -9) kills your
processes the hard way).
    
=item $controller->StartProc({ [ timeout => 42, BLA => 'bla', ... ] },
    "runme args");

=item $controller->StartProc({ [ timeout => 42, BLA => 'bla', ... ] },
    "runme", "arg1", "arg2", ...);

Start the program "runme" with command line arguments, optionally specifying
a timeout after which the program will be killed. Other key-value pairs in
the options are user defined only and can be retrieved via the Info() and
Reap() methods, and be used to find processes by key-value pairs with the
ProcList() method. Keys must not start with underscore, these are used
internally (but will also be returned by Info() etc).

The program can be a "binary/excutable" that is in the $PATH (%PATH%),
or a "script".
Just try. Unix magic "#!" will also work under Windows (and even more...).

This method returns an object of class Proc::PersistentControl::Proc which
has the methods described further below.    

Since the internal information of the controller is stored in the filesystem,
you can just terminate your program that uses the controller, start a new one
later (giving the same directory to new()) and use all the methods described
below. (But see Reap(), which destroys information).

=item $controller->ProcList(['Key', 'Value'])

Returns a list of Proc::PersistentControl::Proc objects that are
under control of the controller object.
If a Key-Value pair is given, only processes with this Key-Value
pair in their options are returned (see StartProc()).

=item $controller->RipeList()
    
Returns a list of Proc::PersistentControl::Proc objects that are
under control of the controller object and have terminated, i. e.
are ready for reaping.

=back
    
=head2 Methods for process objects

=over 4
    
=item $Proc->IsAlive()
    
Returns true if $Proc is still running.

=item $Proc->IsRipe()

equivalent to "not $Proc->IsAlive()"
    
=item $Proc->Info()

Returns a reference to hash that contains information about a process.

Usage:

    sub type {
	print "$_[0]:\n";
	open(T, $_[0]);
	print while (<T>);
	close(T);
    }

    sub printInfo {
	my $r = shift;
	foreach my $k (keys(%$r)) {
	    my $v = $r->{$k};
	    print "$k=$v\n";
	}
	type($r->{_dir} . '/STDOUT');
	type($r->{_dir} . '/STDERR');
    }

    printInfo($Proc->Info());

=item $Proc->Reap()

Returns the process object's "Info()" information if $Proc->IsRipe().
   
The reaped information will be DESTROY'd after the process
object goes out of scope. So make sure you use/copy the information
before that.
(Reap it and eat it before it gets bad).

=item $Proc->Kill()

Kills the operating system process(es) that belong to $Proc.
Should also kill grandchildren.

=back

=head1 BUGS

The "make test" tests could be more detailed (but check out the
examples, too.)
    
If you use controller objects with the same directory in parallel, be
aware that Reap() will reap anything it can. If two calls to Reap() for
the same process intersect, the result is unpredictable. So just don't
do that, call Reap() only in one of the programs. Other behaviour when
using one directory with more than one controller at the same time
is considered to be a feature.

Using this module might interfere with your code if it also installs
signal handlers, wait()s, etc. So don't do that.

The method to store information about the processes should use a more
structured data format (like Persistent::File or so, but no more pre-reqs
should be added).    
    
=head1 Examples

Examples should be available in the Proc/PersistentControl/example
directory (depending on your installation).

=head1 AUTHOR

Michael Staats, E<lt>michael.staats@gmx.euE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Michael Staats

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
   
=cut 

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Exporter);

$VERSION = '1.4';

use strict;
use File::Path qw(mkpath rmtree); # legacy interface, works with older perls
use File::Spec;
use File::Temp 'tempdir'; # also old behaviour, we need the dir permanently
use POSIX ":sys_wait_h";
use Carp;

BEGIN {
    if ($^O =~ /^MSWin/) {
	require Win32;                  Win32->import();
	require Win32::Process;         Win32::Process->import();
    }
}

######################################################################
# the new() method for the controller object
#
my $_debugfh = undef; # quick and dirty global var...

sub new {
    my $class   = shift;
    my %opthash = @_;

    $opthash{nannyname}  ||= 'ppc-nanny';
    $opthash{closefdmax} ||= 12;
    
    my $self   = { _opts => \%opthash };
    $self->{sdir}    = $opthash{directory};
    if (not $self->{sdir}) {
	if ($^O !~ /^MSWin/) {
	    $self->{sdir} =
		((-d '/var/tmp') ? '/var/tmp' : File::Spec->tmpdir()) .
		"/$>/ProcPersCtrl";
	} else {
	    $self->{sdir} =
		Win32::GetLongPathName(File::Spec->tmpdir()) . "\\ProcPersCtrl";
		#File::Spec->tmpdir() . "\\ProcPersCtrl";
	}
    }

    my $sdir = $self->{sdir};
    eval { mkpath($sdir) unless (-d $sdir); };
    croak "'$sdir' is not a directory and could not mkpath() it: $!\n"
	if (not -d $sdir);

    if ($opthash{debug}) {
	my $file = $sdir . '/debug.out';
	my $size = (stat($file))[7];
	if ($size and $size > 102400) {
	    rename($file, $file . '.old');
	}
	open($_debugfh, '>>', $file) ||
	    carp "Cannot append to $file: $!";
	select((select($_debugfh), $|=1)[0]);
	eval { require Time::HiRes; };
	if ($@) {
	    print $_debugfh "No Time::HiRes ($@), sorry...\n";
	}
    }
    
    my $rdir = $sdir . '/reaped';
    if (-e $rdir and not -d $rdir) {
	carp "'$rdir' exists and is not a directory...\n";
	unlink($rdir);
    }
    if (not -d $rdir) {
	mkpath($rdir) or croak "Could not mkpath('$rdir'): $!\n";
    }
    
    bless $self, $class;
    return $self;
}

sub debug {
    return undef unless $_debugfh;
    my $clf = (caller(1))[3];
    $clf ||=  (caller())[1];

    my $msg = join(' ', @_);
    $msg .= "\n" unless ($msg =~ /\n$/);
    my $ts = $INC{'Time/HiRes.pm'} ? Time::HiRes::time() : time();
    print $_debugfh $ts, ' ', $$, ' ', $clf, ': ', $msg;
    return 1;
}

######################################################################
# system dependent stuff

sub _pid_alive($) {
    my $pid  = shift;

    debug($pid);

    return 0 if (not $pid or $pid <= 0);
    
    if ($^O !~ /^MSWin/) {
	my $ret = kill(0, $pid);
	debug("returning $ret");
	return $ret
    }
    
    # Windows
    my $process;
    if (Win32::Process::Open($process, $pid, 0)) {
	debug("Win32::Process::Open ok");
	my $RC;
	$process->GetExitCode($RC);
	debug("Win32 GetExitCode RC=$RC");
	if ($RC == Win32::Process::STILL_ACTIVE()) {
	    debug("returning 1");
	    return 1;
	}
    }
    debug("returning 0");
    return 0;
}

# Using these two variables looks like a bug: it seems they
# are re-used for new children. But they aren't, the are
# only used in the fork()ed child, and this forks only one
# grandchild.

my $_unix_grandch_pid;
my $_unix_grandch_dir;

sub _unix_intr_sighandler {
    my $sig = shift;
    $SIG{INT}  = 'IGNORE';
    $SIG{QUIT} = 'IGNORE';
    $SIG{TERM} = 'IGNORE';

    if ($_unix_grandch_pid) {
	carp "$0:ProcPersCtrl:$$: Caught SIG$sig, killing '$_unix_grandch_pid'...\n";
	_unix_kill($_unix_grandch_pid); # calls the CHLD handler...
    }
    exit(0);
}

sub _unix_chld_sighandler {
    my $child;
    while (($child = waitpid(-1, WNOHANG)) > 0) {
	my $RC = $? >> 8;
	debug("Child $child died with RC=$RC (my grandchild $_unix_grandch_pid)");
	if ($child == $_unix_grandch_pid) {
	    # this is what we have been waiting for
	    $_unix_grandch_pid = undef;
	    debug("Writing rc and endtime to $_unix_grandch_dir");
	    open(RC, '>', $_unix_grandch_dir . "/RC=$RC") or
		carp "Could not write $_unix_grandch_dir/RC=$RC: $!";
	    close(RC);
	    open(I, '>>', $_unix_grandch_dir . "/info") or
		carp "Could not append to $_unix_grandch_dir/info: $!";
	    print I "_endtime=", time(), "\n";
	    close(I);
	}
    }
    $SIG{CHLD} = \&_unix_chld_sighandler;  # ... sysV
}

sub _unix_spawn {
    my $pdir = shift;
    my $opt  = shift;
    my @cmd  = @_;

    debug("called with $pdir for $cmd[0] ...");
    
    $SIG{CHLD} = 'IGNORE'; # for now
    
    my $childpid = fork();
    croak "Cannot fork(): $!\n" if (not defined $childpid);
    
    if ($childpid == 0) {
	debug("I'm the new child for $opt->{nannyname} $cmd[0] ...");
	# child
	# fill the info directory,
	    
	open(I, '>', $pdir . '/info') or croak "Cannot write '$pdir/info': $!\n";
	my $start = time();
	print I "_starttime=$start\n";
	print I "_cmd=", join(",", map { s/([,\\])/\\$1/g; s/\n/\\n/g; $_ }
			     my @tmp = @cmd), "\n";
	foreach my $o (keys(%$opt)) {
	    my $v = $opt->{$o};
	    $v =~ s/\n/\\n/sg;
	    $v =~ s/\r/\\r/sg;
	    print I "$o=$v\n";
	}
	close(I);

	open(STDIN,  '/dev/null');
	open(STDOUT, '>', $pdir . '/STDOUT') or
	    croak "Cannot write '$pdir/STDOUT': $!\n";
	open(STDERR, '>', $pdir . '/STDERR') or
	    croak "Cannot write '$pdir/STDERR': $!\n";

	if ($opt->{_closefdmax} >= 3) {
	    for (my $fd = 3; $fd <= $opt->{_closefdmax}; $fd++) {
		POSIX::close($fd)
		    unless ($_debugfh and $fd == fileno($_debugfh));
	    }
	}
	
	$_unix_grandch_dir = $pdir;

	$0 = $opt->{nannyname} . ' ' . join(' ', @cmd);
	
	$SIG{CHLD} = \&_unix_chld_sighandler;
	
	$_unix_grandch_pid = fork(); # fork again for grandchild
	if ($_unix_grandch_pid == 0) {
	    debug("I'm the new grandchild for $cmd[0] ...");
	    #grandchild
	    $SIG{CHLD} = 'DEFAULT';
	    setpgrp(0, 0);
	    # Sometimes (esp. on AIX) it seems that the following exec
	    # can terminate before $_unix_grandch_pid is set in the
	    # parent, which is bad since the sighandler checks it...
	    # so wait for the pid file
	    my $psynctime = $opt->{psynctime} || 10;
	    my $waited = 0;
	    debug("waiting max $psynctime s for 'start' file");
	    for (my $nwait = 1; $nwait < 10 * $psynctime; $nwait++) {
		last if (-e $pdir . "/pstart");
		$waited++;
		select(undef, undef, undef, 0.1);
	    }
	    unlink($pdir . "/pstart");
	    debug("waited " . (0.1 * $waited) . " s for 'start' file");
	    open(STA, '>', $pdir . "/start"); print STA time(), "\n"; close(STA);
	    if (not exec(@cmd)) {
		open(FA, '>', $pdir . "/fail"); print FA "$!\n"; close(FA);
		unlink($pdir . "/start");
		croak "Could not exec(", join(', ', @cmd), ")\n";
	    }
	}
	croak "Cannot fork(): $!\n" if (not defined $_unix_grandch_pid);

	$SIG{INT}  = \&_unix_term_sighandler;
	$SIG{TERM} = \&_unix_term_sighandler;
	$SIG{QUIT} = \&_unix_term_sighandler;

	open(PID, '>', $pdir . "/pid=$_unix_grandch_pid"); close(PID);	
	open(STA, '>', $pdir . "/pstart"); print STA time(), "\n"; close(STA);
	debug("child says: \$_unix_grandch_pid = $_unix_grandch_pid " .
	      "for $cmd[0] ...");
	
	my $timeout = $opt->{timeout} ? int($opt->{timeout}) : 86400000;
	my $maxtime = time + $timeout;

	# $_unix_grandch_pid will be set to undef in the sighandler...
	# well, sometimes it seems it doesn't (some perls on some AIX, eg.)
	# so we also test with kill(0, ...)
	debug("Before wait loop for $cmd[0] ...");
	while ($_unix_grandch_pid and kill(0, $_unix_grandch_pid) and time < $maxtime) {
	    my $remain = $maxtime - time;
	    # check each min to avoid race condition, see below
	    $remain = 60 if ($remain > 60); 
	    debug("Waiting for grandchild... sleep($remain) at "
		  . scalar(localtime));
	    sleep($remain) # will be interrupted by SIGCHLD, this is what we want
		           # but if the sighandler jumps in exactly HERE
		           # we still have a race cond.
		           # That's why we sleep at most 60 s
		if ($_unix_grandch_pid); # just to be sure...
	}
	debug("after wait loop for $cmd[0] ... at " . scalar(localtime));
	if ($_unix_grandch_pid and kill(0, $_unix_grandch_pid)) {
	    carp "ProcPersCtrl:$$: Child $_unix_grandch_pid is alive after $timeout s, killing it\n";
	    open(I, '>>', $pdir . '/info') or
		croak "Cannot append to '$pdir/info': $!\n";
	    print I "_timed_out=1\n";
	    close(I);
	    _unix_kill($_unix_grandch_pid);
	}
	exit(0);
    }
    # parent
    debug("parent says: child $childpid");
    return $childpid;
}

sub _win_spawn {
    my $pdir = shift;
    my $opt = shift;
    my @cmd = @_;

    # find the helper script
    my $module_path = $INC{'Proc/PersistentControl.pm'};
    $module_path =~ s|(.*)[/\\].*|$1|;
    my $helper = '"' . $module_path . '/PersistentControl/winjob.pl' . '"';

    # construct args the DOS way, hopefully...
    my $Arg = 'perl ' . $helper . " ";
    $Arg .= ' -d ' if ($_debugfh);
    my $timeout = $opt->{timeout} ? $opt->{timeout} : 0;
    $Arg .= " -t $timeout " if ($timeout > 0);
    # Try to escape "" in cmd.
    # Will work in simple cases...
    s/\"/\\\"/g foreach (@cmd);
    # contruct final command
    $Arg .= "\"$pdir\" \"" . join('" "', @cmd) . '"';

    debug("perl \$Arg = '$Arg'");

    # launch windows process (helper script, in background)
    my $process;
    Win32::Process::Create($process, $^X, $Arg, 0, 0, '.') or
	croak "Cannot Win32::Process::Create(): $!\n";

    my $childpid = $process->GetProcessID();
    
    debug("\$childpid = $childpid");
    
    open(I, '>', $pdir . '/info') or croak "Cannot write '$pdir/info': $!\n";
    my $start = time();
    print I "_starttime=$start\n";
    print I "_cmd=", join(",", map { s/([,\\])/\\$1/g; s/\n/\\n/g; $_ }
			  my @tmp = @cmd), "\n";
    foreach my $o (keys(%$opt)) {
	my $v = $opt->{$o};
	$v =~ s/\n/\\n/sg;
	$v =~ s/\r/\\r/sg;
	print I "$o=$v\n";
    }
    close(I);
    
    return $childpid;
}

sub _unix_kill {
    my @pids = @_;
    my @ret;
    foreach my $p (@pids) {
	debug("killing $p");
	# first the process group if we have one
	kill(-15, $p) and
	    (select(undef, undef, undef, 0.2), kill  -3, $p) and
	    (select(undef, undef, undef, 0.4), kill  -9, $p);
	# then a single process
	kill( 15, $p) and
	    (select(undef, undef, undef, 0.2), kill   3, $p) and
	    (select(undef, undef, undef, 0.4), kill   9, $p);
	push(@ret, $p) unless (kill(0, $p));
    }
    return @ret;
}

sub _win_kill {
    my @pids = @_;
    foreach my $p (@pids) {
	my $exitcode = 130;
	debug("killing $p");
	Win32::Process::KillProcess($p, $exitcode);
    }
    return @pids;
}

######################################################################
# internal functions

sub _UID_alive($$) {
    my $sdir = shift;
    my $UID  = shift;

    my $pdir = $sdir . '/' . $UID;
    my $pid;
    my $RC;
    
    opendir(D, $pdir);
    while ($_ = readdir(D)) {
	$pid = $1 if (m/^pid=(\d+)/);
	$RC  = $1 if (m/^RC=(\d+)/);
    }
    closedir(D);    
    return defined($RC) ? 0 : _pid_alive($pid);
}

sub _get_all_uids {
    my $sdir = shift;
    my @ret;

    opendir(D, $sdir) or croak "Cannot opendir '$sdir': $!\n";
    while (my $d = readdir(D)) {
	if ($d =~ m/^PPC-/ and -f "$sdir/$d/info") {
	    push(@ret, $d);
	    debug("found job info dir \"$d\"");
	}
    }
    closedir(D);
    debug("returning " . join(' ', @ret));
    return @ret;
}

sub _get_pid_by_uid {
    my $sdir = shift;
    my $UID  = shift;

    debug("in $sdir $UID");
    my $pdir = $sdir . '/' . $UID;
    my $pid;
    if (opendir(DD, $pdir)) {
	while (my $f = readdir(DD)) {
	    debug("read $f");
	    $pid = $1 if ($f =~ m/pid=(\d+)$/);
	}
	closedir(DD);
	carp "Could not find pid file in $pdir\n" unless ($pid);
    } else {
	carp "Can't opendir $pdir for $UID\n";
    }
    debug("returning $pid");
    return ($pid);
}

sub _get_info_by_uid {
    my $sdir = shift;
    my $UID = shift;
    
    my %ret;

    my $pdir     = $sdir  . '/' . $UID;
    my $infofile = $pdir  . '/info';
    
    open(I, $infofile) or return undef;

    while (<I>) {
	chomp;
	$ret{$1} = $2 if (m/([^=]+)=(.*)/);
    }
    close(I);
    
    $ret{_dir} = $pdir;
    $ret{_dir} =~ s|/|\\|g if ($^O =~ /^MSWin/); # cosmetics, also works without

    my $rctryt = $ret{psynctime} || 10;
    
    my $pidalive = 0;
    debug("waiting max $rctryt s for 'RC' file");
    for (my $ntry = 0; $ntry < 10 * $rctryt; $ntry++, select(undef, undef, undef, 0.1)) {
	# try a few times, just in case this function is called
	# after the process has terminated but before RC could be written
	# nevertheless it's still a race condition...
	debug("try " . ($ntry + 1) . " to get RC in $pdir");
	opendir(D, $pdir) or croak "cannot opendir $pdir: $!";
	while ($_ = readdir(D)) {
	    debug("readdir() gives: $_");
	    $ret{_pid} = $1 if (m/^pid=(\d+)/);
	    $ret{_RC}  = $1 if (m/^RC=(\d+)/);
	}
	closedir(D);
	last if (exists($ret{_RC})); # found ret code, fine
	if ($ret{_pid}) {
	    $pidalive = _pid_alive($ret{_pid});
	    last if ($pidalive); # still alive, also ok
	}
	debug("No RC found in $pdir although process is dead...");
    }
    
    if (exists($ret{_RC})) {
	$ret{_alive} = 0;
    } else {
	if ($pidalive) {
	    $ret{_alive} = 1;
	} else {
	    # no RC and not alive => terminated the hard way...
	    $ret{_alive} = 0;
	    debug("Could not determine RC, setting it to 130");
	    carp "Could not determine return code of job in $pdir, " .
		"setting it to 130";
	    $ret{_RC} = 130;
	    open(RC, '>', $pdir . '/RC=130'); close(RC);
	}
    }
        
    no warnings "uninitialized";
    debug("\$ret{_RC} = $ret{_RC} \$ret{_dir} = $ret{_dir} " .
	  "\$ret{_pid} = $ret{_pid} \$ret{TAG} = $ret{TAG}");

    return \%ret;
}

sub _make_uid_list {
    # return a uid list for @in IDs
    my $sdir = shift;
    my @in = @_;
    my @out;

    debug("in: ", join('-', @in));

    # empty input, return all UIDS
    if (not $in[0]) {
	@out = _get_all_uids($sdir);
    } else {
	# otherwise: return UIDS for input ids
	foreach my $UID (@in) {
	    my $pdir = $sdir . '/' . $UID;
	    push(@out, $UID) if (-f $pdir . '/info');
	}
    }
    debug("out: ", join('-', @out));
    return @out;
}

######################################################################
# Proc::PersistentControl object methods, actually all of them return
# objects of class Proc::PersistentControl::Proc

sub StartProc {
    # this is one of the "new" method for 
    # Proc::PersistentControl::Proc
    
    my $self = shift;
    my $opt  = shift;
    my @cmd  = @_;

    my $sdir = $self->{sdir};

    my $w = "Invalid option to StartProc(): Option should not";
    foreach my $o (keys(%$opt)) {
	carp "$w contain '='"    if ($o =~ m/=/);
	carp "$w start with '_'" if ($o =~ m/^_/);
    }
    
    debug("command '" . join(' ', @cmd) . "'");

    # create a directory for process information
    my $psd = tempdir('PPC-XXXX', DIR => $sdir);
    croak "Cannot make tempdir: $!" unless ($psd and -d $psd);

    $psd =~ m/.*(PPC-.*)/;
    my $UID = $1;

    $opt->{_PPCUID}       = $UID;
    $opt->{nannyname}   ||= $self->{_opts}->{nannyname};
    $opt->{_closefdmax}   = $self->{_opts}->{closefdmax};
    
    ($^O !~ /^MSWin/) ?
	_unix_spawn($psd, $opt, @cmd) :
	_win_spawn( $psd, $opt, @cmd);

    my $Proc = {
	_PPCUID => $UID,
	_controller => $self
    };

    my $psynctime = $opt->{psynctime} || 10;
    my $waited = 0;
    for (my $nwait = 1; $nwait < 10 * $psynctime; $nwait++) {
	last if (-e $psd . "/start" or -e $psd . "/fail");
	$waited++;
	select(undef, undef, undef, 0.1);
    }
    debug("waited " . (0.1 * $waited) . " s for 'start/fail' file");
    if (-e $psd . "/fail") {
	open(FA, $psd . "/fail") or die "Cannot read $psd/fail: $!\n";
	my $st = <FA>;
	close(FA);
	carp "StartProc could not start child process $cmd[0]: $st";
	return undef;
    } elsif (-e $psd . "/start") {
	bless $Proc, 'Proc::PersistentControl::Proc';
	debug("returning Proc object for $UID, pid file " .
	      (glob($psd . '/pid=*'))[0]);
	return $Proc;
    } else {
	carp "StartProc could not start child process after " .
	    (0.1 * $waited) . " s\n";
	return undef;
    }
}

sub ProcList {
    # this is also a "new" method for 
    # Proc::PersistentControl::Proc
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    
    my @ret;

    debug("called from " . join('-', caller()));
    
    my @uidlist = _make_uid_list($self->{sdir});
    
    UID: foreach my $UID (@uidlist) {
	my $i = _get_info_by_uid($self->{sdir}, $UID);
	next UID unless ($i);
	next UID if ($key and $i->{$key} ne $val);
	
	my $Proc = {
	    _PPCUID => $UID,
	    _controller => $self
	};
	bless $Proc, 'Proc::PersistentControl::Proc';
	push(@ret, $Proc);
    }
    return(@ret);
}

sub RipeList {
    # another "new" method for 
    # Proc::PersistentControl::Proc
    
    my $self       = shift;
    my @ret;

    debug("called from " . join('-', caller()));
    
    my @uidlist = _make_uid_list($self->{sdir});

    foreach my $UID (@uidlist) {
	debug("checking $UID");
	if (not _UID_alive($self->{sdir}, $UID)) {
	    my $Proc = {
		_PPCUID => $UID,
		_controller => $self
	    };
	    bless $Proc, 'Proc::PersistentControl::Proc';
	    push(@ret, $Proc);
	    debug("$UID not alive, ready for reaping");
	}
    }
    return(@ret);
}

######################################################################
######################################################################

package Proc::PersistentControl::Proc;
use File::Copy;
use File::Path qw(mkpath rmtree); # legacy interface, works with older perls
use Carp;

sub _getUID {
    my $self = shift;
    return $self->{_PPCUID};
}

sub Kill {
    my $self = shift;

    Proc::PersistentControl::debug("called from " . join('-', caller()));
    
    return undef unless (Proc::PersistentControl::_UID_alive(
			     $self->{_controller}->{sdir},
			     $self->{_PPCUID}));

    my $pid = Proc::PersistentControl::_get_pid_by_uid(
	$self->{_controller}->{sdir},
	$self->{_PPCUID});
	
    my @ret = ($^O !~ /^MSWin/) ?
	Proc::PersistentControl::_unix_kill(($pid)) :
	Proc::PersistentControl::_win_kill( ($pid));

    # wait max 1 sec until process has finished and info is written
    for (my $nwait = 0; $nwait < 10; $nwait++) {
	last if (not $self->IsAlive());
	Proc::PersistentControl::debug("Process not dead after Kill() ($nwait)...");
	select(undef, undef, undef, 0.1);
    }
    carp "Something is strange, Kill()ed process seems to be still alive..."
	if ($self->IsAlive());
    
    return $ret[0];
}

sub Info {
    my $self = shift;

    Proc::PersistentControl::debug("called from " . join('-', caller()));
    
    return Proc::PersistentControl::_get_info_by_uid(
	$self->{_controller}->{sdir},
	$self->{_PPCUID});
}

sub IsAlive {
    my $self = shift;
    
    return Proc::PersistentControl::_UID_alive(
	$self->{_controller}->{sdir},
	$self->{_PPCUID});
}

sub IsRipe {
    my $self = shift;
    return not $self->IsAlive();
}

sub Reap {
    my $self = shift;

    Proc::PersistentControl::debug("called from " . join('-', caller()));
    
    return undef unless ($self->IsRipe());

    my $sdir = $self->{_controller}->{sdir};
    my $UID  = $self->{_PPCUID};
    
    my $source = $sdir . '/' . $UID;
    my $target = $sdir . '/reaped/' . $UID;

    if (not -d $target) {
	rename($source, $target) or
	move($source, $target) or
	    # sometimes (on windows) the dir seems to be "locked"
	    # also after process termination etc.
	    (Proc::PersistentControl::debug("rename/1st move($source, $target) failed, trying again"),
	     select(undef, undef, undef, 0.2),
	     move($source, $target)) or
	     (Proc::PersistentControl::debug("2nd move($source, $target) failed, trying again"),
	      select(undef, undef, undef, 0.8),
	      move($source, $target)) or
	      (Proc::PersistentControl::debug("3rd move($source, $target) failed"));
	# do not check return value of move
	# this is unreliable, maybe (on windows...)
	carp "Cannot move('$source', '$target'): $!\n" unless (-d $target);
    } else {
	### Reap called twice???
	carp "Reap: '$target' already exists, Reap() called twice?\n"
    }
    return Proc::PersistentControl::_get_info_by_uid($sdir . '/reaped', $UID);
}

######################################################################
sub DESTROY {
    my $self = shift;

    my $pdir = $self->{_controller}->{sdir} . '/reaped/' . $self->{_PPCUID};

    if (-d $pdir) {
	rmtree($pdir) or
	    carp "Could not rmtree($pdir): $!";
    }
    return 1;
}

1;
