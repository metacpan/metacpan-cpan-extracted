package Run;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $Wraparound $Forkless);
use Fcntl qw(F_GETFD F_SETFD F_DUPFD FD_CLOEXEC
	     O_RDONLY O_WRONLY O_RDWR O_CREAT O_TRUNC O_APPEND);
use POSIX ();
use IO::Handle ();
use IO::File ();
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(spawn);
$VERSION = '0.07';

%EXPORT_TAGS = ( NEW => [qw(new_system new_spawn new_or new_and new_chain
			    new_env new_redir new_pipe new_pipeline
			    new_readpipe new_readpipe_split)] );
@EXPORT_OK = @{$EXPORT_TAGS{NEW}};

@Run::and::ISA = @Run::or::ISA = @Run::chain::ISA = @Run::spawn::ISA
  = @Run::system::ISA = @Run::pipeline::ISA = qw(Run::base);

@Run::env::ISA = @Run::pipe::ISA = @Run::redir::ISA = qw(Run::base2);
@Run::readpipe::ISA = @Run::readpipe_split::ISA = qw(Run::base1);

# Forkless (OS/2, Win32, VMS; or set $Run::Forkless on Unix to run these code
# paths): every process is started by spawn_nowait(), and redirections are
# applied in the parent around it ("wraparound").  Otherwise they are applied
# in the kid between fork and exec, and the parent's fd table is never
# touched.  $Run::Wraparound is the old name: either one set means forkless.
my $dosish = $^O =~ /^(?:os2|MSWin32|VMS)\z/;
$Forkless = $dosish unless defined $Forkless;
sub forkless { $Forkless || $Wraparound }

sub err { my $errs = shift; push @$errs, join '', @_; return }

sub spawn { spawn_nowait(0, \@_, []) }

