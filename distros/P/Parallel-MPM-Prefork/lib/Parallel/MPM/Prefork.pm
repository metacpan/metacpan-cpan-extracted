package Parallel::MPM::Prefork;

use 5.010;
use strict;
use warnings;
use Exporter 'import';
use Fcntl;
use POSIX qw(:signal_h :sys_wait_h sigprocmask);
use Socket;
use Storable qw(nfreeze thaw);

use Data::Dumper;

use constant {
  MAX_SERVERS => 73,
  MAX_SPARE => 10,
  MIN_SPARE => 5,
  START_SERVERS => 5,
};

use constant CLD_DATA_HDR_FMT => 'iSCL'; # PID, exit code, thaw, data length
use constant CLD_DATA_HDR_LEN => length pack CLD_DATA_HDR_FMT, 0;

our $VERSION = '0.14';

our (@EXPORT_OK, @EXPORT_TAGS) = ();
our @EXPORT =
  qw(
      pf_init
      pf_done
      pf_whip_kids
      pf_kid_new
      pf_kid_busy
      pf_kid_yell
      pf_kid_idle
      pf_kid_exit
  );

our $error;

my $pgid;
my $done;
my $debug;
my $am_parent;
my $timeout;

my $max_servers;
my $max_spare_servers;
my $min_spare_servers;
my $start_servers;

my $parent_stat_fh;
my $parent_data_fh;

my $child_stat_fh;
my $child_stat_fd;

my $child_data_fh;
my $child_data_fd;

my $child_fds;

my $child_data_hook;
my $child_sigh;

my $dhook_in_main;
my $dhook_pid;

my $num_busy;
my $num_idle;
my %busy;
my %idle;

my $sigset_bak = POSIX::SigSet->new();
my $sigset_all = POSIX::SigSet->new();
$sigset_all->fillset();

#
# Public interface
#

