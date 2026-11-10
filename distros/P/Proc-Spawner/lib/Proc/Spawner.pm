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
#          sigignore => [SIGNALS]              ignored in the child
#          rlimit => { NAME => SOFT | [SOFT, HARD] }   the child's resource limits (NOFILE, CORE, ...; a number
#                                              or 'unlimited'; undef: as ours)
#          nice => INCREMENT                   as nice(1)
#                                              posix_spawn has none of these three: they are set right around
#                                              the call, in C, and put back (M1, post-0.08); one that could not
#                                              be put back is unsupported (spawn's POD)
#          unsupported => { OPTION => 'drop' | 'fail' }   passed on to spawn
#          on_exit => CODE                     gets the wait status; undef if other code collected it
#                                              first (finding C2)
#   spawn(FILE, ARGV, ENVP, ACTIONS, ATTR, UNSUPPORTED)  the raw call, see the POD at the end.  Meant to
#        have one interface on POSIX and on Windows: it wraps the XSUB __posix_spawn (on Windows: win_spawn.h's
#        posix_spawn on CreateProcessW) and does what that lacks around the call ($MISSING, below).  UNSUPPORTED
#        (optional): { OPTION => 'drop' | 'fail' }, what a port lacking an option (Windows) does with it;
#        options not listed there take %UNSUPPORTED's value, and '*' there covers the rest.  It applies here
#        too, to the posix_spawn extensions this build's libc lacks (chdir, fchdir, closefrom, tcsetpgrp,
#        pidfd, cgroup; Makefile.PL compiles a call to each): 'fail' fails with ENOTSUP.  EXPERIMENTAL
#   on_read(FD, N, CODE), on_write(FD, BYTES, CODE), defer(CODE, ARGS), poll(), wait_until(CODE), loop()
#        the one event loop, Proc::Spawner::Loop (W5, post-0.10: one interface on POSIX and on Windows), under its
#        old names; loop() is the loop object (read, write, child, after, pipe, ...: its POD).  The rules
#        (decisions R1, D1-D3 of the page "Child Exit Wake-up"): every callback runs from the queue, one at a time,
#        never inside a signal or inside another callback; a callback never waits; SIGCHLD is ours only while
#        wait_until runs.  Background: the document perl-signals-findings.md.
#
# Process-wide state flipped for a while, so bullet-proof only in non-threaded execution: the umask,
# around start's call (umask => N); the SIGCHLD action, while wait_until runs (D3).  Between waits a
# caller may move things on with poll(), for example from its own deferred SIGCHLD handler, as
# Proc::ShellSpawn does while background jobs remain (K3, the user's choice B, post-0.04).
use strict; use warnings;
use POSIX (); use File::Spec ();
use Fcntl qw(F_SETFD FD_CLOEXEC F_GETFL F_SETFL O_NONBLOCK);
use Config;
our $VERSION = '0.11';
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
#
# rlimit, sigignore and nice (M1, post-0.08), which POSIX's posix_spawn has no option for, are done by the XSUB itself
# right around its call, in C (Spawner.xs, around_parse), so they count as native; not on Windows.
#
# No posix_spawn at all (M2, post-0.08; Makefile.PL found none, or PROC_SPAWNER_MISSING has 'posix_spawn'), as Run
# 0.06's spawn_nowait: the primitive is __spawn_nowait, fork and exec with nothing in between; where there is no fork
# either (Windows, OS/2, VMS; on Linux in tests, PROC_SPAWNER_MISSING="posix_spawn fork": $PRIMITIVE 'system1') the
# redirections are delegated to Run (0.07; the user, 2026-11-07), whose start() applies them around Perl's own spawn,
# system { FILE } 1, ARGV (P_NOWAIT; on Unix Run emulates it by fork and exec) and puts our fds back; chdir and fchdir
# are done here.  Everything but rlimit, sigignore and nice (fork only) is then missing, and done around the call as
# above.  On Windows Perl's spawn passes the child fds 0-2 only, as its standard handles, always in a new process group;
# the arguments go to Perl as they are (its command line does not quote them as the C runtime parses them back:
# ❰BUG❱ in Perl, reported; the tests of exact argv there are TODO until Perl is fixed).
our @FEATURES = qw(chdir fchdir dup2 close open closefrom tcsetpgrp sigmask sigdefault pgroup setsid resetids sched cgroup pidfd search rlimit sigignore nice);
our %BIT; @BIT{@FEATURES} = map 1 << $_, 0 .. $#FEATURES;
our %NATIVE = map +($_ => 1), __native();
our %EMULABLE = map +($_ => 1), qw(chdir fchdir dup2 close open closefrom sigmask sigdefault pgroup resetids search pidfd);
my @ASKED = grep length, split /[\s,]+/, $ENV{PROC_SPAWNER_MISSING} // '';
our $FALLBACK = !$NATIVE{posix_spawn} || grep /^(?:posix_spawn|fork)\z/, @ASKED;   # no posix_spawn: __spawn_nowait or system1
my $NOFORK = grep $_ eq 'fork', @ASKED;
our %WINDOWS = (   # Windows only (EXPERIMENTAL, post-0.07): how every child is started (win_spawn.h, WIN_OPT_*)
  new_group => 1,          # in a process group of its own: Ctrl-C at the console reaches the parent, not the children
  kill_with_parent => 1,   # in a job object that Windows ends when this process ends, however it ends
  new_console => 1);       # a child with none of fds 0-2 gets a console of its own (as Perl's own spawn does)
