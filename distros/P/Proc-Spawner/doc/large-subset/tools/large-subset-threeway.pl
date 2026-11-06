#!/usr/bin/perl
# large-subset-threeway.pl (post4-0.04, 2026-11-05): for the commands the subset runs as programs in place of the
# shells' builtins (echo, printf, test, [, kill, pwd), the answers of all three: dash's builtin, bash's builtin
# (--posix) and the program alone, for every argument list that the corpus samples really give them.
#
# Usage (as root, with no network):
#   unshare -n perl large-subset-runcompare.pl -q samples.jsonl samples.tsv QDIR     # ours only, these programs logged
#   unshare -n perl large-subset-threeway.pl [-l LIST.tsv] [-db DB.jsonl] QDIR
# Calls made by another program (xargs printf ..., env echo ...) are left out: there every shell runs the program.
# Each distinct call (name and arguments, as logged) is run three ways, as the user rc9, in an empty directory,
# stdin /dev/null, 5 seconds at most: dash -c '"$@"' sh NAME ARGS..., the same with bash --posix, and the program
# itself (argv[0] = NAME).  Compared: status, standard output; and the messages, with the shells' prefix ("sh: 1: ",
# "sh: line 1: ") and the program's path taken off.  -db keeps every call with its three answers (the "database");
# -l lists the calls where the three do not agree.  The table counts calls and corpus samples (a sample may make
# several calls).
use strict; use warnings; use JSON::PP; use File::Path qw(make_path remove_tree); use Getopt::Long;
my ($LIST, $DB); GetOptions('l=s' => \$LIST, 'db=s' => \$DB) && @ARGV == 1 or die "usage: $0 [-l LIST.tsv] [-db DB.jsonl] QDIR\n";
$> == 0 or die "run as root\n";
my %TOOL = map +($_ => 1), qw(echo printf test [ kill pwd);
my %PROG = (map(+($_ => "/usr/bin/$_"), keys %TOOL));

my (%calls, %samples, %byprog);   # "NAME\037ARG..." => number of samples; and the samples of each
for my $f (glob "$ARGV[0]/run-*.jsonl") { open my $in, '<', $f or die;
  while (<$in>) { my $s = eval { decode_json($_) } or next; my %seen;
    for my $l (split /\n/, $s->{ours}{rec} // '') {
      my $who = $l =~ s/^([^\035\037]*)\035// ? $1 : 'perl';   # the caller: perl (our shell) or a program (xargs, env, ...)
      my ($n) = split /\037/, $l; next unless defined $n && $TOOL{$n};
      if ($who !~ /^perl/) { $byprog{$who}++; next }               # a program calls it so in every shell: no builtin involved
      next if $seen{$l}++;
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
sub norm { my ($e, $n) = @_; $e =~ s/^sh: (?:line )?\d+: //mg; $e =~ s/^\S*\/\Q$n\E: /$n: /mg; $e }

my (%cls, %tool, @list); my $j = JSON::PP->new->utf8->canonical; my $db;
open $db, '>', $DB or die "$DB: $!" if $DB;
for my $l (sort keys %calls) {
  my ($n, @a) = split /\037/, $l, -1;
  my $d = run1('/usr/bin/dash', '-c', '"$@"', 'sh', $n, @a);
  my $b = run1('/usr/bin/bash', '--posix', '-c', '"$@"', 'sh', $n, @a);
  my $p = run1('/usr/bin/perl', '-e', 'exec { $ARGV[0] } @ARGV[1 .. $#ARGV] or exit 127', $PROG{$n}, $n, @a);   # argv[0] = NAME
  $_->{err} = norm($_->{err}, $n) for $d, $b, $p;
  my $eq = sub { my ($x, $y) = @_; $x->{status} eq $y->{status} && $x->{out} eq $y->{out} };
  my ($db_, $dp, $bp) = ($eq->($d, $b), $eq->($d, $p), $eq->($b, $p));
  my $c = $db_ && $dp ? (($d->{err} eq $b->{err} && $d->{err} eq $p->{err}) ? 'same' : 'messages only')
        : $db_ ? 'dash=bash, program differs' : $dp ? 'dash=program, bash differs' : $bp ? 'bash=program, dash differs' : 'all three differ';
  $cls{$c}{calls}++; $cls{$c}{samples} += $calls{$l}; $tool{$n}{$c} += $calls{$l};
  print $db $j->encode({ call => [$n, @a], samples => $calls{$l}, examples => $samples{$l}, class => $c, dash => $d, bash => $b, program => $p }), "\n" if $db;
  if ($c ne 'same') { my $f = sub { my $r = shift; (my $o = "$r->{status} $r->{out}|$r->{err}") =~ s/\n/\\n/g; substr($o, 0, 70) };
    push @list, join "\t", $c, $calls{$l}, join(' ', map { (my $x = $_) =~ s/\n/\\n/g; length $x > 30 ? substr($x, 0, 30) . '...' : $x } $n, @a),
      $f->($d), $f->($b), $f->($p), join(',', @{$samples{$l}}) } }
my @C = ('same', 'messages only', 'dash=bash, program differs', 'dash=program, bash differs', 'bash=program, dash differs', 'all three differ');
printf "%-28s %7s %8s\n", 'class', 'calls', 'samples'; printf "%-28s %7d %8d\n", $_, $cls{$_}{calls} // 0, $cls{$_}{samples} // 0 for @C;
print "\nsamples, by tool:\n"; printf "%-7s %s\n", '', join ' ', map sprintf('%10.10s', $_), @C;
for my $t (sort keys %tool) { printf "%-7s %s\n", $t, join ' ', map sprintf('%10d', $tool{$t}{$_} // 0), @C }
if ($LIST) { open my $o, '>', $LIST or die; print $o "class\tsamples\tcall\tdash\tbash\tprogram\texamples\n", map "$_\n", sort @list }
