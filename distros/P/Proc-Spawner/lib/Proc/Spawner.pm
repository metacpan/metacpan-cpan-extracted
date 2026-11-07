package Proc::Spawner;
# EXPERIMENTAL.  Starts child processes with posix_spawn(3), and runs the one event loop that
# reports what happened: a child ended, an fd became readable or writable.  Nothing else: what the
# children are connected to, and what to do when one ends, is the business of the caller
# (Proc::Spawner::Graph, the companion module, keeps that as a graph).
#
#   start(PATH, ARGV, ENVP, FDS, %opt)  a pid, or undef with $!; with pidfd => 1 in list context, the pid
#        and a pidfd.  FDS: { CHILD_FD => PARENT_FD, or [PATH, FLAGS, MODE] opened in the child, or undef
#        for closed }; an fd not listed is inherited as it is (if it is not close-on-exec).
#        %opt: every setting posix_spawn has (glibc 2.39), and umask, unsupported:
#          chdir => DIR, fchdir => FD          the child's current directory (FD: the parent's fd), set
#                                              before the fds, so FDS paths are relative to it
#          sigdefault => [SIGNALS]             back to the default action in the child (names or numbers)
#          sigmask => [SIGNALS]                blocked in the child; default: none
#          pgroup => PGID                      its process group (0: a new one, led by the child)
#          setsid => 1                         a new session
#          tcsetpgrp => FD                     its group becomes the terminal's foreground, through FD as
#                                              the child has it
#          resetids => 1, sched => [POLICY, PRIORITY], cgroup => FD (a cgroup v2 directory)
#          search => 1                         look PATH up in the PATH of the parent's %ENV (posix_spawnp)
#          pidfd => 1                          also a pidfd (pidfd_spawn)
#          umask => N                          posix_spawn has none: set in Perl just around the call, so
#                                              bullet-proof only in non-threaded execution (the umask is the
#                                              whole process's)
#          unsupported => { OPTION => 'drop' | 'fail' }   passed on to spawn
#          on_exit => CODE                     gets the wait status; undef if other code collected it
#                                              first (finding C2)
#        posix_spawn cannot ignore a signal in the child (it inherits what Perl ignores), nor set
#        resource limits or the nice value.
#   spawn(FILE, ARGV, ENVP, ACTIONS, ATTR, UNSUPPORTED)  the raw call, see the POD at the end.  Meant to
#        have one interface on POSIX and on Windows: it wraps the XSUB __posix_spawn (on Windows: win_spawn.h's
#        posix_spawn on CreateProcessW) and does what that lacks around the call ($MISSING, below).  UNSUPPORTED
#        (optional): { OPTION => 'drop' | 'fail' }, what a port lacking an option (Windows) does with it;
#        options not listed there take %UNSUPPORTED's value, and '*' there covers the rest.  It applies here
#        too, to the posix_spawn extensions this build's libc lacks (chdir, fchdir, closefrom, tcsetpgrp,
#        pidfd, cgroup; Makefile.PL compiles a call to each): 'fail' fails with ENOTSUP.  EXPERIMENTAL
#   on_read(FD, N, CODE)       one read of at most N bytes when FD is readable: CODE->(BYTES), undef at end of file
#   on_write(FD, BYTES, CODE)  writes BYTES as the reader takes them; CODE->() when all is written or the
#                              reader is gone.  FD: a handle (made non-blocking) or an fd number (left as it is)
#   defer(CODE, ARGS)          queues CODE->(ARGS)
#   poll()                     runs what is ready now (queued calls, ended children, ready fds) without
#                              waiting; does nothing inside wait_until or a callback (EXPERIMENTAL, post-0.04)
#   wait_until(CODE)           runs the queue and waits for events until CODE->() is true
#
# The rules (decisions R1, D1-D3 of the page "Child Exit Wake-up"; EXPERIMENTAL, awaiting approval):
# every callback runs from the queue, one at a time, never inside a signal or inside another callback
# (R1).  A callback never waits: wait_until called from one dies (D2).  SIGCHLD is ours only while
# wait_until runs (D3); its handler is a C function (Proc::Spawner::chld_to_fd) that writes one byte into a
# pipe the loop selects on (D1), so no Perl code runs inside the signal and no wake-up is lost.  Without
# it, a deferred Perl handler, and select wakes up every $TICK seconds (B1).  Background: the document
# perl-signals-findings.md.
#
# Process-wide state flipped for a while, so bullet-proof only in non-threaded execution: the umask,
# around start's call (umask => N); the SIGCHLD action, while wait_until runs (D3).  Between waits a
# caller may move things on with poll(), for example from its own deferred SIGCHLD handler, as
# Proc::ShellSpawn does while background jobs remain (K3, the user's choice B, post-0.04).
use strict; use warnings;
use POSIX ();
use Fcntl qw(F_SETFD FD_CLOEXEC F_GETFL F_SETFL O_NONBLOCK);
use Config;
our $VERSION = '0.08';
require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);   # __posix_spawn, fpe_at_exec, chld_to_fd, chld_restore
our %UNSUPPORTED = ('*' => 'fail');   # the defaults for spawn's UNSUPPORTED (EXPERIMENTAL: '*' => 'fail')