# Starts @$args with the current fd table: returns the pid when $spawn, else
# $? (-1 if nothing started, with a message in @$errs).  With $list, $args is
# always a program and its arguments, as in "system { PROG } LIST"; without
# it, a single element is a command string, as for the builtin system.
sub launch {
  my ($spawn, $list, $args, $errs, $prog) = @_;
  if (!$spawn and !forkless()) {
    my @a = @$args;
    my $res = do { no warnings 'exec'; $list ? system { $prog // $a[0] } @a : system @a };
    err($errs, "exec `@a': $!") if $res == -1;
    return $res;
  }
  my $pid = spawn_nowait($list, $args, $errs, $prog);
  return $pid if $spawn;
  $pid or return -1;
  local @SIG{qw(INT QUIT)} = ('IGNORE') x 2;
  waitpid $pid, 0;
  $?;
}

# The one primitive for starting a process when forkless, as spawnvp(P_NOWAIT):
# the kid gets this process's fd table as it is (but no close-on-exec fd).
# Returns the pid; undef (with a message in @$errs) if nothing started.  On
# Unix, which has no spawn, it is emulated by fork and exec with nothing in
# between.  $list: as for launch().
sub spawn_nowait {
  my ($list, $args, $errs, $prog) = @_;
  my @a = @$args;
  if ($^O eq 'os2' and !$list and @a == 1
      and ( $a[0] =~ /[\`|\"\'\$&;*?\{\}\[\]\(\)<>\s~]/
				# backslashes are allowed as far as
				# there is no whitespace.
	    or $a[0] =~ /^\s*\w+=/ )) {
    # system 1, blah would not use shell
    unshift @a, '/bin/sh', '-c'; # /bin/sh will be auto-translated
                                 # to the installed place by system().
  }
  if ($dosish) {
    # untested: relies on do_aspawn() taking the leading 1 as P_NOWAIT
    my $pid = do { no warnings 'exec'; $list ? system { $prog // $a[0] } 1, @a : system 1, @a };
    return $pid > 0 ? $pid : err($errs, "spawn `@a': $!");
  }
  fork_kid(1, $list, \@a, [], 3, $errs, $prog);
}

# Win32 (0.07): Perl has no fcntl there, and close-on-exec is a handle that is
# not inherited; Win32API::File (which comes with Perl there) reads and sets it.
# $Run::AsWin32 (true on Win32; on Unix set it, or RUN_AS_WIN32=1, to debug)
# takes these code paths: copies by dup instead of F_DUPFD, no aliases in the
# wraparound, the flag through os_inherit(); on Unix FD_CLOEXEC stands in for
# the handle's inheritance there, so all but the Win32API::File calls run.
our $AsWin32 = $^O eq 'MSWin32' || !!$ENV{RUN_AS_WIN32};
sub os_inherit {	# (N): is fd N inherited?  (N, ON): make it so or not.  undef, $! = EBADF: N not open
  my ($n, $on) = @_;
  if ($^O eq 'MSWin32') {
    require Win32API::File;
    my $h = Win32API::File::FdGetOsFHandle($n);
    defined $h and $h != Win32API::File::INVALID_HANDLE_VALUE() or do { $! = POSIX::EBADF(); return };
    my $bit = Win32API::File::HANDLE_FLAG_INHERIT();
    return Win32API::File::SetHandleInformation($h, $bit, $on ? $bit : 0) if @_ > 1;
    my $f = 0;
    Win32API::File::GetHandleInformation($h, $f) or return;
    return $f & $bit ? 1 : 0;
  }
  defined(my $t = POSIX::dup($n)) or return;	# (the stand-in, for debugging on Unix)
  if (@_ > 1 && $on) { POSIX::dup2($t, $n); POSIX::close($t); return 1 }	# dup2 clears FD_CLOEXEC
  POSIX::close($t);
  return unix_set_cloexec($n) if @_ > 1;
  my $c = unix_is_cloexec($n) // return;
  $c ? 0 : 1;
}
sub win_dup_above {		# no F_DUPFD there: dup until high enough
  my ($src, $min) = @_;
  my ($fd, @low);
  while (defined(my $d = POSIX::dup($src))) {
    if ($d >= $min) { $fd = $d; last }
    push @low, $d;
  }
  my $e = $!; POSIX::close($_) for @low; $! = $e;
  $fd;
}
sub cloexec_fh {		# FD_CLOEXEC on the handle's fd
  my $fh = shift;
  $AsWin32 ? os_inherit(fileno $fh, 0) : fcntl($fh, F_SETFD, FD_CLOEXEC);
}

# A close-on-exec copy of $fh's fd at the lowest free fd >= $min.
sub dup_above {
  my ($fh, $min, $mode) = @_;
  my $fd;
  my $copy;
  if ($AsWin32) {		# $fh may be an fd number there
    $fd = win_dup_above(ref $fh ? fileno $fh : $fh, $min) // return;
  } else {
    $fd = fcntl($fh, F_DUPFD, $min) // return;
  }
  open $copy, ($mode || '<') . '&=', $fd or POSIX::close($fd), return;
  cloexec_fh($copy) or return;
  $copy;
}

# Normalizes redirections into a Run::redirlist: an array of [fd, how, what],
# applied in order, as sh applies "n>file n>&m n>&-" left to right:
#   [n, fd => m]     n becomes a copy of fd m as it is at that moment
#   [n, fh => FH]    the same, with m = fileno FH at that moment
#   [n, pin => FH]   n becomes a copy of FH's file (FH opened by Run itself)
#   [n, close => 1]  n is closed
# Input is a hash {n => spec} (applied in increasing n) or an array of pairs
# [n => spec, ...]; spec is {filehandle => FH}, {filename => '>file'} or
# {filename => NAME, mode => OP}, OP one of sh's < > >| >> <>.
# Files are opened here and pushed onto @$opened; undef on error.
my %open_flags = ('<'  => O_RDONLY,
		  '>'  => O_WRONLY | O_CREAT | O_TRUNC,
		  '>|' => O_WRONLY | O_CREAT | O_TRUNC,
		  '>>' => O_WRONLY | O_CREAT | O_APPEND,
		  '<>' => O_RDWR | O_CREAT);
sub redir_list {
  my ($in, $opened, $errs) = @_;
  return $in if ref $in eq 'Run::redirlist';
  my @pairs = ref $in eq 'HASH'
    ? map +($_ => $in->{$_}), sort { $a <=> $b } keys %$in : @$in;
  my @out;
  while (my ($n, $spec) = splice @pairs, 0, 2) {
    $n =~ /^\d+\z/ or return err($errs, "not a file descriptor: `$n'");
    my ($file, $mode) = @$spec{qw(filename mode)};
    if (defined $spec->{fd}) {		# {fd => M} (0.07)
      $spec->{fd} =~ /^\d+\z/ or return err($errs, "not a file descriptor: `$spec->{fd}'");
      push @out, [$n, fd => $spec->{fd}];
      next;
    }
    if ($spec->{close}) { push @out, [$n, close => 1]; next }	# {close => 1} (0.07)
    if (!defined $file) {
      push @out, [$n, ($spec->{pin} ? 'pin' : 'fh'), $spec->{filehandle}];
      next;
    }
    if (!defined $mode) {
      push(@out, [$n, fd => $1]), next if $file =~ /^\s*[<>]\s*&\s*=?\s*(\d+)\s*\z/;
      push(@out, [$n, close => 1]), next if $file =~ /^\s*[<>]\s*&\s*-\s*\z/;
    }
    my $fh;
    if (defined $mode) {
      my $flags = $open_flags{$mode} // return err($errs, "unknown mode `$mode'");
      sysopen $fh, $file, $flags or undef $fh;
    } else {
      $fh = IO::File->new($file);
    }
    $fh or return err($errs, "Cannot open `$file': $!");
    cloexec_fh($fh);		# even with a large $^F
    push @$opened, $fh;
    push @out, [$n, pin => $fh];
  }
  bless \@out, 'Run::redirlist';
}

# Applies the list to the current process; false (with a message) on error.
sub apply {
  my ($redirs, $errs) = @_;
  for (@$redirs) {
    my ($n, $how, $what) = @$_;
    if ($how eq 'close') { POSIX::close($n); next }
    my $src = $how eq 'fh' ? fileno $what : $what;
    defined $src or return err($errs, "fd $n: filehandle is not open");
    if ($src == $n) {		# "n>&n": keep the file, drop FD_CLOEXEC
      my $tmp = POSIX::dup($n) // return err($errs, "fd $n: $!");
      POSIX::dup2($tmp, $n);
      POSIX::close($tmp);
    } else {
      defined POSIX::dup2($src, $n) or return err($errs, "dup2($src, $n): $!");
    }
  }
  1;
}

# Runs the program @$args (never a shell string) with @$redirs applied;
# returns the pid when $spawn, else $?.  When nothing was started, returns
# undef (spawn) or -1 (system), with a message in @$errs.  $prog (optional):
# the program to run, when it is not $args->[0] (as "system { PROG } LIST").
# $redirs: a Run::redirlist, or what redir_list() takes (files it opens are
# closed again after the start).  Public since 0.07.
sub start {
  my ($spawn, $args, $redirs, $errs, $prog) = @_;
  if (ref $redirs ne 'Run::redirlist') {
    my @opened;
    my $list = redir_list($redirs, \@opened, $errs);
    my $res = $list ? start($spawn, $args, $list, $errs, $prog) : $spawn ? undef : -1;
    my $e = $!; close $_ for @opened; $! = $e;
    return $res;
  }
  return launch($spawn, 1, $args, $errs, $prog) unless @$redirs;
  my $base = 3;			# first fd above every target
  $_->[0] >= $base and $base = $_->[0] + 1 for @$redirs;
  # A file Run opened may sit on a target fd: move it above all targets.
  my (@pins, @list);
  for (@$redirs) {
    my ($n, $how, $fh) = @$_;
    if ($how ne 'pin') { push @list, $_; next }
    my $pin = dup_above($fh, $base) or return err($errs, "fd $n: $!");
    push @pins, $pin;
    push @list, [$n, fd => fileno $pin];
  }
  forkless() ? wraparound($spawn, $args, \@list, $base, $errs, $prog)
              : fork_kid($spawn, 1, $args, \@list, $base, $errs, $prog);
}

# Closes the fd of handle $h even when PerlIO counts another owner for that
# fd number: inside the wraparound, a Perl handle may still claim a fd that
# apply() has closed or replaced, and a new handle on that number would then
# never close it.  (A pipe end left open hangs its reader.)
sub close_fd { my $h = shift; POSIX::close(fileno $h); close $h }

# fork(), apply the redirections in the kid, exec ($list: as for launch()).
# A close-on-exec pipe carries "errno message" back if anything before exec
# fails.
sub fork_kid {
  my ($spawn, $list, $args, $redirs, $base, $errs, $prog) = @_;
  pipe my $r0, my $w0 or return err($errs, "pipe: $!");
  my ($r, $w) = (scalar dup_above($r0, $base), scalar dup_above($w0, $base, ">"));
  close_fd($_) for $r0, $w0;
  my $pid = $r && $w ? fork : return err($errs, "dup: $!");
  unless (defined $pid) {
    my $e = "fork: $!";
    close_fd($_) for $r, $w;
    return err($errs, $e);
  }
  if (!$pid) {
    close_fd($r);
    my @kid_errs;
    if (apply($redirs, \@kid_errs)) {
      { no warnings 'exec'; $list ? exec { $prog // $args->[0] } @$args : exec @$args }
      err(\@kid_errs, "exec `@$args': $!");
    }
    syswrite $w, ($!+0) . " $kid_errs[0]";
    POSIX::_exit(127);
  }
  close_fd($w);
  my $msg = do { local $/; <$r> } // '';
  close_fd($r);
  if (length $msg) {
    my ($errno, $text) = split ' ', $msg, 2;
    waitpid $pid, 0;
    push @$errs, $text;
    $! = $errno;
    return $spawn ? undef : -1;
  }
  return $pid if $spawn;
  local @SIG{qw(INT QUIT)} = ('IGNORE') x 2;
  waitpid $pid, 0;
  $?;
}

# Whether fd $n has FD_CLOEXEC.  Perl cannot just look: any Perl open of the
# fd, even "<&=$n", sets or clears the flag by $^F (modern Perls).  On Linux
# the flag is read from /proc.  Elsewhere it is inferred: if closing an alias
# closes $n, no Perl handle owns it, so it was inherited, without the flag;
# otherwise Perl opened it, with the flag iff $n > $^F (unless someone has
# changed it since).  Either way $n is left as it was.  undef if $n is closed.
my $cloexec_bit;
sub fdinfo_flags {
  open my $i, '<', "/proc/self/fdinfo/$_[0]" or return;
  my ($f) = map /^flags:\s*(\d+)/ ? oct $1 : (), <$i>;
  $f;
}
sub is_cloexec {
  my $n = shift;
  if ($AsWin32) {		# Win32: read, not inferred (0.07)
    my $i = os_inherit($n) // return;
    return $i ? 0 : 1;
  }
  unix_is_cloexec($n);
}
sub unix_is_cloexec {
  my $n = shift;
  unless (defined $cloexec_bit) {
    $cloexec_bit = 0;
    if (pipe my $r, my $w) {
      fcntl($r, F_SETFD, FD_CLOEXEC); my $on  = fdinfo_flags(fileno $r);
      fcntl($r, F_SETFD, 0);          my $off = fdinfo_flags(fileno $r);
      $cloexec_bit = $on ^ $off if defined $on and defined $off;
    }
  }
  if ($cloexec_bit and defined(my $f = fdinfo_flags($n))) {
    return $f & $cloexec_bit ? 1 : 0;
  }
  open my $alias, '<&=', $n or return;
  release($alias, $n) && $n > $^F ? 1 : 0;
}

# Drops an alias handle of fd $n.  Closing it closes $n unless another Perl
# handle owns $n too (PerlIO counts owners per fd); if it did, put $n back.
# Returns whether another Perl handle owns $n.
sub release {
  my ($alias, $n) = @_;
  my $keep = POSIX::dup($n);
  close $alias;
  return unless defined $keep;
  my $owned = defined(my $probe = POSIX::dup($n));
  $owned ? POSIX::close($probe) : POSIX::dup2($keep, $n);
  POSIX::close($keep);
  $owned;
}

# Sets FD_CLOEXEC on fd $n.
sub set_cloexec {
  my $n = shift;
  return os_inherit($n, 0) if $AsWin32;
  unix_set_cloexec($n);
}
sub unix_set_cloexec {
  my $n = shift;
  local $^F = $n - 1 if $n - 1 < $^F;	# Perl's own open sets it for fd > $^F
  open my $alias, '<&=', $n or return;
  fcntl($alias, F_SETFD, FD_CLOEXEC);
  release($alias, $n);	# if this had to reopen $n, the flag is lost: see POD
}

# No fork(): save every target fd above $base, apply the redirections in
# this process, spawn (the kid inherits the table), then put every target back
# as it was: same file, same FD_CLOEXEC, or closed.
sub wraparound {
  my ($spawn, $args, $redirs, $base, $errs, $prog) = @_;
  IO::Handle::flush($_) for grep defined fileno $_, \*STDOUT, \*STDERR,
    map $_->[1] eq 'fh' ? $_->[2] : (), @$redirs;
  my (%seen, @saved, $res);
  my $ok = 1;
  for my $n (grep !$seen{$_}++, map $_->[0], @$redirs) {
    my $cloexec = is_cloexec($n);	# before any Perl handle touches $n
    if (!defined $cloexec) {
      $!{EBADF} or $ok = err($errs, "fd $n: $!"), last;
      push @saved, [$n];		# closed now, closed afterwards
      next;
    }
    my $copy;
    if ($AsWin32) {		# an fd number does there: no alias needed
      $copy = dup_above($n, $base);
    } else {
      # The alias may change $n's flag; harmless, as apply() replaces $n.
      open my $alias, '<&=', $n or $ok = err($errs, "fd $n: $!"), last;
      $copy = dup_above($alias, $base);
      release($alias, $n);
    }
    $copy or $ok = err($errs, "fd $n: $!"), last;
    push @saved, [$n, $copy, $cloexec];
  }
  if ($ok and apply($redirs, $errs)) {
    $res = launch($spawn, 1, $args, $errs, $prog);
  }
  for (reverse @saved) {
    my ($n, $copy, $cloexec) = @$_;
    if (!$copy) { POSIX::close($n); next }
    POSIX::dup2(fileno $copy, $n);	# clears FD_CLOEXEC
    close $copy;
    set_cloexec($n) if $cloexec;
  }
  $res;
}

sub run_system_spawn {
  my $do_spawn = shift;
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  # Sets result in $data->{result} on failure
  local %ENV = (%ENV, %{$data->{env}}) if $data->{env};

  # Expand args:
  my @args = map {ref $_ ? $_->run : ($_)} @$tree;
  return if grep !defined, @args;

  my $print_errs = not exists $data->{errs};
  my $errs = $print_errs ? [] : $data->{errs};
  my $spawn = $do_spawn || $data->{'spawn'};
  my @opened;
  my $redirs = redir_list($data->{redir} || [], \@opened, $errs);
  my $res = $redirs && start($spawn, \@args, $redirs, $errs);
  if ($spawn) {
    push @{$data->{pids}}, $res if $res;
  } else {
    $data->{result} = $res //= -1;
    push @$errs, "system `@args': rc=$res" if $res > 0;
    $res = $res == 0 ? 1 : undef;
  }
  close $_ for @opened;
  print STDERR join "\n", @$errs, "" if $print_errs and @$errs;
  return $res;
}

sub Run::system::run {
  run_system_spawn(0,@_);
}

sub Run::spawn::run {
  run_system_spawn(1,@_);
}


sub Run::chain::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $out = 1;

  print(STDERR "cannot 'chain' with spawn\n"), return if $data->{'spawn'};
  $out = $_->run($data) for @$tree;	# as sh: the last command decides
  return $out;
}

sub Run::and::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;

  print(STDERR "cannot 'and' with spawn\n"), return if $data->{'spawn'};
  for my $cmd (@$tree) {
    my $res = $cmd->run($data);
    return unless defined $res;
  }
  return 1;
}

sub Run::or::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;

  print(STDERR "cannot 'or' with spawn\n"), return if $data->{'spawn'};
  for my $cmd (@$tree) {
    my $res = $cmd->run($data);
    return 1 if defined $res;
  }
  return;
}

sub Run::env::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  local $data->{env} = { %{$data->{env} || {}}, %{$tree->[0]} };
  $tree->[1]->run($data);
}

# Outer redirections apply first, then these: like sh's "{ cmd 2>&1; } >f".
# A fresh list is localized, so siblings never see these entries.
sub Run::redir::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my $print_errs = not exists $data->{errs};
  my $errs = $print_errs ? [] : $data->{errs};
  my @opened;
  my $outer = redir_list($data->{redir} || [], \@opened, $errs);
  my $inner = $outer && redir_list($tree->[0], \@opened, $errs);
  my $ret;
  if ($inner) {
    local $data->{redir} = bless [@$outer, @$inner], 'Run::redirlist';
    $ret = $tree->[1]->run($data);
  } else {
    $data->{result} = -1;	# nothing started
  }
  close $_ for @opened;
  print STDERR join "\n", @$errs, "" if $print_errs and @$errs;
  return $ret;
}

sub Run::pipe::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  my ($dir, $cmd) = @$tree;
  pipe my $r, my $w
    or print(STDERR "cannot create pipe: $!\n"), return;
  cloexec_fh($_) for $r, $w;	# even with a large $^F
  my ($kid_end, $ours, $fd) = $dir eq 'r' ? ($w, $r, 1) : ($r, $w, 0);
  local $data->{'spawn'} = 1;
  Run::redir->new([$fd => {filehandle => $kid_end, pin => 1}], $cmd)
    ->run($data) or return;
  close $kid_end;
  return $ours;
}

