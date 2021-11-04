#+##############################################################################
#                                                                              #
# File: No/Worries/Proc.pm                                                     #
#                                                                              #
# Description: process handling without worries                                #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Proc;
use strict;
use warnings;
use 5.005; # need the four-argument form of substr()
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.26 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Config qw(%Config);
use IO::Select qw();
use No::Worries qw($_IntegerRegexp $_NumberRegexp);
use No::Worries::Die qw(dief);
use No::Worries::Dir qw(dir_change);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate validate_with :types);
use POSIX qw(:sys_wait_h :errno_h setsid);
use Time::HiRes qw();

#
# global variables
#

our(@SigName, $Transient);

#
# check a command to be executed
#

sub _chk_cmd (@) {
    my(@cmd) = @_;
    my($path);

    if ($cmd[0] =~ /\//) {
        dief("invalid command: %s", $cmd[0]) unless -f $cmd[0] and -x _;
    } else {
        $path = $ENV{PATH} || "/usr/bin:/usr/sbin:/bin:/sbin";
        foreach my $dir (split(/:/, $path)) {
            next unless length($dir) and -d $dir;
            next unless -f "$dir/$cmd[0]" and -x _;
            $cmd[0] = "$dir/$cmd[0]";
            last;
        }
        dief("command not found: %s", $cmd[0]) unless $cmd[0] =~ /\//;
    }
    return(\@cmd);
}

#
# definition of the process structure
#

my $nbre = "(\\d+\\.)?\\d+"; # fractional number pattern
my $ksre = "([A-Z]+\\/${nbre}\\s+)*[A-Z]+\\/${nbre}"; # kill spec. pattern

my %proc_structure = (
    # public
    command => { optional => 0, type => ARRAYREF },
    pid     => { optional => 0, type => SCALAR, regex => $_IntegerRegexp },
    start   => { optional => 0, type => SCALAR, regex => $_NumberRegexp },
    stop    => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
    status  => { optional => 1, type => SCALAR, regex => qr/^-?\d+$/ },
    timeout => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
    # private
    kill    => { optional => 1, type => SCALAR, regex => qr/^${ksre}$/ },
    maxtime => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
    fhin    => { optional => 1, type => GLOBREF },
    fhout   => { optional => 1, type => GLOBREF },
    fherr   => { optional => 1, type => GLOBREF },
    bufin   => { optional => 1, type => SCALAR },
    cbout   => { optional => 1, type => CODEREF },
    cberr   => { optional => 1, type => CODEREF },
);

sub _chk_proc ($) {
    my($proc) = @_;

    validate_with(
        params  => $proc,
        spec    => \%proc_structure,
        on_fail => sub { dief("invalid process structure: %s", $_[0]) },
    );
    return(); # so that validate_with() is called in void context
}

#
# close a file handle used for IPC
#

sub _close ($$$$) {
    my($proc, $fh, $what, $ios) = @_;

    $ios->remove($fh) if $ios;
    close($fh) or dief("cannot close(): %s", $!);
    delete($proc->{"fh$what"});
    delete($proc->{"cb$what"});
}

#
# try to read from a dead process in case we called _is_alive() on it
# before all its output pipes got emptied...
#

sub _read_zombie ($$$) {
    my($proc, $iosr, $iosw) = @_;
    my($fh, $buf, $done);

    foreach my $what (qw(in)) {
        next unless $proc->{"fh$what"} and $proc->{"cb$what"};
        $fh = $proc->{"fh$what"};
        # no write, simply close
        _close($proc, $fh, $what, $iosw);
    }
    foreach my $what (qw(out err)) {
        next unless $proc->{"fh$what"} and $proc->{"cb$what"};
        $fh = $proc->{"fh$what"};
        # read until EOF then close
        $done = 1;
        while ($done) {
            last if $iosr and not grep($fh eq $_, $iosr->can_read(1));
            $buf = "";
            $done = sysread($fh, $buf, 8192);
            dief("cannot sysread(): %s", $!) unless defined($done);
            $proc->{"cb$what"}($proc, $buf);
        }
        _close($proc, $fh, $what, $iosr);
    }
}

