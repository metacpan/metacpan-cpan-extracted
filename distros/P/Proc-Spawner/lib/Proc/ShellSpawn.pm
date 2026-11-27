package Proc::ShellSpawn;
BEGIN { *ProcSS:: = \*Proc::ShellSpawn:: }   # JU3 (post-0.12, the user, 2026-11-15): the alias by which Large and Builtins call this module
# Runs Proc::ShellSubset parse trees with posix_spawn(3), in the simplest scenario:
# this module is the only code that starts child processes, and it owns
# SIGCHLD while it runs.  No fork in Perl: compound commands, pipelines of
# them, subshells, $( ), loops and background chains run in this process as
# continuations driven by one event loop.  This is the shell layer only: the
# loop and the starting of children are Proc::Spawner's, the ends and the
# process nodes (with the continuation each runs when it ends) Proc::Spawner::Graph's.
# Aim: what dash and bash do alike (the parsers reject what they do differently); where the two differ only at
# run time, as dash does (rule A5, doc/large-subset/large-subset-spec.md).  Every program started is a child of this
# Perl process, never a grandchild.
#
# Process-wide state flipped for a while, so bullet-proof only in non-threaded execution: Perl's umask,
# set to the shell's while a redirection's file is opened (open_end); SIGINT, SIGQUIT and SIGPIPE,
# ignored while run() runs (ignoring_int); traps, set in %SIG while run() runs and put back after it
# (Proc::ShellSpawn::Large, b_trap); SIGCHLD between run() calls while background jobs remain (idle, K3);
# and Proc::Spawner's own (umask in start, SIGCHLD in wait_until).
use strict; use warnings; use feature 'current_sub';
use POSIX ();
use File::Glob ();
use Cwd ();
use Proc::Spawner;
use Proc::Spawner::Graph;
use Scalar::Util qw(weaken);

our $VERSION = '0.14';
our $TRACE; *TRACE = \$Proc::Spawner::TRACE;   # undef, or a code ref given one line per fd or process operation
our %PARSE = map +($_ => 1), qw(assign param_ops if while for case read empty);   # options for Proc::ShellSubset and
                                                                                  # Proc::ShellSubset::Large
  # (empty, post4-0.04: a string with no command, or only comments, runs as nothing, status 0, as in both shells; also eval '')
