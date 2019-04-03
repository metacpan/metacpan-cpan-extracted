#+##############################################################################
#                                                                              #
# File: No/Worries/PidFile.pm                                                  #
#                                                                              #
# Description: pid file handling without worries                               #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::PidFile;
use strict;
use warnings;
our $VERSION  = "1.6";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Fcntl qw(:DEFAULT :flock :seek);
use No::Worries qw($_IntegerRegexp $_NumberRegexp);
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use No::Worries::Proc qw(proc_terminate);
use No::Worries::Stat qw(ST_MTIME);
use Params::Validate qw(validate :types);
use POSIX qw(:errno_h);
use Time::HiRes qw();

#
# safely read something from an open file
#

sub _read ($$;$) {
    my($path, $fh, $noclose) = @_;
    my($data, $done);

    flock($fh, LOCK_EX)
        or dief("cannot flock(%s, LOCK_EX): %s", $path, $!);
    sysseek($fh, 0, SEEK_SET)
        or dief("cannot sysseek(%s, 0, SEEK_SET): %s", $path, $!);
    $data = "";
    $done = -1;
    while ($done) {
        $done = sysread($fh, $data, 16, length($data));
        dief("cannot sysread(%s, %d): %s", $path, 16, $!)
            unless defined($done);
    }
    if ($noclose) {
        flock($fh, LOCK_UN)
            or dief("cannot flock(%s, LOCK_UN): %s", $path, $!);
    } else {
        close($fh)
            or dief("cannot close(%s): %s", $path, $!);
    }
    return($data);
}

#
# safely write something to an open file
#

sub _write ($$$) {
    my($path, $fh, $data) = @_;
    my($length, $offset, $done);

    flock($fh, LOCK_EX)
        or dief("cannot flock(%s, LOCK_EX): %s", $path, $!);
    sysseek($fh, 0, SEEK_SET)
        or dief("cannot sysseek(%s, 0, SEEK_SET): %s", $path, $!);
    truncate($fh, 0)
        or dief("cannot truncate(%s, 0): %s", $path, $!);
    $length = length($data);
    $offset = 0;
    while ($length) {
        $done = syswrite($fh, $data, $length, $offset);
        dief("cannot syswrite(%s, %d): %s", $path, $length, $!)
            unless defined($done);
        $length -= $done;
        $offset += $done;
    }
    close($fh)
        or dief("cannot close(%s): %s", $path, $!);
}

#
# check if a process is alive by killing it ;-)
#

sub _alive ($) {
    my($pid) = @_;

    return(1) if kill(0, $pid);
    return(0) if $! == ESRCH;
    dief("cannot kill(0, %d): %s", $pid, $!);
}

#
# kill a process
#

sub _kill ($$$%) {
    my($path, $fh, $pid, %option) = @_;
    my($maxtime);

    # gently
    $option{callback}->("(pid $pid) is being told to quit...");
    _write($path, $fh, "$pid\nquit\n");
    $maxtime = Time::HiRes::time() + $option{linger};
    while (1) {
        last unless _alive($pid);
        last if Time::HiRes::time() > $maxtime;
        Time::HiRes::sleep(0.1);
    }
    if (_alive($pid)) {
        # forcedly
        $option{callback}->("(pid $pid) is still running, killing it now...");
        if ($option{kill}) {
            proc_terminate($pid, kill => $option{kill});
        } else {
            proc_terminate($pid);
        }
        $option{callback}->("(pid $pid) has been successfully killed");
    } else {
        $option{callback}->("does not seem to be running anymore");
    }
}

#
# check a process
#

sub _status ($%) {
    my($path, %option) = @_;
    my($fh, @stat, $data, $pid, $status, $message, $lsb);

    $status = 0;
    unless (sysopen($fh, $path, O_RDWR)) {
        if ($! == ENOENT) {
            ($message, $lsb) =
                ("does not seem to be running (no pid file)", 3);
            goto done;
        }
        dief("cannot sysopen(%s, O_RDWR): %s", $path, $!);
    }
    @stat = stat($fh)
        or dief("cannot stat(%s): %s", $path, $!);
    $data = _read($path, $fh);
    if ($data eq "") {
        # this can happen in pf_set(), between open() and lock()
        ($message, $lsb) =
            ("does not seem to be running yet (empty pid file)", 4);
        goto done;
    }
    if ($data =~ /^(\d+)(\s+([a-z]+))?\s*$/s) {
        $pid = $1;
    } else {
        dief("unexpected pid file contents in %s: %s", $path, $data);
    }
    unless (_alive($pid)) {
        ($message, $lsb) =
            ("(pid $pid) does not seem to be running anymore", 1);
        goto done;
    }
    $data = localtime($stat[ST_MTIME]);
    if ($option{freshness} and
        $stat[ST_MTIME] < Time::HiRes::time() - $option{freshness}) {
        ($message, $lsb) =
            ("(pid $pid) does not seem to be running anymore since $data", 4);
        goto done;
    }
    # so far so good ;-)
    ($status, $message, $lsb) = (1, "(pid $pid) was active on $data", 0);
  done:
    return($status, $message, $lsb);
}

