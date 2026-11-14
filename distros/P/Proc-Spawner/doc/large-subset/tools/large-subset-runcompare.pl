#!/usr/bin/perl
# large-subset-runcompare.pl (post4-0.04, 2026-11-05; -env, -base, post-0.09): run every corpus sample the large parser
# accepts in dash, bash --posix and Proc::ShellSpawn, and record what each did, for large-subset-runreport.pl to compare.
#
# Usage (as root, from the distribution's directory, after make):
#   perl doc/large-subset/tools/large-subset-runcompare.pl [-j 4] [-n MAX] [-only ID,...|@FILE] [-env V,...] [-base DIR]
#        samples.jsonl samples.tsv OUTDIR
# samples.tsv is large-subset-yardsticks.pl -o's output (its column 'large' says which samples the parser accepts).
# OUTDIR gets run-K.jsonl per worker (one line per sample); a rerun skips the samples already there, so it can be
# stopped and started again.  -only @FILE: the IDs one per line (the first field of a line; '#' lines skipped).
#
# Isolation (no sample can harm the machine or another sample):
# - each worker K runs as its own unprivileged user rcK (made if missing), with no network (unshare -n), CPU,
#   file-size and process limits (prlimit), a 5-second timeout, and every process of rcK killed after each run;
# - each run starts in a fresh copy of the same small directory (FIXTURE below), with HOME inside it;
# - PATH is the programs of %QUIET (run, not logged), then one directory of recorders: one for every program name on the system's PATH.  A recorder appends
#   its name and arguments to the run's log; for the names in %REAL (the programs we run in place of builtins,
#   and tools that only read or print) it then runs the real program, otherwise it exits 0 with no output.
# So the three shells see the same files, the same environment and the same "programs", and only the shells differ.
# Ours runs from a copy of lib/, blib/ and t/try.pl made at the start (BASE/dist), so lib/ may be edited during a run.
#
# -env V,...: the run's environment changed for every run of the three shells (known issue X27: tries the other case of
# an assumption, or fixes what the runs would otherwise share; large-subset-environment.md, section 9).  The variants
# (%ENVV below) that mount do so as root in a mount namespace of each run's own, before dropping to rcK, so nothing
# outside the run sees them.  BASE (-base, default /var/tmp/runcompare) holds the recorders, the copy and the runs'
# directories: it must not lie under what a variant hides (with tmp or private, use for instance -base /runcompare).
# The stand-in variants take their answer from this script's own environment, with a default: fail STANDIN_STATUS
# (default 1), output STANDIN_OUTPUT (default "one  two\n*\n\nlast"), mtime FIXTURE_MTIME (seconds since 1970, default
# 1577836800, 2020-01-01 00:00:00 UTC).  So  STANDIN_STATUS=2 perl large-subset-runcompare.pl -env fail ...  tries
# status 2.  The values used are written to OUTDIR/env.txt.
# -run DIR (post-0.09): ours goes through Run (DIR: Run's blib/lib, or the directory of Run.pm), as where there is neither
# posix_spawn nor fork (M2, Proc::Spawner's primitive 'system1'): PROC_SPAWNER_MISSING="posix_spawn fork", which t/try.pl
# takes out of the environment once the modules are loaded (TRY_HIDE), so that the samples do not see it.
# -shells LIST (post-0.10): run only these of dash, bash, ours (for instance ours alone, after a change of ours, to be
# joined with an earlier run's dash and bash; unlike -q, nothing more is logged).
# -setup FILE (X27, step 2; 2026-11-10): one example setup per sample, from large-subset-setups.pl (PREFIX-K.jsonl):
# before each run of the three shells, the files it names are made (a file with its text and mode, a directory) or
# removed in the run's copy of the fixture, its variables are added to the environment, and its standard input
# replaces /dev/null.  Only the samples the file names run (with -only: those of both).  OUTDIR/setup.txt names FILE.
# -standin LIST (X27, step 3; 2026-11-12): these programs of %REAL (below) are stand-ins too: logged, answering as the
# others (nothing, or -env output's STANDIN_OUTPUT; a setup's STANDIN_OUTPUT, STANDIN_STATUS).  A setup's own "standin"
# list does the same for its sample alone.  -env cowroot: every run gets a root of its own, a copy-on-write overlay of
# /, so that a setup can make or remove a file anywhere (its files with absolute names) and nothing a run writes stays
# (/tmp too); /dev, /proc and /sys are the real ones, the run's directory is bound in.
# -after SECONDS (post-0.11, 2026-11-12; the user, A18: the runner waits for every process of the run, with a reasonable
# timeout): after the shell ends, its background jobs still running get up to SECONDS (default 5, as the shell's own
# timeout) to end, so that their effects count whichever shell started them; then the rest is killed and the run
# records "after": "killed".  -after 0: killed at once, as before (the shells' jobs then often died before they did
# anything, while ours finishes its jobs before it ends).  With -env pidns, process 1 of the namespace waits for all.
# -workers-from DIR (post-0.10): each sample runs in the worker K (directory BASE/wK, user rcK) that ran it in the earlier
# run DIR (its run-K.jsonl), so that paths, $PWD and $USER are those of that run; samples not there are spread as usual.
use strict; use warnings; use JSON::PP; use File::Path qw(make_path remove_tree); use Cwd 'abs_path'; use Getopt::Long;
use POSIX ();
my ($J, $MAX, $ONLY, $Q, $ENVL, $BASE, $RUNLIB, $SHELLS, $WFROM, $SETUPF, $STANDIN, $AFTER) = (4, 0, '', 0, '', '/var/tmp/runcompare', '', 'dash,bash,ours', '', '', '', 5);   # -q: run ours only, and log the programs of %QUIET too, each line headed by its caller's name and \035 (for large-subset-threeway.pl),
#     and every builtin call (t/try.pl, RECBUILTIN; for large-subset-builtins.pl)
GetOptions('j=i' => \$J, 'n=i' => \$MAX, 'only=s' => \$ONLY, 'q' => \$Q, 'env=s' => \$ENVL, 'base=s' => \$BASE, 'run=s' => \$RUNLIB, 'shells=s' => \$SHELLS, 'workers-from=s' => \$WFROM, 'standin=s' => \$STANDIN, 'setup=s' => \$SETUPF, 'after=f' => \$AFTER) && @ARGV == 3
  or die "usage: $0 [-j N] [-n MAX] [-only IDS|\@FILE] [-q] [-env V,...] [-base DIR] [-run RUNLIB] [-shells LIST] [-workers-from DIR] [-standin LIST] [-setup FILE] [-after SECONDS] samples.jsonl samples.tsv OUTDIR\n";