our $WIN = $^O eq 'MSWin32';   # EXPERIMENTAL (post-0.07): no SIGCHLD, no fcntl; the loop's Windows backend (W5, post-0.10):
                               # Proc::Spawner::Loop::Win32
my %SIGNUM; @SIGNUM{split ' ', $Config{sig_name}} = split ' ', $Config{sig_num};
our $DOSISH = $^O =~ /^(?:MSWin32|os2|VMS)\z/;
our $PRIMITIVE = !$FALLBACK ? 'posix_spawn' : defined &__spawn_nowait && !$DOSISH && !$NOFORK ? 'fork' : 'system1';
%NATIVE = $PRIMITIVE eq 'fork' ? (map +($_ => 1), grep $NATIVE{$_}, qw(rlimit sigignore nice)) : () if $FALLBACK;
our $MISSING = 0; $MISSING |= $BIT{$_} for grep !$NATIVE{$_}, @FEATURES;
for (grep !/^(?:posix_spawn|fork)\z/, @ASKED) {
  exists $BIT{$_} or die "Proc::Spawner: PROC_SPAWNER_MISSING: unknown setting '$_' (known: posix_spawn fork @FEATURES)\n";
  $MISSING |= $BIT{$_} }
sub missing { my $m = @_ ? shift : $MISSING; grep $m & $BIT{$_}, @FEATURES }   # the names in a bitmap

our %WINJOB = (AS => 'ProcessMemoryLimit', DATA => 'ProcessMemoryLimit', CPU => 'PerProcessUserTimeLimit',
               NPROC => 'ActiveProcessLimit');   # W4's mapping of rlimit (approximate: see the POD)