#
# set the pid file
#

my %pf_set_options = (
    pid => { optional => 1, type => SCALAR, regex => $_IntegerRegexp },
);

sub pf_set ($@) {
    my($path, %option, $fh);

    $path = shift(@_);
    %option = validate(@_, \%pf_set_options) if @_;
    $option{pid} ||= $$;
    sysopen($fh, $path, O_WRONLY|O_CREAT|O_EXCL)
        or dief("cannot sysopen(%s, O_WRONLY|O_CREAT|O_EXCL): %s", $path, $!);
    _write($path, $fh, "$option{pid}\n");
}

#
# check the pid file
#

my %pf_check_options = (
    pid => { optional => 1, type => SCALAR, regex => $_IntegerRegexp },
);

sub pf_check ($@) {
    my($path, %option, $fh, $data, $pid, $action);

    $path = shift(@_);
    %option = validate(@_, \%pf_check_options) if @_;
    $option{pid} ||= $$;
    sysopen($fh, $path, O_RDWR)
        or dief("cannot sysopen(%s, O_RDWR): %s", $path, $!);
    $data = _read($path, $fh);
    if ($data =~ /^(\d+)\s*$/s) {
        ($pid, $action) = ($1, "");
    } elsif ($data =~ /^(\d+)\s+([a-z]+)\s*$/s) {
        ($pid, $action) = ($1, $2);
    } else {
        dief("unexpected pid file contents in %s: %s", $path, $data)
    }
    dief("pid file %s has been taken over by pid %d!", $path, $pid)
        unless $pid == $option{pid};
    return($action);
}

#
# touch the pid file
#

sub pf_touch ($) {
    my($path) = @_;
    my($now);

    $now = time();
    utime($now, $now, $path)
        or dief("cannot utime(%d, %d, %s): %s", $now, $now, $path, $!);
}

#
# unset the pid file
#

sub pf_unset ($) {
    my($path) = @_;

    unless (unlink($path)) {
        return if $! == ENOENT;
        dief("cannot unlink(%s): %s", $path, $!);
    }
}

#
# use the pid file to find out the program status
#

my %pf_status_options = (
    freshness => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
    timeout   => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
);

sub pf_status ($@) {
    my($path, %option, $maxtime, $status, $message, $lsb);

    $path = shift(@_);
    %option = validate(@_, \%pf_status_options) if @_;
    if ($option{timeout}) {
        # check multiple times until success or timeout
        $maxtime = Time::HiRes::time() + $option{timeout};
        while (1) {
            ($status, $message, $lsb) = _status($path, %option);
            last if $status or Time::HiRes::time() > $maxtime;
            Time::HiRes::sleep(0.1);
        }
    } else {
        # check only once
        ($status, $message, $lsb) = _status($path, %option);
    }
    return($status, $message, $lsb) if wantarray();
    return($status);
}

#
# use the pid file to make the program quit
#

my %pf_quit_options = (
    callback  => { optional => 1, type => CODEREF },
    linger    => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
    kill      => { optional => 1, type => SCALAR },
);

sub pf_quit ($@) {
    my($path, %option, $fh, $data, $pid);

    $path = shift(@_);
    %option = validate(@_, \%pf_quit_options) if @_;
    $option{callback} ||= sub { printf("%s\n", $_[0]) };
    $option{linger} ||= 5;
    unless (sysopen($fh, $path, O_RDWR)) {
        if ($! == ENOENT) {
            $option{callback}->("does not seem to be running (no pid file)");
            return;
        }
        dief("cannot sysopen(%s, O_RDWR): %s", $path, $!);
    }
    $data = _read($path, $fh, 1);
    if ($data eq "") {
        # this can happen while setting the pid file, between open and lock in pf_set()
        # but what can we do? we wait a bit, try again and complain if itis still empty
        sleep(1);
        $data = _read($path, $fh, 1);
    }
    if ($data =~ /^(\d+)(\s+([a-z]+))?\s*$/s) {
        $pid = $1;
    } else {
        dief("unexpected pid file contents in %s: %s", $path, $data);
    }
    _kill($path, $fh, $pid, %option);
    # in any case, we make sure that _this_ pid file does not exist anymore
    # we have to be extra careful to make sure it is the same pid file
    unless (sysopen($fh, $path, O_RDWR)) {
        return if $! == ENOENT;
        dief("cannot sysopen(%s, O_RDWR): %s", $path, $!);
    }
    $data = _read($path, $fh);
    return if $data eq "";
    if ($data =~ /^(\d+)(\s+([a-z]+))?\s*$/s) {
        return unless $1 == $pid;
    } else {
        dief("unexpected pid file contents in %s: %s", $path, $data);
    }
    # same pid so assume same pid file... remove it
    $option{callback}->("removing stale pid file: $path");
    unless (unlink($path)) {
        # take into account a potential race condition...
        dief("cannot unlink(%s): %s", $path, $!) unless $! == ENOENT;
    }
}

#
# sleep for some time, taking into account an optional pid file
#