my %SETUP;   # -setup: sample id => its setup
if (length $SETUPF) { open my $in, '<', $SETUPF or die "$SETUPF: $!"; while (<$in>) { my $s = decode_json($_); $SETUP{$s->{id}} = $s }
  %SETUP or die "-setup $SETUPF: no setups\n" }
our $CURSETUP;   # the setup of the sample being run
our $ARG0;       # its $0 when the setup gives arguments
!length $RUNLIB or -e "$RUNLIB/Run.pm" or die "-run $RUNLIB: no Run.pm there\n";
my %SH = map +($_ => 1), split /,/, $SHELLS; /^(?:dash|bash|ours)\z/ or die "-shells: dash, bash, ours\n" for keys %SH;
%SH or die "-shells: none\n"; %SH = (ours => 1) if $Q;
# The variants of -env: what each does, and the code of large-subset-provenance.tsv it is for.
my %ENVV = (
  posix   => 'POSIXLY_CORRECT=1 in the environment (code echo: the other case)',
  utf8    => 'LANG and LC_ALL C.UTF-8 in place of C (code locale: the other case)',
  sigpipe => 'SIGPIPE ignored, as inherited by the shells (code pipeline: the other case)',
  noproc  => 'an empty tmpfs over /proc (code devfd: the other case; as on a system without /proc)',
  tmp     => 'a fresh tmpfs on /tmp, /var/tmp and /dev/shm (code path-tmp: the runs no longer meet there)',
  random  => 'one fixed file of 1 MiB over /dev/urandom and /dev/random (code path-random: the same bytes in every run)',
  private => 'an empty tmpfs over /home, /root, /mnt, /media, /srv and /var (codes path-home, path-mnt, path-var)',
  dev     => 'a private /dev: only null, zero, full, tty, random, urandom, ptmx, pts, shm and the links fd, stdin, stdout, stderr (code path-dev)',
  fail    => 'every program the run only logs (not %REAL) exits with STANDIN_STATUS in place of 0 (code prog-status: another answer)',
  output  => 'every program the run only logs (not %REAL) prints STANDIN_OUTPUT in place of nothing (code prog-output: another answer)',
  mtime   => 'every file and directory of the run\'s copy of the fixture gets the times FIXTURE_MTIME (code time: ls -l, stat)',
  cowroot => 'a root of its own for every run: a copy-on-write overlay of / (absolute names in setups; nothing a run writes stays)',
  samearg0 => 'the three shells get the same $0, sh (code start: $0; the messages then start with sh: in all three)',
  pidns   => 'every run in a PID namespace of its own: the shell is process 2, its parent 1, in every run (code pid: $$, $PPID)',
  clock   => 'a clock that stands at FIXTURE_MTIME for the shell and what it starts (libfaketime; code time: $SECONDS, date); not to be used: libfaketime 0.9.10 opens its shared memory as descriptors 3 and 4 in every process (>&3 then succeeds)');