# ------------------------------------------------------------------ settings the spawn primitive lacks (EXPERIMENTAL, post-0.06)
# $MISSING: a bitmap of the settings the primitive (posix_spawn here; CreateProcessW in a Windows port) does not do itself:
# what this build's libc lacks, plus $ENV{PROC_SPAWNER_MISSING} (names, for tests: the suite runs "as if").  spawn
# does the missing ones in this process, around the call, and undoes them after (bullet-proof only with one thread):
#   chdir, fchdir            this process changes directory, then comes back
#   dup2, close, open,       this process arranges its own fds as the child should have them (close: close-on-exec),
#   closefrom                then puts them back; one missing means all four, and chdir and fchdir too (the order)
#   sigmask                  this process's mask, set around the call (the child inherits it)
#   sigdefault               an ignored signal's action set back to the default around the call
#   pgroup => PGID (> 0)     this process joins the group around the call (the child inherits it)
#   resetids                 the effective ids set to the real ones around the call
#   search                   PATH looked up here; pidfd: pidfd_open right after the call
# Not possible so: setsid (no way back), tcsetpgrp and pgroup => 0 (the child's pid is known only after), sched
# and cgroup (not undone reliably): these are unsupported (drop or fail, as UNSUPPORTED says).  While this
# process's fds or directory are changed, every signal is blocked, so no handler of ours sees them; the child's mask
# is set by the primitive.  If sigmask is missing too, signals cannot be blocked without the child inheriting it: then
# a handler that runs in that moment sees the changed fds.
our @FEATURES = qw(chdir fchdir dup2 close open closefrom tcsetpgrp sigmask sigdefault pgroup setsid resetids sched cgroup pidfd search);
our %BIT; @BIT{@FEATURES} = map 1 << $_, 0 .. $#FEATURES;
our %NATIVE = map +($_ => 1), __native();
our %EMULABLE = map +($_ => 1), qw(chdir fchdir dup2 close open closefrom sigmask sigdefault pgroup resetids search pidfd);
our $MISSING = 0; $MISSING |= $BIT{$_} for grep !$NATIVE{$_}, @FEATURES;
for (split /[\s,]+/, $ENV{PROC_SPAWNER_MISSING} // '') {
  next unless length; exists $BIT{$_} or die "Proc::Spawner: PROC_SPAWNER_MISSING: unknown setting '$_' (known: @FEATURES)\n";
  $MISSING |= $BIT{$_} }
sub missing { my $m = @_ ? shift : $MISSING; grep $m & $BIT{$_}, @FEATURES }   # the names in a bitmap