#
# check if a process is alive, record its status if not
#

sub _is_alive ($$$) {
    my($proc, $iosr, $iosw) = @_;

    # check if it recently died
    if (waitpid($proc->{pid}, WNOHANG) == $proc->{pid}) {
        $proc->{status} = $?;
        $proc->{stop} = Time::HiRes::time();
        delete($proc->{maxtime});
        delete($proc->{kill});
        _read_zombie($proc, $iosr, $iosw);
        return(0); # no
    }
    # check if we can kill it
    if (kill(0, $proc->{pid}) or $! == EPERM) {
        return(1); # yes
    }
    # ooops
    return(); # don't know
}

#
# prepare I/O before creating a process
#

sub _prepare_stdin ($$) {
    my($proc, $stdin) = @_;
    my($ref, $rdrin, $wrtin);

    return() unless defined($stdin);
    $ref = ref($stdin);
    if ($ref eq "") {
        if ($stdin eq "") {
            dief("unexpected stdin: empty string");
        } else {
            ## no critic 'InputOutput::RequireBriefOpen'
            open($rdrin, "<", $stdin)
                or dief("cannot open(<, %s): %s", $stdin, $!);
        }
    } elsif ($ref eq "SCALAR") {
        pipe($rdrin, $wrtin)
            or dief("cannot pipe(): %s", $!);
        $proc->{fhin} = $wrtin;
        $proc->{bufin} = ${ $stdin };
    } else {
        dief("unexpected stdin: ref(%s)", $ref);
    }
    return($rdrin, $wrtin);
}

sub _prepare_stdout ($$) {
    my($proc, $stdout) = @_;
    my($ref, $rdrout, $wrtout);

    return() unless defined($stdout);
    $ref = ref($stdout);
    if ($ref eq "") {
        if ($stdout eq "") {
            dief("unexpected stdout: empty string");
        } else {
            ## no critic 'InputOutput::RequireBriefOpen'
            open($wrtout, ">", $stdout)
                or dief("cannot open(>, %s): %s", $stdout, $!);
        }
    } elsif ($ref eq "CODE" or $ref eq "SCALAR") {
        pipe($rdrout, $wrtout)
            or dief("cannot pipe(): %s", $!);
        $proc->{fhout} = $rdrout;
        if ($ref eq "CODE") {
            $proc->{cbout} = $stdout;
        } else {
            ${ $stdout } = "";
            $proc->{cbout} = sub {
                my($_proc, $_buf) = @_;
                ${ $stdout } .= $_buf;
            };
        }
    } else {
        dief("unexpected stdout: ref(%s)", $ref);
    }
    return($rdrout, $wrtout);
}

sub _prepare_stderr ($$) {
    my($proc, $stderr) = @_;
    my($ref, $rdrerr, $wrterr, $merge);

    return() unless defined($stderr);
    $ref = ref($stderr);
    if ($ref eq "") {
        if ($stderr eq "") {
            # special case: stderr will be merged with stdout
            $merge = 1;
        } else {
            ## no critic 'InputOutput::RequireBriefOpen'
            open($wrterr, ">", $stderr)
                or dief("cannot open(>, %s): %s", $stderr, $!);
        }
    } elsif ($ref eq "CODE" or $ref eq "SCALAR") {
        pipe($rdrerr, $wrterr)
            or dief("cannot pipe(): %s", $!);
        $proc->{fherr} = $rdrerr;
        if ($ref eq "CODE") {
            $proc->{cberr} = $stderr;
        } else {
            ${ $stderr } = "";
            $proc->{cberr} = sub {
                my($_proc, $_buf) = @_;
                ${ $stderr } .= $_buf;
            };
        }
    } else {
        dief("unexpected stderr: ref(%s)", $ref);
    }
    return($rdrerr, $wrterr, $merge);
}