# The stand-ins' answers and the fixture's time (see above): from this script's environment, else the defaults.
my %STANDIN = (STANDIN_STATUS => $ENV{STANDIN_STATUS} // 1, STANDIN_OUTPUT => $ENV{STANDIN_OUTPUT} // "one  two\n*\n\nlast",
               FIXTURE_MTIME => $ENV{FIXTURE_MTIME} // 1577836800);
$STANDIN{STANDIN_STATUS} =~ /^(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\z/ or die "STANDIN_STATUS: 0 to 255\n";
$STANDIN{FIXTURE_MTIME} =~ /^[0-9]+\z/ or die "FIXTURE_MTIME: seconds since 1970\n";
my %ENV_ON = map +($_ => 1), grep length, split /,/, $ENVL;
for (sort keys %ENV_ON) { $ENVV{$_} or die "-env $_: unknown; known: ", join(', ', sort keys %ENVV), "\n" }
die "-q needs /proc (its recorder reads its caller's name there): not with -env noproc\n" if $Q && $ENV_ON{noproc};
my $FAKETIME = '/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1';
$ENV_ON{clock} && !-e $FAKETIME and die "-env clock needs libfaketime ($FAKETIME; apt-get install libfaketime)\n";
my ($SJ, $ST, $OUT) = @ARGV; make_path($OUT); $OUT = abs_path($OUT);
$> == 0 or die "run as root (it makes the users rcK and drops to them)\n";
my $DIST = abs_path('.'); -e "$DIST/blib/arch/auto/Proc/Spawner/Spawner.so" or die "run make first\n";
$BASE =~ m{^/} or die "-base: an absolute path\n";
for my $m (($ENV_ON{tmp} || $ENV_ON{private} ? qw(/tmp /var/tmp /dev/shm) : ()), ($ENV_ON{private} ? qw(/home /root /mnt /media /srv /var) : ()),
           ($ENV_ON{dev} ? '/dev' : ()), ($ENV_ON{noproc} ? '/proc' : ())) {
  "$BASE/" =~ m{^\Q$m\E/} and die "-base $BASE lies under $m, which -env $ENVL hides: choose another (-base /runcompare)\n" }
make_path($BASE); chmod 0755, $BASE;
my $COPY = "$BASE/dist"; remove_tree($COPY); make_path("$COPY/t");   # ours runs from this copy
system('cp', '-a', "$DIST/lib", "$DIST/blib", $COPY) == 0 && system('cp', '-a', "$DIST/t/try.pl", "$COPY/t/") == 0 or die "copy to $COPY failed\n";
if (length $RUNLIB) { make_path("$COPY/run"); system('cp', '-a', "$RUNLIB/Run.pm", "$COPY/run/") == 0 or die "copy of Run.pm failed\n" }
system('chmod', '-R', 'a+rX', $COPY) == 0 or die;
my $RANDOM = "$BASE/random";   # -env random: 1 MiB, the same everywhere (SHA-256 of "x27-random-N", N = 0, 1, ...)
if ($ENV_ON{random}) { require Digest::SHA; open my $o, '>:raw', $RANDOM or die "$RANDOM: $!";
  print $o Digest::SHA::sha256("x27-random-$_") for 0 .. 32767; close $o; chmod 0444, $RANDOM }
my $LIMIT = 4000;   # characters of each output kept

# %QUIET: the programs Proc::ShellSpawn runs in place of the shells' builtins (R-program): run, not logged, since the
# shells' builtins leave no log either.  %REAL: logged, then run (they only read, print or make files; rm, mv, cp,
# ln are only logged, to keep a sample from removing what it did not make).
my %QUIET = map +($_ => 1), qw(echo printf test [ true false pwd kill);
my %REAL = (%QUIET, map +($_ => 1), qw(cat grep egrep fgrep sed awk sort head tail wc tr cut uniq seq expr basename
  dirname printenv env xargs tee ls mkdir touch cmp diff od rev nl paste join fold comm tac realpath readlink stat
  sha256sum md5sum base64 yes));
delete $REAL{$_} for grep !$QUIET{$_}, split /,/, $STANDIN;   # -standin: stand-ins too
# The recorders, made once: one per program name found on the system's PATH.
my $REC = "$BASE/bin"; remove_tree($REC); make_path($REC);
open my $r, '>', "$BASE/rec" or die; print $r <<'SH'; close $r; chmod 0755, "$BASE/rec";
#!/bin/sh
n=${0##*/}
l=$n; for a in "$@"; do l="$l$(printf '\037')$a"; done
if [ -n "$RECPARENT" ]; then read p < /proc/$PPID/comm; l="$p$(printf '\035')$l"; fi   # -q: who called it (perl, xargs, env, ...)
printf '%s\n' "$l" >> "$RECLOG"   # one write, so that pipeline elements do not mix their lines
case " $REALNAMES " in *" $n "*) exec "$REALDIR/$n" "$@";; esac
printf '%s' "${STANDIN_OUTPUT-}"   # -env output: the stand-in's answer (else nothing)
exit "${STANDIN_STATUS:-0}"        # -env fail
SH
my %seen;
for my $d (qw(/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin)) {
  opendir my $dh, $d or next;
  for my $n (readdir $dh) { next if $n =~ /^\./ || $seen{$n}++ || !-x "$d/$n" || -d "$d/$n"; symlink "$BASE/rec", "$REC/$n" or die "$REC/$n: $!" } }
my $REALDIR = "$BASE/real"; remove_tree($REALDIR); make_path($REALDIR);   # the real programs, by absolute path
for my $n (keys %REAL) { for my $d (qw(/usr/bin /bin)) { if (-x "$d/$n") { symlink "$d/$n", "$REALDIR/$n"; last } } }
my $QDIR = "$BASE/quiet"; remove_tree($QDIR); make_path($QDIR);   # first in PATH: run under their own names, not logged
for my $n (keys %QUIET) { symlink "$REALDIR/$n", "$QDIR/$n" if -e "$REALDIR/$n" }

# The fixture: the same files in every run's directory.
my %FIXTURE = ('a.txt' => "alpha\nbeta\n", 'b.txt' => "one two\n", 'file.txt' => "hello world\n", 'c.log' => "x\n",
  '.hidden' => "h\n", 'dir/x.txt' => "in dir\n", 'dir/sub/y.sh' => "echo y\n", 'home/.profile' => '', 'empty' => '');

my %done;   # restart: samples already in a run-K.jsonl
for my $f (glob "$OUT/run-*.jsonl") { open my $in, '<', $f or die; while (<$in>) { my $r = eval { decode_json($_) } or next; $done{$r->{id}} = 1 } }   # (post-0.10: the keys are sorted, "id" is not first)
my %acc; { open my $in, '<', $ST or die "$ST: $!"; my $h = <$in>; chomp $h; my @h = split /\t/, $h; my %c; @c{@h} = 0 .. $#h;
  while (<$in>) { chomp; my @f = split /\t/, $_, -1; $acc{$f[$c{id}]} = [$f[$c{verdict}], $f[$c{features}]] if $f[$c{large}] } }
my %only = map +($_ => 1), grep length, $ONLY =~ /^\@(.*)/s ? do { open my $in, '<', $1 or die "$1: $!"; map { /^([^#\t\n][^\t\n]*)/ ? $1 : () } <$in> }
                                                         : split /,/, $ONLY;
length $ONLY && !%only and die "-only $ONLY: no snippet IDs (an empty list would mean every sample)\n";
my @todo; { open my $in, '<', $SJ or die "$SJ: $!";
  while (<$in>) { my $s = decode_json($_); next unless $acc{$s->{id}} && !$done{$s->{id}} && (!%only || $only{$s->{id}}) && (!%SETUP || $SETUP{$s->{id}});
    push @todo, $s; last if $MAX && @todo >= $MAX } }
print STDERR scalar(@todo), " samples to run, ", scalar(keys %done), " done before", (%ENV_ON ? ", -env " . join(',', sort keys %ENV_ON) : ''), "\n";
if (length $RUNLIB) { require Digest::SHA; open my $e, '>', "$OUT/run.txt" or die;
  print $e "ours through Run: PROC_SPAWNER_MISSING=\"posix_spawn fork\"; Run.pm sha256 ", Digest::SHA->new(256)->addfile("$COPY/run/Run.pm")->hexdigest, "\n"; close $e }
if (%SETUP) { open my $e, '>', "$OUT/setup.txt" or die; print $e "setups from ", abs_path($SETUPF), "\n"; close $e }
if (%ENV_ON) { open my $e, '>', "$OUT/env.txt" or die; print $e map "$_: $ENVV{$_}\n", sort keys %ENV_ON;
  my %used = (fail => 'STANDIN_STATUS', output => 'STANDIN_OUTPUT', mtime => 'FIXTURE_MTIME');
  print $e map { my $v = $used{$_}; $v ? "$v=" . JSON::PP->new->allow_nonref->encode("$STANDIN{$v}") . "\n" : () } sort keys %ENV_ON; close $e }

my %WK;   # -workers-from: sample id => its worker in that run
if (length $WFROM) { for my $f (glob "$WFROM/run-*.jsonl") { my ($k) = $f =~ /run-(\d+)\.jsonl\z/ or next;
    $k < $J or die "-workers-from $WFROM: it has run-$k.jsonl, more workers than -j $J\n";
    open my $in, '<', $f or die; while (<$in>) { my $r = eval { decode_json($_) } or next; $WK{$r->{id}} = $k } }
  %WK or die "-workers-from $WFROM: no run-K.jsonl there\n" }
my @kids;
for my $k (0 .. $J - 1) {
  my $u = "rc$k"; system("id $u >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -d /nonexistent $u") == 0 or die "useradd $u\n";
  my $pid = fork // die; if ($pid) { push @kids, $pid; next }
  worker($k, $u, [@todo[grep { defined $WK{$todo[$_]{id}} ? $WK{$todo[$_]{id}} == $k : $_ % $J == $k } 0 .. $#todo]]); exit 0 }
waitpid $_, 0 for @kids;
print STDERR "finished\n";

sub worker {
  my ($k, $u, $list) = @_; my $W = "$BASE/w$k"; my $j = JSON::PP->new->utf8->canonical; my $n = 0;
  open my $out, '>>', "$OUT/run-$k.jsonl" or die; select((select($out), $| = 1)[0]);
  for my $s (@$list) {
    my %rec = (id => $s->{id}, src => $s->{src}, text => $s->{text}, verdict => $acc{$s->{id}}[0], features => $acc{$s->{id}}[1]);
    local $CURSETUP = $SETUP{$s->{id}} && { %{$SETUP{$s->{id}}}, failed => [] }; $rec{setup} = $CURSETUP->{k} if $CURSETUP;
    for my $sh (($Q ? () : ([dash => {}, '/usr/bin/dash', '-c'], [bash => {}, '/usr/bin/bash', '--posix', '-c'])),
                [ours => (length $RUNLIB ? {PROC_SPAWNER_MISSING => 'posix_spawn fork', TRY_HIDE => 'PROC_SPAWNER_MISSING'} : {}),
                 $^X, "-I$COPY/blib/lib", "-I$COPY/blib/arch", (length $RUNLIB ? "-I$COPY/run" : ()), "$COPY/t/try.pl"]) {
      my ($name, $xenv, @cmd) = @$sh; next unless $SH{$name};
      local $ARG0 = $name eq 'ours' ? 'sh' : $cmd[0];   # -setup with arguments: $0 as each shell has it without (so its messages' prefix)
      $rec{$name} = run1($W, $u, $s->{text}, $xenv, @cmd) }
    $rec{setup_failed} = [do { my %u; grep !$u{$_}++, @{$CURSETUP->{failed}} }] if $CURSETUP && @{$CURSETUP->{failed}};
    print $out $j->encode(\%rec), "\n"; $n++ }
  close $out }

sub run1 {   # one shell, one sample, in a fresh copy of the fixture
  my ($W, $u, $text, $xenv, @cmd) = @_;   # $xenv: variables for this shell alone (-run)
  system('pkill', '-9', '-u', $u); remove_tree($W); make_path("$W/run");
  for my $f (sort keys %FIXTURE) { my ($d) = $f =~ m{^(.*)/}; make_path("$W/run/$d") if $d;
    open my $o, '>', "$W/run/$f" or die; print $o $FIXTURE{$f}; close $o }
  if ($CURSETUP) { for my $f (sort grep !m{^/}, keys %{$CURSETUP->{files} // {}}) {   # -setup: the sample's files, then (below) its variables and input
      my ($what, $text, $mode) = @{$CURSETUP->{files}{$f}}; my $p = "$W/run/$f"; remove_tree($p) if -e $p || -l $p;
      next if $what eq 'absent';
      eval { my ($d) = $p =~ m{^(.*)/}; make_path($d);   # (a setup that cannot be made, e.g. a file where it needs a directory:
        if ($what eq 'dir') { make_path($p) } else { open my $o, '>', $p or die "$p: $!\n"; print $o $text; close $o }   #  noted)
        chmod $mode, $p if defined $mode; 1 } or push @{$CURSETUP->{failed}}, "$f: $@" }
    if (defined $CURSETUP->{stdin}) { open my $o, '>', "$W/stdin" or die; print $o $CURSETUP->{stdin}; close $o } }
  system('chown', '-R', "$u:$u", $W); chmod 0755, $W;
  if ($ENV_ON{mtime}) { my $t = $STANDIN{FIXTURE_MTIME}; my @all = ("$W/run");   # after chown, which changes only ctime
    for (my $i = 0; $i < @all; $i++) { next if -l $all[$i] || !-d _; opendir my $dh, $all[$i] or die; push @all, map "$all[$i]/$_", grep !/^\.\.?\z/, readdir $dh }
    utime $t, $t, @all or die "utime: $!" }
  for my $lf ("$W/log", "$W/blog", "$W/out", "$W/err") { open my $l, '>', $lf or die; close $l; system('chown', "$u:$u", $lf) } # out, err: the run's own, so that /dev/stdout, /dev/stderr (reopened by path on Linux) are writable
  utime $STANDIN{FIXTURE_MTIME}, $STANDIN{FIXTURE_MTIME}, $W if $ENV_ON{mtime};   # also the worker's directory, the run's ".." (post-0.10: ls -la showed the day of the run)
  my %env = (($Q ? (RECPARENT => 1, RECBUILTIN => "$W/blog") : ()), PATH => $Q ? $REC : "$QDIR:$REC", HOME => "$W/run/home", LANG => 'C', LC_ALL => 'C', USER => $u, LOGNAME => $u, TERM => 'dumb',
             SHELL => '/bin/sh', RECLOG => "$W/log", REALDIR => $REALDIR, TMPDIR => "$W/run",
             REALNAMES => join(' ', sort grep { my $n = $_; !$CURSETUP || !grep $_ eq $n, @{$CURSETUP->{standin} // []} } keys %REAL),
             ($ENV_ON{posix} ? (POSIXLY_CORRECT => 1) : ()), ($ENV_ON{utf8} ? (LANG => 'C.UTF-8', LC_ALL => 'C.UTF-8') : ()),
             ($ENV_ON{fail} ? (STANDIN_STATUS => $STANDIN{STANDIN_STATUS}) : ()), ($ENV_ON{output} ? (STANDIN_OUTPUT => $STANDIN{STANDIN_OUTPUT}) : ()),
             ($CURSETUP ? %{$CURSETUP->{env} // {}} : ()), %$xenv);
  delete $env{$_} for grep !defined $env{$_}, keys %env;   # -setup: a variable given as null is unset
  my $pid = fork // die;
  unless ($pid) {
    if (%ENV_ON && !eval { environment($W, $u); 1 }) { open my $f, '>', "$W/envfail"; print $f $@; close $f; require POSIX; POSIX::_exit(125) }
    chdir "$W/run" or die; %ENV = %env;
    $SIG{PIPE} = 'IGNORE' if $ENV_ON{sigpipe};   # inherited through exec by prlimit, setpriv, timeout and the shell
    open STDIN, '<', $CURSETUP && defined $CURSETUP->{stdin} ? "$W/stdin" : '/dev/null'; open STDOUT, '>', "$W/out"; open STDERR, '>', "$W/err";
    exec '/usr/bin/prlimit', '--cpu=10', '--fsize=20000000', '--nproc=400', '--',
         '/usr/bin/setpriv', "--reuid=$u", "--regid=$u", '--clear-groups', '--inh-caps=-all', '--',
         '/usr/bin/timeout', '-k', '1', '5',
         ($ENV_ON{clock} ? ('/usr/bin/env', "LD_PRELOAD=$FAKETIME", 'FAKETIME=' . POSIX::strftime('%Y-%m-%d %H:%M:%S', gmtime $STANDIN{FIXTURE_MTIME}),
           'TZ=UTC0', 'FAKETIME_DONT_FAKE_MONOTONIC=1') : ()),   # -env clock: the shell's (timeout keeps the real one)
         @cmd, $text, ($ENV_ON{samearg0} ? ('sh', @{$CURSETUP && $CURSETUP->{args} || []})
           : $CURSETUP && $CURSETUP->{args} ? ($ARG0, @{$CURSETUP->{args}}) : ());   # -setup: $0, $1 ...
    exit 127 }
  waitpid $pid, 0;
  if (-e "$W/envfail") {   # (a setup that cannot be made there: recorded, the run goes on)
    die "-env failed in the run's child: ", slurp("$W/envfail") unless $CURSETUP; push @{$CURSETUP->{failed}}, 'env: ' . slurp("$W/envfail") }
  my $st = $? >> 8; $st = 'signal ' . ($? & 127) if $? & 127;
  my $after;   # -after: the run's processes still there when the shell ended get up to $AFTER seconds (A18)
  if ($ENV_ON{pidns}) { $after = 'killed' if unlink "$W/killed" }   # (process 1 of the namespace waited, and says so)
  elsif ($AFTER > 0) { require Time::HiRes; my $end = Time::HiRes::time() + $AFTER;
    while (system("pgrep -u $u > /dev/null") == 0) { if (Time::HiRes::time() >= $end) { $after = 'killed'; last } Time::HiRes::sleep(0.05) } }
  system('pkill', '-9', '-u', $u);
  my %r = (status => $st, out => slurp("$W/out"), err => slurp("$W/err"), rec => slurp("$W/log"), $Q ? (builtins => slurp("$W/blog")) : (),
           $after ? (after => $after) : ());
  my (@files, @nomsg); my $walk; $walk = sub { my ($d, $p) = @_; opendir my $dh, $d or return;
    for my $n (sort grep !/^\.\.?\z/, readdir $dh) { my $f = "$d/$n";
      if (-l $f) { push @files, "$p$n -> " . readlink $f; push @nomsg, $files[-1] }
      elsif (-d $f) { push @files, "$p$n/"; push @nomsg, $files[-1]; $walk->($f, "$p$n/") }
      else { push @files, "$p$n " . (-s $f // '?') . ' ' . substr(Digest_sha($f), 0, 12);
        push @nomsg, "$p$n " . substr(Digest_sha_nomsg($f), 0, 12) } } };   # post-0.11: also without the shells' messages
  $walk->("$W/run", ''); $r{files} = join "\n", @files; $r{files_nomsg} = join "\n", @nomsg;
  \%r }

sub environment {   # -env, in the run's child, as root: a mount namespace of its own, then the variants' mounts
  my ($W, $u) = @_;
  my @m = grep $ENV_ON{$_}, qw(cowroot private dev tmp random noproc pidns); @m or return;
  syscall(272, 0x00020000) == 0 or die "unshare(CLONE_NEWNS): $!\n";   # x86_64 Linux: SYS_unshare, CLONE_NEWNS
  my $mt = sub { system('mount', @_) == 0 or die "mount @_: failed\n" };
  $mt->('--make-rprivate', '/');
  if ($ENV_ON{cowroot}) {   # first: the other variants mount inside the new root
    my $c = "$W.cow"; make_path($c); $mt->('-t', 'tmpfs', '-o', 'mode=0755', 'none', $c); make_path("$c/u", "$c/w", "$c/r");
    $mt->('-t', 'overlay', '-o', "lowerdir=/,upperdir=$c/u,workdir=$c/w", 'overlay', "$c/r");
    $mt->('--rbind', '/dev', "$c/r/dev"); $mt->('-t', 'proc', 'proc', "$c/r/proc"); $mt->('--rbind', '/sys', "$c/r/sys");
    $mt->('--bind', $W, "$c/r$W");   # the run's directory, its logs: the real ones
    chroot("$c/r") or die "chroot: $!\n"; chdir '/' or die }
  elsif ($CURSETUP && grep m{^/}, keys %{$CURSETUP->{files} // {}}) { die "a setup with absolute names needs -env cowroot\n" }
  my $empty = sub { make_path($_[0]); $mt->('-t', 'tmpfs', '-o', "mode=$_[1]", 'none', $_[0]) };   # make_path: /var/tmp under private's /var
  if ($ENV_ON{private}) { for (qw(/home /root /mnt /media /srv /var)) { $empty->($_, '0755') if -d $_ } }
  if ($ENV_ON{dev}) {
    my $keep = "$BASE/devkeep$$"; make_path($keep); $mt->('--rbind', '/dev', $keep);
    $empty->('/dev', '0755');
    for my $n (qw(null zero full tty random urandom ptmx)) { open my $t, '>', "/dev/$n" or die; close $t; $mt->('--bind', "$keep/$n", "/dev/$n") }
    for my $d (qw(pts shm)) { make_path("/dev/$d") } chmod 01777, '/dev/shm'; $mt->('--rbind', "$keep/pts", '/dev/pts');
    symlink '/proc/self/fd', '/dev/fd'; symlink "/proc/self/fd/$_->[1]", "/dev/$_->[0]" for [stdin => 0], [stdout => 1], [stderr => 2];
    $mt->('--make-rprivate', $keep); system('umount', '-l', $keep); rmdir $keep }
  if ($ENV_ON{tmp}) { $empty->($_, '1777') for qw(/tmp /var/tmp /dev/shm) }
  if ($ENV_ON{random}) { $mt->('--bind', $RANDOM, $_) for qw(/dev/urandom /dev/random) }
  if ($ENV_ON{noproc}) { $empty->('/proc', '0555') }
  if ($ENV_ON{cowroot}) {   # last: a setup's absolute names, in the new root and its fresh /tmp
    for my $f (sort grep m{^/}, keys %{$CURSETUP ? $CURSETUP->{files} // {} : {}}) {   # -setup: its absolute names
      my ($what, $text, $mode) = @{$CURSETUP->{files}{$f}}; remove_tree($f) if -e $f || -l $f; next if $what eq 'absent';
      my ($d) = $f =~ m{^(.*)/}; make_path($d) if length $d;
      if ($what eq 'dir') { make_path($f) } else { open my $o, '>', $f or die "$f: $!\n"; print $o $text; close $o }
      my (undef, undef, $uid, $gid) = getpwnam $u; chown $uid, $gid, $f; chmod $mode, $f if defined $mode } }
  if ($ENV_ON{pidns}) {   # last: a PID namespace; this process waits for its first process and ends as it ended
    syscall(272, 0x20000000) == 0 or die "unshare(CLONE_NEWPID): $!\n";   # CLONE_NEWPID: the next child is its process 1
    my $p = fork // die "fork: $!\n";
    if ($p) { waitpid $p, 0; my $st = $?; require POSIX;
      if (open my $f, '<', "$W/pid1-status") { $st = 0 + (<$f> // 0); close $f; unlink "$W/pid1-status" }   # the shell's, from process 1
      if (my $sig = $st & 127) { $SIG{$_} = 'DEFAULT' for keys %SIG; kill $sig, $$; sleep 1 } POSIX::_exit($st >> 8) }
    $mt->('-t', 'proc', 'proc', '/proc');   # its own /proc
    # process 1 (post-0.11, -after): the run goes on in its child; this one reaps every process of the namespace (orphans
    # come to it), and when the run's own process has ended, waits up to $AFTER seconds for the rest, then kills them
    my $c = fork // die "fork: $!\n"; return unless $c;
    require POSIX; require Time::HiRes; my ($cst, $end) = (0, undef);
    while (1) { my $w = waitpid(-1, defined $end ? POSIX::WNOHANG() : 0);
      if ($w == $c) { $cst = $?; $end = Time::HiRes::time() + $AFTER; next }
      last if $w < 0;   # no process left
      next if $w > 0;
      if (Time::HiRes::time() >= $end) { kill 'KILL', -1; open my $k, ">", "$W/killed"; close $k; $end = 9e99 }
      else { Time::HiRes::sleep(0.05) } }
    open my $f, '>', "$W/pid1-status" or POSIX::_exit(126); print $f $cst; close $f; POSIX::_exit(0) } }

sub slurp { my $f = shift; open my $i, '<:raw', $f or return ''; local $/; my $t = <$i> // ''; length $t > $LIMIT ? substr($t, 0, $LIMIT) . "\n[...cut]" : $t }
# A shell's message line (post-0.11): a line starting with dash's, bash's or our prefix, whichever shell wrote it (the
# same pattern for all three, so equal texts stay equal).  large-subset-matchreport.pl drops such lines from standard
# output and compares files by files_nomsg: messages count nowhere, wherever a redirection sends them.
sub Digest_sha_nomsg { require Digest::SHA; open my $i, '<:raw', shift or return '?'; local $/; my $t = <$i> // '';
  $t =~ s/^(?:(?:\S*\/)?dash: \d+: |(?:\S*\/)?bash: (?:line \d+: )?|sh: ).*(?:\n|\z)//mg; Digest::SHA::sha256_hex($t) }
sub Digest_sha { require Digest::SHA; my $d = Digest::SHA->new(256); open my $i, '<:raw', shift or return '?'; $d->addfile($i); $d->hexdigest }