my %CLASS_NICE = (idle => 19, below_normal => 5, normal => 0, above_normal => -5, high => -10, realtime => -20);
sub win_job_for_rlimit {   # W4: rlimit entries as win_job limits (approximate); also the resources with no counterpart
  my (%job, @none);
  for (@{+shift}) {
    my ($res, $soft, $hard) = @$_; (my $k = uc($res // '')) =~ s/^RLIMIT_//;
    my ($lim) = grep defined && $_ ne 'unlimited' && $_ ne 'infinity', $soft, $hard;   # the one that acts first
    my $w = $WINJOB{$k} or do { push @none, $k; next };
    next unless defined $lim;
    $lim *= 10_000_000 if $k eq 'CPU';   # seconds -> 100-ns units
    $job{$w} = defined $job{$w} && $job{$w} < $lim ? $job{$w} : $lim }
  (\%job, @none) }
sub win_class_for_nice {   # W4: a nice increment as a priority class, from ours (approximate; never realtime)
  my $n = ($CLASS_NICE{defined &__win_priority_class ? __win_priority_class() : 'normal'} // 0) + shift;
  $n >= 10 ? 'idle' : $n >= 1 ? 'below_normal' : $n == 0 ? 'normal' : $n > -10 ? 'above_normal' : 'high' }

sub spawn {   # the raw call: the primitive (__posix_spawn, or __spawn_nowait), with what it lacks done around it
  my ($file, $argv, $envp, $acts, $attr, $uns) = @_;
  if (!$FALLBACK) {
    my $winonly = !$WIN && ref $attr eq 'HASH' && grep defined $attr->{$_}, qw(win_priority win_job);   # (W4: refused here)
    return __posix_spawn(@_) unless ($MISSING || $winonly) && (!defined $uns || ref $uns eq 'HASH');   # (its errors)
    ref $acts eq 'ARRAY' && (!defined $attr || ref $attr eq 'HASH') or return __posix_spawn(@_) }   # its errors
  else {   # the same errors as __posix_spawn's
    !defined $uns || ref $uns eq 'HASH' or die "Proc::Spawner::spawn: unsupported must be a hash reference\n";
    ref $acts eq 'ARRAY' or die "Proc::Spawner::spawn: actions must be an array reference\n";
    !defined $attr || ref $attr eq 'HASH' or die "Proc::Spawner::spawn: attr must be a hash reference\n";
    ref eq 'ARRAY' or die "Proc::Spawner::spawn: an action is not an array reference\n" for @$acts }
  my %m = map +($_ => 1), missing();
  my %at = %{$attr // {}}; my @acts = @$acts;
  my $refuse = sub {   # an unsupported setting: true (and $! = ENOTSUP) to fail, false to drop it
    my $n = shift; my $v = ($uns && $uns->{$n}) // $UNSUPPORTED{$n} // $UNSUPPORTED{'*'} // 'fail';
    $v eq 'drop' ? 0 : do { $! = POSIX::ENOTSUP(); 1 } };
  if ($WIN) {   # W4 (the user, 2026-11-08: "(c) and (b); (c) beats (b) if present"): nice and rlimit mapped to what Windows
    # has per child, approximately; win_priority and win_job, Windows' own settings, exact, win over the mapping
    if ($at{nice}) { $at{win_priority} //= win_class_for_nice($at{nice}) } delete $at{nice};
    if (ref $at{rlimit} eq 'ARRAY' && @{$at{rlimit}}) {
      my ($job, @none) = win_job_for_rlimit($at{rlimit});
      for (@none) { return if $refuse->('rlimit') }   # (no Windows counterpart; drop: the rest still mapped)
      $at{win_job} = { %$job, %{$at{win_job} // {}} } if %$job }
    delete $at{rlimit} }
  elsif (grep defined $at{$_}, qw(win_priority win_job)) {   # Windows' own settings elsewhere
    for (qw(win_priority win_job)) { next unless defined $at{$_}; return if $refuse->($_); delete $at{$_} } }
  if ($WIN && ref $at{sigignore} eq 'ARRAY') {   # what a Windows child does anyway (post-0.08): there is no SIGPIPE, and
    # Ctrl-C is off in a new process group (Perl's kill INT, GenerateConsoleCtrlEvent, does not reach it either)
    my $group = $PRIMITIVE eq 'system1' || $WINDOWS{new_group} || defined $at{pgroup} && !$at{pgroup};
    $at{sigignore} = [grep !($_ == $SIGNUM{PIPE} || $group && $_ == $SIGNUM{INT}), @{$at{sigignore}}] }
  if ($PRIMITIVE eq 'system1' && $WIN) {   # Perl's own spawn on Windows: what it does anyway, and what it cannot
    delete @at{qw(sigdefault resetids)};   # nothing is inherited, no set-user-id
    delete $at{sigmask} if ref $at{sigmask} eq 'ARRAY' && !@{$at{sigmask}};
    delete $at{pgroup} if defined $at{pgroup} && !$at{pgroup};   # always a new group
    for my $n (qw(sigmask pgroup pidfd)) { next unless defined $at{$n} && $at{$n}; return if $refuse->($n); delete $at{$n} }
    my @k;   # the child sees fds 0-2 only
    for my $x (@acts) {
      my ($op, @a) = @$x;
      if ($op eq 'close' && $a[0] >= 3) { next }
      if ($op eq 'closefrom') { push @k, map [close => $_], $a[0] .. 2; next }
      if ($op eq 'dup2' && $a[1] >= 3 || $op eq 'open' && $a[0] >= 3 || $op eq 'fchdir') { return if $refuse->($op); next }
      push @k, $x }
    @acts = @k }
  if (ref $at{sigignore} eq 'ARRAY' && ref $at{sigdefault} eq 'ARRAY') {   # ignored and set to the default: which?
    my %d = map +($_ => 1), @{$at{sigdefault}}; if (grep $d{$_}, @{$at{sigignore}}) { $! = POSIX::EINVAL(); return } }
  if (grep $m{$_}, qw(dup2 close open closefrom)) { $m{$_} = 1 for qw(dup2 close open closefrom chdir fchdir) }
  my %given = (setsid => sub { $at{setsid} }, nice => sub { $at{nice} },
               sigignore => sub { ref $at{sigignore} eq 'ARRAY' && @{$at{sigignore}} });
  for my $n (qw(setsid sched cgroup rlimit sigignore nice)) {
    next unless $m{$n} && ($given{$n} ? $given{$n}->() : defined $at{$n});
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
  if ($FALLBACK && @there) { $! = POSIX::EINVAL(); return }   # (an action the emulation does not know)
  my $sigmask = $m{sigmask} ? delete $at{sigmask} : undef;
  my $sigdef = $m{sigdefault} ? delete $at{sigdefault} : undef;
  my $pg = $m{pgroup} && defined $at{pgroup} ? delete $at{pgroup} : undef;
  my $reset = $m{resetids} && delete $at{resetids};
  my $pidfd = $m{pidfd} && delete $at{pidfd};
  my $search = $m{search} && delete $at{search};
  if ($search && !$WIN and $file !~ m{/}) {
    my ($p) = grep -x && !-d, map +(length ? $_ : '.') . "/$file", path_split($ENV{PATH});
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
    my $redirs = $PRIMITIVE eq 'system1' ? run_redirs(\@here, \@undo) : do { emulate_actions(\@here, \@undo) if @here; undef };
    @r = $PRIMITIVE eq 'posix_spawn' ? __posix_spawn($file, $argv, $envp, \@there, \%at, $uns)
       : $PRIMITIVE eq 'fork' ? __spawn_nowait($file, $argv, $envp, { map +($_ => $at{$_}), grep exists $at{$_}, qw(rlimit sigignore nice) }, $uns)
       : system1($file, $argv, $envp, $search, $redirs);
    $err = $!;
    if (@r && $pidfd) { my $fd = __pidfd_open($r[0]); push @r, $fd >= 0 ? $fd : undef }
    1 };
  my $died = !$ok && $@ !~ /^Proc::Spawner: errno (\d+)/ && $@;   # not ours (Run missing, ...): passed on, after the undo
  $err = $@ =~ /^Proc::Spawner: errno (\d+)/ ? $1 : ($! + 0 || POSIX::EINVAL()) unless $ok;
  $_->() for @undo;
  die $died if $died;
  $! = $err; $ok && @r or return; wantarray ? @r : $r[0] }   # (scalar context: the pid, as the XSUB gives it)

our $PATH_SEP = $Config{path_sep};
sub path_split {   # a PATH value's entries, split at $PATH_SEP (post-0.10: $Config{path_sep}, ';' on Windows).  POSIX: an empty
  # entry is the current directory.  Windows (as Perl's own win32.c reads PATH): a "quoted" part is taken whole, its quotes
  # dropped (an unclosed one runs to the end); empty entries are dropped
  my $p = shift // ''; my $s = quotemeta $PATH_SEP;
  $WIN ? grep(length, map tr/"//dr, $p =~ /((?:"[^"]*(?:"|$)|[^"$s])*)/g) : split /$s/, $p, -1 }

sub win_find {   # posix_spawnp's lookup on Windows, as win_spawn.h's: a name with no directory through PATH (path_split),
  # PATHEXT's extensions before the bare name; a path as it is (relative: to the directory now)
  my ($file, $search) = @_;
  my @ext = ((grep length, split /;/, $ENV{PATHEXT} // '.COM;.EXE;.BAT;.CMD'), '');   # (PATHEXT: Windows' own, always ';')
  my @dirs = $search && $file !~ m{[/\\:]} ? path_split($ENV{PATH}) : ('');
  for my $d (@dirs) { for my $e (@ext) {
    my $p = length $d ? "$d\\$file$e" : "$file$e"; return File::Spec->rel2abs($p) if -f $p && -x _ } }
  return }

sub system1 {   # the primitive without posix_spawn and fork (M2): Run::start around Perl's own spawn; the pid, or empty with $!
  my ($file, $argv, $envp, $search, $redirs) = @_;
  require Run; Run->VERSION('0.07');   # (Run::start with a program, {fd => M}, {close => 1})
  local $Run::Forkless = 1;
  if ($WIN) {   # posix_spawn's meaning of FILE (with search: PATH and PATHEXT), not Perl's
    $file = win_find($file, $search) // do { $! = -e $file && !-d _ ? POSIX::EACCES() : POSIX::ENOENT(); return } }
  local %ENV = map { /^([^=]+)=(.*)\z/s ? ($1, $2) : () } @$envp if $envp;
  # X38 (post-0.10): Perl's spawn on Windows passes the child every inheritable handle, and Perl makes its handles
  # inheritable (no close-on-exec by $^F there): our fds from 3 up are made not inheritable for the call, then put back,
  # as POSIX has it.  Not thread-safe: another thread's spawn meanwhile does not pass these fds either.
  my @off = $WIN ? grep(__fd_cloexec($_) == 0, 3 .. __fd_limit() - 1) : (); __set_cloexec($_, 1) for @off;
  my @errs; my $pid = eval { Run::start(1, $argv, $redirs, \@errs, $file) }; my ($died, $err) = ($@, $!);
  __set_cloexec($_, 0) for @off; die $died if $died; $! = $err;
  $pid or return; $pid }

sub run_redirs {   # system1 (M2): the fd actions as Run's redirections (Run::start applies them around the call and puts
  # our fds back); chdir and fchdir done here, in order, so that an open's relative path is taken from the directory then;
  # the way back pushed on @$undo
  my ($acts, $undo) = @_;
  my (@r, $here, @opened);
  my $die = sub { die "Proc::Spawner: errno " . (0 + $!) . "\n" };
  unshift @$undo, sub {
    close $_ for @opened;
    if (defined $here) { if ($WIN) { chdir $here } else { __fchdir($here); POSIX::close($here) } } };
  for my $x (@$acts) {
    my ($op, @a) = @$x;
    if ($op eq 'chdir' || $op eq 'fchdir') {
      $here //= $WIN ? do { require Cwd; Cwd::getcwd() // $die->() }
              : do { my $h = POSIX::open('.', POSIX::O_RDONLY()); defined $h or $die->(); __set_cloexec($h, 1); $h };
      ($op eq 'chdir' ? chdir $a[0] : __fchdir($a[0])) or $die->() }
    elsif ($op eq 'dup2') { push @r, $a[1] => { fd => $a[0] } }
    elsif ($op eq 'close') { push @r, $a[0] => { close => 1 } }
    elsif ($op eq 'open') {
      sysopen my $fh, $a[1], $a[2], $a[3] // 0666 or $die->(); push @opened, $fh;
      push @r, $a[0] => { filehandle => $fh, pin => 1 } }
    elsif ($op eq 'closefrom') { push @r, map +($_ => { close => 1 }), grep __fd_cloexec($_) == 0, $a[0] .. __fd_limit() - 1 }
    else { $! = POSIX::EINVAL(); $die->() } }
  \@r }

sub emulate_actions {   # the file actions, done on this process's own fds in order; the way back pushed on @$undo
  my ($acts, $undo) = @_;
  my $top = 10;   # above every fd the actions name (not an open's flags or mode)
  for my $x (@$acts) { for (@$x[1 .. ($x->[0] eq 'dup2' ? 2 : 1)]) { $top = $_ + 1 if defined && /^[0-9]+\z/ && $_ >= $top } }
  my (%flag, %save, %ours);   # an fd's close-on-exec before (-1: was not open); its contents before (a copy; undef: none)
  my $die = sub { die "Proc::Spawner: errno " . (0 + $!) . "\n" };
  my $flag_touch = sub { my $fd = shift; $flag{$fd} //= __fd_cloexec($fd) };
  my $content_touch = sub { my $fd = shift; return if exists $save{$fd}; $flag_touch->($fd);
    $save{$fd} = $flag{$fd} >= 0 ? do { my $c = __dup_high($fd, $top + 1); $c >= 0 or $die->(); $ours{$c} = 1; $c } : undef };
  my $here;   # this process's directory before
  unshift @$undo, sub {   # contents first, then the flags, then the directory
    for my $fd (keys %save) { my $c = $save{$fd}; defined $c ? (POSIX::dup2($c, $fd), POSIX::close($c)) : POSIX::close($fd) }
    for my $fd (keys %flag) { __set_cloexec($fd, $flag{$fd}) if $flag{$fd} >= 0 }
    if ($WIN) { chdir $here if defined $here }   # (no directory fds there)
    elsif ($here) { __fchdir($here); POSIX::close($here) } };
  for my $x (@$acts) {
    my ($op, @a) = @$x;
    if ($op eq 'chdir' || $op eq 'fchdir') {
      $here //= $WIN ? do { require Cwd; Cwd::getcwd() // $die->() }
              : do { my $h = POSIX::open('.', POSIX::O_RDONLY()); defined $h or $die->(); __set_cloexec($h, 1); $ours{$h} = 1; $h };
      ($op eq 'chdir' ? chdir $a[0] : __fchdir($a[0])) or $die->() }
    elsif ($op eq 'dup2') {
      my ($from, $to) = @a;
      if ($from == $to) { __fd_cloexec($from) >= 0 or do { $! = POSIX::EBADF(); $die->() }; $flag_touch->($to); __set_cloexec($to, 0) }
      else { __fd_cloexec($from) >= 0 or do { $! = POSIX::EBADF(); $die->() }; $content_touch->($to); defined POSIX::dup2($from, $to) or $die->() } }
    elsif ($op eq 'close' && $WIN) { $content_touch->($a[0]); POSIX::close($a[0]) if defined $save{$a[0]} }   # (fds 0-2: Perl's
                                                                       # spawn passes the standard handles, inheritable or not)
    elsif ($op eq 'close') { $flag_touch->($a[0]); __set_cloexec($a[0], 1) if __fd_cloexec($a[0]) >= 0 }
    elsif ($op eq 'closefrom') {
      for my $fd ($a[0] .. __fd_limit() - 1) { next if $ours{$fd} || __fd_cloexec($fd) < 0; $flag_touch->($fd); __set_cloexec($fd, 1) } }
    elsif ($op eq 'open') {
      my ($fd, $path, $fl, $mode) = @a; $content_touch->($fd);
      my $o = POSIX::open($path, $fl, $mode // 0666); defined $o or $die->();
      if ($o == $fd) { __set_cloexec($fd, 0) } else { my $r = POSIX::dup2($o, $fd); my $e = $!; POSIX::close($o); defined $r or do { $! = $e; $die->() } } }
    else { $! = POSIX::EINVAL(); $die->() } } }

# The loop is Proc::Spawner::Loop (W5, post-0.10); these are its variables, and the functions below its old names.
use Proc::Spawner::Loop ();
our ($TRACE, $CAUSE, $REACTING, $DEPTH);   # undef or a code ref given one line per operation; the caller's cause (Graph)
*TRACE = \$Proc::Spawner::Loop::TRACE; *CAUSE = \$Proc::Spawner::Loop::CAUSE;
*REACTING = \$Proc::Spawner::Loop::REACTING; *DEPTH = \$Proc::Spawner::Loop::DEPTH;

sub tr_ { $TRACE->(join '', @_) if $TRACE }

# ------------------------------------------------------------------ spawning
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
my %RLIMIT = defined &__rlimits ? __rlimits() : ();
sub rlimits {   # { NAME => SOFT | [SOFT, HARD] } as spawn's [[RESOURCE, SOFT, HARD], ...]; NAME: NOFILE, RLIMIT_NOFILE or a number
  my $h = shift;
  map { my ($n, $v) = ($_, $h->{$_}); (my $k = uc $n) =~ s/^RLIMIT_//;
        my $r = $WIN ? $k : $RLIMIT{$k} // ($n =~ /^[0-9]+\z/ ? $n : die "Proc::Spawner: unknown resource '$n'\n");   # (Windows: the name, W4)
        [$r, ref $v ? @$v[0, 1] : ($v, undef)] } sort keys %$h }
sub start {
  my ($path, $argv, $envp, $fds, %o) = @_;
  my @a = ((map [$_ => $o{$_}], grep defined $o{$_}, qw(chdir fchdir)), actions($fds),
           defined $o{tcsetpgrp} ? [tcsetpgrp => $o{tcsetpgrp}] : ());
  my %attr = (sigmask => [signums($o{sigmask})], sigdefault => [signums($o{sigdefault})],
              map +($_ => $o{$_}), grep exists $o{$_}, qw(pgroup setsid resetids sched cgroup search pidfd nice win_priority win_job));
  $attr{sigignore} = [signums($o{sigignore})] if $o{sigignore};
  $attr{rlimit} = [rlimits($o{rlimit})] if $o{rlimit};
  my $um = defined $o{umask} && umask $o{umask};
  my ($pid, $pidfd) = spawn($path, $argv, $envp, \@a, \%attr, $o{unsupported});
  { local $!; umask $um if defined $o{umask} }
  my $how = join ', ', map "$$_[0] " . join('->', @$_[1 .. $#$_]), @a;
  $pid or return tr_("spawn failed: @$argv: $!"), undef;
  tr_("spawn $pid: $path [@$argv]", @a ? "; $how" : '');
  my $cb = $o{on_exit};   # (Windows: the kept process handle is released once the status is taken, post-0.08)
  loop()->child($pid, sub { __win_spawn_forget($pid) if $WIN; $cb->(@_) if $cb });
  $o{pidfd} && wantarray ? ($pid, $pidfd) : $pid }

# ------------------------------------------------------------------ the loop: Proc::Spawner::Loop under its old names
sub loop { Proc::Spawner::Loop->new }
sub defer { loop()->defer(@_) }
sub wait_until { loop()->wait_until(@_) }
sub poll { loop()->poll }
sub turn { loop()->turn(@_) }
sub on_read { my ($fd, $n, $cb) = @_; loop()->read($fd, $n, $cb) }
sub on_write { my ($fd, $bytes, $cb, $chunk) = @_; loop()->write($fd, $bytes, $cb, chunk => $chunk) }

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

The comments at the top of the module describe C<start>.  The loop is
L<Proc::Spawner::Loop> (since post-0.10); C<on_read>, C<on_write>, C<defer>,
C<poll> and C<wait_until> here are its old names, and C<loop()> is the loop.

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

Attributes posix_spawn has no option for (EXPERIMENTAL, post-0.08):
C<sigignore =E<gt> [SIGNUMS]> (ignored in the child); C<rlimit =E<gt>
[[RESOURCE, SOFT, HARD], ...]> (RESOURCE a number, see C<__rlimits()> for
the names; SOFT or HARD undef: as ours; C<'unlimited'>); C<nice =E<gt>
INCREMENT>.  The XSUB sets them in this process right around the call, in C,
with every signal blocked, and puts them back right after.  One that could
not be put back is unsupported (C<\%UNSUPPORTED> below): a hard limit lower
than ours without C<CAP_SYS_RESOURCE>; a higher nice value unless
C<CAP_SYS_NICE> or C<RLIMIT_NICE> allows lowering it back; a CPU limit this
process has used up; ignoring C<SIGCHLD>.  A signal both ignored and set to
the default fails with C<EINVAL>.  On Windows C<sigignore> is unsupported
but for C<PIPE> (no SIGPIPE there) and C<INT> in a new process group (Ctrl-C
is off there), which need nothing.

On Windows (post-0.09, decision W4) two settings of Windows' own, exact:
C<< win_priority => 'idle' | 'below_normal' | 'normal' | 'above_normal' |
'high' | 'realtime' >> (the child's priority class) and C<< win_job =>
{ ProcessMemoryLimit => BYTES, JobMemoryLimit => BYTES,
PerProcessUserTimeLimit => TICKS, PerJobUserTimeLimit => TICKS,
ActiveProcessLimit => N } >> (limits of a job of the child's own, by
Windows' names and units: committed memory, user time in 100-ns ticks;
nested in the job of C<kill_with_parent>, which needs Windows 8).
C<nice> and C<rlimit> are mapped to them, approximately: C<nice> from this
process's class to the class whose nice value is nearest (10 and up
C<idle>, 1 to 9 C<below_normal>, -1 to -9 C<above_normal>, -10 and below
C<high>, never C<realtime>); C<rlimit> C<AS> and C<DATA> to
C<ProcessMemoryLimit>, C<CPU> to C<PerProcessUserTimeLimit>, C<NPROC> to
C<ActiveProcessLimit> (the soft value if set, else the hard one: Windows has
one limit, and ends the child at it); the other resources have no
counterpart and are unsupported.  Where both are given, C<win_priority> and
C<win_job> win.  Elsewhere C<win_priority> and C<win_job> are unsupported.

Without posix_spawn (F<Makefile.PL> found none, or
C<PROC_SPAWNER_MISSING=posix_spawn>), C<spawn> forks and execs, in C, with
nothing in between, and does every other setting around the call; then
C<setsid>, C<< pgroup => 0 >>, C<tcsetpgrp>, C<sched> and C<cgroup> are
unsupported.  Where there is no fork either (Windows with posix_spawn
masked, OS/2, VMS), the redirections are delegated to L<Run> 0.07, whose
C<start> applies them around Perl's own C<system { FILE } 1, ARGV>; the
arguments go to Perl as they are (on Windows Perl's command line does not
yet quote them as the child parses them back); the child sees fds 0-2 only
there; at most 64 children at once (C<$Proc::Spawner::PRIMITIVE> says which
primitive is used).

C<reaped(PID)>: after waiting yourself for a child of C<spawn>.  On Windows
it releases the process handle kept for the exit code; elsewhere it does
nothing.  The loop calls it for the children of C<start>.

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
The signal actions and resource limits set around the call (C<sigignore>,
C<rlimit>) are the process's too; on Linux C<nice> and the signal mask are
per thread.  A memory limit lower than what this process uses makes glibc's
posix_spawn fail with C<ENOMEM>.  Without F</proc> (FreeBSD and the like),
Perl's own writes into a pipe it was given by the caller (not one of the
graph's) are blocking writes of C<PIPE_BUF> bytes once C<select> says the pipe
is writable: another writer filling the pipe in between makes Perl wait, and
can hang the loop when the reader waits on Perl (known issue X32 in
F<doc/pspawn-known-issues.md>; not observed).  Only Linux with glibc 2.39 has
been tested (and Windows under Wine).

=head1 AUTHOR

Ilya Zakharevich

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2026 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