# The whole output of $cmd; the kid is reaped and its $? left in
# $data->{result}.
sub read_all {
  my ($cmd, $data) = @_;
  $data //= {};
  local $data->{pids} = [];
  my $pipe = Run::pipe->new(r => $cmd)->run($data) or return;
  my $out = do { local $/; <$pipe> } // '';
  close $pipe;
  waitpid $_, 0 for @{$data->{pids}};
  $data->{result} = $?;
  $out;
}

sub Run::readpipe::run { read_all($_[0][0], $_[1]) }

sub Run::readpipe_split::run {
  my $out = read_all($_[0][0], $_[1]);
  defined $out ? split ' ', $out : ();
}

# a | b | ... : see PIPELINES in the POD.
sub is_simple {
  my $t = shift;
  $t = $t->[1] while ref $t eq 'Run::env' or ref $t eq 'Run::redir';
  ref $t eq 'Run::system' or ref $t eq 'Run::spawn';
}

# A wait status as an exit code for a forked copy of this process.
sub exit_code {
  my $st = shift // -1;
  $st == -1 ? 127 : $st & 127 ? 128 + ($st & 127) : $st >> 8;
}

sub Run::pipeline::run {
  $_[1] = {} unless defined $_[1];
  my ($tree, $data) = @_;
  print(STDERR "cannot 'pipeline' with spawn\n"), return if $data->{'spawn'};
  my $print_errs = not exists $data->{errs};
  my $errs = $print_errs ? [] : $data->{errs};
  my @compound = grep !is_simple($tree->[$_]), 0 .. $#$tree;
  my $here = $compound[-1];	# runs in this process
  my ($started, $died, @opened, @pipes, @pid, @status, @errpipe);
  # $pipes[$i]: [read end, write end] between elements $i and $i+1
  my $ends = sub {		# fds 0 and 1 of element $_[0]
    my $i = shift;
    ($i ? $pipes[$i-1][0] : undef, $i < $#$tree ? $pipes[$i][1] : undef);
  };
  my $others = sub {		# the pipe ends element $_[0] does not use
    my %mine = map +($_ => 1), grep defined, defined $_[0] ? $ends->($_[0]) : ();
    grep !$mine{$_}, map @$_, @pipes;
  };
  my $outer = redir_list($data->{redir} || [], \@opened, $errs);
  my $redirs = sub {		# outer redirections first, then the pipe
    my ($in, $out) = $ends->(shift);
    bless [@$outer, ($in ? [0, pin => $in] : ()), ($out ? [1, pin => $out] : ())],
      'Run::redirlist';
  };
  {
    $outer or last;
    @compound > 1 and forkless() and err($errs,
      "pipeline: without fork (\$Run::Forkless), only one element may be other than a simple command"), last;
    for (1 .. $#$tree) {
      pipe my $r, my $w or err($errs, "cannot create pipe: $!"), last;
      cloexec_fh($_) for $r, $w;	# even with a large $^F
      push @pipes, [$r, $w];
    }
    @pipes == $#$tree or last;
    $started = 1;
    for my $i (grep !defined $here || $_ != $here, 0 .. $#$tree) {
      local $data->{redir} = $redirs->($i);
      if (is_simple($tree->[$i])) {
	local $data->{spawn} = 1;
	local $data->{pids} = [];
	$tree->[$i]->run($data);
	$pid[$i] = $data->{pids}[0];
	next;
      }
      # Another compound element: in a forked copy of this process, which
      # sends its messages back through a pipe when the caller collects them.
      pipe my $er, my $ew or err($errs, "cannot create pipe: $!"), next;
      defined($pid[$i] = fork) or err($errs, "fork: $!"), next;
      if ($pid[$i]) { close $ew; $errpipe[$i] = $er; next }
      close $_ for $er, $others->($i);
      local $data->{errs} = [] unless $print_errs;
      undef $data->{result};
      my $code = eval { $tree->[$i]->run($data); exit_code($data->{result}) } // do {
	$print_errs ? print STDERR $@ : push @{$data->{errs}}, $@ =~ s/\n\z//r;
	255;
      };
      close $_ for grep defined, $ends->($i);	# no reader waits for the messages
      syswrite $ew, join "\0", @{$data->{errs}} unless $print_errs;
      POSIX::_exit($code);
    }
    close $_ for $others->($here);
    if (defined $here) {
      local $data->{redir} = $redirs->($here);
      undef $data->{result};
      eval { $tree->[$here]->run($data); 1 } or $died = $@;
      $status[$here] = $data->{result} // -1;
    }
  }
  close $_ for grep defined fileno $_, map @$_, @pipes;
  for my $er (grep defined, @errpipe) {
    push @$errs, split /\0/, do { local $/; <$er> } // '';
    close $er;
  }
  {
    local @SIG{qw(INT QUIT)} = ('IGNORE') x 2;
    for (grep $pid[$_], 0 .. $#$tree) { waitpid $pid[$_], 0; $status[$_] = $? }
  }
  # -1: nothing started, or the last element did not start
  $data->{result} = $started ? $status[$#$tree] // -1 : -1;
  close $_ for @opened;
  print STDERR join "\n", @$errs, "" if $print_errs and @$errs;
  die $died if defined $died;	# after every kid has been reaped
  $data->{result} == 0 ? 1 : undef;
}

sub Run::base::new {
  my $class = shift;
  bless [@_], $class;
}

sub Run::base2::new {
  my $class = shift;
  die "need two arguments in $class\->new" unless @_ == 2;
  bless [@_], $class;
}

sub Run::base1::new {
  my $class = shift;
  die "need one argument in $class\->new" unless @_ == 1;
  bless [@_], $class;
}

sub new_system	{ Run::system->new(@_) }
sub new_spawn	{ 'Run::spawn'->new(@_) }
sub new_or	{ Run::or->new(@_) }
sub new_and	{ Run::and->new(@_) }
sub new_chain	{ Run::chain->new(@_) }
sub new_env	{ Run::env->new(@_) }
sub new_redir	{ Run::redir->new(@_) }
sub new_pipe	{ Run::pipe->new(@_) }
sub new_pipeline	{ Run::pipeline->new(@_) }
sub new_readpipe	{ Run::readpipe->new(@_) }
sub new_readpipe_split	{ Run::readpipe_split->new(@_) }

1;
__END__

=head1 NAME

Run - start programs in the background, and run command trees (and, or, chains, pipelines, redirections) without a shell

=head1 SYNOPSIS

  use Run;                      # exports spawn
  my $pid = spawn 'long_running_task', 'arg1', 'arg2' or die "spawn: $!";
  do_something_else();
  waitpid $pid, 0;

  use Run ':NEW';               # the command trees
  my $tree = new_pipeline(new_system('sort'),
                          new_redir([1 => {filename => 'out.txt', mode => '>'}],
                                    new_system('uniq', '-c')));
  my %data = (errs => []);
  $tree->run(\%data) or warn "status $data{result}: @{$data{errs}}";

  # one program, its redirections applied as sh would (public since 0.07)
  my @errs;
  my $kid = Run::start(1, ['prog', 'arg'],
                       [1 => {filename => 'log', mode => '>>'}, 2 => {fd => 1}],
                       \@errs);

=head1 DESCRIPTION

Run starts programs with redirections, without a shell, on systems with
C<fork> and on systems with a native spawn but no C<fork> (Win32, OS/2,
VMS; see L</FORKLESS>).  It has three layers:

=over

=item C<spawn>

like the builtin C<system>, but the program runs in the background (see
L</spawn>);

=item command trees

nodes for simple commands, C<&&>, C<||>, C<;>, pipelines, pipes to and from
this process, command substitution, environment settings and redirections,
which C<run> as sh would run the same command line (see L</COMMAND TREES>);

=item C<Run::start>

one program with a list of redirections (see L</STARTING ONE PROGRAM>), the
layer the others are built on; L<Proc::Spawner> uses it where there is
neither posix_spawn nor C<fork>.

=back

=head1 EXPORT

C<spawn> by default; the tag C<:NEW> exports the constructors
C<new_system>, C<new_spawn>, C<new_and>, C<new_or>, C<new_chain>,
C<new_env>, C<new_redir>, C<new_pipe>, C<new_pipeline>, C<new_readpipe>
and C<new_readpipe_split>.

=head1 spawn

C<spawn LIST> starts LIST as the builtin C<system LIST> would (a single
string is a command line for the shell; more elements, a program and its
arguments) and returns the kid's pid at once; the caller waits for it with
C<waitpid>.  Without C<fork> it is C<system 1, LIST> (P_NOWAIT).  When
nothing was started it returns undef, with C<$!> set.

=head1 COMMAND TREES

A tree is built of these nodes (C<CMD> is a node):

=over

=item C<new_system(PROG, ARGS...)>

runs PROG with ARGS and waits for it.  PROG and ARGS are never a shell
command line: a single element is a program name (as C<system { PROG }
PROG, ARGS>).  An element that is itself a node (C<new_readpipe>,
C<new_readpipe_split>) is replaced by that node's output first, as a
command substitution is.

=item C<new_spawn(PROG, ARGS...)>

the same, without waiting: the kid's pid is pushed on C<$data-E<gt>{pids}>.

=item C<new_and(CMD...)>, C<new_or(CMD...)>, C<new_chain(CMD...)>

C<CMD && CMD ...>, C<CMD || CMD ...> and C<CMD; CMD ...>.  They wait for
each command, so they cannot run under C<new_spawn> or C<new_pipe>.

=item C<new_env({NAME =E<gt> VALUE, ...}, CMD)>

CMD with these variables added to its environment.

=item C<new_redir(REDIRS, CMD)>

CMD with these redirections (see L</REDIRECTIONS>), applied after the
outer ones, as in sh's C<{ CMD 2E<gt>&1; } E<gt>f>.

=item C<new_pipeline(CMD...)>

C<CMD | CMD | ...>; see L</PIPELINES>.

=item C<new_pipe('r' or 'w', CMD)>

starts CMD (a simple command) with its fd 1 (C<'r'>) or fd 0 (C<'w'>) on a
pipe, and C<run> returns this process's end of it as a handle.  The kid's
pid is pushed on C<$data-E<gt>{pids}>; the caller waits for it.

=item C<new_readpipe(CMD)>, C<new_readpipe_split(CMD)>

C<run> returns CMD's whole output (trailing newlines kept), or that output
split at whitespace; the kid is waited for.  As an argument of
C<new_system> they are command substitutions.

=back

C<$tree-E<gt>run(\%DATA)> runs a tree; C<%DATA> (optional) passes:

=over

=item C<errs =E<gt> \@ERRS>

the messages (a program or a file that could not be opened, ...) are
pushed here; without it they are printed on STDERR.

=item C<env =E<gt> {...}>, C<redir =E<gt> REDIRS>

variables and redirections for every command of the tree.

=item C<pids =E<gt> \@PIDS>

receives the pids of C<new_spawn> and C<new_pipe> kids.

=item C<result>

set by C<run>: the C<$?> of the last command that ran, 0 included, or -1
when nothing was started (the program or a redirection target could not
be opened; the reason is in C<errs>).

=back

C<run> returns true iff the command succeeded (C<new_pipe>: the handle;
C<new_readpipe>: the output).  After C<new_and>, C<new_or>, C<new_chain>
and C<new_pipeline>, C<result> holds the status sh would give; C<new_chain>
succeeds iff its last command does, as in sh.

=head1 PIPELINES

C<new_pipeline(CMD1, CMD2, ...)> is C<CMD1 | CMD2 | ...>.  An element
that is a simple command (C<new_system> or C<new_spawn>, possibly under
C<new_env> and C<new_redir>) is spawned with the pipe ends as fds 0 and 1:
after the outer redirections and before its own, as in sh.

Any other element (C<new_and>, C<new_or>, C<new_chain>, a nested
C<new_pipeline>) runs in this process, after every other element has
started, with the pipe ends applied to each command it starts.  This
process keeps its write end open until the element's last command has
ended, so in C<{ A || B } | C> the reader sees one stream: B starts (or
not) when A has ended, and C sees end of file only after that.  Before
running it, this process closes every other pipe end, so readers see end
of file and writers get C<SIGPIPE> as in sh.

Only one element can run in this process (the last such one).  Where
C<fork> exists, the others run in forked copies of this process, which
exit with the status of their last command (255 if it died); their
messages, and the message of a C<die>, come back into C<errs>.
With C<$Run::Forkless> a second such element is refused.  If the element
run in this process dies, the pipeline closes its pipes, reaps its kids
and then rethrows.

The pipeline succeeds iff its last element does; C<$data-E<gt>{result}>
is the last element's status, or -1 if it did not start or nothing could
be started (a pipe could not be created, a refused element).  An element that
did not start is reported in C<errs> and the others run on.  The
pipeline cannot itself run under C<spawn> (as a C<new_pipe> element).

=head1 REDIRECTIONS

C<new_redir>, C<run({redir =E<gt> ...})> and C<Run::start> take either a
hash C<{FD =E<gt> SPEC}>, applied in increasing FD, or an array
C<[FD =E<gt> SPEC, ...]>, applied in the order given.  As in sh,
redirections are applied left to right, outer C<new_redir> first, so
C<[1 =E<gt> {filename =E<gt> 'f', mode =E<gt> 'E<gt>'}, 2 =E<gt> {fd =E<gt> 1}]>
is C<E<gt>f 2E<gt>&1>, and the reverse order is C<2E<gt>&1 E<gt>f>.  SPEC is one of:

=over

=item C<{filename =E<gt> NAME, mode =E<gt> OP}>

NAME is the file's name as it is (C<->, C<&1> and leading blanks are
literal), opened as sh's OP does: C<E<lt>> reads, C<E<gt>> and
C<E<gt>|> create or truncate, C<E<gt>E<gt>> appends, C<E<lt>E<gt>> reads
and writes, creating the file but not truncating it.  FD becomes a copy of
that file.  Use this form for names that come from elsewhere.

=item C<{fd =E<gt> M}> (since 0.07), C<{filehandle =E<gt> FH}>

FD becomes a copy of fd M (or C<fileno FH>) I<as it is at that point>, so
an earlier redirection of that fd counts: sh's C<FDE<gt>&M>.

=item C<{close =E<gt> 1}> (since 0.07)

FD is closed in the kid: sh's C<FDE<gt>&->.

=item C<{filehandle =E<gt> FH, pin =E<gt> 1}>

FD becomes a copy of FH's file, even when C<fileno FH> is itself one of
the target fds: FH is first copied above every target.  This is the safe
way to pass a file the caller opened, or a pipe end.

=item C<{filename =E<gt> STRING}>

the older form: C<'E<gt>&N'> (or C<'E<gt>&=N'>, C<'E<lt>&N'>) is
C<{fd =E<gt> N}>, C<'E<gt>&-'> (or C<'E<lt>&-'>) is C<{close =E<gt> 1}>;
any other STRING is opened with 2-argument C<open> (so C<-> means STDIN or
STDOUT, leading blanks are dropped, and so on), and FD becomes a copy of
that file.

=back

Where C<fork> exists, the redirections are applied in the kid between
C<fork> and C<exec>, and the parent's fd table is never changed.  Where it
does not (forkless, see below), they are applied in the parent around a
spawn that inherits the fd table, and afterwards every target fd is put
back as it was: open on the same file with the same close-on-exec flag, or
closed.

=head1 STARTING ONE PROGRAM

C<Run::start(SPAWN, \@ARGS, REDIRS, \@ERRS, PROG)> (public since 0.07) runs
the program C<@ARGS> (never a shell command line) with REDIRS applied (see
L</REDIRECTIONS>; files it opens for them are closed again after the
start).  PROG (optional) is the program to run when it is not
C<$ARGS[0]>, as C<system { PROG } LIST>.  Returns the pid when SPAWN is
true, else C<$?>; when nothing was started, undef (SPAWN) or -1, with C<$!>
set and a message pushed on C<@ERRS>.

=head1 FORKLESS

On OS/2, Win32 and VMS C<$Run::Forkless> is true, and Run starts every
process with one primitive,
C<Run::spawn_nowait(LIST_FLAG, \@ARGS, \@ERRS, PROG)>: like
C<spawnvp(P_NOWAIT)>, the kid gets this process's fd table as it is
(except close-on-exec fds), and the pid is returned (undef, with a
message, if nothing started).  There it is C<system { PROG } 1, ARGS>
(with a false LIST_FLAG, C<system 1, ARGS>, whose single string is a
command line).  Nothing else in Run forks; C<new_system> is
C<spawn_nowait> followed by C<waitpid>.

On Unix, which has no spawn, the primitive is emulated by C<fork> and
C<exec> with nothing in between.  Setting C<$Run::Forkless> (C<local> is
fine; C<$Run::Wraparound> is the old name, and either one set means
forkless) runs the forkless code paths there, which is how they are
tested.

Limits of the parent-side way: other threads see the redirected fds while
the kid starts; and outside Linux and Win32 the close-on-exec flag of a
target fd is inferred, not read (Perl cannot look at it without changing
it), so a fd opened by C code with the flag set comes back without it.

=head2 Win32

Perl's own spawn passes a kid fds 0..2 only (as its standard handles), and
in a new process group; at most 64 kids can be running at once (Perl's
table of children: then C<EAGAIN>).  Perl has no C<fcntl> there:
close-on-exec is the handle's inheritance, read and set through
L<Win32API::File> (which comes with Perl there; since 0.07).  A kid's
arguments go through Perl's command line, which does not quote them as the
kid's C runtime parses them back: an argument with C<"> or a trailing
C<\> does not arrive as given (a bug of Perl's; the test is TODO).
Tested under Wine with Strawberry Perl 5.38.2; OS/2 and VMS are not tested.

C<$Run::AsWin32> (true on Win32) selects these code paths: copies made by
C<dup> instead of C<F_DUPFD>, no alias handles while fds are saved, the
flag read and set through C<os_inherit()>.  Set it on Unix (or
C<RUN_AS_WIN32=1> in the environment, before Run is loaded) to debug and
test them there: C<FD_CLOEXEC> then stands in for the handle's
inheritance, so all but the Win32API::File calls themselves run.
F<t/as-win32.t> runs every test file so.

=head1 NOTES

C<open FH, "E<gt>&=FH1"> creates a "naughty" copy of C<FH1>.  Closing
C<FH> will invalidate C<FH1> -- unless another Perl handle also uses that
fd: PerlIO counts the handles of each fd.  Such an open also sets or
clears close-on-exec on that fd according to C<$^F>.

=head1 TODO

The messages of the commands of C<new_or> that failed stay in C<errs> when
a later one succeeds; should they be cleared?

=head1 AUTHOR

Ilya Zakharevich E<lt>ilyaz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1997-2026 by Ilya Zakharevich.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  That is, at your choice, under the
GNU General Public License as published by the Free Software Foundation
(version 1, or any later version), or under the Artistic License that comes
with Perl (see L<perlartistic> and L<perlgpl>).

=head1 SEE ALSO

L<perlfunc/system>, L<perlport>, L<Proc::Spawner>.

=cut