#
# redirect I/O after creating a process
#

sub _redirect_io ($$$$) {
    my($rdrin, $wrtout, $wrterr, $merge) = @_;
    my($fd);

    # handle stdin
    if ($rdrin) {
        $fd = fileno($rdrin);
        if (fileno(*STDIN) != $fd) {
            open(*STDIN, "<&=$fd")
                or dief("cannot redirect stdin: %s", $!);
        }
    }
    # handle stdout
    if ($wrtout) {
        $fd = fileno($wrtout);
        if (fileno(*STDOUT) != $fd) {
            open(*STDOUT, ">&=$fd")
                or dief("cannot redirect stdout: %s", $!);
        }
    }
    # handle stderr
    if ($wrterr or $merge) {
        $fd = $merge ? fileno(*STDOUT) : fileno($wrterr);
        if (fileno(*STDERR) != $fd) {
            open(*STDERR, ">&=$fd")
                or dief("cannot redirect stderr: %s", $!);
        }
    }
}

#
# fork a new process, setup its environment and exec() the command
#

my %proc_create_options = (
    command => { optional => 0, type => ARRAYREF },
    cwd     => { optional => 1, type => SCALAR },
    timeout => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
    kill    => { optional => 1, type => SCALAR, regex => qr/^${ksre}$/ },
    stdin   => { optional => 1, type => SCALAR | SCALARREF },
    stdout  => { optional => 1, type => SCALAR | SCALARREF | CODEREF },
    stderr  => { optional => 1, type => SCALAR | SCALARREF | CODEREF },
);

sub proc_create (@) {
    my(%option, %proc, $merge);
    my($rdrin, $wrtin, $rdrout, $wrtout, $rdrerr, $wrterr);

    #
    # preparation
    #

    %option = validate(@_, \%proc_create_options);
    $proc{command} = _chk_cmd(@{ $option{command} });
    # check the "current working directory" option
    if (defined($option{cwd})) {
        dief("invalid directory: %s", $option{cwd}) unless -d $option{cwd};
    }
    # prepare I/O
    ($rdrin, $wrtin) = _prepare_stdin(\%proc, $option{stdin});
    ($rdrout, $wrtout) = _prepare_stdout(\%proc, $option{stdout});
    ($rdrerr, $wrterr, $merge) = _prepare_stderr(\%proc, $option{stderr});
    # fork
    $proc{pid} = fork();
    dief("cannot fork(): %s", $!) unless defined($proc{pid});

    #
    # handle the child
    #

    unless ($proc{pid}) {
        # we are about to exec() or die()
        $Transient = 1;
        # handle the "current working directory"
        dir_change($option{cwd}) if defined($option{cwd});
        # make sure the STD* file handles are "normal"
        foreach my $glob (*STDIN, *STDOUT, *STDERR) {
            next unless tied($glob);
            no warnings qw(untie);  ## no critic 'ProhibitNoWarnings'
            untie($glob);
        }
        # handle the pipe ends to close
        foreach my $fh ($wrtin, $rdrout, $rdrerr) {
            next unless $fh;
            close($fh) or dief("cannot close pipe: %s", $!);
        }
        # redirect I/O
        _redirect_io($rdrin, $wrtout, $wrterr, $merge);
        # execute the command
        exec({ $proc{command}[0] } @{ $proc{command} })
            or dief("cannot execute %s: %s", $proc{command}[0], $!);
        exit(-1);
    }

    #
    # handle the father
    #

    # record the "start" time
    $proc{start} = Time::HiRes::time();
    # record the maximum running time
    if (defined($option{timeout})) {
        $proc{maxtime} = $proc{start} + $option{timeout};
    }
    # record the kill specification
    $proc{kill} = $option{kill} if $option{kill};
    # handle the pipe ends to close
    foreach my $fh ($rdrin, $wrtout, $wrterr) {
        next unless $fh;
        close($fh) or dief("cannot close pipe: %s", $!);
    }
    # so far so good
    return(\%proc);
}

