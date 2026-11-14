#!/usr/bin/perl
# large-subset-threeway.pl (post4-0.04, 2026-11-05): for the commands the subset runs as programs in place of the
# shells' builtins (echo, printf, test, [, kill, pwd), the answers of all three: dash's builtin, bash's builtin
# (--posix) and the program alone, for every argument list that the corpus samples really give them.
#
# Usage (as root, with no network):
#   unshare -n perl large-subset-runcompare.pl -q samples.jsonl samples.tsv QDIR     # ours only, these programs logged
#   unshare -n perl large-subset-threeway.pl [-l LIST.tsv] [-db DB.jsonl] QDIR...
# Several QDIRs (post-0.11): logging runs of several environments (large-subset-environment.md, section 11); a sample
# counts once for each distinct call, however many of the runs make it.  The calls are those ours ran as programs
# (kill) and, since 0.10 (IP1), inside Perl (echo, printf, test, [, pwd: logged as builtin calls of the handler
# Proc::ShellSpawn::inproc).  -ours DIR (post-0.11): a fourth answer, ours alone (DIR holds blib/ and t/try.pl, as
# large-subset-runcompare.pl's BASE/dist: it is copied, world-readable), the call's words single-quoted.
# Calls made by another program (xargs printf ..., env echo ...) are left out: there every shell runs the program.
# Each distinct call (name and arguments, as logged) is run three ways, as the user rc9, in an empty directory,
# stdin /dev/null, 5 seconds at most: dash -c '"$@"' sh NAME ARGS..., the same with bash --posix, and the program
# itself (argv[0] = NAME).  Compared: status, standard output; and the messages, with the shells' prefix ("sh: 1: ",
# "sh: line 1: ") and the program's path taken off.  -db keeps every call with its three answers (the "database");
# -l lists the calls where the three do not agree.  The table counts calls and corpus samples (a sample may make
# several calls).
use strict; use warnings; use JSON::PP; use File::Path qw(make_path remove_tree); use Getopt::Long;
sub records {   # (post-0.11) a log's records: one per line, but an argument or a variable may hold a newline; a record
  my ($t, $start) = @_; my @r;   # starts as $start says, a line that does not continues the record before it
  for (split /\n/, $t // '') { if (/$start/ || !@r) { push @r, $_ } else { $r[-1] .= "\n$_" } } @r }
my ($LIST, $DB, $OURS); GetOptions('l=s' => \$LIST, 'db=s' => \$DB, 'ours=s' => \$OURS) && @ARGV >= 1 or die "usage: $0 [-l LIST.tsv] [-db DB.jsonl] [-ours DIST] QDIR...\n";
$> == 0 or die "run as root\n";
my %TOOL = map +($_ => 1), qw(echo printf test [ kill pwd);
my %PROG = (map(+($_ => "/usr/bin/$_"), keys %TOOL));

my (%calls, %samples, %byprog, %seen);   # "NAME\037ARG..." => number of samples; and the samples of each
for my $f (map glob("$_/run-*.jsonl"), @ARGV) { open my $in, '<', $f or die;
  while (<$in>) { my $s = eval { decode_json($_) } or next;
    for my $l (records($s->{ours}{rec}, qr/^[^\035\037]*\035/)) {
      my $who = $l =~ s/^([^\035\037]*)\035// ? $1 : 'perl';   # the caller: perl (our shell) or a program (xargs, env, ...)
      my ($n) = split /\037/, $l; next unless defined $n && $TOOL{$n};
      if ($who !~ /^perl/) { $byprog{$who}++; next }               # a program calls it so in every shell: no builtin involved
      next if $seen{$s->{id}}{$l}++;                               # a sample counts once per call, over all QDIRs
      $calls{$l}++; push @{$samples{$l}}, $s->{id} if @{$samples{$l} // []} < 3 }
    for my $b (records($s->{ours}{builtins}, qr/^[^\035\036\037]*\035/)) {   # inside Perl (IP1): HANDLER \035 ENV \035 ARGV joined by \037; a record starts with any handler's name (2026-11-13: not only Proc::ShellSpawn::WORD, which glued the next Large::b_... or "not found" record to an inproc call)
      my ($h, undef, $l) = split /\035/, $b, 3; next unless $h eq 'Proc::ShellSpawn::inproc' && defined $l;
      my ($n) = split /\037/, $l; next unless defined $n && $TOOL{$n};
      next if $seen{$s->{id}}{$l}++;
      $calls{$l}++; push @{$samples{$l}}, $s->{id} if @{$samples{$l} // []} < 3 } } }
print STDERR scalar(keys %calls), " distinct calls by our shell; left out, made by other programs: ", join(', ', map "$_ $byprog{$_}", sort keys %byprog) || 'none', "\n";

my $u = 'rc9'; my $W = '/var/tmp/runcompare/three';   # a user of its own: it may run beside large-subset-runcompare.pl
system("id $u >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -d /nonexistent $u") == 0 or die "useradd $u\n";
sub run1 { my @cmd = @_;
  system('pkill', '-9', '-u', $u); remove_tree($W); make_path("$W/run"); system('chown', '-R', "$u:$u", $W);
  my $pid = fork // die;
  unless ($pid) { chdir "$W/run"; %ENV = (PATH => '/usr/bin:/bin', LANG => 'C', LC_ALL => 'C', HOME => "$W/run");
    open STDIN, '<', '/dev/null'; open STDOUT, '>', "$W/out"; open STDERR, '>', "$W/err";
    exec '/usr/bin/setpriv', "--reuid=$u", "--regid=$u", '--clear-groups', '--inh-caps=-all', '--', '/usr/bin/timeout', '-k', '1', '5', @cmd; exit 127 }
  waitpid $pid, 0; my $st = $? >> 8; system('pkill', '-9', '-u', $u);
  my %r = (status => $st); for my $p (qw(out err)) { open my $i, '<:raw', "$W/$p"; local $/; $r{$p} = <$i> // '' }
  \%r }
my $OD = "$W-dist";   # -ours: a world-readable copy of ours
if ($OURS) { remove_tree($OD); make_path("$OD/t"); system('cp', '-a', "$OURS/blib", "$OD/") == 0 && system('cp', "$OURS/t/try.pl", "$OD/t/") == 0
    or die "-ours $OURS: cannot copy blib/ and t/try.pl\n"; system('chmod', '-R', 'a+rX', $OD) }
sub sq { my $x = shift; $x =~ s/'/'\\''/g; "'$x'" }
sub norm { my ($e, $n) = @_; $e =~ s/^sh: (?:line \d+: |\d+: )?//mg; $e =~ s/^\S*\/\Q$n\E: /$n: /mg; $e }

my (%cls, %tool, @list, %ocl, @olist); my $j = JSON::PP->new->utf8->canonical; my $db;
open $db, '>', $DB or die "$DB: $!" if $DB;
for my $l (sort keys %calls) {
  my ($n, @a) = split /\037/, $l, -1;
  my $d = run1('/usr/bin/dash', '-c', '"$@"', 'sh', $n, @a);
  my $b = run1('/usr/bin/bash', '--posix', '-c', '"$@"', 'sh', $n, @a);
  my $p = run1('/usr/bin/perl', '-e', 'exec { $ARGV[0] } @ARGV[1 .. $#ARGV] or exit 127', $PROG{$n}, $n, @a);   # argv[0] = NAME
  my $o = $OURS && run1('/usr/bin/perl', "-I$OD/blib/lib", "-I$OD/blib/arch", "$OD/t/try.pl", join ' ', map sq($_), $n, @a);
  $_->{err} = norm($_->{err}, $n) for grep $_, $d, $b, $p, $o;
  my $eq = sub { my ($x, $y) = @_; $x->{status} eq $y->{status} && $x->{out} eq $y->{out} };
  my ($db_, $dp, $bp) = ($eq->($d, $b), $eq->($d, $p), $eq->($b, $p));
  my $c = $db_ && $dp ? (($d->{err} eq $b->{err} && $d->{err} eq $p->{err}) ? 'same' : 'messages only')
        : $db_ ? 'dash=bash, program differs' : $dp ? 'dash=program, bash differs' : $bp ? 'bash=program, dash differs' : 'all three differ';
  $cls{$c}{calls}++; $cls{$c}{samples} += $calls{$l}; $tool{$n}{$c} += $calls{$l};
  if ($o) { my $op = $eq->($o, $p) ? 'ours=program' : 'ours differs from the program'; $ocl{$op}{calls}++; $ocl{$op}{samples} += $calls{$l};
    push @olist, join "\t", $calls{$l}, join(' ', $n, @a) =~ s/\n/\\n/gr, "$o->{status} $o->{out}" =~ s/\n/\\n/gr, "$p->{status} $p->{out}" =~ s/\n/\\n/gr if $op ne 'ours=program' }
  print $db $j->encode({ call => [$n, @a], samples => $calls{$l}, examples => $samples{$l}, class => $c, dash => $d, bash => $b, program => $p, $o ? (ours => $o) : () }), "\n" if $db;
  if ($c ne 'same') { my $f = sub { my $r = shift; (my $o = "$r->{status} $r->{out}|$r->{err}") =~ s/\n/\\n/g; substr($o, 0, 70) };
    push @list, join "\t", $c, $calls{$l}, join(' ', map { (my $x = $_) =~ s/\n/\\n/g; length $x > 30 ? substr($x, 0, 30) . '...' : $x } $n, @a),
      $f->($d), $f->($b), $f->($p), join(',', @{$samples{$l}}) } }
my @C = ('same', 'messages only', 'dash=bash, program differs', 'dash=program, bash differs', 'bash=program, dash differs', 'all three differ');
printf "%-28s %7s %8s\n", 'class', 'calls', 'samples'; printf "%-28s %7d %8d\n", $_, $cls{$_}{calls} // 0, $cls{$_}{samples} // 0 for @C;
print "\nsamples, by tool:\n"; printf "%-7s %s\n", '', join ' ', map sprintf('%10.10s', $_), @C;
for my $t (sort keys %tool) { printf "%-7s %s\n", $t, join ' ', map sprintf('%10d', $tool{$t}{$_} // 0), @C }
if ($LIST) { open my $o, '>', $LIST or die; print $o "class\tsamples\tcall\tdash\tbash\tprogram\texamples\n", map "$_\n", sort @list }
if ($OURS) { print "\nours alone against the program (status and output):\n", map(sprintf("%-30s %7d calls %8d samples\n", $_, $ocl{$_}{calls}, $ocl{$_}{samples}), sort keys %ocl),
    @olist ? ("\nwhere ours differs (samples, call, ours, program):\n", map "  $_\n", @olist) : () }
