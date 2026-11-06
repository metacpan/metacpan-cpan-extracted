#!/usr/bin/perl
# large-subset-runcompare.pl (post4-0.04, 2026-11-05): run every corpus sample the large parser accepts in dash,
# bash --posix and Proc::ShellSpawn, and record what each did, for large-subset-runreport.pl to compare.
#
# Usage (as root, from the distribution's directory, after make):
#   perl doc/large-subset/tools/large-subset-runcompare.pl [-j 4] [-n MAX] [-only ID,...] samples.jsonl samples.tsv OUTDIR
# samples.tsv is large-subset-yardsticks.pl -o's output (its column 'large' says which samples the parser accepts).
# OUTDIR gets run-K.jsonl per worker (one line per sample); a rerun skips the samples already there, so it can be
# stopped and started again.
#
# Isolation (no sample can harm the machine or another sample):
# - each worker K runs as its own unprivileged user rcK (made if missing), with no network (unshare -n), CPU,
#   file-size and process limits (prlimit), a 5-second timeout, and every process of rcK killed after each run;
# - each run starts in a fresh copy of the same small directory (FIXTURE below), with HOME inside it;
# - PATH is the programs of %QUIET (run, not logged), then one directory of recorders: one for every program name on the system's PATH.  A recorder appends
#   its name and arguments to the run's log; for the names in %REAL (the programs we run in place of builtins,
#   and tools that only read or print) it then runs the real program, otherwise it exits 0 with no output.
# So the three shells see the same files, the same environment and the same "programs", and only the shells differ.
use strict; use warnings; use JSON::PP; use File::Path qw(make_path remove_tree); use Cwd 'abs_path'; use Getopt::Long;
my ($J, $MAX, $ONLY, $Q) = (4, 0, '', 0);   # -q: run ours only, and log the programs of %QUIET too, each line headed by its caller's name and \035 (for large-subset-threeway.pl),
#     and every builtin call (t/try.pl, RECBUILTIN; for large-subset-builtins.pl)
GetOptions('j=i' => \$J, 'n=i' => \$MAX, 'only=s' => \$ONLY, 'q' => \$Q) && @ARGV == 3 or die "usage: $0 [-j N] [-n MAX] [-only IDS] [-q] samples.jsonl samples.tsv OUTDIR\n";
my ($SJ, $ST, $OUT) = @ARGV; make_path($OUT); $OUT = abs_path($OUT);
$> == 0 or die "run as root (it makes the users rcK and drops to them)\n";
my $DIST = abs_path('.'); -e "$DIST/blib/arch/auto/Proc/Spawner/Spawner.so" or die "run make first\n";
my $BASE = '/var/tmp/runcompare'; make_path($BASE); chmod 0755, $BASE;
my $LIMIT = 4000;   # characters of each output kept