sub spawn {   # the raw call: the primitive (__posix_spawn), with what it lacks done around it
  my ($file, $argv, $envp, $acts, $attr, $uns) = @_;
  return __posix_spawn(@_) unless $MISSING && (!defined $uns || ref $uns eq 'HASH');   # (its errors)
  my %m = map +($_ => 1), missing();
  ref $acts eq 'ARRAY' && (!defined $attr || ref $attr eq 'HASH') or return __posix_spawn(@_);   # its errors
  my %at = %{$attr // {}}; my @acts = @$acts;
  if (grep $m{$_}, qw(dup2 close open closefrom)) { $m{$_} = 1 for qw(dup2 close open closefrom chdir fchdir) }
  my $refuse = sub {   # an unsupported setting: true (and $! = ENOTSUP) to fail, false to drop it
    my $n = shift; my $v = ($uns && $uns->{$n}) // $UNSUPPORTED{$n} // $UNSUPPORTED{'*'} // 'fail';
    $v eq 'drop' ? 0 : do { $! = POSIX::ENOTSUP(); 1 } };
  for my $n (qw(setsid sched cgroup)) {
    next unless $m{$n} && ($n eq 'setsid' ? $at{$n} : defined $at{$n});
    return if $refuse->($n); delete $at{$n} }
  if ($m{pgroup} && defined $at{pgroup} && !$at{pgroup}) { return if $refuse->('pgroup'); delete $at{pgroup} }
  if ($m{tcsetpgrp} && grep ref eq 'ARRAY' && ($_->[0] // '') eq 'tcsetpgrp', @acts) {
    return if $refuse->('tcsetpgrp'); @acts = grep !(ref eq 'ARRAY' && ($_->[0] // '') eq 'tcsetpgrp'), @acts }
  my %kind = (chdir => 'dir', fchdir => 'dir', dup2 => 'fd', close => 'fd', open => 'fd', closefrom => 'fd');
  my (@here, @there);   # actions done here (in order), and those left to the primitive
  for my $x (@acts) { my $k = ref $x eq 'ARRAY' ? $x->[0] // '' : ''; if ($m{$k} && $kind{$k}) { push @here, $x } else { push @there, $x } }
  if (@here && @there) {   # what is done here happens first: so no action done there may come before one done here
    my %pos; @pos{map 0 + $_, @acts} = 0 .. $#acts;
    my $first_there = (sort { $a <=> $b } map $pos{0 + $_}, @there)[0];
    my $last_here = (sort { $b <=> $a } map $pos{0 + $_}, @here)[0];
    if ($first_there < $last_here) { $! = POSIX::EINVAL(); return } }   # (start() puts chdir first)
  my $sigmask = $m{sigmask} ? delete $at{sigmask} : undef;
  my $sigdef = $m{sigdefault} ? delete $at{sigdefault} : undef;
  my $pg = $m{pgroup} && defined $at{pgroup} ? delete $at{pgroup} : undef;
  my $reset = $m{resetids} && delete $at{resetids};
  my $pidfd = $m{pidfd} && delete $at{pidfd};
  if ($m{search} && delete $at{search} and $file !~ m{/}) {
    my ($p) = grep -x && !-d, map +(length ? $_ : '.') . "/$file", split /:/, $ENV{PATH} // '', -1;
    defined $p or do { $! = POSIX::ENOENT(); return }; $file = $p }
  my @undo; my $err; my @r;
  my $ok = eval {
    if (!$m{sigmask} && (@here || $sigdef || defined $pg || $reset)) {   # no handler of ours while this process is changed
      my ($all, $old) = (POSIX::SigSet->new, POSIX::SigSet->new); $all->fillset;
      POSIX::sigprocmask(POSIX::SIG_BLOCK(), $all, $old); unshift @undo, sub { POSIX::sigprocmask(POSIX::SIG_SETMASK(), $old) } }
    if ($sigmask) {
      my ($set, $old) = (POSIX::SigSet->new(signums($sigmask)), POSIX::SigSet->new);
      POSIX::sigprocmask(POSIX::SIG_SETMASK(), $set, $old) or die $!; unshift @undo, sub { POSIX::sigprocmask(POSIX::SIG_SETMASK(), $old) } }
    for my $sig ($sigdef ? signums($sigdef) : ()) {
      my $old = POSIX::SigAction->new; POSIX::sigaction($sig, undef, $old);
      next unless ($old->{HANDLER} // '') eq 'IGNORE';   # a caught signal is reset by exec anyway
      POSIX::sigaction($sig, POSIX::SigAction->new('DEFAULT')) or die $!; unshift @undo, sub { POSIX::sigaction($sig, $old) } }
    if (defined $pg) { my $old = getpgrp; POSIX::setpgid(0, $pg) or die $!; unshift @undo, sub { POSIX::setpgid(0, $old) } }
    if ($reset) {
      if ($> != $<) { my $e = $>; $> = $<; $> == $< or die $!; unshift @undo, sub { $> = $e } }
      my ($eg, $rg) = ((split ' ', $))[0], (split ' ', $()[0]);
      if ($eg != $rg) { my $o = $); $) = $rg; unshift @undo, sub { $) = $o } } }
    emulate_actions(\@here, \@undo) if @here;
    @r = __posix_spawn($file, $argv, $envp, \@there, \%at, $uns); $err = $!;
    if (@r && $pidfd) { my $fd = __pidfd_open($r[0]); push @r, $fd >= 0 ? $fd : undef }
    1 };
  $err = $@ =~ /^Proc::Spawner: errno (\d+)/ ? $1 : ($! + 0 || POSIX::EINVAL()) unless $ok;
  $_->() for @undo;
  $! = $err; $ok && @r or return; wantarray ? @r : $r[0] }   # (scalar context: the pid, as the XSUB gives it)

sub emulate_actions {   # the file actions, done on this process's own fds in order; the way back pushed on @$undo
  my ($acts, $undo) = @_;
  my $top = 10; for my $x (@$acts) { for (@$x[1 .. $#$x]) { $top = $_ + 1 if defined && /^[0-9]+\z/ && $_ >= $top } }
  my (%flag, %save, %ours);   # an fd's close-on-exec before (-1: was not open); its contents before (a copy; undef: none)
  my $die = sub { die "Proc::Spawner: errno " . (0 + $!) . "\n" };
  my $flag_touch = sub { my $fd = shift; $flag{$fd} //= __fd_cloexec($fd) };
  my $content_touch = sub { my $fd = shift; return if exists $save{$fd}; $flag_touch->($fd);
    $save{$fd} = $flag{$fd} >= 0 ? do { my $c = __dup_high($fd, $top + 1000); $c >= 0 or $die->(); $ours{$c} = 1; $c } : undef };
  my $here;   # this process's directory before
  unshift @$undo, sub {   # contents first, then the flags, then the directory
    for my $fd (keys %save) { my $c = $save{$fd}; defined $c ? (POSIX::dup2($c, $fd), POSIX::close($c)) : POSIX::close($fd) }
    for my $fd (keys %flag) { __set_cloexec($fd, $flag{$fd}) if $flag{$fd} >= 0 }
    if ($here) { __fchdir($here); POSIX::close($here) } };
  for my $x (@$acts) {
    my ($op, @a) = @$x;
    if ($op eq 'chdir' || $op eq 'fchdir') {
      $here //= do { my $h = POSIX::open('.', POSIX::O_RDONLY()); defined $h or $die->(); __set_cloexec($h, 1); $ours{$h} = 1; $h };
      ($op eq 'chdir' ? chdir $a[0] : __fchdir($a[0])) or $die->() }
    elsif ($op eq 'dup2') {
      my ($from, $to) = @a;
      if ($from == $to) { __fd_cloexec($from) >= 0 or do { $! = POSIX::EBADF(); $die->() }; $flag_touch->($to); __set_cloexec($to, 0) }
      else { __fd_cloexec($from) >= 0 or do { $! = POSIX::EBADF(); $die->() }; $content_touch->($to); defined POSIX::dup2($from, $to) or $die->() } }
    elsif ($op eq 'close') { $flag_touch->($a[0]); __set_cloexec($a[0], 1) if __fd_cloexec($a[0]) >= 0 }
    elsif ($op eq 'closefrom') {
      for my $fd ($a[0] .. __fd_limit() - 1) { next if $ours{$fd} || __fd_cloexec($fd) < 0; $flag_touch->($fd); __set_cloexec($fd, 1) } }
    elsif ($op eq 'open') {
      my ($fd, $path, $fl, $mode) = @a; $content_touch->($fd);
      my $o = POSIX::open($path, $fl, $mode // 0666); defined $o or $die->();
      if ($o == $fd) { __set_cloexec($fd, 0) } else { my $r = POSIX::dup2($o, $fd); my $e = $!; POSIX::close($o); defined $r or do { $! = $e; $die->() } } }
    else { $! = POSIX::EINVAL(); $die->() } } }

our $TRACE;    # undef, or a code ref given one line per operation
our $CAUSE;    # the caller's: a call queued keeps the value current when it was queued, and runs with it
our $REACTING = 0;   # true while a queued call runs
my $CHLD_C = defined &Proc::Spawner::chld_to_fd;
our %WINDOWS = (   # Windows only (EXPERIMENTAL, post-0.07): how every child is started (win_spawn.h, WIN_OPT_*)
  new_group => 1,          # in a process group of its own: Ctrl-C at the console reaches the parent, not the children
  kill_with_parent => 1,   # in a job object that Windows ends when this process ends, however it ends
  new_console => 1);       # a child with none of fds 0-2 gets a console of its own (as Perl's own spawn does)
our $WIN = $^O eq 'MSWin32';   # EXPERIMENTAL (post-0.07): no SIGCHLD, no fcntl, and select only on sockets: the loop polls
                               # for ended children every $TICK; on_read and on_write of pipes are not done there yet
our $TICK = $CHLD_C && !$WIN ? undef : 0.05;

sub tr_ { $TRACE->(join '', @_) if $TRACE }

# ------------------------------------------------------------------ spawning
my %SIGNUM; @SIGNUM{split ' ', $Config{sig_name}} = split ' ', $Config{sig_num};
my (@Q, %KID, %RD, %WR, $SELF_R, $SELF_W);

sub actions {   # the file actions giving a child exactly %$fds, whatever the parent's own fd numbers
  my $fds = shift; my @t = sort { $a <=> $b } keys %$fds;
  my @src = grep defined && !ref, values %$fds;
  my $top = 9; for (@t, @src) { $top = $_ if $_ > $top }
  my (@a, @open, %via, @scratch);
  for my $f (@src) {   # a source fd the child gets something else on: copy it first
    next if $via{$f} or !exists $fds->{$f} or !ref $fds->{$f} && ($fds->{$f} // -1) == $f;
    push @a, [dup2 => $f, $via{$f} = ++$top]; push @scratch, $top }
  for my $t (@t) {   # dup2 to itself too: it clears close-on-exec
    my $f = $fds->{$t} // next; ref $f ? push @open, [open => $t, @$f] : push @a, [dup2 => $via{$f} // $f, $t] }
  @a, @open, map [close => $_], (grep !defined $fds->{$_}, @t), @scratch }

sub signums { map $SIGNUM{$_} // (/^[0-9]+\z/ ? $_ : die "Proc::Spawner: unknown signal '$_'\n"), @{$_[0] // []} }
sub start {
  my ($path, $argv, $envp, $fds, %o) = @_;
  my @a = ((map [$_ => $o{$_}], grep defined $o{$_}, qw(chdir fchdir)), actions($fds),
           defined $o{tcsetpgrp} ? [tcsetpgrp => $o{tcsetpgrp}] : ());
  my %attr = (sigmask => [signums($o{sigmask})], sigdefault => [signums($o{sigdefault})],
              map +($_ => $o{$_}), grep exists $o{$_}, qw(pgroup setsid resetids sched cgroup search pidfd));
  my $um = defined $o{umask} && umask $o{umask};
  my ($pid, $pidfd) = spawn($path, $argv, $envp, \@a, \%attr, $o{unsupported});
  { local $!; umask $um if defined $o{umask} }
  my $how = join ', ', map "$$_[0] " . join('->', @$_[1 .. $#$_]), @a;
  $pid or return tr_("spawn failed: @$argv: $!"), undef;
  tr_("spawn $pid: $path [@$argv]", @a ? "; $how" : '');
  $KID{$pid} = $o{on_exit} // sub {}; $o{pidfd} && wantarray ? ($pid, $pidfd) : $pid }

# ------------------------------------------------------------------ the loop
sub defer { push @Q, [$CAUSE, @_] }
pipe $SELF_R, $SELF_W or die "pipe: $!";
unless ($WIN) { for ($SELF_R, $SELF_W) { fcntl($_, F_SETFD, FD_CLOEXEC); fcntl($_, F_SETFL, fcntl($_, F_GETFL, 0) | O_NONBLOCK) } }
my $CHLD = $WIN ? undef : POSIX::SigAction->new(sub { syswrite $SELF_W, 'x' }, POSIX::SigSet->new, POSIX::SA_RESTART());
$CHLD->safe(1) if $CHLD;   # the fallback: deferred; POSIX::sigaction's immediate default corrupts the heap (S2)

sub reap {   # our children only: waitpid(-1) would take statuses that are not ours (C2)
  for my $p (keys %KID) {
    my $r = waitpid $p, POSIX::WNOHANG(); next unless $r;
    my $w = $r > 0 ? $? : undef;
    tr_("reaped $p: ", defined $w ? "wait status $w" : 'status taken by other code');
    defer(delete $KID{$p}, $w) } }

our $DEPTH = 0;   # nesting of wait_until (outside reactions)
sub wait_until {
  my $done = shift;
  die "Proc::Spawner: wait inside a reaction\n" if $REACTING;   # D2
  my $old = POSIX::SigAction->new;
  ($CHLD_C ? Proc::Spawner::chld_to_fd(fileno $SELF_W) : POSIX::sigaction(POSIX::SIGCHLD(), $CHLD, $old)) unless $DEPTH || $WIN;
  my $ok = eval { local $DEPTH = $DEPTH + 1; turn() until $done->(); 1 };
  ($CHLD_C ? Proc::Spawner::chld_restore() : POSIX::sigaction(POSIX::SIGCHLD(), $old)) unless $DEPTH || $WIN;
  die $@ unless $ok }

sub turn {   # one queued call, or one round of waiting (at most $timeout seconds; default $TICK): false if nothing happened
  my $timeout = @_ ? shift : $TICK;
  if (@Q) { my ($cause, $k, @a) = @{shift @Q}; local ($CAUSE, $REACTING) = ($cause, 1); $k->(@a); return 1 }
  reap(); return 1 if @Q;
  die "Proc::Spawner: nothing left to wait for\n" unless %KID || %RD || %WR;
  if ($WIN) { select undef, undef, undef, $timeout // $TICK; return 0 }   # (no select on pipes there: polling only)
  my $rin = ''; vec($rin, $_, 1) = 1 for fileno $SELF_R, map $_->[0], values %RD;
  my $win = ''; vec($win, $_->[0], 1) = 1 for values %WR;
  my $n = select my $rout = $rin, my $wout = $win, undef, $timeout;
  1 while sysread $SELF_R, my $buf, 512;
  return 0 if $n <= 0;                  # timeout, or EINTR: the sets say nothing
  my %served;                           # one reader per fd and round, the oldest first
  for my $id (sort { $a <=> $b } keys %RD) {
    my ($fd, $len, $cb) = @{$RD{$id}};
    next if $served{$fd}++ or !vec($rout, $fd, 1);
    my $got = POSIX::read($fd, my $b, $len);
    next if !defined $got && $! == POSIX::EAGAIN();
    $got = 0 + ($got // 0);             # "0 but true" at end of file; an error ends it too
    delete $RD{$id};
    defer($cb, $got ? $b : undef) }
  for my $id (sort { $a <=> $b } keys %WR) {
    my $w = $WR{$id}; next unless vec($wout, $w->[0], 1);
    my $did = POSIX::write($w->[0], $w->[1], $w->[3] && $w->[3] < length $w->[1] ? $w->[3] : length $w->[1]);
    next if !defined $did && $! == POSIX::EAGAIN();
    substr($w->[1], 0, $did // length $w->[1]) = '';   # an error (the reader is gone) ends the write
    defer((delete $WR{$id})->[2]) if $w->[1] eq '' }
  1 }
sub poll {   # between waits (K3, the user's choice B, post-0.04): what is ready now, without waiting
  return if $REACTING || $DEPTH;
  local $DEPTH = $DEPTH + 1;            # a callback's own wait_until still dies (D2)
  1 while (@Q || %KID || %RD || %WR) && turn(0) }

my $ID = 0;
sub fd_of { ref $_[0] ? fileno $_[0] : $_[0] }
sub on_read { my ($fd, $n, $cb) = @_; $RD{++$ID} = [fd_of($fd), $n, $cb]; $ID }
sub on_write {   # $chunk: at most so many bytes per write (a blocking pipe: PIPE_BUF, which a writable pipe takes at once)
  my ($fd, $bytes, $cb, $chunk) = @_;
  fcntl($fd, F_SETFL, fcntl($fd, F_GETFL, 0) | O_NONBLOCK) if ref $fd && !$WIN;
  $WR{++$ID} = [fd_of($fd), $bytes, $cb, $chunk]; $ID }

1;

__END__

=head1 NAME

Proc::Spawner - start children with posix_spawn(3) and run the one event loop (EXPERIMENTAL)

=head1 SYNOPSIS

  my $pid = Proc::Spawner::start('/bin/ls', ['ls', '-l'], undef, { 1 => fileno $w, 3 => undef },
                                 chdir => '/tmp', sigdefault => ['PIPE'], on_exit => sub { ... });
  Proc::Spawner::wait_until(sub { $done });

  # the raw call, without the loop:
  my $pid = Proc::Spawner::spawn('ls', ['ls', '-l'], undef,
                              [[dup2 => fileno($w), 1], [close => 3], [chdir => '/tmp']],
                              {search => 1, sigdefault => [POSIX::SIGPIPE()]})
    // die "spawn: $!";

=head1 DESCRIPTION

The comments at the top of the module describe C<start> and the loop.

C<spawn(FILE, \@ARGV, \@ENV_OR_UNDEF, \@ACTIONS, \%ATTR, \%UNSUPPORTED)>
(here an alias of the XSUB C<__posix_spawn>) calls
C<posix_spawn> (or C<posix_spawnp> with C<< search => 1 >>; C<pidfd_spawn> or
C<pidfd_spawnp> with C<< pidfd => 1 >>) and returns the pid (and with
C<pidfd>, the pidfd too), or the empty list with C<$!> set.  C<\@ENV> is a
list of C<"NAME=value"> strings; undef passes C<environ>.

Actions, applied in the child in order: C<[dup2 =E<gt> FROM, TO]>,
C<[close =E<gt> FD]>, C<[open =E<gt> FD, PATH, FLAGS, MODE]>,
C<[chdir =E<gt> DIR]>, C<[fchdir =E<gt> FD]>, C<[closefrom =E<gt> FD]>,
C<[tcsetpgrp =E<gt> FD]> (the last four are glibc extensions).

Attributes: C<search>; C<pidfd>; C<sigdefault =E<gt> [SIGNUMS]> (reset to
the default action in the child); C<sigmask =E<gt> [SIGNUMS]> (the child's
signal mask, C<[]> for an empty one); C<pgroup =E<gt> PGID> (0: a new group
led by the child); C<setsid>; C<resetids>; C<sched =E<gt> [POLICY,
PRIORITY]>; C<cgroup =E<gt> FD>.

C<\%UNSUPPORTED> (optional) says, per option, what a port that lacks it (a
future Windows one) does: C<'drop'> it or C<'fail'>.  Options not listed take
the value in C<%Proc::Spawner::UNSUPPORTED>, where C<'*'> covers the rest
(default C<'fail'>, which fails the call with C<ENOTSUP>).  It applies with
posix_spawn too, to the extensions this build's libc lacks: C<chdir>,
C<fchdir>, C<closefrom>, C<tcsetpgrp>, C<pidfd> and C<cgroup>.  They are
functions, not macros, so F<Makefile.PL> finds them by compiling a call to
each (in glibc they came with 2.29, 2.29, 2.34, 2.35, 2.39 and 2.39).  A
dropped C<pidfd> returns only the pid.

=head1 LIMITATIONS

Process-wide state is flipped for a while, so these parts are bullet-proof
only in non-threaded execution: the umask, set around C<start>'s call
(C<< umask => N >>), and the SIGCHLD action, taken over while C<wait_until>
runs.  C<poll()> (EXPERIMENTAL) runs what is ready without waiting; it does
nothing inside C<wait_until> or a callback.  L<Proc::ShellSpawn> calls it from a
deferred SIGCHLD handler of its own between C<run()> calls while background
jobs remain; while that handler is installed, the program's own C<sleep> and
C<select> return early whenever a child ends.
posix_spawn cannot make the child ignore a signal, nor set its resource
limits or nice value.  Only Linux with glibc 2.39 has been tested.

=head1 AUTHOR

Ilya Zakharevich

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2026 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