#
# terminate a process
#

my %proc_terminate_options = (
    kill  => { optional => 1, type => SCALAR, regex => qr/^${ksre}$/ },
    _iosr => { optional => 1, type => UNDEF|OBJECT },
    _iosw => { optional => 1, type => UNDEF|OBJECT },
);

sub proc_terminate ($@) {
    my($proc, %option, $pid, $sig, $grace, $maxtime);

    # setup
    $proc = shift(@_);
    if (ref($proc) eq "") {
        dief("unexpected pid: %s", $proc) unless $proc =~ /^\d+$/;
        $proc = { pid => $proc };
    } elsif (ref($proc) eq "HASH") {
        _chk_proc($proc);
    } else {
        dief("unexpected process: %s", $proc);
    }
    %option = validate(@_, \%proc_terminate_options) if @_;
    $option{kill} ||= $proc->{kill} || "TERM/1 INT/1 QUIT/1";
    $pid = $proc->{pid};
    # gentle kill
    foreach my $spec (split(/\s+/, $option{kill})) {
        if ($spec =~ /^([A-Z]+)\/(${nbre})$/) {
            ($sig, $grace) = ($1, $2);
        } else {
            dief("unexpected kill specification: %s", $spec);
        }
        unless (kill($sig, $pid)) {
            dief("cannot kill(%s, %d): %s", $sig, $pid, $!) unless $! == ESRCH;
        }
        $maxtime = Time::HiRes::time() + $grace;
        while (Time::HiRes::time() < $maxtime) {
            return unless _is_alive($proc, $option{_iosr}, $option{_iosw});
            Time::HiRes::sleep(0.01);
        }
        return unless _is_alive($proc, $option{_iosr}, $option{_iosw});
    }
    # hard kill
    $sig = "KILL";
    unless (kill($sig, $pid)) {
        dief("cannot kill(%s, %d): %s", $sig, $pid, $!) unless $! == ESRCH;
    }
}

#
# setup monitoring
#

sub _monitor_setup ($) {
    my($procs) = @_;
    my(%process, %map, $iosr, $iosw, $fh);

    # store the processes to monitor in a hash
    foreach my $proc (@{ $procs }) {
        _chk_proc($proc);
        $process{$proc->{pid}} = $proc;
    }
    # record the file handles to monitor
    $iosr = IO::Select->new();
    $iosw = IO::Select->new();
    foreach my $proc (values(%process)) {
        foreach my $what (qw(in out err)) {
            $fh = $proc->{"fh$what"};
            next unless $fh;
            if ($what eq "in") {
                $iosw->add($fh);
            } else {
                $iosr->add($fh);
            }
            $map{"$fh"} = [ $proc->{pid}, $what ];
        }
    }
    $iosr = undef unless $iosr->count();
    $iosw = undef unless $iosw->count();
    return(\%process, \%map, $iosr, $iosw);
}

#
# monitor I/O
#

sub _monitor_reading ($$$$$) {
    my($process, $map, $iosr, $bufsize, $timeout) = @_;
    my($buf, $done, $proc, $what);

    foreach my $fh ($iosr->can_read($timeout)) {
        $timeout = 0;
        $buf = "";
        $done = sysread($fh, $buf, $bufsize);
        dief("cannot sysread(): %s", $!) unless defined($done);
        $proc = $process->{$map->{"$fh"}[0]};
        $what = $map->{"$fh"}[1];
        $proc->{"cb$what"}($proc, $buf);
        unless ($done) {
            _close($proc, $fh, $what, $iosr);
        }
    }
    return($timeout);
}

