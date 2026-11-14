#!/usr/bin/perl
# large-subset-difffuzz.pl (2026-11-01, the large-subset session of the old Project; ported post-0.11, 2026-11-11):
# differential fuzzing.  Random strings made of up to 5 pieces of the large subset (below; joined by ; && || newline |)
# that the large parser accepts are run by dash, by bash --posix and by ours (t/try.pl), each in an empty directory of
# its own; compared as section 11 of large-subset-environment.md compares: status, standard output with the shells'
# message lines dropped, and the files left (names and contents); messages count nowhere.  The classes: same; OURS (dash
# and bash agree, ours differs: the work list); =dash, =bash, neither (dash and bash differ); timeout.  It found the
# executor's bugs L1-L10 in 2026-11 (doc/pspawn-known-issues.md).
# Usage (from the distribution's directory, after make; also: make probe-fuzz [FUZZ="-n 300 -seed 1 -j 4"]):
#   perl doc/large-subset/tools/large-subset-difffuzz.pl [-n COUNT] [-seed N] [-all] [-j WORKERS] [-time SECONDS]
# Prints every string not in class same (with -all, every string), with what each shell did, then the counts.  The
# same seed gives the same strings with the same perl, whatever -j: each of the WORKERS processes makes the whole
# sequence and runs every WORKERS-th string, in a directory of its own; the results are printed in the sequence's order.
# -n 0: no limit; -time: no string started after SECONDS (the strings after the first one not run are dropped); a
# progress line every 1,000 strings on standard error.  Each run has 10 seconds; each shell runs in run/work of its
# worker's directory, and the files compared are those of run/ (a piece does cd ..).  Run it as a user that may lose
# its own processes: some pieces send signals to the shell itself.
use strict; use warnings; use Getopt::Long; use Cwd 'abs_path'; use File::Temp 'tempdir'; use Digest::SHA 'sha256_hex';
use lib 'lib'; use Proc::ShellSubset::Large;
my ($N, $SEED, $ALL, $J, $TIME) = (300, 1, 0, 1, 0);
GetOptions('n=i' => \$N, 'seed=i' => \$SEED, 'all' => \$ALL, 'j=i' => \$J, 'time=i' => \$TIME) && !@ARGV && $J >= 1
  or die "usage: $0 [-n COUNT] [-seed N] [-all] [-j WORKERS] [-time SECONDS]\n";