my %pf_sleep_options = (
    time => { optional => 1, type => SCALAR, regex => $_NumberRegexp },
);

sub pf_sleep ($@) {
    my($path, %option, $end, $sleep);

    $path = shift(@_);
    %option = validate(@_, \%pf_sleep_options) if @_;
    $option{time} = 1 unless defined($option{time});
    if ($path) {
        $end = Time::HiRes::time() + $option{time} if $option{time};
        while (1) {
            return(0) if pf_check($path) eq "quit";
            pf_touch($path);
            last unless $option{time};
            $sleep = $end - Time::HiRes::time();
            last if $sleep <= 0;
            $sleep = 1 if $sleep > 1;
            Time::HiRes::sleep($sleep);
        }
    } else {
        Time::HiRes::sleep($option{time}) if $option{time};
    }
    return(1);
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, map("pf_$_",
                              qw(set check touch unset status quit sleep)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::PidFile - pid file handling without worries

=head1 SYNOPSIS

  use No::Worries::PidFile qw(*);

  # idiomatic daemon code
  pf_set($pidfile);
  while (1) {
      ...
      $action = pf_check($pidfile);
      last if $action eq "quit";
      pf_touch($pidfile);
      ...
  }
  pf_unset($pidfile);

  # idiomatic daemon code with sleeping
  pf_set($pidfile);
  while (1) {
      ...
      pf_sleep($pidfile, time => 5) or last;
      ...
  }
  pf_unset($pidfile);

  # here is how to handle a --status option
  if ($Option{status}) {
      ($status, $message, $code) = pf_status($pidfile, freshness => 10);
      printf("myprog %s\n", $message);
      exit($code);
  }

  # here is how to handle a --quit option
  if ($Option{quit}) {
      pf_quit($pidfile,
          linger   => 10,
          callback => sub { printf("myprog %s\n", $_[0]) },
      );
  }

=head1 DESCRIPTION

This module eases pid file handling by providing high level functions to set,
check, touch and unset pid files. All the functions die() on error.

The pid file usually contains the process id on a single line, followed by a
newline. However, it can also be followed by an optional I<action>, also
followed by a newline. This allows some kind of inter-process communication: a
process using pf_quit() will append the C<quit> I<action> to the pid file and
the owning process will detect this via pf_check().

All the functions properly handle concurrency. For instance, when two
processes start at the exact same time and call pf_set(), only one will
succeed and the other one will get an error.

Since an existing pid file will make pf_set() fail, it is very important to
remove the pid file in all situations, including errors. The recommended way
to do so is to use an END block:

  # we need to know about transient processes
  use No::Worries::Proc qw();
  # we need to record what needs to be cleaned up
  our(%NeedsCleanup);
  # we set the pid file here and remember to clean it up
  pf_set($pidfile);
  $NeedsCleanup{pidfile} = 1;
  # ... anything can happen here ...
  # cleanup code in an END block
  END {
      # transient processes do not need cleanup
      return if $No::Worries::Proc::Transient;
      # cleanup the pid file if needed
      pf_unset($pidfile) if $NeedsCleanup{pidfile};
  }

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item pf_set(PATH[, OPTIONS])

set the pid file by writing the given pid at the given path; supported
options:

=over

=item * C<pid>: the pid to use (default: C<$$>)

=back

=item pf_check(PATH[, OPTIONS])

check the pid file and make sure the given pid is present, also return the
I<action> in the pid file or the empty string; supported options:

=over

=item * C<pid>: the pid to use (default: C<$$>)

=back

=item pf_unset(PATH)

unset the pid file by removing the given path

=item pf_touch(PATH)

touch the pid file (i.e. update the file modification time) to show that the
owning process is alive

=item pf_sleep(PATH[, OPTIONS])

check and touch the pid file and eventually sleep for the givent amount of
time, returning true if the program should continue or false if it has been
told to stop via pf_quit(); supported options:

=over

=item * C<time>: the time to sleep (default: 1, can be fractional)

=back

=item pf_status(PATH[, OPTIONS])

use information from the pid file (including its last modification time) to
guess the status of the corresponding process, return the status (true means
that the process seems to be running); in list context, also return an
informative message and an LSB compatible exit code; supported options:

=over

=item * C<freshness>: maximum age allowed for an active pid file

=item * C<timeout>: check multiple times until success or timeout

=back

=item pf_quit(PATH[, OPTIONS])

tell the process corresponding to the pid file to quit (setting its I<action>
to C<quit>), wait a bit to check that it indeed stopped and kill it using
L<No::Worries::Proc>'s proc_terminate() is everything else fails; supported
options:

=over

=item * C<callback>: code that will be called with information to report

=item * C<linger>: maximum time to wait after having told the process to quit
(default: 5)

=item * C<kill>: kill specification to use when killing the process

=back

=back

=head1 SEE ALSO

L<http://refspecs.linuxbase.org/LSB_4.1.0/LSB-Core-generic/LSB-Core-generic/iniscrptact.html>,
L<No::Worries>,
L<No::Worries::Proc>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