# %QUIET: the programs Proc::ShellSpawn runs in place of the shells' builtins (R-program): run, not logged, since the
# shells' builtins leave no log either.  %REAL: logged, then run (they only read, print or make files; rm, mv, cp,
# ln are only logged, to keep a sample from removing what it did not make).
my %QUIET = map +($_ => 1), qw(echo printf test [ true false pwd kill);
my %REAL = (%QUIET, map +($_ => 1), qw(cat grep egrep fgrep sed awk sort head tail wc tr cut uniq seq expr basename
  dirname printenv env xargs tee ls mkdir touch cmp diff od rev nl paste join fold comm tac realpath readlink stat
  sha256sum md5sum base64 yes));
# The recorders, made once: one per program name found on the system's PATH.
my $REC = "$BASE/bin"; remove_tree($REC); make_path($REC);
open my $r, '>', "$BASE/rec" or die; print $r <<'SH'; close $r; chmod 0755, "$BASE/rec";
#!/bin/sh
n=${0##*/}
l=$n; for a in "$@"; do l="$l$(printf '\037')$a"; done
if [ -n "$RECPARENT" ]; then read p < /proc/$PPID/comm; l="$p$(printf '\035')$l"; fi   # -q: who called it (perl, xargs, env, ...)
printf '%s\n' "$l" >> "$RECLOG"   # one write, so that pipeline elements do not mix their lines
case " $REALNAMES " in *" $n "*) exec "$REALDIR/$n" "$@";; esac
exit 0
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
for my $f (glob "$OUT/run-*.jsonl") { open my $in, '<', $f or die; while (<$in>) { $done{$1} = 1 if /^\{"id":"((?:[^"\\]|\\.)*)"/ } }
my %acc; { open my $in, '<', $ST or die "$ST: $!"; my $h = <$in>; chomp $h; my @h = split /\t/, $h; my %c; @c{@h} = 0 .. $#h;
  while (<$in>) { chomp; my @f = split /\t/, $_, -1; $acc{$f[$c{id}]} = [$f[$c{verdict}], $f[$c{features}]] if $f[$c{large}] } }
my %only = map +($_ => 1), grep length, split /,/, $ONLY;
my @todo; { open my $in, '<', $SJ or die "$SJ: $!";
  while (<$in>) { my $s = decode_json($_); next unless $acc{$s->{id}} && !$done{$s->{id}} && (!%only || $only{$s->{id}});
    push @todo, $s; last if $MAX && @todo >= $MAX } }
print STDERR scalar(@todo), " samples to run, ", scalar(keys %done), " done before\n";

my @kids;
for my $k (0 .. $J - 1) {
  my $u = "rc$k"; system("id $u >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -d /nonexistent $u") == 0 or die "useradd $u\n";
  my $pid = fork // die; if ($pid) { push @kids, $pid; next }
  worker($k, $u, [@todo[grep $_ % $J == $k, 0 .. $#todo]]); exit 0 }
waitpid $_, 0 for @kids;
print STDERR "finished\n";

sub worker {
  my ($k, $u, $list) = @_; my $W = "$BASE/w$k"; my $j = JSON::PP->new->utf8->canonical; my $n = 0;
  open my $out, '>>', "$OUT/run-$k.jsonl" or die; select((select($out), $| = 1)[0]);
  for my $s (@$list) {
    my %rec = (id => $s->{id}, src => $s->{src}, text => $s->{text}, verdict => $acc{$s->{id}}[0], features => $acc{$s->{id}}[1]);
    for my $sh (($Q ? () : ([dash => '/usr/bin/dash', '-c'], [bash => '/usr/bin/bash', '--posix', '-c'])),
                [ours => $^X, "-I$DIST/blib/lib", "-I$DIST/blib/arch", "$DIST/t/try.pl"]) {
      my ($name, @cmd) = @$sh; $rec{$name} = run1($W, $u, $s->{text}, @cmd) }
    print $out $j->encode(\%rec), "\n"; $n++ }
  close $out }

sub run1 {   # one shell, one sample, in a fresh copy of the fixture
  my ($W, $u, $text, @cmd) = @_;
  system('pkill', '-9', '-u', $u); remove_tree($W); make_path("$W/run");
  for my $f (sort keys %FIXTURE) { my ($d) = $f =~ m{^(.*)/}; make_path("$W/run/$d") if $d;
    open my $o, '>', "$W/run/$f" or die; print $o $FIXTURE{$f}; close $o }
  system('chown', '-R', "$u:$u", $W); chmod 0755, $W;
  for my $lf ("$W/log", "$W/blog") { open my $l, '>', $lf or die; close $l; system('chown', "$u:$u", $lf) }
  my %env = (($Q ? (RECPARENT => 1, RECBUILTIN => "$W/blog") : ()), PATH => $Q ? $REC : "$QDIR:$REC", HOME => "$W/run/home", LANG => 'C', LC_ALL => 'C', USER => $u, LOGNAME => $u, TERM => 'dumb',
             SHELL => '/bin/sh', RECLOG => "$W/log", REALDIR => $REALDIR, REALNAMES => join(' ', sort keys %REAL), TMPDIR => "$W/run");
  my $pid = fork // die;
  unless ($pid) {
    chdir "$W/run" or die; %ENV = %env;
    open STDIN, '<', '/dev/null'; open STDOUT, '>', "$W/out"; open STDERR, '>', "$W/err";
    exec '/usr/bin/prlimit', '--cpu=10', '--fsize=20000000', '--nproc=400', '--',
         '/usr/bin/setpriv', "--reuid=$u", "--regid=$u", '--clear-groups', '--inh-caps=-all', '--',
         '/usr/bin/timeout', '-k', '1', '5', @cmd, $text;
    exit 127 }
  waitpid $pid, 0; my $st = $? >> 8; $st = 'signal ' . ($? & 127) if $? & 127;
  system('pkill', '-9', '-u', $u);
  my %r = (status => $st, out => slurp("$W/out"), err => slurp("$W/err"), rec => slurp("$W/log"), $Q ? (builtins => slurp("$W/blog")) : ());
  my @files; my $walk; $walk = sub { my ($d, $p) = @_; opendir my $dh, $d or return;
    for my $n (sort grep !/^\.\.?\z/, readdir $dh) { my $f = "$d/$n";
      if (-l $f) { push @files, "$p$n -> " . readlink $f }
      elsif (-d $f) { push @files, "$p$n/"; $walk->($f, "$p$n/") }
      else { push @files, "$p$n " . (-s $f // '?') . ' ' . substr(Digest_sha($f), 0, 12) } } };
  $walk->("$W/run", ''); $r{files} = join "\n", @files;
  \%r }

sub slurp { my $f = shift; open my $i, '<:raw', $f or return ''; local $/; my $t = <$i> // ''; length $t > $LIMIT ? substr($t, 0, $LIMIT) . "\n[...cut]" : $t }
sub Digest_sha { require Digest::SHA; my $d = Digest::SHA->new(256); open my $i, '<:raw', shift or return '?'; $d->addfile($i); $d->hexdigest }