my $END = $TIME ? time + $TIME : 0;
-e 't/try.pl' && -d 'blib' or die "run from the distribution's directory, after make\n";
srand $SEED;
my $TRY = abs_path('t/try.pl'); my $TOP = abs_path('.');
my @S = (   # snippets: each a complete command, or a fragment marked by its use below
  'echo a', 'echo "$x"', 'x=1', 'x="a  b"', 'y=$x', 'echo $x', 'echo ${x:-d}', 'echo ${x#?}', 'echo ${x%b}', 'echo ${#x}',
  'echo ${u:=w} $u', 'unset x', 'export x', 'export z=$x', 'readonly r=1', 'r=2', 'set -- p "q r" s', 'shift',
  'shift 2', 'echo $# "$1" "$*"', 'for i in "$@"; do echo "<$i>"; done', 'f() { echo "f:$#:$1"; return 3; }',
  'f a b', 'echo $?', 'g() { local x=in; echo "g:$x"; }', 'g; echo "x=$x"', 'h() ( x=sub; echo $x )', 'h',
  'set -e', 'set +e', 'set -u', 'set +u', 'false', 'true', 'echo $((n=n+1)) $n', 'eval "echo ev \$x"',
  'trap "echo T" EXIT', 'trap - EXIT', 'cat <<E@Nhd $x@NE', "cat <<'E'\@Nlit \$x\@NE", 'cat <<-E@N@Tt@N@TE',
  'umask 077; umask', 'command -v echo', 'command -v nosuch', 'getopts ab: o -b v; echo $o $OPTARG $OPTIND',
  'c=echo; $c dyn', 'echo a | cat', '{ echo grp; } >f; cat f', 'exec 3>g; echo e3 >&3; cat g', '(exit 4); echo $?',
  'case $x in a*) echo A;; *) echo O;; esac', 'while [ ${n:-0} -lt 3 ]; do n=$((n+1)); done; echo $n',
  'echo "${x:-"q  w"}"', 'echo ${x:+"$x"}', 'printf "%s|" $x; echo', 'IFS=:; v=a:b; set -- $v; echo $#; IFS=" "',
  'f() { echo "${1:?missing}"; }; f', 'kill -TERM $$; echo after', 'trap "echo caught" USR1; kill -USR1 $$; echo after',
  'wait', 'sleep 0 & wait $!; echo $?', 'echo $$ >/dev/null', 'k() { echo k; }; k | cat', 'exit 5', 'return',
  ': ${q=7}; echo $q', 'IFS=": "; x="a: b::c"; set -- $x; echo $#', 'IFS=:; x=":a:"; set -- $x; echo $#', 'unset IFS',
  'set -u; echo ${zz%a}', 'set -u; echo ${zz-d} ${zz:+e}', '{ trap "echo T" EXIT; true; } &', '(trap "echo P" EXIT; true) | cat',
  'for a; do echo "[$a]"; done', 'f() { for a do echo "[$a]"; done; }; f x "y z"', 'm() { cat <<E@Nm:$1@NE@N}; m arg',
  'n() { m2() { echo inner; }; m2; }; n; m2', 'eval "e() { echo ev:\$1; }"; e q', 'while getopts ab: o -a -b v; do echo $o; done',
  '(readonly ro=1); ro=2; echo $ro', 'exec 4>h; echo four >&4; exec 4>&-; cat h', 'x=out; s() { local x=in; t; }; t() { echo $x; }; s; t',
  'p() { echo "$#"; }; p "$@"; set -- 1 2; p "$@" x', 'command f 2>/dev/null; echo $?', 'unset -f f; f', 'q() { while :; do return 4; done; }; q; echo $?',
  'r() { for i in 1 2; do break; done; echo r; }; r', 'echo ${zz:=}; echo "[$zz]"', 'set -a; ex=1; sh -c "echo \$ex"; set +a',
  'trap "echo int" INT; kill -INT $$', 'x=$(f() { echo sub; }; f); echo $x', 'echo "$(echo "$@")"', 'set -- a; echo "${1+"$@"}"', 'echo ${x##*a}', 'cd ..; cd -', 'set -f; echo *; set +f', 'set -C; echo 1 >f; echo $?',
);
my @J = ('; ', ' && ', ' || ', "\n", ' | ');
my %SH = (dash => ['dash', '-c'], bash => ['bash', '--posix', '-c'], ours => [$^X, "-I$TOP/blib/lib", "-I$TOP/blib/arch", $TRY]);
my $MSG = qr/^(?:(?:\S*\/)?dash: \d+: |(?:\S*\/)?bash: (?:line \d+: )?|sh: ).*(?:\n|\z)/m;   # as large-subset-matchreport.pl
my $top = tempdir('difffuzz.XXXXXX', TMPDIR => 1, CLEANUP => 1); my $base;   # $base: the worker's directory
sub files { my ($d, $p) = @_; opendir my $h, $d or return (); my @r;
  for my $n (sort grep !/^\.\.?\z/, readdir $h) { my $f = "$d/$n";
    if (-l $f) { push @r, "$p$n -> " . readlink $f } elsif (-d $f) { push @r, "$p$n/", files($f, "$p$n/") }
    else { open my $i, '<:raw', $f; local $/; my $t = <$i> // ''; $t =~ s/$MSG//g; $t =~ s{\Q$base\E/run}{RUN}g; push @r, "$p$n " . substr(sha256_hex($t), 0, 12) } }
  @r }
sub run1 { my ($sh, $s) = @_; my $d = "$base/run"; system('rm', '-rf', $d); mkdir $d and mkdir "$d/work" or die "$d: $!";
  my $pid = fork // die; unless ($pid) { chdir "$d/work"; $ENV{HOME} = "$d/work"; open STDIN, '<', '/dev/null';
    open STDOUT, '>', "$base/$sh.out"; open STDERR, '>', "$base/$sh.err"; exec 'timeout', '-k', '1', '10', @{$SH{$sh}}, $s; exit 127 }
  waitpid $pid, 0; my $st = $? >> 8; $st = 'signal ' . ($? & 127) if $? & 127;
  open my $o, '<:raw', "$base/$sh.out"; local $/; my $out = <$o> // ''; $out =~ s/$MSG//g; $out =~ s/\b$pid\b/PID/g; $out =~ s{\Q$base\E/run}{RUN}g;
  return +{ status => $st, out => $out, files => join("\n", files($d, '')), timeout => ($st =~ /^(?:124|137)\z/ ? 1 : 0) } }
my $eq = sub { my ($x, $y) = @_; $x->{status} eq $y->{status} && $x->{out} eq $y->{out} && $x->{files} eq $y->{files} };
sub one {   # the string's class and report (empty when not shown); undef when the parser rejects it
  my ($s) = @_; return undef unless ref Proc::ShellSubset::Large::parse($s) eq 'ARRAY';
  my %r = map +($_ => run1($_, $s)), qw(dash bash ours);
  my $c = grep($_->{timeout}, values %r) ? 'timeout' : $eq->($r{dash}, $r{bash}) ? ($eq->($r{dash}, $r{ours}) ? 'same' : 'OURS')
    : $eq->($r{ours}, $r{dash}) ? '=dash' : $eq->($r{ours}, $r{bash}) ? '=bash' : 'neither';
  return [$c, ''] if $c eq 'same' && !$ALL;
  (my $show = $s) =~ s/\n/\\n/g; $show =~ s/\t/\\t/g;
  [$c, join '', "$c: $show\n", map { my $x = $r{$_}; sprintf "  %-4s %s |%s| %s\n", $_, $x->{status}, $x->{out} =~ s/\n/\\n/gr,
    $x->{files} eq $r{dash}{files} ? '' : 'files: ' . ($x->{files} =~ s/\n/; /gr) } qw(dash bash ours)] }
sub string { my $s = join '', map { ($_ ? $J[rand @J] : '') . $S[rand @S] } 0 .. int rand 5; $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s }
my @W;   # per worker: the pipe its records come through, one line each: "-" (rejected), "." (the time is up), or class
for my $w (0 .. $J - 1) {   # and the length of the report that follows
  pipe(my $r, my $wr) or die "pipe: $!"; my $pid = fork // die "fork: $!";
  if (!$pid) { close $r; $base = "$top/w$w"; mkdir $base or die; select $wr; $| = 1;
    for (my $i = 0; !$N || $i < $N; $i++) { my $s = string(); next if $i % $J != $w;
      if ($END && time >= $END) { print ".\n"; last }
      my $x = one($s); print $x ? "$x->[0] " . length($x->[1]) . "\n$x->[1]" : "-\n" }
    close $wr; exit 0 }
  close $wr; push @W, [$r, $pid] }
$SIG{INT} = $SIG{TERM} = sub { kill 'TERM', map $_->[1], @W; exit 1 };
my (%n, $tried, $acc);
for (my $i = 0; !$N || $i < $N; $i++) {
  my $h = $W[$i % $J][0]; my $l = <$h>; last if !defined $l || $l eq ".\n";
  $tried++; print STDERR "seed $SEED: $tried strings, ", time - $^T, " s\n" if $tried % 1000 == 0;
  next if $l eq "-\n"; $acc++;
  my ($c, $len) = split ' ', $l; $n{$c}++; next unless $len;
  read($h, my $t, $len); print $t }
kill 'TERM', map $_->[1], @W; waitpid $_->[1], 0 for @W;
print "seed $SEED: tried $tried, accepted $acc: ", join(', ', map "$_ " . ($n{$_} // 0), qw(same OURS =dash =bash neither timeout)), "\n";