# The parser for run(STRING): run(STRING, parser => CODE), CODE->(TEXT) returning a tree or an error hash.
# Default (EXPERIMENTAL, awaiting approval):
# the largest of Proc::ShellSubset::Large, Proc::ShellSubset, Proc::ShellSubset::Small that the
# caller has loaded; if none is, Proc::ShellSubset is loaded.  The executor itself loads no parser otherwise.
sub default_parser {
  defined &Proc::ShellSubset::Large::parse ? sub { Proc::ShellSubset::Large::parse($_[0], %PARSE, @_[1 .. $#_]) }
  : defined &Proc::ShellSubset::parse ? sub { Proc::ShellSubset::parse($_[0], %PARSE) }
  : defined &Proc::ShellSubset::Small::parse ? \&Proc::ShellSubset::Small::parse
  : do { require Proc::ShellSubset; sub { Proc::ShellSubset::parse($_[0], %PARSE) } } }
our $NAME = 'sh';           # prefix of error messages, as sh's "$0"
# EXPERIMENTAL (item N9): with TRACE=dot, one Graphviz picture per event (a start, an exit, an end
# closed) as trace-001.dot, ... in the directory TRACE_DIR (default: the current one).
our $DOT = ($ENV{TRACE} // '') eq 'dot' ? $ENV{TRACE_DIR} // '.' : undef;

sub tr_ { $TRACE->(join '', @_) if $TRACE }
our $G = Proc::Spawner::Graph->new(dot => $DOT);   # our children and our own reads and writes, now

# ------------------------------------------------------------------ extension points (EXPERIMENTAL, awaiting approval)
# Handlers are named by fully qualified sub names, resolved (and their module loaded) at first use:
#   a command node { ext => NAME, ... }, or one with a key of %KIND:  NAME->(CONTEXT, NODE, TAIL, K)
#   a command name in %CMD (or the shell's own table, for functions):  NAME->(CONTEXT, ARGV, ENV, K, DATA)
#   a Part [ext => NAME, ...] of a Word:                                  NAME->(CONTEXT, PART, K) with K->(TEXT)
# Each calls K exactly once (or ends the shell with leave), maybe later, and never waits (D2).
our %KIND = map +($_ => "Proc::ShellSpawn::Large::x_$_"), qw(func export readonly local exec);
our %CMD = (':' => ['Proc::ShellSpawn::b_colon'], exit => ['Proc::ShellSpawn::b_exit'], read => ['Proc::ShellSpawn::b_read'],
            (map +($_ => ['Proc::ShellSpawn::b_break']), qw(break continue)),   # (JU2, post-0.12: a function each)
            (map +($_ => ["Proc::ShellSpawn::Large::b_$_"]),
              qw(return shift set eval trap wait umask command getopts unset kill pwd)),
            '.' => ['Proc::ShellSpawn::Large::b_dot'], (map +($_ => ['Proc::ShellSpawn::Large::b_test']), '[', 'test'));
our $ONBUILTIN;   # undef, or a code ref called (HANDLER, [ARGV], {SETTINGS}) for each command where no program runs: before a
                 # builtin or function runs (cd: x_cd; export, readonly, local: x_NAME, after), a command not found ('not found',
                 # 'denied'), settings alone (x_set, ARGV empty, after)
our %A4;   # builtins left to sh: A4 (status 248) when one is named at run time
# B2 of "Shell Corpus Gaps": the tables of command names, searched in order; a module adds its own with
# unshift @Proc::ShellSpawn::CMDS, \%MINE (Proc::ShellSpawn::Builtins does).  %A4 stays last.
our @CMDS = (\%CMD, \%A4);
sub cmd_of { my $n = shift; for (@CMDS) { return $_->{$n} if exists $_->{$n} } undef }
sub a4 { $A4{$_} //= ['Proc::ShellSpawn::Large::b_unsupported'] for keys %Proc::ShellSubset::BI }
our $SIGNALLED;   # after run(): the signal of 'kill ... $$' that ended the string, if any
our %TRAPSAVE;   # signals the trap builtin changed during run(), with their old settings
our %SPECIAL = map +($_ => 1), qw(: break continue . eval exec exit export readonly return set shift times trap unset);
BEGIN { *handler = \&Proc::Spawner::Graph::handler }
sub done { my ($k, $st) = @_; sub { $k->($st) } }   # "then finish with status $st": for a call that takes what to do next
sub fail {   # stop this shell with $st, after the message $text if given
  my ($c, $st, $text) = @_; defined $text ? msg($c, $text, sub { leave($c, $st) }) : defer(\&leave, $c, $st); return }

# ------------------------------------------------------------------ ends
# The ends (Proc::Spawner::Graph) are what a context maps its fds to; each context holds the ends of
# its map, and the last release closes one.
sub own_fd { $G->parent_end(shift) }
sub is_open { my $d = POSIX::dup($_[0]) // return 0; POSIX::close($d); 1 }   # without touching its flags
sub visible {   # open and not close-on-exec: an fd sh would have inherited (not ours, nor the caller's handles)
  Proc::Spawner::__fd_cloexec(shift) == 0 }   # fcntl F_GETFD (until 0.05: /proc/self/fdinfo, Linux only; RT #182479)
sub new_pipe { $G->new_pipe }

# ------------------------------------------------------------------ paths
# POSIX, and Windows (post-0.10): there a path is absolute with a drive (C:/x, C:\x) or as a UNC name (//server/share);
# /x is the current drive's root; \ separates as / does; PATH is split at $Config{path_sep} (;, Proc::Spawner::path_split)
# and a command is looked up with the extensions of PATHEXT first; /dev/null is NUL.  The shell's own directory keeps
# Perl's form (C:/x/y).
our $WIN = $Proc::Spawner::WIN;
my $SEP = $WIN ? qr{[/\\]+} : qr{/+};
sub is_abs { $WIN ? $_[0] =~ m{^(?:[A-Za-z]:)?[/\\]} : $_[0] =~ m{^/} }
sub has_dir { $WIN ? $_[0] =~ m{[/\\]} : $_[0] =~ m{/} }   # a command name with a directory: no PATH lookup
sub path_in {   # PATH from the shell's directory
  my ($c, $p) = @_;
  return $p if $WIN ? $p =~ m{^[A-Za-z]:[/\\]|^[/\\]{2}} : $p =~ m{^/};
  return ($c->{sh}{cwd} =~ m{^([A-Za-z]:|[/\\]{2}[^/\\]+[/\\][^/\\]+)} ? $1 : '') . $p if $WIN && $p =~ m{^[/\\]};   # (the drive,
    # or the UNC share)
  "$c->{sh}{cwd}/$p" }
sub path_list { Proc::Spawner::path_split(@_) }   # a PATH value's directories (an empty one: the current directory, POSIX)
sub win_home {   # ~user on Windows (post-0.10, the user's follow-up (b) to WS1): one's own name is %USERPROFILE%; another
  # is its sibling of that name, if that is a directory (profiles are usually siblings; not always: the registry's
  # ProfileList has the real ones, a domain profile may be user.DOMAIN); else undef (~user stays as written)
  my $n = shift; my $up = $ENV{USERPROFILE} // return; return if $n =~ /^\.\.?\z/;
  return $up if lc $n eq lc($ENV{USERNAME} // '');
  my $d = ($up =~ s{[^/\\]+[/\\]*\z}{}r) . $n; -d $d ? $d : undef }
sub os_path { my $p = shift; $WIN && $p eq '/dev/null' ? 'NUL' : $p }   # a redirection's file name, as the system has it
# files_eq(A, B): do the two names mean the same file?  The one place for this question (the user, 2026-11-14, JH3: the
# device and inode numbers are a legacy way to tell, and the uses are not to be tied to it): where the shell starts
# (start_pwd), and test -ef and pwd -L of Proc::ShellSpawn::Programs, which loads this module for it only then.  On the
# legacy systems: the same device and inode numbers.  Where stat gives no usable numbers for one of the two (an inode of
# 0, as Perl on Windows gave before 5.34): paths_eq.  On Windows (post-0.12, the user, 2026-11-16) the way Microsoft
# documents: both opened, and the volume's serial number with the 128-bit file ID compared (the 64-bit file index where
# that is not there; Proc::Spawner::__win_same_file), the names made absolute first (Perl's directory, which a
# pseudo-process does not share with the process); only if that cannot tell, the rest.  False if either does not exist.
sub files_eq {
  my @a = stat $_[0] or return ''; my @b = stat $_[1] or return '';
  if ($WIN && defined &Proc::Spawner::__win_same_file) {
    require File::Spec; my $here = Cwd::getcwd();
    my $r = Proc::Spawner::__win_same_file(map File::Spec->rel2abs($_, $here), @_[0, 1]);
    return $r ? 1 : '' if defined $r }
  $a[1] && $b[1] ? $a[0] == $b[0] && $a[1] == $b[1] : paths_eq(@_) }
sub paths_eq {   # the same path once symbolic links, '.' and '..' are resolved (Windows: without regard to case); two
  my ($x, $y) = map Cwd::realpath($_), @_[0, 1];   # hard links to one file are not found the same this way
  defined $x && defined $y && ($WIN ? lc $x eq lc $y : $x eq $y) }

sub open_end {  # an end on a file, or undef with $!
  my ($c, $name, $op) = @_;
  my $path = path_in($c, os_path($name));
  return $! = POSIX::EEXIST(), undef if $op eq '>' && $c->{sh}{opt}{C} && -f $path;   # set -C
  my $um = umask $c->{sh}{umask};
  my $ok = sysopen my $fh, $path, $Proc::Spawner::Graph::OPEN{$op}, 0666; my $err = $!; umask $um;
  $! = $err, return unless $ok;
  $G->file_end($fh, $op, $name) }

# ------------------------------------------------------------------ contexts
# A context: what the commands run in it get.
#   map   => { CHILD_FD => end, or undef for closed }; fds not listed are ours, inherited as they are
#   sh    => the shell state: vars, exp(orted names), cwd, q ($?), bang ($!), qsub
#   loops => [ { brk => K, cont => K, scope => [contexts] }, ... ] of the enclosing loops
#   shell => { exit => K, scope => [contexts] } for exit
#   held  => 1 if this context holds its map's ends; released by release_ctx, once
my %LIVE;   # each shell (context) not ended yet, weakly: a job's shell is released once its last process has started
sub derive {    # a context with its own map, which it holds
  my ($c, $map, %o) = @_;
  my $d = { %$c, map => $map, held => 1, released => 0, root => !!$o{shell}, late => 0 };
  if (my $k = $o{shell}) {   # a new shell: copies of the state; exit and loops start afresh;
    my $sh = $c->{sh};        # leaving it releases every context made in it
    $d->{sh} = { %$sh, main => $sh->{main} // $sh, vars => { %{$sh->{vars}} }, exp => { %{$sh->{exp}} }, args => [@{$sh->{args}}],
                 opt => { %{$sh->{opt}} }, cmd => { %{$sh->{cmd}} }, ro => { %{$sh->{ro}} }, jobl => [],
                 ljobs => $o{jobs} ? [@{$sh->{ljobs} // []}, @{$sh->{jobl}}] : [],   # jobs listed in a pipeline or $( ) (rule E)
                 pend => [], twait => [], tbusy => 0,   # the caught signals belong to the shell whose trap caught them (X19)
                 trap => { map +($_ => ''), grep $sh->{trap}{$_} eq '', keys %{$sh->{trap}} } };   # sh: only ignored traps stay
    my $scope = [];
    $d->{loops} = []; delete @$d{qw(frame cond)}; $d->{shell} = { scope => $scope, exit => shell_exit($d, $scope, $k) };
    weaken($LIVE{$d} = $d) }   # (for the wait at exit, K5)
  hold($_) for values %$map;
  push @{ @{$d->{loops}} ? $d->{loops}[-1]{scope} : $d->{shell}{scope} }, $d;
  $d }
sub leave { my ($c, $st) = @_; release_all(map $_->{scope}, @{$c->{loops}}); $c->{shell}{exit}->($st) }   # exit
sub shell_exit {   # the end of a shell: its EXIT trap first (once; an exit inside the trap ends it there)
  my ($c, $scope, $k) = @_; my $id = "$c"; weaken($c); my $state = 0;
  sub { my $st = shift;
    return if $state == 2;
    my $a = $state == 0 && $c && delete $c->{sh}{trap}{EXIT};
    if (defined $a && $a ne '' and ref(my $t = $c->{sh}{parse}->($a, nolineno => 1)) eq 'ARRAY') {
      $state = 1; my $tc = { %$c, loops => [], held => 0, cond => undef, frame => undef };
      return x_list($tc, $t, undef, sub { return if $state == 2; $state = 2; delete $LIVE{$id}; late($c); release_all($scope); $k->($st) }) }
    $state = 2; delete $LIVE{$id}; late($c); release_all($scope); $k->($st) } }
sub late { my $c = shift; release_ctx($c) if $c && $c->{late} }   # the release a trap postponed (the trap is gone by now)
sub release_ctx {
  my $c = shift; return if !$c->{held} or $c->{released};
  return $c->{late} = 1 if $c->{root} && ($c->{sh}{trap}{EXIT} // '') ne '';   # its EXIT trap still needs them (L5)
  $c->{released} = 1; release($_) for values %{$c->{map}} }
sub release_all { for my $s (@_) { release_ctx($_) for @$s; @$s = () } }   # also breaks the cycles through the scopes

# ------------------------------------------------------------------ the loop and the graph
# Proc::Spawner runs the loop; every continuation runs from its queue, one at a time, and never waits.
# Our children and our own reads and writes are nodes of the graph $G (Proc::Spawner::Graph); a
# child's node carries its continuation as on_exit ['Proc::ShellSpawn::resume', K].
BEGIN { *defer = \&Proc::Spawner::defer; *hold = \&Proc::Spawner::Graph::hold; *release = \&Proc::Spawner::Graph::release }
sub loop_until { Proc::Spawner::wait_until(@_) }
sub on_read { my ($e, $n, $cb) = @_; $G->perl_read($e, $n, sub { $cb->($_[1]) }) }   # one read of end $e: $cb->(BYTES),
                                                                                     # or undef at end of file
sub on_write { my ($e, $bytes, $cb) = @_; $G->perl_write($e, $bytes, $cb) }   # Perl writes BYTES to end $e without blocking

sub status_of {   # a wait status as sh's $?
  my $w = shift;
  $w & 127 ? 128 + ($w & 127) : $w >> 8 }   # (by hand: Windows' POSIX has no WIFSIGNALED; Perl's $? is the same there)

# Background jobs left running when run() returns go on between calls too (idle, below); at exit we finish them.
my %JOBS;
# As Perl's system: SIGINT and SIGQUIT are ignored here while commands run (a foreground child gets
# them back by sigdefault; a background child keeps them ignored, as POSIX asks of an asynchronous list).
sub ignoring_int { local @SIG{qw(INT QUIT PIPE)} = ('IGNORE') x 3; $_[0]->() }   # PIPE: a here-document's reader may go away
sub wait_all { idle(0); ignoring_int(sub { loop_until(sub { !%JOBS }) }) if %JOBS }
# At exit (post-0.12, K5, the user, 2026-11-15: "as shell"): the shells leave their background jobs running.  ShellSpawn
# starts every command of a job itself (no fork: a job's next command is started here when the one before ends), so
# it waits while it has anything left to do for a job: a command still to start, a read or write of its own, a call
# queued; then it exits, leaving the processes running, as the shells do.  PROC_SHELLSPAWN_END, or $END_WAIT at run
# time (a stopgap until such choices are arguments of the API): MODE[:SECONDS], MODE shell (the default), all (wait
# until every job has ended: before post-0.12), none (exit at once: the jobs' commands not yet started never start);
# SECONDS: wait at most that long (then as none).
our $END_WAIT = $ENV{PROC_SHELLSPAWN_END} // 'shell';
sub end_wait_mode { my ($m, $s) = ($_[0] // '') =~ /\A(shell|all|none)?(?::(\d+(?:\.\d*)?))?\z/ or return; ($m // 'shell', $s) }
(end_wait_mode($END_WAIT))[0] // do { my $v = $END_WAIT; $END_WAIT = 'shell';   # (so that END does not complain again)
  die "PROC_SHELLSPAWN_END: '$v' is not MODE[:SECONDS], MODE one of shell, all, none\n" };
sub settled { !grep(defined && !$_->{released}, values %LIVE) && !%{$G->{io}} && !Proc::Spawner::loop()->queued }
sub end_wait {
  my ($mode, $secs) = end_wait_mode($END_WAIT);
  $mode //= 'shell', warn "Proc::ShellSpawn: \$END_WAIT '$END_WAIT' is not MODE[:SECONDS]; shell taken\n" unless defined $mode;
  return if !%JOBS or $mode eq 'none';
  idle(0); ignoring_int(sub { Proc::Spawner::wait_until($mode eq 'all' ? sub { !%JOBS } : sub { !%JOBS || settled() }, $secs) }) }
END { local $?; end_wait() }
# Between run() calls (K3, the user's choice B, post-0.04): while background jobs remain, a deferred SIGCHLD
# handler moves them on when a child ends, whatever Perl is doing (a chain's next command starts at once).
# Its cost, documented: the program's own sleep and select return early when a child ends, and the
# program's own $SIG{CHLD} is called by ours (a CODE handler; set afterwards, it replaces ours).
our $RUNNING = 0;   # inside run(): the loop there does it
my ($IDLE_ON, $IDLE_OLD);
sub idle_pass {
  return if $RUNNING || !%JOBS;
  ignoring_int(\&Proc::Spawner::poll);
  idle(0) unless %JOBS }
sub idle {   # 1: install the handler (if jobs remain), 0: put the previous one back
  my $on = shift;
  return if $WIN;   # (no SIGCHLD there: background jobs move on at the next run, wait or poll)
  if ($on && %JOBS && !$IDLE_ON) {
    $IDLE_OLD = POSIX::SigAction->new;
    my $a = POSIX::SigAction->new(sub { local ($?, $!);   # (X55: the program's $? and $! stay as they were)
                                    idle_pass(); my $h = $IDLE_OLD && $IDLE_OLD->{HANDLER}; $h->(@_) if ref $h eq 'CODE' },
                                  POSIX::SigSet->new, POSIX::SA_RESTART());
    $a->safe(1);   # deferred: runs between Perl operations, never inside the signal (S2)
    POSIX::sigaction(POSIX::SIGCHLD(), $a, $IDLE_OLD) and $IDLE_ON = 1 }
  elsif (!$on && $IDLE_ON) { POSIX::sigaction(POSIX::SIGCHLD(), $IDLE_OLD); $IDLE_ON = 0 } }

# ------------------------------------------------------------------ spawning
# Signals ignored when we were loaded stay ignored in children, as sh keeps the ones ignored on entry.
# SIGFPE as Perl's own exec would pass it: Perl may ignore it for itself at startup, and puts back
# the disposition it found then (PERL_FPU_PRE_EXEC, PL_sigfpe_saved; fpe_at_exec() reads it).
my $FPE = Proc::Spawner::fpe_at_exec();
our %IGN0 = map +($_ => 1), grep +($SIG{$_} // '') eq 'IGNORE' && ($_ ne 'FPE' || $FPE == 1), keys %SIG;

sub put {   # Perl writes $t to the context's fd $fd, then $then->(); never waits (L10).  Callers go on only
  # in $then, so nothing started later overtakes the text.
  my ($c, $fd, $t, $then) = @_; $then //= sub {};
  my $e = $c->{map}{$fd};
  $e ? do { hold($e); on_write($e, $t, sub { release($e); $then->() }) } : defer($then); return }
sub msg { my ($c, $text, $then) = @_; put($c, 2, "$NAME: $text\n", $then) }   # an error message, to fd 2
sub write_fd {   # as put, then $k->(ERRNO or undef): EBADF when the fd is closed (and there is something to write)
  my ($c, $fd, $t, $k) = @_; my $e = $c->{map}{$fd};
  return defer($k, undef) if $t eq ''; return defer($k, POSIX::EBADF()) unless $e;
  hold($e); on_write($e, $t, sub { my $err = $! + 0; release($e); $k->($err || undef) }); return }

# Programs run inside this process (Proc::ShellSpawn::Programs, after coreutils 9.4), by name (X21).  Decision IP1 (the
# user, 2026-11-08: "when a well-debugged builtin is already present, use it.  (By default; Configurable.)"): echo
# printf test [ true false, and since post-0.10 pwd (b_pwd runs it as 'pwd -L', X23), on every platform;
# PROC_SHELLSPAWN_INPROC changes the default (none: the programs; names:
# only these; all), and %INPROC can be changed at run time.  A name with a '/' is always a program.
our @INPROC = qw(echo printf test [ true false pwd);
our %INPROC = map +($_ => 1), map $_ eq 'all' ? @INPROC : $_ eq 'none' ? () : $_,
  split ' ', $ENV{PROC_SHELLSPAWN_INPROC} // 'all';
# Whose echo the in-process echo is (decision EC1, the user, 2026-11-09): coreutils (the default; it heeds POSIXLY_CORRECT),
# dash or bash (their builtins, which do not); $ECHO can be changed at run time.  The program echo (not in %INPROC) is not
# affected.
our $ECHO = $ENV{PROC_SHELLSPAWN_ECHO} || 'coreutils';
die "PROC_SHELLSPAWN_ECHO: '$ECHO' is none of coreutils, dash, bash\n" unless $ECHO =~ /\A(?:coreutils|dash|bash)\z/;

# sh as Perl with this module (post-0.10, SH1, the user's follow-up (c) to WS1: "Windows has no sh"): a command named sh
# (no directory) runs as $^X -MPARSER -MProc::ShellSpawn=sh -e0 -- ARGS, PARSER the largest parser loaded here (as
# default_parser), with this Perl's @INC; then sh_main below reads ARGS as sh does.  PROC_SHELLSPAWN_SH (or $SH at run
# time): auto (the default: so when the command's PATH has no sh), perl (always), program (never).  The text after -c is
# an argument: through the primitive system1 on Windows, Perl's own spawn drops a " from it,
# and splits it at blanks too if it has one (❰BUG❱ in
# Perl, doc/perl-win32-system-bugs.md, 1); not worked around.
our $SH = $ENV{PROC_SHELLSPAWN_SH} || 'auto';
die "PROC_SHELLSPAWN_SH: '$SH' is none of auto, perl, program\n" unless $SH =~ /\A(?:auto|perl|program)\z/;
sub sh_argv {   # the argv of sh as Perl, or undef: run the program sh
  my ($c, $argv, $path) = @_;
  return if $argv->[0] ne 'sh' or $SH eq 'program' or $SH eq 'auto' && defined((find_cmd($c, 'sh', $path))[0]);
  my ($parser) = grep { no strict 'refs'; defined &{"${_}::parse"} }
    qw(Proc::ShellSubset::Large Proc::ShellSubset Proc::ShellSubset::Small);
  [$^X, (map "-I$_", grep !ref, @INC), '-M' . ($parser // 'Proc::ShellSubset'), '-MProc::ShellSpawn=sh', '-e0', '--',
   @$argv[1 .. $#$argv]] }
sub import {   # use Proc::ShellSpawn 'sh': run as sh with @ARGV, then exit (SH1); with no list, nothing
  my ($pkg, @w) = @_; return unless @w;
  die "Proc::ShellSpawn: only 'sh' can be imported\n" unless @w == 1 && $w[0] eq 'sh';
  exit sh_main(@ARGV) }
sub sh_main {   # sh -c TEXT [NAME [ARGS]], sh FILE [ARGS], sh [-s] [ARGS] (the text from stdin): the exit status
  my @a = @_; my ($opt_c, $opt_s, $text, $name, %opt);
  my $bad = sub { print STDERR "sh: $_[0]\n"; 2 };
  while (@a && $a[0] =~ /\A-(.+)\z/s) {
    shift @a; last if $1 eq '-';
    for my $l (split //, $1) {   # -c, -s; other letters as set takes them (-e, -u, -x, ...)
      $l eq 'c' ? ($opt_c = 1) : $l eq 's' ? ($opt_s = 1) : $l =~ /\A[a-zA-Z]\z/ && $l ne 'o' && $l ne 'i' ? ($opt{$l} = 1)
        : return $bad->("-$l: option not supported here (SH1)") } }
  if ($opt_c) { @a or return $bad->('-c requires an argument'); $text = shift @a; $name = shift @a }
  elsif (!$opt_s && @a) {
    $name = shift @a; open my $f, '<', $name or return $bad->("0: cannot open $name: $!"); binmode $f; local $/; $text = <$f> }
  else { binmode STDIN; local $/; $text = <STDIN> // '' }
  local $NAME = $name // 'sh';
  my ($st, $err) = run($text, args => \@a, arg0 => $NAME, opt => \%opt);
  defined $st or print(STDERR "$NAME: outside the subset: $err->{error} at $err->{pos}\n"), return 255;   # (as t/try.pl)
  if (my $s = $SIGNALLED) { local $SIG{$s} = 'DEFAULT'; kill $s, $$; sleep 1 }   # die by it, as sh would
  $st }

# TEMPORARY WORKAROUND (post-0.10, BIN1; the user's follow-up (d) to WS1, "Replace them from %ENV (inventing suitable
# fallbacks)", marked temporary by the user, 2026-11-10): where cat, sort, grep and the like come from.  The directories
# in PROC_SHELLSPAWN_BIN (split as PATH; 'none': none, since Windows has no empty variables) are searched before PATH, on
# any platform.  Unset, on Windows: the first of Git for Windows' usr\bin (beside git.exe on PATH, or under
# %ProgramFiles%, %ProgramW6432%, %LOCALAPPDATA%\Programs), MSYS2's (%SystemDrive%\msys64\usr\bin) and Cygwin's
# (%SystemDrive%\cygwin64\bin) that has cat.exe; elsewhere none.  Also on Windows, a program of the system's own (under
# %SystemRoot%) named sort, find, timeout or expand is never taken for the POSIX one: they differ.  @BIN at run time.
our @BIN = !defined $ENV{PROC_SHELLSPAWN_BIN} ? ($WIN ? win_posix_bin() : ())
         : $ENV{PROC_SHELLSPAWN_BIN} eq 'none' ? () : Proc::Spawner::path_split($ENV{PROC_SHELLSPAWN_BIN});
sub win_posix_bin {
  my $sd = $ENV{SystemDrive} // 'C:';
  my $up = sub { $_[0] =~ s{[/\\][^/\\]+\z}{}r };   # the parent directory
  my @git = map { ($up->($_), $up->($up->($_))) } grep -f "$_\\git.exe", Proc::Spawner::path_split($ENV{PATH});   # Git\cmd,
    # Git\mingw64\bin
  for my $d ((map "$_\\usr\\bin", @git), (map "$_\\Git\\usr\\bin", grep defined, @ENV{qw(ProgramFiles ProgramW6432)}),
             (defined $ENV{LOCALAPPDATA} ? "$ENV{LOCALAPPDATA}\\Programs\\Git\\usr\\bin" : ()),
             "$sd\\msys64\\usr\\bin", "$sd\\cygwin64\\bin") {
    return $d if -f "$d\\cat.exe" } () }
my %WINCLASH = map +($_ => 1), qw(sort find timeout expand);   # Windows' own programs of these names are others (BIN1)
sub win_clash { my ($name, $p) = @_; my $r = $ENV{SystemRoot} // return 0;
  $WINCLASH{lc $name} && lc(substr($p, 0, length $r) =~ tr{/}{\\}r) eq lc($r =~ tr{/}{\\}r) }

sub find_cmd {   # the path to run for $name, or undef and the status (127, 126); Windows: PATHEXT's extensions first.  With
  my ($c, $name, $path) = @_;   # 127 a fourth value: the error the search met, as dash keeps it (X72), or undef: not found
  my @ext = ($WIN ? (grep length, split /;/, $c->{sh}{vars}{PATHEXT} // '.COM;.EXE;.BAT;.CMD') : (), '');
  if (has_dir($name)) { -f path_in($c, "$name$_") and return "$name$_" for @ext; return $name }
  my ($denied, $err);
  for my $d (@BIN, path_list($path)) { for my $e (@ext) {   # (@BIN: BIN1, a temporary workaround)
    my $p = ($d eq '' ? '.' : $d) . ($WIN && $d =~ /\\/ && $d !~ m{/} ? '\\' : '/') . "$name$e";   # (Windows: as PATH writes it)
    unless (-f path_in($c, $p)) {   # dash: a name that cannot be looked at (a directory of PATH that may not be searched),
      my $e = $! + 0;               # or is no regular file ($! taken before -e _, which sets it)
      $err = -e _ ? POSIX::EACCES() : $e == POSIX::ENOENT() || $e == POSIX::ENOTDIR() ? $err : $e unless $WIN;
      next }
    next if $WIN && win_clash($name, $p);
    return $p if -x _;
    $denied //= $p } }
  defined $denied ? (undef, 126, $denied) : (undef, 127, undef, $err) }
sub not_found { my $e = shift; $e ? do { local $! = $e; "$!" } : 'not found' }   # X72: the message for find_cmd's fourth value

sub spawn {   # starts @$argv with $map; $k->(STATUS) when it has ended; returns its process node or undef
  my ($c, $map, $argv, $env, $k, $search, $pre) = @_;   # $search: the PATH to look in, if not the command's own (command -p);
                                                        # $pre: 'exec: ' before the message of exec's command that does not start
  my %e = (%{$c->{sh}{vars}}{grep $c->{sh}{exp}{$_} && /^[A-Za-z_][A-Za-z_0-9]*\z/, keys %{$c->{sh}{vars}}}, %$env);   # as dash:
    # names only
  return inproc($c, $map, $argv, \%e, $k) if $INPROC{$argv->[0]};
  my $look = $search // (exists $env->{PATH} ? $env->{PATH} : $c->{sh}{vars}{PATH});   # X73: the shell's PATH, exported or not (or
  if (my $a = sh_argv($c, $argv, $look)) { $argv = $a; undef $search }   # sh as Perl (SH1)       #  the command's own PATH=...)
  my ($path, $st, $what, $serr) = find_cmd($c, $argv->[0], $look);
  $c->{sh}{hash}{$argv->[0]} = $path if defined $path && !defined $search && !has_dir($argv->[0]);   # remembered, as dash
    # (hash, type)
  my $no = sub {   # the command does not start: its message and the status, 127 (not found) or 126 ($why); with $log the
    my ($st, $why, $log) = @_;   # measuring hook is told too (no program runs)
    $ONBUILTIN->($st == 127 ? 'not found' : 'denied', $argv, {%$env}) if $log && $ONBUILTIN;
    cmd_msg($c, $map, ($pre // '') . "$argv->[0]: " . ($st == 127 ? not_found($serr) : $why), done($k, $st)) };
  return $no->(126, not_found($serr), 1)   # exec, and the search met an error: 126, as dash (the plain command: 127)
    if !defined $path && $pre && $serr && $serr != POSIX::ELOOP() && $serr != POSIX::ENAMETOOLONG();
  return $no->($st, 'Permission denied', 1) if !defined $path;
  return $no->(126, 'Permission denied', 1)   # Windows runs neither: as sh says it (CreateProcess: not found,
                                              # or "Exec format error")
    if $WIN && -e path_in($c, $path) && (-d _ || !-x _);
  my @envp = map "$_=$e{$_}", sort keys %e;
  my %def = map +($_ => 1), grep !$IGN0{$_} && ($SIG{$_} // '') eq 'IGNORE' && ($c->{sh}{trap}{$_} // 1) ne '',   # trap '' SIG:
    # stays ignored
    keys %SIG, $FPE ? () : 'FPE';
  delete @def{qw(INT QUIT)} if $c->{sh}{job};   # in the background: left ignored
  my @o = (sigdefault => [sort keys %def],
           $WIN ? () : (umask => $c->{sh}{umask}), on_exit => ['Proc::ShellSpawn::resume', $k],   # (Windows: no umask)
           $c->{sh}{cwd} ne Cwd::getcwd() ? (chdir => $c->{sh}{cwd}) : ());
  my $node = $G->start($path, $argv, \@envp, $map, @o);
  if (!$node && !$WIN && $! == POSIX::ENOEXEC()) {   # a script without #!: sh runs it with sh
    $node = $G->start('/bin/sh', ['sh', $path, @$argv[1 .. $#$argv]], \@envp, $map, @o) }
  return $node if $node;
  my $err = "$!";   # an fd of ours that is not open: the first one the child should have got
  my ($bad) = grep !is_open($_), map $map->{$_} ? $map->{$_}{fd} : (), sort { $a <=> $b } keys %$map;
  $st = $! == POSIX::ENOENT() ? 127 : 126;
  return msg($c, "$bad: Bad file descriptor", done($k, $st)) if defined $bad;   # (a redirection failed: the shell's own fd 2)
  $no->($st, $err) }
sub cmd_msg {   # X47: a command that does not start: its message to the command's own fd 2 (2>log, 2>&1 | ...), as both shells
  my ($c, $map, $text, $k) = @_; my @e = grep defined, values %$map; hold($_) for @e;
  msg({ %$c, map => $map }, $text, sub { release($_) for @e; $k->() }) }
sub inproc {   # a program of %INPROC, run here: its output and messages in the program's order, then $k->(STATUS).  A
  # write error on stdout, as coreutils: death by SIGPIPE (EPIPE, unless the shell ignores SIGPIPE for its children), else
  # no more output, the message "NAME: write error: ..." at the end and status 1.  Undef, as spawn for no process started.
  my ($c, $map, $argv, $env, $k) = @_;
  require Proc::ShellSpawn::Programs;
  my $d = { %$c, map => $map }; hold($_) for values %$map;   # (the caller releases its holds when spawn returns)
  $ONBUILTIN->('Proc::ShellSpawn::inproc', $argv, {%$env}) if $ONBUILTIN;   # (measurement: no program runs)
  tr_("in-process: @$argv");
  my %opt = (cwd => $c->{sh}{cwd}, echo => $ECHO, isatty => sub { my $e = $map->{$_[0]}; $e && POSIX::isatty($e->{fd}) });
  my ($out, $err, $st, $seq) = Proc::ShellSpawn::Programs->can($argv->[0] eq '[' ? 'test' : $argv->[0])->($argv, $env, \%opt);
  my @seq = grep length $_->[1], @{$seq // [[2, $err], [1, $out]]};
  my $pipe_dfl = !$IGN0{PIPE} && ($c->{sh}{trap}{PIPE} // 1) ne '';   # (Windows: as POSIX, though it has no SIGPIPE)
  my $pipe_dies = $pipe_dfl && !defined $c->{sh}{trap}{PIPE};   # D3: no trap of this shell's own either
  my $werr;
  loop_async(sub {
    my $next = shift;
    my $p = shift @seq;
    if (!$p) {
      unless ($werr) { release($_) for values %$map; return $k->($st) }
      local $! = $werr;   # X81: the message first, then the holds go (a 2>/dev/null of this command alone was closed before)
      return write_fd($d, 2, "$argv->[0]: write error" . ($werr > 0 ? ": $!" : '') . "\n", sub { release($_) for values %$map; $k->(1) }) }
    return $next->() if $p->[0] == 1 && $werr;
    write_fd($d, $p->[0], $p->[1], sub {
      my $e = shift;
      if ($e && $p->[0] == 1) {
        if ($e == POSIX::EPIPE() && $pipe_dfl) { release($_) for values %$map;   # (SIGPIPE: 13)
          return $pipe_dies ? sigpipe($c) : $k->(128 + 13) }
        # the reason only when it failed in the final flush (close_stream: errno 0 after an earlier failure): the last
        # piece for stdout, short enough for one write of the buffer (glibc's: st_blksize, 4096 for a pipe)
        $werr = !grep($_->[0] == 1, @seq) && length $p->[1] <= 4096 ? $e : -1 }
      $next->() }) });
  return }
sub sigpipe {   # D3 (decided 2026-11-22; TODO A17): a command that dash and bash run as a builtin, in their own process, and
  # ShellSpawn here, died of SIGPIPE: the shell running it dies with it, as in dash and bash.  A pipeline element or a
  # subshell ends with status 141 and runs no EXIT trap (a death by a signal); the main shell ends the whole string, as
  # kill -PIPE $$ would (b_kill), and the caller may die by the signal too ($SIGNALLED).  Only where SIGPIPE is neither
  # ignored nor trapped in this shell (inproc's $pipe_dies); otherwise the command fails alone, as the shells' builtin.
  my $c = shift; my $sh = $c->{sh};
  $sh->{trap}{EXIT} = '' if exists $sh->{trap}{EXIT};
  return leave($c, 128 + 13) if $sh->{main};
  $SIGNALLED = 'PIPE'; $sh->{die}->(128 + 13); return }
sub resume { my ($g, $node, $w, $k) = @_; $k->(defined $w ? status_of($w) : 1) }   # on_exit of our children

# ------------------------------------------------------------------ redirections
# Applies @$redirs to a copy of $c's map: $k->(MAP, [opened ends]), or $k->() after a message.
sub redirect {
  my ($c, $redirs, $k) = @_;
  my %m = %{$c->{map}}; my @opened;
  my $fail = sub { msg({ map => \%m }, shift, sub { release($_) for @opened; $k->() }) };   # through the redirections so far
  my $i = 0;
  loop_async(sub { my $next = shift;
    return $k->(\%m, \@opened) if $i > $#$redirs;
    my ($fd, $op, $w) = @{$redirs->[$i++]};
    if ($op eq '<<') {   # a here-document: Perl writes the expanded body into a pipe the command reads
      # X50: expanded with the redirections so far (messages, $( )), and an error that would end the shell (set -u,
      # ${x:?}, arithmetic) fails the redirection instead, as dash: the command does not run, status 2, the shell goes
      # on (a special builtin's failed redirection still ends it)
      my $hc = { %$c, map => \%m, held => 0, loops => [],
        shell => { %{$c->{shell}}, exit => sub { release($_) for @opened; $k->() } } };
      return expand_str($hc, $w, sub { my $body = shift;
        my ($r, $wr) = new_pipe() or return $fail->("pipe: $!");
        push @opened, $m{$fd} = $r; on_write($wr, $body, sub { release($wr) }); $next->() }) }
    if ($op eq '<&' or $op eq '>&') {
      if ($w eq '-') { $m{$fd} = undef }
      elsif (exists $m{$w}) { defined $m{$w} ? ($m{$fd} = $m{$w}) : return $fail->("$w: Bad file descriptor") }
      elsif (visible($w)) { $m{$fd} = own_fd($w) }
      else { return $fail->("$w: Bad file descriptor") }
      return $next->() }
    my $open = sub {
      my $name = shift // return $fail->('ambiguous redirect');   # (X4, below)
      my $e = $name ne '' && open_end($c, $name, $op);
      if (!$e) {   # dash's wording
        my $err = $name eq '' || $!{ENOENT} ? ($op eq '<' ? 'No such file' : 'Directory nonexistent') : "$!";
        return $fail->(($op eq '<' ? 'cannot open' : 'cannot create') . " $name: $err") }
      push @opened, $m{$fd} = $e; $next->() };
    $c->{sh}{redir_strict} && ref $w ? strict_name($c, $w, $open) : expand_str($c, $w, $open) }) }
sub strict_name {   # X4 (Q1, run's option redir_strict): a redirection's file name, $k->(NAME); $k->(undef) when an unquoted
  my ($c, $w, $k) = @_; my ($name, $bad, $unq) = ('', 0, 0);   # expansion in it gives a character of IFS (a blank, by default)
  my $ifs = $c->{sh}{vars}{IFS} // " \t\n";   # or a pattern character, or when it has one and the name comes out empty: where
  each_async($w, sub { my ($p, $more) = @_;   # bash outside POSIX mode says "ambiguous redirect" (but bash takes a pattern that
    return $name .= $p, $more->() unless ref $p;   # matches one file)
    expand_str($c, [$p], sub { my $v = shift;
      if ($p->[0] =~ /^(?:\$|ext\z)/) { $unq = 1; $bad ||= active($v) || length $ifs && $v =~ /[\Q$ifs\E]/ }
      $name .= $v; $more->() }) },
    sub { $k->($bad || $unq && $name eq '' ? undef : $name) }) }

sub keep_map {   # exec's redirections: the map $m (made by redirect, with the ends @$opened) is the context's own from now on
  my ($c, $m, $opened) = @_;
  hold($_) for grep defined, values %$m; release($_) for @$opened;
  my $old = $c->{held} && !$c->{released} ? $c->{map} : {};
  $c->{map} = $m; release($_) for grep defined, values %$old;
  push @{$c->{shell}{scope}}, $c unless $c->{held};   # released when the shell ends
  @$c{qw(held released)} = (1, 0) }

# Runs $body->(CONTEXT, K2) with @$redirs applied, then $k->(STATUS); status 2 if they fail.
sub with_redirs {
  my ($c, $redirs, $tail, $k, $body) = @_;
  return $body->($c, $tail, $k) unless $redirs && @$redirs;
  redirect($c, $redirs, sub {
    my ($m, $opened) = @_ or return defer($k, 2);
    my $d = derive($c, $m); release($_) for @$opened;
    $body->($d, [$d, @{$tail // []}], sub { release_ctx($d); $k->(@_) }) }) }

# ------------------------------------------------------------------ expansion
sub var {   # also $0-$9 ${10}..., $#, $$, $@ and $* (joined by the first character of IFS)
  my ($c, $n) = @_; my $sh = $c->{sh};
  return $n ? $sh->{args}[$n - 1] // '' : $sh->{arg0} // 'sh' if $n =~ /^[0-9]+\z/;
  $n eq '?' ? $sh->{q} : $n eq '!' ? ($sh->{bang} // {})->{first} // '' : $n eq '#' ? scalar @{$sh->{args}}
    : $n eq '$' ? $sh->{pid} : $n eq '@' || $n eq '*' ? join(ifs1($c), @{$sh->{args}}) : $sh->{vars}{$n} // '' }
sub ifs1 { my $i = $_[0]{sh}{vars}{IFS}; defined $i ? substr($i, 0, 1) : ' ' }
sub isset {
  my ($c, $n) = @_; my $sh = $c->{sh};
  $n =~ /^[1-9][0-9]*\z/ ? $n <= @{$sh->{args}} : $n =~ /^[@*]\z/ ? !!@{$sh->{args}}
    : $n eq '!' ? defined $sh->{bang} : $n =~ /^[?#\$0]\z/ || defined $sh->{vars}{$n} }
sub getvar {   # a value for $NAME, or undef after ending the shell (set -u)
  my ($c, $n) = @_;
  return fail($c, 2, "$n: parameter not set") if $c->{sh}{opt}{u} && $n !~ /^[@*!]\z/ && !isset($c, $n);
  var($c, $n) }

sub active { $_[0] =~ /(?:^|[^\\])(?:\\\\)*[*?\[]/ }   # X52: an expansion's text has a pattern character no backslash escapes
                                                     #   (else no pathname expansion: x\* stays x\*, as both shells)
sub glob_quote { (my $s = shift) =~ s/([\\*?\[\]{}~!^-])/\\$1/g; $s }   # also ! ^ -: literal inside [...]
sub slash_brackets {   # for bsd_glob: a bracket expression with a '/' is none, its '[' literal (both shells); [^...] as [!...]
  my $p = shift; my $o = '';
  while ($p =~ /\G(?:(\\.)|(\[)|(.))/gcs) {
    if (!defined $2) { $o .= $+; next }
    my $s = pos $p;
    if ($p =~ /\G([!^]?)(\]?(?:\\.|\[:[a-z]+:\]|[^\]\\])*)\]/gcs) { my ($n, $b) = ($1, $2);
      if ("$n$b" =~ m{/}) { $o .= '\\['; pos($p) = $s }
      else { $b =~ s/\[:([a-z]+):\]/class_chars($1)/ge; $o .= ($n ? '[!' : '[') . "$b]" } }   # [^...]: [!...] (rule E)
    else { $o .= '['; pos($p) = $s } }
  $o }
my %CLASS = (   # X40: the classes in the C locale, as ranges [FROM, TO] and single characters
  alpha => [['a', 'z'], ['A', 'Z']], upper => [['A', 'Z']], lower => [['a', 'z']], digit => [['0', '9']],
  alnum => [['a', 'z'], ['A', 'Z'], ['0', '9']], xdigit => [['0', '9'], ['A', 'F'], ['a', 'f']],
  space => [" ", "\t", "\n", "\r", "\f", "\013"], blank => [" ", "\t"], cntrl => [["\x01", "\x1f"], "\x7f"],
  print => [["\x20", "\x7e"]], graph => [["\x21", "\x7e"]],
  punct => [grep $_ ne "/" && /[[:punct:]]/, map chr, 33 .. 126]);   # (no / in a name)
sub class_chars {   # X40: bsd_glob has no character classes: [:digit:] as its characters, in the C locale (as dash there;
  my $n = shift; my $m = $CLASS{$n} or return "[:$n:]";   # in a UTF-8 locale other letters belong too, not here)
  join '', map { ref $_ ? quote_bracket($_->[0]) . '-' . quote_bracket($_->[1]) : quote_bracket($_) } @$m }
sub quote_bracket { my $c = shift; $c =~ /[A-Za-z0-9]/ ? $c : "\\$c" }   # a member of a bracket expression, for bsd_glob

# A Word into fields: $k->([FIELD, ...]).  $how: 'argv' splits and globs; 'str' gives one string.
# A field under construction is a hash (JU1, post-0.12; before, an array by number): text, the field's text; pat, the
# same as a glob pattern (quoted characters escaped); keep, true to keep the field even if it is empty (something quoted
# was in it); glob, true if it has an active glob character; gone, true when "$@" stood for no parameters (L1).
sub fresh_field { +{ text => '', pat => '', keep => 0, glob => 0, gone => 0 } }
sub brace_seq {   # {FROM..TO} (the parser's option brace): integers, zero-padded to the longer one if either starts with 0, or
  my ($f, $t) = @_;   # single characters, in their order or backwards, as bash
  my @r = $f =~ /[0-9]/ ? ($f <= $t ? $f .. $t : reverse $t .. $f)
        : map chr, ord $f <= ord $t ? ord $f .. ord $t : reverse ord $t .. ord $f;
  return @r unless grep /^-?0[0-9]/, $f, $t;
  my $w = length $f > length $t ? length $f : length $t; map sprintf('%0*d', $w, $_), @r }
sub brace_words {   # X3: the words that brace expansion makes of a word, in bash's order (the last brace varies fastest)
  my @w = ([]);
  for my $p (@{$_[0]}) {
    my @alt = !ref $p ? [$p] : $p->[0] eq '{..' ? map([$_ eq '\\' ? ["'", ''] : $_], brace_seq(@$p[1, 2]))   # (bash: the word that
              # is a lone backslash, as in {X..b}, comes out empty)
            : $p->[0] eq '{' ? map([ref $_ ? @$_ : length $_ ? $_ : ()], @$p[1 .. $#$p]) : [$p];   # (an empty alternative adds
    @w = map { my $pre = $_; map [@$pre, @$_], @alt } @w }                                        #  nothing, as in f{,.bak})
  @w }
sub expand {
  my ($c, $word, $how, $k) = @_;
  return $k->([$word]) unless ref $word;
  if (grep ref && $_->[0] =~ /^\{/, @$word) {   # X3: brace expansion comes first; each word it makes is then expanded as usual
    my @all;
    return each_async([brace_words($word)],
      sub { my ($w, $more) = @_; expand($c, $w, $how, sub { push @all, @{$_[0]}; $more->() }) },
      sub { $k->($how eq 'argv' ? \@all : [join ' ', @all]) }) }
  my @f; my $cur = fresh_field();
  my $add = sub {   # text; $pat: its glob characters are active; $split: an unquoted expansion
    my ($t, $pat, $split) = @_;
    my $ifs = $c->{sh}{vars}{IFS} // " \t\n";
    if ($split && $how eq 'argv' && $ifs ne '') {   # split at IFS characters (L2); the pieces may glob
      my ($ws, $nw) = map quotemeta, join('', $ifs =~ /[ \t\n]/g), join('', $ifs =~ /[^ \t\n]/g);
      my $d = $nw eq '' ? qr/[$ws]+/ : $ws eq '' ? qr/[$nw]/ : qr/[$ws]*[$nw][$ws]*|[$ws]+/;
      my @p = split /($d)/, $t, -1;
      for my $j (0 .. $#p) {
        if ($j % 2) {   # a delimiter: one with a non-blank IFS character ends a field even if it is empty
          push @f, $cur if length $cur->{text} or $cur->{keep} or $nw ne '' && $p[$j] =~ /[$nw]/; $cur = fresh_field(); next }
        $cur->{text} .= $p[$j]; $cur->{pat} .= $p[$j]; $cur->{glob} ||= active($p[$j]) } }
    elsif ($split && $how eq 'argv') { $cur->{text} .= $t; $cur->{pat} .= $t; $cur->{glob} ||= active($t) }   # IFS empty: no splitting
    else { $cur->{text} .= $t; $cur->{pat} .= $pat ? $t : glob_quote($t); $cur->{glob} ||= $pat && $t =~ /[*?\[]/;
           $cur->{keep} = 1 unless $pat } };
  my $params = sub {   # "$@" and "${@#p}": one field per parameter; none: the field goes, quotes or not (L1)
    $cur->{gone} = 1 unless @_;
    for my $j (0 .. $#_) { if ($j) { push @f, $cur; $cur = fresh_field() } $add->($_[$j], 0) } };
  my @parts = @$word; my $i = 0;
  loop_async(sub { my $next = shift;
    if ($i > $#parts) {
      push @f, $cur if length $cur->{text} or $cur->{keep} && !$cur->{gone} or $how ne 'argv';
      return $k->([map $_->{text}, @f]) if $how ne 'argv';
      return $k->([map {   # a pattern that matches nothing stays as it is
        my ($t, $p, $g) = @$_{qw(text pat glob)};
        my $base = !$g || is_abs($p) || $c->{sh}{cwd} eq Cwd::getcwd() ? '' : glob_quote($c->{sh}{cwd}) . '/';
        my @m = $g && !$c->{sh}{opt}{f} ? sort { $a cmp $b } grep !m{(?:^|/)\.\.?\z},
          File::Glob::bsd_glob($base . slash_brackets($p), File::Glob::GLOB_QUOTE()) : ();   # never . or .. (rule E, as bash)
        s{^\Q$c->{sh}{cwd}\E/}{} for $base ? @m : ();
        @m ? @m : $t } @f]) }
    my $x = $parts[$i++];
    return $add->($x, 0), $next->() unless ref $x;
    my ($kind, @a) = @$x; (my $q = $kind) =~ s/^"//; my $split = $kind !~ /^"/;
    if    ($kind eq '*')   { $add->($a[0], 1) }
    elsif ($kind eq '~')   { $add->($a[0] ne '' ? ($WIN ? win_home($a[0]) : (getpwnam $a[0])[7]) // "~$a[0]"   # ~ without HOME:
                                    #   from the password
                                    : exists $c->{sh}{vars}{HOME} ? var($c, 'HOME')   #   file (G16); Windows: no user database,
                                    : ($WIN ? $ENV{USERPROFILE} : (getpwuid $<)[7]) // '~', 0) }   #   USERPROFILE
    elsif ($kind eq '"$' && $a[0] eq '@' && $how eq 'argv') { $params->(@{$c->{sh}{args}}) }   # "$@"
    elsif ($q eq '$')      { my $v = getvar($c, $a[0]) // return; $add->($v, 0, $split) }
    elsif ($q eq '${#')    { my $v = getvar($c, $a[0]) // return; $add->(length $v, 0, $split) }
    elsif ($q eq '${')     {   # the word is expanded only if it is used, as in sh
      my ($n, $op, $w) = @a; my $v = var($c, $n);
      my $set = isset($c, $n) && ($op !~ /:/ || $v ne '');
      if ($op =~ /^[%#]/) {   # remove the smallest or largest matching suffix or prefix
        getvar($c, $n) // return;   # set -u (L4)
        return pattern_re($c, $w, sub { my $re = shift;
          my $trim = sub { my $v = shift; my @i = 0 .. length $v; @i = reverse @i if $op =~ /^(?:%|##)\z/;
            for my $i (@i) { my ($cut, $keep) = $op =~ /%/ ? (substr($v, $i), substr($v, 0, $i))
                               : (substr($v, 0, $i), substr($v, $i));
                             return $keep if $cut =~ $re }
            $v };
          if ($n eq '@' || $n eq '*') {   # G4 (rule E, as bash): from each parameter, then as $@ or $* would be
            my @t = map $trim->($_), @{$c->{sh}{args}};
            if ($kind eq '"${' && $n eq '@' && $how eq 'argv') { $params->(@t) }   # "${@#p}": as "$@"
            else { $add->(join(ifs1($c), @t), 0, $split) } }
          else { $add->($trim->($v), 0, $split) }
          $next->() }) }
      my $word = $op =~ /[-=?]/ ? !$set : $set;
      unless ($word) { $add->($op =~ /[-=?]/ ? $v : '', 0, $split); return $next->() }
      return expand($c, $w, 'str', sub { my $t = $_[0][0];
        return fail($c, 2, "$n: " . ($t ne '' ? $t : $op =~ /:/ ? 'parameter not set or null' : 'parameter not set'))
          if $op =~ /\?/;
        if ($op =~ /=/) { setvar($c, $n, $t) or return }
        $add->($t, 0, $split); $next->() }) if !$split || $op =~ /[=?]/;
      return each_async(ref $w ? $w : [$w], sub { my ($p, $more) = @_;   # unquoted: strings are split, ["'", text] is not
        return $add->($p, 0, 1), $more->() unless ref $p;
        return $add->($p->[1], 0), $more->() if $p->[0] eq "'";
        expand($c, [$p], 'str', sub { $add->($_[0][0], 0, $p->[0] !~ /^"/); $more->() }) }, $next) }
    elsif ($kind eq "'")   { $add->($a[0], 0) }
    elsif ($kind eq 'ext') { return handler($a[0])->($c, $x, sub { $add->(shift, 0, $split); $next->() }) }
    elsif ($q eq '$((' && ref $a[0]) {   # with $( ), `...` or ${#NAME} inside (parser item P2): those first, then the text
      return expand_str($c, $a[0], sub { my $v = arith($c, shift); return unless defined $v; $add->($v, 0, $split); $next->() }) }
    elsif ($q eq '$((')    { my $v = arith($c, $a[0]); return unless defined $v; $add->($v, 0, $split) }
    elsif ($q eq '$(')     { return subst($c, $a[0], sub { $add->(shift, 0, $split); $next->() }) }
    else { die "Proc::ShellSpawn: unknown part '$kind'" }
    $next->() }) }
sub loop_async {   # JH1 (post-0.12, X60): $body->(NEXT) again each time it calls NEXT; it stops by not calling it.  A
  my $body = shift;   # NEXT called at once continues a plain loop (no recursion, however many steps finish at once); a
  sub { my $resume = __SUB__;   # NEXT called later (a program, a $( ) to wait for) resumes it from the event loop
    while (1) { my ($now, $again) = 1;
      $body->(sub { $now ? ($again = 1) : $resume->() });
      $now = 0; $again or return } }->(); return }
sub each_async {   # $body->(ITEM, NEXT) for each item in turn (each may finish later), then $done->()
  my ($items, $body, $done) = @_; my $i = 0;
  loop_async(sub { my $next = shift; return $done->() if $i > $#$items; $body->($items->[$i++], $next) }) }
sub expand_str  { my ($c, $w, $k) = @_; expand($c, $w, 'str', sub { $k->($_[0][0]) }) }
sub expand_list {   # several words, one after another (each may see the effect of the one before)
  my ($c, $ws, $how, $k) = @_; my @out;
  each_async($ws, sub { my ($w, $next) = @_; expand($c, $w, $how, sub { push @out, @{$_[0]}; $next->() }) }, sub { $k->(\@out) }) }

sub subst {   # $( list ): $k->(OUTPUT without trailing newlines)
  my ($c, $list, $k) = @_;
  my ($r, $w) = new_pipe() or return msg($c, "pipe: $!", sub { $k->('') });
  my ($out, $st, $eof) = ('');
  my $done = sub { return unless $eof && defined $st; $c->{sh}{qsub} = $st; $k->($out =~ tr/\0//dr =~ s/\n+\z//r) };
  my $d = derive($c, { %{$c->{map}}, 1 => $w }, jobs => 1, shell => sub { $st = shift; $done->() }); release($w);
  on_read($r, 65536, sub {
    return $eof = 1, release($r), $done->() unless defined $_[0];
    $out .= $_[0]; on_read($r, 65536, __SUB__) });
  x_list($d, $list, [$d], $d->{shell}{exit}) }

# $(( )): sh's integer arithmetic.  undef (after a message, and leaving the shell) on error.
sub arith {
  my ($c, $e) = @_; my $src = $e;
  my $unset; $e =~ s/\$\{?([A-Za-z_][A-Za-z_0-9]*|[0-9]+|[?!#\$])\}?/getvar($c, $1) \/\/ ($unset = '0')/ge;
  return if $unset;
  my @t = $e =~
    /\G\s*(0[xX][0-9a-fA-F]+|[0-9]+|[A-Za-z_][A-Za-z_0-9]*|<<=|>>=|<<|>>|<=|>=|==|!=|&&|\|\||[-+*\/%&^|]=|[-+*\/%<>&^|!~?:()=])/gc;
  my $err = sub { fail($c, 2, "arithmetic expression: $_[0]: \"$src\""); undef };
  return $err->('syntax error') if $e !~ /\G\s*\z/gc;
  # JU4 (post-0.12): the two parsers are named functions over these variables, set with local for this call, as test's
  # parser is written (before: two closures calling each other, kept from a cycle by weak references, E21).  Each
  # thread has its own interpreter, so its own copies of them.
  local our ($AC, @AT, $AP, $ABAD, $ADEAD, $ASKIP) = ($c, @t); $AP = 0; $ASKIP = 0;   # $ASKIP: inside the side of && || ?:
  my $v = arith_expr(0); $ABAD //= 'syntax error' if $AP <= $#AT;                       # that is not taken
  return if $ADEAD;   # a readonly variable: the shell is already ending
  defined $ABAD ? $err->($ABAD) : $v }
{ use integer;
  my %bin = ('*' => 9, '/' => 9, '%' => 9, '+' => 8, '-' => 8, '<<' => 7, '>>' => 7, '<' => 6, '<=' => 6,
             '>' => 6, '>=' => 6, '==' => 5, '!=' => 5, '&' => 4, '^' => 3, '|' => 2, '&&' => 1, '||' => 0);
  our ($AC, @AT, $AP, $ABAD, $ADEAD, $ASKIP);
  sub arith_unary {
    my $x = $AT[$AP++] // return +($ABAD //= 'syntax error') && 0;
    return -arith_unary() if $x eq '-'; return +arith_unary() if $x eq '+';
    return !arith_unary() ? 1 : 0 if $x eq '!'; return ~arith_unary() if $x eq '~';
    if ($x eq '(') { my $v = arith_expr(0); ($AT[$AP++] // '') eq ')' or $ABAD //= 'syntax error'; return $v }
    return do { no warnings 'portable'; $x =~ /^0[xX]/ ? hex $x : $x =~ /^0/ ? oct $x : $x } if $x =~ /^[0-9]/;   # 64-bit, as dash
    if ($x =~ /^[A-Za-z_]/) { my $v = var($AC, $x); $v = 0 if $v =~ /^\s*\z/;
      unless ($v =~ /^\s*[-+]?[0-9]+\s*\z/) { $ABAD //= "$x: not a number" unless $ASKIP; return 0 }   # (X42: no Perl warning)
      return $v + 0 }
    $ABAD //= 'syntax error'; 0 }
  sub arith_expr {
    my $min = shift;
    if (!$min && ($AT[$AP] // '') =~ /^[A-Za-z_]/ && ($AT[$AP + 1] // '') =~ /^(?:<<|>>|[-+*\/%&^|])?=\z/) {   # NAME op= EXPR,
      # right to left
      my ($n, $op) = @AT[$AP, $AP + 1]; $AP += 2; my $r = arith_expr(0); $op =~ s/=\z//;
      my $o = var($AC, $n); $o = 0 if $o =~ /^\s*\z/;
      ($op =~ m{^[/%]\z} && !$r) ? ($ABAD //= 'division by zero') : $op ne '' and $r = eval "\$o $op \$r";
      $ASKIP or $ADEAD or setvar($AC, $n, $r) or $ADEAD = 1; return $r }
    my $l = arith_unary();
    while (defined(my $op = $AT[$AP])) {
      if ($op eq '?' && $min <= 0) {
        $AP++; my $a = do { local $ASKIP = $ASKIP || !$l; arith_expr(0) };
        ($AT[$AP++] // '') eq ':' or $ABAD //= 'syntax error';
        my $b = do { local $ASKIP = $ASKIP || $l; arith_expr(0) }; $l = $l ? $a : $b; next }
      my $pr = $bin{$op}; last unless defined $pr && $pr >= $min; $AP++;
      my $r = do { local $ASKIP = $ASKIP || ($op eq '&&' ? !$l : $op eq '||' ? $l : 0); arith_expr($pr + 1) };
      if    ($op eq '&&') { $l = $l && $r ? 1 : 0 } elsif ($op eq '||') { $l = $l || $r ? 1 : 0 }
      elsif ($op =~ m{^[/%]\z} && !$r) { $ABAD //= 'division by zero' unless $ASKIP; $l = 0 }
      else { $l = eval "\$l $op \$r" ; $l = $l ? 1 : 0 if $op =~ /^[<>=!]=?\z|^[<>]\z/ } }
    $l } }

# ------------------------------------------------------------------ the tree
# x_*($c, NODE, $tail, $k): run NODE in context $c, then $k->(STATUS).  $tail: the contexts to
# release as soon as the last process NODE can start has started (undef: something may follow).
sub after_start { release_ctx($_) for @{$_[0] // []} }

sub x_list {
  my ($c, $l, $tail, $k) = @_; my $i = 0;
  sub { my $st = shift; my $p = $c->{sh}{pend}; my $me = __SUB__;
        return Proc::ShellSpawn::Large::run_pending($c, sub { $c->{sh}{q} = $st; $me->($st) })
          if !$c->{intrap} && ($p && @$p || $c->{sh}{tbusy});   # X19
        return defer($k, $st) if $i > $#$l;
        x_andor($c, $l->[$i++], $i > $#$l ? $tail : undef, $me) }->(0) }

sub x_andor {
  my ($c, $ao, $tail, $k) = @_;
  return x_bg($c, [@$ao[0 .. $#$ao - 1]], $k) if $ao->[-1] eq '&';
  my ($i, $ran) = (0, -1); my $cc = cond($c);
  sub { my $st = shift;
    $i += 2 while $i > 0 && $i <= $#$ao && ($ao->[$i - 1] eq '&&') != ($st == 0);
    if ($i > $#$ao) {   # set -e: the last pipeline failed, not negated, not in a condition
      return leave($c, $st) if $st && $c->{sh}{opt}{e} && !$c->{cond} && $ran == $#$ao && ref $ao->[-1][0];
      return defer($k, $st) }
    my $p = $ao->[$ran = $i]; $i += 2;
    x_pipeline($i > $#$ao ? $c : $cc, $p, $i > $#$ao ? $tail : undef, __SUB__) }->(0) }
sub cond { +{ %{$_[0]}, cond => 1, held => 0 } }   # a context whose commands do not trigger set -e

sub x_bg {   # chain & : its own shell and job, fd 0 from /dev/null
  my ($c, $ao, $k) = @_;
  my $null = open_end($c, '/dev/null', '<') or return msg($c, "/dev/null: $!", done($k, 2));
  my $job = { pids => [] }; $JOBS{$job} = $job; push @{$c->{sh}{jobl}}, $job;
  $job->{id} = ++$c->{sh}{jobs};
  my $d = derive($c, { %{$c->{map}}, 0 => $null }, shell => sub {
    tr_("background job $job->{id}: done, status $_[0]"); delete $JOBS{$job};
    $job->{st} = shift; $_->() for splice @{$job->{waiters} // []} });   # for the wait builtin
  release($null);
  $d->{sh}{job} = $job;         # shared by the job's shells: its first process becomes $!
  x_andor($d, $ao, [$d], $d->{shell}{exit});
  $c->{sh}{bang} = $job;
  $c->{sh}{q} = 0; defer($k, 0) }

sub x_pipeline {
  my ($c, $p, $tail, $k) = @_;
  my @cmd = @$p; my $neg = !ref $cmd[0] && shift @cmd; $c = cond($c) if $neg;
  my $kk = sub { my $st = $neg ? ($_[0] ? 0 : 1) : $_[0]; $c->{sh}{q} = $st; $k->($st) };
  return x_cmd($c, $cmd[0], $tail, $kk) if @cmd == 1;
  my (@ends, @d, @st); my $left = @cmd;
  for (1 .. $#cmd) { push @ends, [new_pipe()]; @{$ends[-1]} or return msg($c, "pipe: $!", sub { $kk->(2) }) }
  for my $j (0 .. $#cmd) {   # each element: a shell of its own, fds 0 and 1 on the pipes
    my %m = %{$c->{map}};
    $m{0} = $ends[$j - 1][0] if $j; $m{1} = $ends[$j][1] if $j < $#cmd;
    my $done = sub { $st[$j] = shift; defer($kk, $st[-1]) unless --$left };
    $d[$j] = derive($c, \%m, jobs => 1, shell => $done) }
  release($_) for map @$_, @ends;           # the creator's holds: only the elements' remain
  x_cmd($d[$_], $cmd[$_], [$d[$_]], $d[$_]{shell}{exit}) for 0 .. $#cmd;
  after_start($tail) }

sub x_cmd {
  my ($c, $x, $tail, $k) = @_;
  $c->{sh}{vars}{LINENO} = $x->{line} if $x->{line};   # G8 (rule E, as bash): the line where the command starts
  return x_simple($c, $x, $tail, $k) if $x->{argv};
  return with_redirs($c, $x->{redir}, undef, $k, sub { x_cd($_[0], $x, $_[2]) }) if exists $x->{cd};   # cd with redirections
    # (post4-0.03)
  return with_redirs($c, $x->{redir}, undef, $k, sub { x_set($_[0], $x, $_[2]) }) if $x->{set};   # (D2: as dash, redirect
    # first; failed: no setting, status 2; the values are expanded with the redirections in force; JH2, post-0.12)
  return handler('Proc::ShellSpawn::Large::x_rest')->($c, $x, $tail, $k) if exists $x->{rest};   # P1
  if (my ($h) = $x->{ext} // map $KIND{$_}, grep exists $x->{$_}, sort keys %KIND) { return handler($h)->($c, $x, $tail, $k) }
  with_redirs($c, $x->{redir}, $tail, $k, sub {
    my ($c, $tail, $k) = @_;
    if (my $l = $x->{group}) { return x_list($c, $l, $tail, $k) }
    if (my $l = $x->{sub}) {
      my $d = derive($c, { %{$c->{map}} }, shell => $k);
      return x_list($d, $l, [$d, @{$tail // []}], $d->{shell}{exit}) }
    return x_if($c, $x->{if}, $tail, $k) if $x->{if};
    return x_while($c, $x, $k) if $x->{while} || $x->{until};
    return x_for($c, $x, $k) if exists $x->{for};
    return x_case($c, $x, $tail, $k) if exists $x->{case};
    die "Proc::ShellSpawn: unknown command node" }) }

sub x_if {
  my ($c, $arms, $tail, $k) = @_; my $i = 0;
  loop_async(sub { my $next = shift;
    return defer($k, 0) if $i > $#$arms;
    return x_list($c, $arms->[$i], $tail, $k) if $i == $#$arms;       # else
    my $then = $arms->[$i + 1]; $i += 2;
    x_list(cond($c), $arms->[$i - 2], undef, sub { $_[0] ? $next->() : x_list($c, $then, $tail, $k) }) }) }

sub loop {   # runs $iter->(CONTEXT, NEXT, END) per iteration, with break and continue
  my ($c, $k, $iter) = @_; my $st = 0;
  my $rec = { scope => [] };
  my $lc = { %$c, loops => [@{$c->{loops}}, $rec] };
  my $end = sub { release_all($rec->{scope}); delete @$rec{qw(brk cont)}; defer($k, @_ ? shift : $st) };
  $rec->{brk} = sub { $end->(0) };
  sub { my $next = __SUB__; release_all($rec->{scope}); $rec->{scope} = [];
        $rec->{cont} = sub { $st = 0; $next->() }; $iter->($lc, sub { $st = shift; defer($next) }, $end) }->() }

sub x_while {
  my ($c, $x, $k) = @_; my $until = exists $x->{until};
  loop($c, $k, sub { my ($c, $next, $end) = @_;
    x_list(cond($c), $x->{while} // $x->{until}, undef, sub {
      ($_[0] == 0) != $until ? x_list($c, $x->{do}, undef, $next) : $end->() }) }) }

sub x_for {
  my ($c, $x, $k) = @_;
  expand_list($c, $x->{in} // [[['"$', '@']]], 'argv', sub {
    my @w = @{$_[0]};
    loop($c, $k, sub { my ($c, $next, $end) = @_;
      return $end->() unless @w;
      setvar($c, $x->{for}, shift @w) or return; x_list($c, $x->{do}, undef, $next) }) }) }

sub x_case {
  my ($c, $x, $tail, $k) = @_; my @in = @{$x->{in}};
  expand_str($c, $x->{case}, sub { my $s = shift;
    loop_async(sub { my $next = shift; return defer($k, 0) unless @in;
      my ($pats, $l) = splice @in, 0, 2; my @p = @$pats;
      loop_async(sub { my $again = shift; return $next->() unless @p;
        pattern_re($c, shift @p, sub { $s =~ $_[0] ? x_list($c, $l, $tail, $k) : $again->() }) }) }) }) }

sub pattern_re {   # a case (or ${N%p}) pattern as a regex anchored at both ends: quoted parts literal.  The whole
  my ($c, $w, $k) = @_;   # pattern is put together first, quoted text escaped, so that a bracket expression may span Parts
  my @parts = ref $w ? @$w : ($w); my $g = ''; my $i = 0;
  loop_async(sub { my $next = shift;
    return $k->(eval { my $re = glob_re($g); qr/\A$re\z/s } // do { (my $t = $g) =~ s/\\(.)/$1/gs; qr/\A\Q$t\E\z/s })
      if $i > $#parts;
    my $x = $parts[$i++];
    return $g .= glob_quote($x), $next->() unless ref $x;
    if ($x->[0] eq '*') { $g .= $x->[1]; return $next->() }
    expand($c, [$x], 'str', sub { $g .= $x->[0] =~ /^"/ ? glob_quote($_[0][0]) : $_[0][0]; $next->() }) }) }
sub glob_re {   # a glob pattern (quoted characters escaped with '\') as a regex
  my $g = shift; my $re = '';
  while ($g =~ /\G(?:(\*)|(\?)|\[([!^]?)(\]?(?:\\.|\[:[a-z]+:\]|[^\]\\])*)\]|\\(.)|(.))/gcs) {
    $re .= defined $1 ? '.*' : defined $2 ? '.' : defined $4 ? bracket_re($3, $4) : quotemeta($5 // $6) }
  $re }
sub bracket_re {   # the members of a bracket expression: classes and ranges kept, every other character literal
  my ($neg, $b) = @_; my $o = '';
  while ($b =~ /\G(?:(\[:[a-z]+:\])|\\(.)|(-)|(.))/gcs) { $o .= defined $1 ? $1 : defined $3 ? '-' : quotemeta($2 // $4) }
  '[' . ($neg ? '^' : '') . $o . ']' }

sub setvar {   # 1, or 0 after ending the shell (a readonly variable, as dash)
  my ($c, $n, $v) = @_; my $sh = $c->{sh};
  return do { fail($c, 2, "$n: is read only"); 0 } if $sh->{ro}{$n};
  $sh->{exp}{$n} = 1 if $sh->{opt}{a}; $sh->{vars}{$n} = $v; 1 }

sub x_set {   # NAME=value ... alone (with redirections: through with_redirs, in x_cmd; rule E: category effect)
  my ($c, $x, $k) = @_; my @s = @{$x->{set}};
  delete $c->{sh}{qsub}; my %log;   # the settings as made, for $ONBUILTIN (measurement)
  loop_async(sub { my $next = shift;
        unless (@s) { $ONBUILTIN->('x_set', [], {%log}) if $ONBUILTIN; return defer($k, $c->{sh}{qsub} // 0) }
        my ($n, $w) = splice @s, 0, 2;
        expand_str($c, $w, sub { $log{$n} = $_[0]; setvar($c, $n, shift) or return; $next->() }) }) }

sub x_cd {
  my ($c, $x, $k) = @_;
  my $go = sub {
    my @f = @_; $ONBUILTIN->('x_cd', ['cd', ($x->{cd_p} ? '-P' : ()), @f], {}) if $ONBUILTIN;   # (measurement)
    my $phys = $x->{cd_p};
    unless ($x->{cd_dd}) {   # X80: options made by an expansion are read from the fields, as both shells read them: -L, -P
      while (@f && $f[0] =~ /^-./) {   # (the last counts), --; any other is an error, status 2, as both (bash's own -e, -@: as dash, A5)
        my $o = shift @f; last if $o eq '--';
        return msg($c, "cd: Illegal option -$1", done($k, 2)) if $o =~ /^-[LP]*([^LP])/;
        $phys = substr($o, -1) eq 'P' } }
    my $d = @f ? $f[0] : var($c, 'HOME');
    my $dash = @f == 1 && $d eq '-' and $d = var($c, 'OLDPWD');   # cd -: back, and print where
    $d = '.' if @f == 1 && $d eq '';   # X74: an empty operand is '.', so OLDPWD becomes this directory, as both shells; so is
      # cd - with OLDPWD empty or unset, which then prints the directory, as dash (A5; bash: "OLDPWD not set", status 1)
    return msg($c, "cd: too many arguments", done($k, 1)) if @f > 1;   # as bash (rule E), also when an expansion gives the
      # extra fields at run time (X54); counted after the expansion of every operand word and the options (X80)
    return msg($c, "cd: HOME not set", done($k, 1)) if !@f && !isset($c, 'HOME');   # as bash (rule E; N4)
    $d = '.' if !@f && $d eq '';   # HOME empty: stays, as both shells (X45), and OLDPWD becomes this directory (X74)
    my $new = path_in($c, $d);   # (an operand starting with - is a directory's name here: after --, as both shells)
    if ($phys) { $new = -d $new && Cwd::realpath($new) }   # cd -P: symbolic links resolved, '..' physical (P6)
    else {   # (Windows: the drive or the //server/share stays in front)
      my ($pre, $rest) = $WIN && $new =~ m{^([A-Za-z]:|[/\\]{2}[^/\\]+[/\\][^/\\]+)(.*)}s ? ($1 =~ tr{\\}{/}r, $2) : ('', $new);
      my @p; for (split $SEP, $rest) { next if $_ eq '' or $_ eq '.'; $_ eq '..' ? pop @p : push @p, $_ }
      $new = $pre . '/' . join '/', @p }
    $new && -d $new && ($WIN || -x _) or return msg($c, "cd: can't cd to $d", done($k, 2));   # X44: and searchable, as both shells
    setvar($c, OLDPWD => $c->{sh}{cwd}) && setvar($c, PWD => $new) or return; $c->{sh}{cwd} = $new;
    $dash ? put($c, 1, "$new\n", done($k, 0)) : defer($k, 0) };
  defined $x->{cd} ? expand_list($c, [$x->{cd}, @{$x->{cd_more} // []}], 'argv', sub { $go->(@{$_[0]}) }) : $go->() }   # X80

sub x_simple {
  my ($c, $x, $tail, $k) = @_;
  my $k0 = $k; $k = sub { leave($c, shift) } if $x->{exec};   # exec cmd: then the shell ends
  my @env = @{$x->{env} // []}; my %env;
  delete $c->{sh}{qsub};
  my $settings = sub {   # NAME=value before the command, left to right, each seeing the ones before
    my $next = shift;
    loop_async(sub { my $again = shift; return $next->() unless @env;
          my ($n, $w) = splice @env, 0, 2;
          my $v = { %$c, sh => { %{$c->{sh}}, vars => { %{$c->{sh}{vars}}, %env } } };
          expand_str($v, $w, sub { $env{$n} = shift;
            $c->{sh}{qsub} = $v->{sh}{qsub} if exists $v->{sh}{qsub}; $again->() }) }) };
  $settings->(sub { expand_list($c, $x->{argv}, 'argv', sub {
    my @argv = @{$_[0]};
    redirect($c, $x->{redir} // [], sub {   # (JH2: one call; every word expanded to nothing, the redirections are still done)
      my ($m, $opened) = @_;
      if (!$m) { return @argv && $SPECIAL{$argv[0]} ? leave($c, 2) : defer($k, 2) }
      if ($x->{exec} && !@argv) {   # X75: exec, and its words expanded to nothing: as exec alone; the redirections and
        setvar($c, $_, $env{$_}) or return for sort keys %env;   # the settings stay, the shell goes on (both shells)
        keep_map($c, $m, $opened); return defer($k0, 0) }
      unless (@argv) { release($_) for @$opened; return defer($k, $c->{sh}{qsub} // 0) }
      if (my $e = !$x->{exec} && ($c->{sh}{cmd}{$argv[0]}   # a function or a builtin, in this process; not after exec, which
                                  // ($x->{fn} ? ['Proc::ShellSpawn::Large::b_late'] : cmd_of($argv[0])))) {   # runs only a
        # program, as both shells (X56)
        my $d = derive($c, $m); release($_) for @$opened;          # a context holds its fds until it is done
        $ONBUILTIN->($e->[0], \@argv, {%env}) if $ONBUILTIN;   # (measurement: doc/large-subset/tools/large-subset-builtins.pl)
        if ($SPECIAL{$argv[0]}) { setvar($c, $_, $env{$_}) or return for sort keys %env; %env = () }   # these settings stay
        return handler($e->[0])->($d, \@argv, \%env, sub { release_ctx($d); $k->(@_) }, $e->[1]) }
      @argv = printf_zero(@argv) if $argv[0] eq 'printf';
      my $node = spawn($c, $m, \@argv, \%env, $k, undef, $x->{exec} && 'exec: ');
      $c->{sh}{job}{first} //= $node->{pid} if $node && $c->{sh}{job};
      release($_) for @$opened; after_start($tail) }) }) }) }

sub printf_zero {   # the 0 flag of %s, %c, %b dropped from printf's format, as both shells (glibc's printf(3) ignores it; the
  my @a = @_;       # flag is undefined for them in C and POSIX); the program printf (coreutils) refuses it
                    # (decision Z0, 2026-11-05)
  my $i = ($a[1] // '') eq '--' ? 2 : 1;
  return @a unless defined $a[$i] && $a[$i] !~ /^-/;   # printf -v ...: the program's, as decided (Q2)
  $a[$i] =~ s{%(%|([-+ #0']*)(\*|[0-9]*)((?:\.(?:\*|[0-9]*))?)([a-zA-Z]))}{
    my ($all, $fl, $w, $p, $cv) = ($1, $2, $3, $4, $5);
    defined $cv && $cv =~ /^[scb]\z/ ? '%' . ($fl =~ tr/0//dr) . $w . $p . $cv : "%$all" }ge;
  @a }
sub ok_num {   # NV1 (the user, 2026-11-10; X42): an operand of exit, return, break, continue known only at run time is a
  # number as dash takes it: digits, maybe after +, at most 2^31-1, at least $min; else an error, status 2, as the shells
  my ($v, $min) = @_; defined $v && $v =~ /^\+?[0-9]+\z/ && $v <= 2147483647 && $v >= $min }
sub b_colon { my ($c, $argv, $env, $k) = @_; defer($k, 0) }   # :
sub b_exit {
  my ($c, $argv, $env, $k) = @_; my (undef, @a) = @$argv;
  return leave($c, $c->{sh}{q}) unless @a;
  return fail($c, 2, "exit: Illegal number: $a[0]") unless ok_num($a[0], 0);   # NV1 (X42): known only at run time, as the shells
  leave($c, $a[0] % 256) }   # exit 1000: 232, as both shells (parser item P4)
sub b_break {   # break and continue
  my ($c, $argv, $env, $k) = @_; my ($n, @a) = @$argv;
  my $l = $c->{loops}; my $j = @a ? $a[0] : 1;
  return fail($c, 2, "$n: Illegal number: $j") unless ok_num($j, 1);   # NV1: 0, -1, x1 (bash goes on after 0: dash's way)
  $j += 0;
  return leave($c, 0) if $j > @$l;   # the loop is outside this subshell: it ends the subshell, as dash (rule E, post-0.04)
  release_all(map $_->{scope}, @$l[$#$l - $j + 1 .. $#$l]);
  defer($l->[-$j]{$n eq 'break' ? 'brk' : 'cont'}) }
sub b_read { my ($c, $argv, $env, $k) = @_; my (undef, @a) = @$argv; read_line($c, $c->{map}, $env, \@a, $k) }

# read [-r] [-p PROMPT] NAME...: one line from fd 0, one byte at a time (later commands get the rest), split
# as sh does: IFS blanks around fields are dropped, one other IFS character ends a field, the last
# NAME gets the rest of the line; without -r a backslash protects the next character, and a
# backslash before the newline continues the line.  Status 1 at end of file.  The prompt of -p goes to fd 2,
# and only when fd 0 is a terminal, as in both shells (P6).
sub read_line {
  my ($c, $m, $env, $names, $k) = @_; my @a = @$names; my ($raw, $prompt);
  while (@a && $a[0] =~ /^-(r*)(p?)\z/ && "$1$2" ne '') { shift @a; $raw ||= $1 ne ''; $prompt = shift @a if $2 }
  # names may come from expansions (post-0.04): checked here, with dash's messages and status 2 (A5)
  return msg($c, "read: arg count", done($k, 2)) unless @a;
  for (@a) { return msg($c, "read: $_: bad variable name", done($k, 2)) unless /^[A-Za-z_][A-Za-z0-9_]*\z/;
             return handler("Proc::ShellSpawn::Large::unsupported")->($c, "the name '$_' in 'read'")
               unless Proc::ShellSubset::settable($_);
             return msg($c, "read: $_: is read only", done($k, 2)) if $c->{sh}{ro}{$_} }
  my $e = $m->{0} or return defer($k, 1);
  my $ifs = $env->{IFS} // $c->{sh}{vars}{IFS} // " \t\n";
  # JC1 (post-0.12): the line is split by regular expressions (before: a character array walked by an index).  $ws: the
  # IFS blanks, $nws: the other IFS characters, both for a bracket expression (without -r never a backslash: none is left
  # unprotected), and either may be empty, so each expression is built for the case (a class that cannot match, under
  # '*+', makes Perl 5.38 panic); a unit: one character, or (without -r) a backslash with the character it protects
  my ($ws, $nws) = map { join '', map quotemeta, grep $raw || $_ ne '\\', @$_ } [$ifs =~ /[ \t\n]/g], [$ifs =~ /[^ \t\n]/g];
  my $W = length $ws ? qr/[$ws]*+/ : qr//;                # IFS blanks, as many as there are
  my $sep = length $nws ? qr/$W(?:[$nws]$W)?/ : $W;       # after a field: blanks, at most one other IFS character, blanks
  my $end = length $nws ? qr/$W(?:[$nws]$W)?\z/ : qr/$W\z/;   # after the only field left: blanks, at most one such character, blanks (X61)
  my $unit = $raw ? qr/./s : qr/\\.|[^\\]/s;
  my $field = length "$ws$nws" ? qr/(?:(?![$ws$nws])$unit)*+/ : qr/(?:$unit)*+/;   # units up to an unprotected IFS character
  my $val = sub { my $s = shift; $raw ? $s : $s =~ s/\\(.)/$1/gsr };   # a field's text: the protecting backslashes go
  my $line = '';
  my $got = sub {
    my $eof = shift;
    $line =~ s/(?<!\\)((?:\\\\)*)\\\z/$1/ unless $raw;   # a lone backslash at the end of the input goes
    $line =~ s/^$W//;
    for my $name (@a[0 .. $#a - 1]) { $line =~ s/^($field)$sep//; setvar($c, $name, $val->($1)) }
    # the last name: the rest without its final blanks; a single trailing delimiter after the only field is dropped, as in dash
    $line =~ /^($field)$end/ or $line =~ /^((?:$unit)*?)$W\z/;
    setvar($c, $a[-1], $val->($1));
    defer($k, $eof ? 1 : 0) };
  my $go = sub { on_read($e, 1, sub {
    my $b = shift;
    return $got->(1) unless defined $b;
    if ($b eq "\n") {   # continued if the line ends in an odd number of backslashes
      return $got->(0) if $raw or ($line =~ /(\\*)\z/)[0] =~ tr/\\// % 2 == 0;
      chop $line; return on_read($e, 1, __SUB__) }
    $line .= $b; on_read($e, 1, __SUB__) }) };
  defined $prompt && $e->{fh} && -t $e->{fh} ? put($c, 2, $prompt, $go) : $go->() }

# ------------------------------------------------------------------ entry points
sub start_pwd {
  my $phys = Cwd::getcwd();
  my $p = $ENV{PWD};
  return $p if defined $p && is_abs($p) && files_eq($p, '.');   # PWD from the environment, if it names where we are
  $phys }

# run(STRING or TREE, parser => CODE, interactive => 'nop' or 'dash', args => [$1 ...], arg0 => $0, opt => {e => 1, ...}):
# sh's status, or (undef, ERROR) if STRING is
# outside the subset.  The parser also reads the text of eval, . and trap actions (with the aliases defined so far:
# parser->(TEXT, aliases => {NAME => VALUE})).  interactive: what history, fc, bind, help, compopt, logout and
# set -o history do (B2): nothing (nop, the default; give the parser the same option) or as in dash (not found).
# redir_strict => 1 (X4; Q1): a redirection whose file name comes from an unquoted expansion fails with "ambiguous redirect"
# (status 2) when that expansion gives a blank (a character of IFS) or a pattern character, or the name is empty.
require Proc::ShellSpawn::Builtins;
# The variables a shell starts with: %ENV's.  On Windows Perl gives %ENV's names in upper case, so a shell started there
# would see only Z for an inherited z (X65).  The names there (post-0.12, the user, 2026-11-15, A22 (a)): as the process's
# environment block spells them, but PATH (Windows spells it Path; the shell needs PATH, as Cygwin makes it); the values
# from %ENV.  PROC_SHELLSPAWN_ENVNAMES (or $Proc::ShellSpawn::ENV_NAMES before run): 'block', the default, or 'upper',
# the names as %ENV gives them (A22 (b)), so that on Windows only an upper-case name reaches a shell of ours.
our $ENV_NAMES = $ENV{PROC_SHELLSPAWN_ENVNAMES} // 'block';
die "PROC_SHELLSPAWN_ENVNAMES: '$ENV_NAMES' is neither block nor upper\n" unless $ENV_NAMES =~ /\A(?:block|upper)\z/;
sub env_vars {
  return %ENV unless $WIN && $ENV_NAMES eq 'block' && defined &Proc::Spawner::__win_env_names;
  my %name = map +(uc($_) => $_), Proc::Spawner::__win_env_names(); $name{PATH} = 'PATH';
  map +(($name{uc $_} // $_) => $ENV{$_}), keys %ENV }
our $PATH0 = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';   # X6: the shell's PATH when the environment has
                           # none: dash's own default (bash's as Debian and Ubuntu build it).  $PATH itself is then outside the subset (V8)
sub run {
  my ($s, %o) = @_; my $parse = $o{parser} // default_parser(); a4();
  my $tree = ref $s ? $s : $parse->($s);
  return (undef, $tree) if ref $tree eq 'HASH';
  my $cwd = start_pwd();
  # dash sets OPTIND and IFS when it starts (L3)
  my %env = env_vars();
  my $sh = { vars => { %env, PWD => $cwd, OPTIND => 1, IFS => " \t\n",
                       PPID => $Proc::Spawner::WIN ? Proc::Spawner::__win_ppid() : getppid() },
             exp => { map +($_ => 1), keys %env, 'PWD' }, cwd => $cwd, q => 0,
             parse => $parse, args => [@{$o{args} // []}], arg0 => $o{arg0}, pid => $$, opt => {%{$o{opt} // {}}},
             cmd => {}, ro => {}, trap => {}, jobl => [], umask => umask,
             alias => {}, hash => {}, intext => 0, interactive => $o{interactive} // 'nop', redir_strict => $o{redir_strict} };
  my $st;
  $sh->{vars}{PATH} = $PATH0 unless $WIN || exists $env{PATH};   # X6: not exported, as in both shells
  my $c = { sh => $sh, loops => [], map => { map +($_ => is_open($_) ? own_fd($_) : undef), 0 .. 2 } };
  my $scope = []; $c->{shell} = { scope => $scope, exit => shell_exit($c, $scope, sub { $st //= shift }) };
  $sh->{die} = sub { $st //= shift };   # kill ... $$ (Proc::ShellSpawn::Large::b_kill): the whole string ends
  local %TRAPSAVE = (); $SIGNALLED = undef;   # signals the trap builtin changed: put back afterwards
  { local $RUNNING = 1;
    ignoring_int(sub { x_list($c, $tree, undef, $c->{shell}{exit}); loop_until(sub { defined $st }) }) }
  $SIG{$_} = $TRAPSAVE{$_} for keys %TRAPSAVE;
  %$c = ();
  idle(1); idle_pass();   # K3 (B): background jobs move on between calls too
  $st }

1;