sub pf_init {
  my %opts = @_;

  eval {
    setpgrp();
    $pgid = getpgrp();

    $timeout = $am_parent = 1;
    $dhook_pid = $done = $num_busy = $num_idle = 0;
    $child_fds = $child_stat_fd = $child_data_fd = $error = '';

    undef %busy;
    undef %idle;

    $debug = $opts{debug};

    # Just like Apache, we allow start_servers to be larger than
    # max_spare_servers to accommodate for high initial load.
    $max_servers = int($opts{max_servers} // MAX_SERVERS);
    $max_spare_servers = int($opts{max_spare_servers} // MAX_SPARE);
    $min_spare_servers = int($opts{min_spare_servers} // MIN_SPARE);
    $start_servers = int($opts{start_servers} // START_SERVERS);

    if ($max_servers <= 0 || $max_spare_servers <= 0 ||
        $min_spare_servers <= 0 || $start_servers <= 0) {
      die "All child server process numbers must be >= 1!";
    }

    if ($max_servers < $min_spare_servers) {
      $max_servers = $min_spare_servers;
      warn "Adjusted max_servers to $max_servers";
    }

    if ($max_spare_servers < $min_spare_servers) {
      $max_spare_servers = $min_spare_servers;
      warn "Adjusted max_spare_servers to $max_spare_servers";
    }

    if ($start_servers > $max_servers) {
      $start_servers = $max_servers;
      warn "Adjusted start_servers to $start_servers";
    }
    elsif ($start_servers < $min_spare_servers) {
      $start_servers = $min_spare_servers;
      warn "Adjusted start_servers to $start_servers";
    }

    if (defined($child_data_hook = $opts{child_data_hook})) {
      ref $child_data_hook eq 'CODE' or
        die "child_data_hook must be a code reference";
    }

    $child_sigh = _make_child_sigh($opts{child_sigh});
    $dhook_in_main = $opts{data_hook_in_main};

    if ($child_data_hook) {
      _socketpair($parent_data_fh, $child_data_fh);
      if ($dhook_in_main) {
        vec($child_data_fd, fileno $child_data_fh, 1) = 1;
        $child_fds |= $child_data_fd;
      }
      else {
        $dhook_pid = _fork_data_hook_helper($parent_data_fh, $child_data_fh);
      }
    }

    _socketpair($parent_stat_fh, $child_stat_fh);
    vec($child_stat_fd, fileno $child_stat_fh, 1) = 1;
    $child_fds |= $child_stat_fd;

    $SIG{CHLD} = \&_sig_chld;
    _wait_for_children()
  };

  if ($@) {
    $error = $@;
    return undef;
  }

  return $parent_stat_fh;
}

sub pf_whip_kids ($;$) {
  my $code = shift;
  my $args = shift;

  return 0 if $done;

  if ($start_servers) {
    do { _spawn($code, $args) } until ! --$start_servers;
  }
  elsif ((my $lack = $min_spare_servers - $num_idle) > 0) {
    _log_child_action('Forking', $lack) if $debug;
    for (1 .. $lack) {
      last if (_spawn($code, $args) // return undef) < 0;
    }
  }
  elsif ((my $plus = $num_idle - $max_spare_servers) > 0) {
    _log_child_action('Killing', $plus) if $debug;
    _kill_idlers($plus);
  }

  _log_child_status() if $debug;
  _read_child_drool();

  return 1;
}

sub pf_kid_new () {
  while (!$done) {
    if ($start_servers) {
      $start_servers--;
      return _spawn();
    }
    elsif ((my $lack = $min_spare_servers - $num_idle) > 0) {
      _log_child_action('Lacking', $lack, "Forking 1 child.\n") if $debug;
      my $pid = _spawn();
      return $pid if !defined $pid || $pid >= 0;
    }
    elsif ((my $plus = $num_idle - $max_spare_servers) > 0) {
      _log_child_action('Killing', $plus) if $debug;
      _kill_idlers($plus);
    }

    _log_child_status() if $debug;
    _read_child_drool();
  }

  return -1;
}

sub pf_kid_busy {
  syswrite $parent_stat_fh, "R$$\n" if ! $am_parent;
}

sub pf_kid_idle {
  syswrite $parent_stat_fh, "S$$\n" if ! $am_parent;
}

sub pf_kid_yell($;$$) {
  my ($data, $thaw, $exitcode) = @_;

  return undef if $am_parent || !($parent_data_fh && ref $data);

  $data = eval { nfreeze($data) } // do {
    warn "ERROR: Could not nfreeze() data from pid $$: ", $@;
    $error = $@;
    return undef;
  };

  syswrite $parent_data_fh,
    pack(CLD_DATA_HDR_FMT, $$, $exitcode // 256, $thaw ? 1 : 0, length $data)
    . $data;
}

sub pf_kid_exit(;$$$) {
  my ($exitcode, $data, $thaw) = @_;

  return if $am_parent;

  ($exitcode //= 0) &= 0xff;

  pf_kid_yell($data, $thaw, $exitcode);

  exit $exitcode;
}

sub pf_done (;$) {
  my $exitcode = shift;

  return if !$am_parent || $done++;

  local $SIG{CHLD} = 'IGNORE';
  local $SIG{TERM} = 'IGNORE';
  kill 'TERM', 0;

  my $pid = 0;
  my $nbytes;

  undef $child_fds if ! $child_stat_fh;

  do {
    $pid = waitpid -$pgid, WNOHANG if $pid >= 0;
    $nbytes = _read_child_data();
    select my $rfds = $child_fds, undef, undef, .1 if !($pid || $nbytes);
  } while $pid >= 0 || $nbytes;

  exit $exitcode if defined $exitcode;

  undef $_ for ($parent_stat_fh, $child_stat_fh,
                $parent_data_fh, $child_data_fh);
}


#
# Private parts
#

sub _make_child_sigh {
  my $child_sigh = shift // return undef;

  ref $child_sigh eq 'HASH' or die "child_sigh must be a hash reference";

  if (%$child_sigh) {
    my %sig2hnd;
    while (my ($sigs, $code) = each %$child_sigh) {
      if (defined $code &&
          ref $code ne 'CODE' && $code !~ /^(?:DEFAULT|IGNORE)$/) {
        die "child_sigh($sigs) must be a code ref, DEFAULT, IGNORE or undef";
      }
      for (split ' ', $sigs) {
        $sig2hnd{$_} =
          exists $SIG{$_} ? $code : die "child_sigh: No such signal: $_";
      }
    }
    return \%sig2hnd;
  }

  return undef;
}

sub _socketpair {
  socketpair $_[0], $_[1], AF_UNIX, SOCK_STREAM, PF_UNSPEC
    or die "ERROR: socketpair(): $!\n";
  fcntl $_[1], F_SETFL, fcntl($_[1], F_GETFL, 0) | O_NONBLOCK;
}

sub _fork_data_hook_helper {
  my ($parent_data_fh, $child_data_fh) = @_;

  sigprocmask(SIG_BLOCK, $sigset_all, $sigset_bak);

  my $cpid = fork() // die "Could not fork: $!";

  if ($cpid) {
    sigprocmask(SIG_SETMASK, $sigset_bak);
    return $cpid;
  }

  undef $parent_data_fh;
  $0 .= ' [data_hook_helper]';

  $child_fds = '';
  vec($child_fds, fileno $child_data_fh, 1) = 1;

  while (my ($sig, $hnd) = each %SIG) {
    undef $SIG{$sig} if defined $hnd && $sig ne 'FPE';
  }

  sigprocmask(SIG_SETMASK, $sigset_bak);

  while (1) {
    select my $rfds = $child_fds, undef, undef, undef;
    _read_child_data();
  }
}

sub _spawn {
  my $code = shift;
  my $args = shift;

  if ($num_idle + $num_busy >= $max_servers) {
    warn "Server seems busy, consider increasing max_servers.\n";
    _log_child_status();
    return -1;
  }

  # Temporarily block signal delivery until child has installed all handlers
  # and knows for sure it's not the parent.
  sigprocmask(SIG_BLOCK, $sigset_all, $sigset_bak);

  my $cpid = fork();

  if ($cpid) {
    # Parent
    $num_idle++;
    $idle{$cpid}++;
  }
  elsif (defined $cpid) {
    # Child
    undef $am_parent;
    undef $child_data_fh;
    undef $child_stat_fh;

    @SIG{keys %$child_sigh} = values %$child_sigh if $child_sigh;

    if ($code) {
      sigprocmask(SIG_SETMASK, $sigset_bak);
      $code->(@{$args // []});
      exit;
    }
  }

  sigprocmask(SIG_SETMASK, $sigset_bak);

  $cpid;
}

sub _sig_chld {
  # force select() to return immediately if child exited shortly before
  $timeout = 0;
}

sub _wait_for_children {
  my $ct;
  while ((my $pid = waitpid -$pgid, WNOHANG) > 0) {
    if ($pid == $dhook_pid) {
      warn "ERROR: data_hook_helper exited, forking new one.\n";
      $dhook_pid = _fork_data_hook_helper($parent_data_fh, $child_data_fh);
    }
    else {
      delete $busy{$pid} and $num_busy--;
      delete $idle{$pid} and $num_idle--;
      warn "PID $pid exited.\n" if $debug;
    }
    $ct++;
  }
  $ct;
}

sub _read_child_drool {
  my $status_changed;
  do {
    if (select my $rfds = $child_fds, undef, undef, $timeout) {
      $status_changed = unpack '%32b*', $rfds & $child_stat_fd;
      if ($dhook_in_main && unpack '%32b*', $rfds & $child_data_fd) {
        _read_child_data();
        $status_changed ||= select $rfds = $child_stat_fd, undef, undef, 0;
      }
      _read_child_status() if $status_changed;
    }
    $timeout = 1;
  } until _wait_for_children() || $status_changed;
}

# An in-memory scoreboard would surely be nicer ...
sub _read_child_status {
  sigprocmask(SIG_BLOCK, $sigset_all, $sigset_bak);
  while (<$child_stat_fh>) {
    my ($status, $pid) = unpack 'aA*';
    # Ignore delayed status messages from no longer existing children
    next unless $busy{$pid} or $idle{$pid};
    if ($status eq 'R') {
      delete $idle{$pid} and $num_idle--;
      $busy{$pid}++ or $num_busy++;
    }
    elsif ($status eq 'S') {
      delete $busy{$pid} and $num_busy--;
      $idle{$pid}++ or $num_idle++;
    }
    elsif ($status ne '0') { # 0 = Jeffries tube. cg use only!
      warn "ERROR: Dubious status: $_";
    }
  }
  sigprocmask(SIG_SETMASK, $sigset_bak);
}

sub _read_child_data {
  return undef unless $child_data_fh && fileno $child_data_fh;

  my $nbytes = 0;
  my $chunks = $dhook_in_main ? 3 : ~0;  # read at most that many chunks per
                                         # call

  sigprocmask(SIG_BLOCK, $sigset_all, $sigset_bak);

 HDR:
  while ($chunks-- && sysread $child_data_fh, my $header, CLD_DATA_HDR_LEN) {
    my ($pid, $exitcode, $thaw, $data_len) = unpack CLD_DATA_HDR_FMT, $header;

    # Exit code 256 means "undef", minimum nfreeze() data length is 3.
    if ($pid <= 1 || $exitcode > 256 || $thaw > 1 || $data_len < 3) {
      warn(
        'ERROR: read corrupted child data: ',
        "pid:$pid exitcode:$exitcode thaw:$thaw data_len:$data_len",
        ', skipping all pending data'
      );
      $nbytes += sysread($child_data_fh, $header, 16384) || last HDR while 1;
    }

    my $cbytes = sysread($child_data_fh, (my $data), $data_len) // do {
      warn "ERROR: sysread(): $!";
      next HDR;
    };

    $nbytes += $cbytes;

    if ($cbytes != $data_len) {
      warn "ERROR: sysread(): read $cbytes bytes but expected $data_len";
      next HDR;
    }

    # Don't block signals in the data hook.
    sigprocmask(SIG_SETMASK, $sigset_bak);
    $child_data_hook->(
      $pid,
      ($thaw ? eval { thaw $data } : $data) //
        do {
          warn "ERROR: Could not thaw() data from pid $pid: ", $@;
          $error = $data;
          undef;
        },
      $exitcode <= 255 ? $exitcode : undef,
    );
    sigprocmask(SIG_BLOCK, $sigset_all, $sigset_bak) if $chunks;
  }

  sigprocmask(SIG_SETMASK, $sigset_bak);

  $nbytes;
}

sub _kill_idlers {
  my $plus = shift;

  $num_idle -= $plus;
  kill 'TERM', my @idlers = (keys %idle)[0 .. --$plus];
  delete @idle{@idlers};
}

sub _log_child_action {
  my ($what, $count, @more) = @_;
  warn "$what $count child", $count == 1 ? ".\n" : "ren.\n", @more;
}

sub _log_child_status {
  warn "busy:$num_busy idle:$num_idle\n";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Parallel::MPM::Prefork - A simple non-threaded, non-OO, pre-forking, self-regulating, multi-purpose multi-processing module. Period.

=head1 SYNOPSIS

  use Data::Dumper;
  use Parallel::MPM::Prefork;
  use sigtrap qw(die normal-signals);
  use Socket;

  pf_init(
    min_spare_servers => 2,
    max_spare_servers => 4,
    start_servers => 3,
    max_servers => 20,
    data_hook_in_main => 0,
    child_data_hook => sub {
      my ($pid, $data, $exitcode) = @_;
      print "$pid ", Dumper($data), "\n";
    },
    child_sigh => {
      HUP => sub { print "$$ ignoring SIGHUP\n" },
      'TERM INT' => sub { print "$$ exiting (SIG$_[0])\n"; exit },
    },
  ) or die $Parallel::MPM::Prefork::error;

  my $SOCK = mksock();
  $SIG{TERM} = $SIG{INT} = sub { pf_done(0) };

  # Variant 1: More convenient, less flexible.
  1 while pf_whip_kids(\&echo_server, [$SOCK]);

  # Variant 2: More flexible, less convenient.
  while (1) {
    my $pid = pf_kid_new() // die "Could not fork: $!";
    last if $pid < 0;
    next if $pid;
    echo_server($SOCK);
    pf_kid_exit(0, \'Bazinga!', 1);
  }

  END {
    pf_done();
  }

  # A simple echo server.
  sub echo_server {
    my $sock = shift;
    CONN: while (accept my $conn, $sock) {
      pf_kid_busy(); # tell parent we're busy
      /^quit/ ? last CONN : syswrite $conn, $_ while <$conn>;
      pf_kid_yell({ foo => 'bar' }, 1);  # send data to parent
      pf_kid_idle(); # tell parent we're idle again
    }
  }

  sub mksock {
    socket my $SOCK, AF_INET, SOCK_STREAM, 0;
    setsockopt($SOCK, SOL_SOCKET, SO_REUSEADDR, 1);
    bind $SOCK, pack_sockaddr_in(20116, inet_aton('127.0.0.1'));
    listen $SOCK, SOMAXCONN;
    $SOCK;
  }

=head1 DESCRIPTION

Parallel::MPM::Prefork is a pre-forking multi-processing module that adjusts
the number of child processes dynamically depending on the current work load
reported by the child processes. The child processes can send the main process
(almost) any kind of data at any time.

=head1 FUNCTIONS

By default, all functions described below are exported.

=head2 pf_init ( %options )

Initialization. Creates a process group (see NOTES), sets up internal child
communications channels, reaps potentially left-over child processes and
installs a SIGCHLD handler. Does I<not> fork any child processes.

Returns false on error. Accepts an optional hash of the following options:

=head3 max_servers

Maximum total number of child processes Default: 73.

=head3 max_spare_servers

Maximum number of idle child processes. Surplus idle child processes will
receive a SIGTERM (and are supposed to obey it). Default: 10.

=head3 min_spare_servers

Minimum number of idle child processes Default: 5.

=head3 start_servers

Number of child processes initially created by pf_whip_kids() or
pf_kid_new(). Default: 5.

=head3 child_sigh

Signal handlers to be installed in the child. Hash reference holding space
separated signal names as keys and code references or the special strings
'DEFAULT' or 'IGNORE' as values, e.g: C<< { HUP => $code, 'INT TERM' =>
'DEFAULT' } >>. Default: undef.

Any SIGTERM handler should cause the child process to exit sooner or later.

=head3 child_data_hook

Code reference to be called when a child calls pf_kid_yell() or pf_kid_exit()
with a C<$data> argument. Receives child pid, data and exit code as arguments
(in this order). The exit code is undef for pf_kid_yell().

If thaw() was requested (see pf_kid_yell() and pf_kid_exit()) and failed,
$data is undef and $Parallel::MPM::Prefork::error contains the original data
from Storable::nfreeze().

This hook is executed in a dedicated child process unless data_hook_in_main is
set to true.

=head3 data_hook_in_main

Boolean value. If false (the default), a separate child process reads child
data from pf_kid_yell() and pf_kid_exit() and executes child_data_hook. If
true, this is done in the main process.

Note that if you set this to true, a long-running or heavily used
child_data_hook will slow down the child process management of the main
process. Putting it in a separate process only affects the performance of the
child processes.

=head2 pf_whip_kids () and pf_kid_new ()

These two functions manage the child processes. Which one you use is up to
your taste and use case. Either one must be called in a loop to keep the show
running.

In either case, I<all> signals are blocked during child process creation, the
old signal mask is saved, and the signal handlers given by child_sigh are
installed. The old signal mask is restored just before pf_kid_new() returns or
pf_whip_kids() calls the code reference.

=head2 pf_whip_kids ( $code, $args )

Wraps child processing in a single call.

Returns 1 as soon as any child changes status, yells or exits. Immediately
returns undef if a fork() failed or 0 if pf_done() has already been called;

Typical code:

  $SIG{TERM} = $SIG{INT} = sub { pf_done(0) };
  1 while pf_whip_kids(\&echo_server, [$SOCK]);

=head3 $code

Code reference to be called in the child processes. Must make sure it calls
pf_kid_busy() and pf_kid_idle() as needed. If it returns, the child will exit
via C<exit(0)>.

=head3 $args (optional)

Array reference holding arguments to be passed when $code is called (C<<
$code->(@$args) >>).

=head2 pf_kid_new ()

Forks a new child process if too few are idle (E<lt>
min_spare_servers). Blocks otherwise and kills child processes if too many are
idle (E<gt> max_spare_servers).

If a new child process was forked, returns the child pid to the parent, 0 to
the child, undef if fork() failed.

As a special case it always returns -1 immediately if pf_done() has already
been called.

The newly created child is considered idle by the parent. It should call
pf_kid_busy() as soon as it starts working and pf_kid_idle() when it is
available again so that the parent can arrange for enough available child
processes.

Typical code:

  $SIG{TERM} = $SIG{INT} = sub { pf_done(0) };
  while (1) {
    my $pid = pf_kid_new() // die "Could not fork: $!";
    last if $pid < 0;  # pf_done()
    next if $pid;  # parent
    # child:
    pf_kid_busy();
    # do some rocket science
    pf_kid_idle();
    pf_kid_exit();
  }

  END {
    pf_done();
  }

=head2 pf_kid_busy ()

To be called by a child process to tell the main process it is busy.

=head2 pf_kid_idle ()

To be called by a child process to tell the main process it is idle.

=head2 pf_kid_exit ( $exitcode, $data, $thaw )

Calls C<pf_kid_yell($data, $thaw)> and then exits from the child via
C<exit($exitcode)>. C<$exitcode> will be tuncated to an 8-bit unsigned
integer, defaults to 0 if omitted. C<$data> and C<$thaw> are optional (see
pf_kid_yell()).

=head2 pf_kid_yell ( $data, $thaw )

Sends data from a child to the main process which then calls
C<child_data_hook($pid, undef, $data)> with either the serialized or (if $thaw
is true) deserialized data.

Returns true on success, undef otherwise. If $data could not be serialized,
$Parallel::MPM::Prefork::error contains the error message from
Storable::nfreeze():

This function is a no-op in the main process, if child_data_hook is not set or
if C<$data> is not a reference.

As all child processes share the same upstream socket to the parent you should
probably not send more than POSIX::PIPE_BUF bytes in one go if your children
are nerve-racking blare machines. Otherwise the data might be split up in
smaller chunks and get intermixed with data from other child processes sending
at the same time. While this could be avoided with some extra effort I prefer
to keep it simple.

=head3 $data (required)

A I<reference> to any Perl data type that Storable can serialize. Will be
passed to child_data_hook in the main process as a Storable::nfreeze() string.

=head3 $thaw (optional)

A boolean value. If true, $data will be deserialized with Storable::thaw()
before passing it to child_data_hook.

=head2 pf_done ( $exitcode )

To be called by the main process when you are done.

Sends all child processes a SIGTERM, waits for all child processes to
terminate, reads remaining child data and executes child_data_hook if
necessary.

Exits with C<$exitcode> if given, returns otherwise.

=head1 VARIABLES

=head2 $Parallel::MPM::Prefork::error

Holds an error message if pf_init() failed or the data provided by
pf_kid_yell() or pf_kid_exit() could not be serialized or deserialized.

=head2 $Parallel::MPM::Prefork::VERSION

The module's version.

=head1 NOTES

=head2 You Don't Mess with the ZIGCHLD

Parallel::MPM::Prefork relies on SIGCHLD being delivered to its own handler in
the main process (installed by pf_init()) and select() being interrupted by at
least SIGCHLD.

=head2 Forking your own processes

Parallel::MPM::Prefork creates a process group with setpgrp() which allows it
to wait only for its own child processes. That is, if you want to fork and
wait for an independent child process you just call setpgrp() in the child and
waitpid($pid, ...) in the main process.

system(LIST) can be replaced by system('setsid', LIST);

However, Parallel::MPM::Prefork will still catch SIGCHLD (see previous note).

=head2 Difference to Parallel::ForkManager

With Parallel::ForkManager, the main process decides in advance how much work
there is to do, how to split it up and how many child processes will work in
parallel. A child is always considered busy.

With Parallel::MPM::Prefork, the child processes take on work automatically as
it arrives. A child may be busy or idle. The main process only makes sure
there are always enough child processes available without too many idling
around.

Keep in mind that these are completely different use cases.

=head1 SEE ALSO

=head2 Net::Server::Prefork

Similar to Parallel::MPM::Prefork but limited to serving network
connections. Heavyweight hook-laden OO style. A pain in the ass when it comes
to customizing signal handling but its pipe concept for managing child
processes rocks. Inspired the creation of this module.

=head2 Parallel::ForkManager

Different use case (see NOTES). Waits for all child processes, not only its
own offspring; we don't (see NOTES). Features the awesome inline child code
paradigm.

=head2 Parallel::Prefork::SpareWorkers

Kind of a hybrid between Net::Server::Prefork and Parallel::ForkManager. Fails
to manage the workers if you want to keep them alive.

=head1 ACKNOWLEDGEMENTS

Thanks to the UN for not condemning child labor on the operating system level.

=head1 COPYRIGHT

Copyright © 2013 Carsten Gaebler (cgpan ʇɐ gmx ʇop de). All rights reserved.

I only accept encrypted e-mails, either via
L<SMIME|http://cpan.org/authors/id/C/CG/CGPAN/cgpan-smime.crt> or
L<GPG|http://cpan.org/authors/id/C/CG/CGPAN/cgpan-gpg.asc>.

=head1 LICENSE

This program is free software. You can redistribute and/or modify it under the
same terms as Perl itself.

=cut