sub _monitor_writing ($$$$$) {
    my($process, $map, $iosw, $bufsize, $timeout) = @_;
    my($buf, $done, $proc, $what);

    foreach my $fh ($iosw->can_write($timeout)) {
        $timeout = 0;
        $proc = $process->{$map->{"$fh"}[0]};
        $what = $map->{"$fh"}[1];
        $buf = $proc->{"buf$what"};
        if (length($buf)) {
            $done = syswrite($fh, $buf, length($buf));
            dief("cannot syswrite(): %s", $!) unless defined($done);
            substr($proc->{"buf$what"}, 0, $done, "");
        } else {
            _close($proc, $fh, $what, $iosw);
        }
    }
    return($timeout);
}

#
# monitor termination (death and timeout)
#

sub _monitor_termination ($$$$) {
    my($process, $iosr, $iosw, $timeout) = @_;
    my($now);

    # check if some processes finished
    foreach my $proc (grep(!defined($_->{status}), values(%{ $process }))) {
        next if _is_alive($proc, $iosr, $iosw);
        $timeout = 0;
    }
    # check if some processes timed out
    $now = Time::HiRes::time();
    foreach my $proc (grep($_->{maxtime}, values(%{ $process }))) {
        next unless $now > $proc->{maxtime};
        $timeout = 0;
        delete($proc->{maxtime});
        $proc->{timeout} = $now;
        proc_terminate($proc, _iosr => $iosr, _iosw => $iosw);
    }
    return($timeout);
}

#
# monitor one or more processes
#

my %proc_monitor_options = (
    timeout => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
    bufsize => { optional => 1, type => SCALAR, regex => $_IntegerRegexp },
    deaths  => { optional => 1, type => SCALAR, regex => $_IntegerRegexp },
);

sub proc_monitor ($@) {
    my($procs, %option, $process, $map, $iosr, $iosw);
    my($maxtime, $timeout, $zombies);

    #
    # preparation
    #

    $procs = shift(@_);
    if (ref($procs) eq "HASH") {
        $procs = [ $procs ];
    } elsif (ref($procs) ne "ARRAY") {
        dief("unexpected processes: %s", $procs);
    }
    %option = validate(@_, \%proc_monitor_options) if @_;
    $option{bufsize} ||= 8192;
    ($process, $map, $iosr, $iosw) = _monitor_setup($procs);
    # count the number of processes which are already dead
    $zombies = grep(defined($_->{status}), values(%{ $process }));

    #
    # work
    #

    $maxtime = Time::HiRes::time() + $option{timeout}
        if defined($option{timeout});
    while ($iosr or $iosw
           or grep(!defined($_->{status}), values(%{ $process }))) {
        $timeout = 0.01;
        # read what can be read
        $timeout = _monitor_reading($process, $map, $iosr, $option{bufsize},
                                    $timeout) if $iosr;
        # write what can be written
        $timeout = _monitor_writing($process, $map, $iosw, $option{bufsize},
                                    $timeout) if $iosw;
        # check if some processes finished or timed out
        $timeout = _monitor_termination($process, $iosr, $iosw, $timeout);
        # or if we timed out
        last if $maxtime and Time::HiRes::time() > $maxtime;
        # or if enough processes died
        last if $option{deaths}
            and grep(defined($_->{status}), values(%{ $process }))
                >= $zombies + $option{deaths};
        # sleep a bit if needed (= if we have not worked before in the loop)
        Time::HiRes::sleep($timeout) if $timeout;
        # update the IO::Select objects
        $iosr = undef unless $iosr and $iosr->count();
        $iosw = undef unless $iosw and $iosw->count();
    }
}

#
# run the given command
#

sub proc_run (@) {
    my(@args) = @_;
    my($proc);

    # create the process
    $proc = proc_create(@args);
    # monitor it until it ends
    proc_monitor($proc);
    # return what is expected
    return(%{ $proc }) if wantarray();
    return($proc->{status});
}

#
# execute the given command, check its status and return its output
#

sub proc_output (@) {
    my(@command) = @_;
    my($output, $status);

    $output = "";
    $status = proc_run(command => \@command, stdout => \$output);
    dief("%s failed: %d", $command[0], $status) if $status;
    return($output);
}

#
# detach ourself and go in the background
#

my %proc_detach_options = (
    callback => { optional => 1, type => CODEREF },
);

sub proc_detach (@) {
    my(%option, $pid, $sid);

    %option = validate(@_, \%proc_detach_options) if @_;
    # change directory to a known place
    dir_change("/");
    # fork and let dad die
    $pid = fork();
    dief("cannot fork(): %s", $!) unless defined($pid);
    if ($pid) {
        # we are about to exit()
        $Transient = 1;
        $option{callback}->($pid) if $option{callback};
        exit(0);
    }
    # create a new session
    $sid = setsid();
    dief("cannot setsid(): %s", $!) if $sid == -1;
    # detach std* from anything but plain files (i.e. allow: cmd --detach > log)
    unless (-f STDIN) {
        open(STDIN, "<", "/dev/null")
            or dief("cannot re-open stdin: %s", $!);
    }
    unless (-f STDOUT) {
        open(STDOUT, ">", "/dev/null")
            or dief("cannot re-open stdout: %s", $!);
    }
    unless (-f STDERR) {
        open(STDERR, ">", "/dev/null")
            or dief("cannot re-open stderr: %s", $!);
    }
}

#
# return a string representation of the process status
#

sub proc_status ($) {
    my($status) = @_;
    my($signum, @list);

    return("ok") unless $status;
    $signum = $status & 127;
    push(@list, sprintf("code=%d", $status >> 8));
    push(@list, sprintf("signal=%s", $SigName[$signum] || $signum))
        if $signum;
    push(@list, "(core dumped)")
        if $status & 128;
    return(join(" ", @list));
}

#
# module initialization
#

@SigName[split(/\s+/, $Config{sig_num})] = split(/\s+/, $Config{sig_name});

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++,
         map("proc_$_", qw(create detach monitor output run status terminate)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::Proc - process handling without worries

=head1 SYNOPSIS

  use No::Worries::Proc qw(proc_run proc_create proc_monitor proc_detach);

  # simple interface to execute a command
  $status = proc_run(command => [ "foo", "-x", 7 ]);
  printf("foo exited with %d\n", $status);

  # idem but with output redirection and more information
  %proc = proc_run(command => [ qw(uname -a) ], stdout => \$output);
  printf("process %d output is %s\n", $proc->{pid}, $output);

  # start two process and wait for them to finish
  $p1 = proc_create(
      command => \@cmd1,
      timeout => 5,           # to be killed if still running after 5s
      stderr  => "/dev/null", # discard stderr
  );
  $p2 = proc_create(
      command => \@cmd2,
      stdout  => \$output,    # get stdout+stderr in $output
      stderr  => "",          # merge stderr with stdout
  );
  proc_monitor([ $p1, $p2 ], timeout => 10);
  printf("%d finished\n", $p1->{pid}) if $p1->{stop};
  printf("%d finished\n", $p2->{pid}) if $p2->{stop};

  # detach ourself to run as a daemon
  proc_detach(callback => sub { print("started with pid $_[0]\n")});

=head1 DESCRIPTION

This module eases process handling by providing high level functions to start,
monitor and stop processes. All the functions die() on error.

It also provides the $No::Worries::Proc::Transient variable that indicates,
after a fork(), which process is transient and is about to exec() or exit().
This is useful for instance in an END block:

  END {
      # remove our pid file unless we are transient
      pf_unset($pidfile) unless $No::Worries::Proc::Transient;
  }

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item proc_output(COMMAND...)

execute the given command, capture its output (stdout only), check its exit
code (report an error if it is not zero) and return the captured output; this
is similar to Perl's qx() operator but bypassing the shell and always checking
the exit code

=item proc_create(OPTIONS)

create a new process that will execute the given command and return a hash
reference representing this process (see the L</"PROCESS STRUCTURE"> sections
for more information), to be given to proc_monitor() or proc_terminate()
afterwards; supported options:

=over

=item * C<command>: the command to execute, it must be an array reference

=item * C<cwd>: the current working directory of the new process

=item * C<timeout>: the maximum number of seconds that the process is allowed
to take to run (can be fractional); after this, it may be killed by
proc_monitor()

=item * C<kill>: how to "gently" kill the process, see below

=item * C<stdin>: what to do with stdin, see below

=item * C<stdout>: what to do with stdout, see below

=item * C<stderr>: what to do with stderr, see below

=back

=item proc_terminate(PROC[, OPTIONS])

terminate the given process (PROC can be either a process structure or simply
a process id) by sending signals and waiting for the process to finish;
supported options:

=over

=item * C<kill>: how to "gently" kill the process, see below

=back

=item proc_monitor(PROCS[, OPTIONS])

monitor the given process(es) (as created by proc_create()); PROCS can be
either a single process or a reference to a list of processes; supported
options:

=over

=item * C<timeout>: the maximum number of seconds that proc_monitor() should
take, can be fractional

=item * C<bufsize>: the buffer size to use for I/O operations (default: 8192)

=item * C<deaths>: the minimum number of process deaths that proc_monitor()
will wait for before returning

=back

=item proc_run(OPTIONS)

execute the given process (i.e. create and monitor it until termination) and
return its status (i.e. $?) in scalar context or the whole process structure
in list context; supported options: the ones of proc_create()

=item proc_detach([OPTIONS])

detach the current process so that it becomes a daemon running in the
background (this implies forking and re-opening std*); supported options:

=item proc_status(STATUS)

return a string representation of the given process status (i.e. $?)

=over

=item * C<callback>: code reference that will be executed by the parent
process just before exiting and will be given the child pid

=back

=back

=head1 PROCESS STRUCTURE

The process structure (hash) used in this module has the following fields:

=over

=item * C<command>: the command being executed, as an array reference

=item * C<pid>: the process id

=item * C<start>: the start time, in fractional seconds

=item * C<stop>: the stop time, in fractional seconds

=item * C<status>: the status (i.e. $?)

=item * C<timeout>: true if the process has been killed because of timeout

=back

=head1 FILE DESCRIPTOR REDIRECTION

When using the C<stdin> option of proc_create(), the value can be:

=over

=item * a string: input will be read from the given file name

=item * a scalar reference: input will be the scalar itself

=back

When using the C<stdout> and C<stderr> options of proc_create(), the value can
be:

=over

=item * a string: output will be written to the given file name

=item * a scalar reference: output will be stored in the scalar

=item * a code reference: each time new output is available, the code will be
called with two parameters: the process structure and the new output

=back

In addition, C<stderr> can also be given an empty string that means that
stderr should be merged with stdout.

=head1 KILL SPECIFICATION

Both proc_create() and proc_terminate() can be given a C<kill> option that
specifies how the process should be killed.

The specification is a string containing a space separated list of
I<signal>/I<grace> couples, meaning: send the given signal and wait a bit for
the process to finish.

If not specified, the default is C<TERM/1 INT/1 QUIT/1>, meaning:

=over

=item * send SIGTERM and wait up to 1 second for the process to finish

=item * if the process is still alive, send SIGINT and wait up to 1 second

=item * if the process is still alive, send SIGQUIT and wait up to 1 second

=item * if the process is still alive, send SIGKILL (implicit)

=back

=head1 GLOBAL VARIABLES

This module uses the following global variables (none of them being exported):

=over

=item $Transient

true if the process is about to exec() or exit(), there is usually no need to
perform any cleanup (e.g. in an END block) for this kind of process

=back

=head1 SEE ALSO

L<No::Worries>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
