#!/usr/bin/perl
# large-subset-builtins.pl (post4-0.04, 2026-11-05): the atomic calls without coreutils where no program runs.  Every
# such command that Proc::ShellSpawn runs in the corpus samples, with its words as expanded there, run alone in dash,
# bash --posix and ours: the builtins (cd, read, set, export, readonly, local, shift, trap, unset, umask, jobs, wait,
# eval, ., exit, return, getopts, command, type, ...), also inside function bodies; settings alone (x=1); and a
# command that is not found (or not allowed to run).  (The calls to external programs need no such run: large-subset-runcompare.pl's logs already
# compare them, call by call; the calls to echo, printf, test, [, kill, pwd: large-subset-threeway.pl.)
#
# Usage (as root, with no network):
#   unshare -n perl large-subset-runcompare.pl -q samples.jsonl samples.tsv QDIR     # ours only; builtins logged
#   unshare -n perl large-subset-builtins.pl [-l LIST.tsv] [-db DB.jsonl] QDIR
# Each distinct call (NAME=VALUE settings before it, the name, the arguments) becomes a text: the settings and
# arguments single-quoted (a plain name stays bare).  It runs as the user rc9, in a fresh copy of large-subset-runcompare.pl's directory, stdin
# /dev/null, 5 seconds at most: dash -c TEXT, bash --posix -c TEXT, perl t/try.pl TEXT.  Compared: status, standard
# output, the files left; and the messages, as in large-subset-runreport.pl (the shells' prefixes taken off,
# compared as a multiset of characters).  Calls of functions are counted, not run (the commands of their bodies are
# taken one by one); a name a function may have (b_late) is taken where it runs: as the builtin, or as the function.
# A side effect inside an expansion (: $((z=3))) is not in the expanded words, so it is lost when the call runs alone.
use strict; use warnings; use JSON::PP; use File::Path qw(make_path remove_tree); use Cwd 'abs_path'; use Getopt::Long;
my ($LIST, $DB); GetOptions('l=s' => \$LIST, 'db=s' => \$DB) && @ARGV == 1 or die "usage: $0 [-l LIST.tsv] [-db DB.jsonl] QDIR\n";
$> == 0 or die "run as root\n";
my $DIST = abs_path('.'); -e "$DIST/blib/arch/auto/Proc/Spawner/Spawner.so" or die "run make first, in the distribution's directory\n";
my %SKIP = map +($_ => 1), qw(Proc::ShellSpawn::Large::call Proc::ShellSpawn::Large::b_late);
my %TOOL = map +($_ => 1), qw(echo printf test [ kill pwd true false);   # coreutils: large-subset-threeway.pl

my (%calls, %samples, %skipped, %kind);   # TEXT => number of samples; examples
sub q1 { my $s = shift; $s =~ s/'/'\\''/g; "'$s'" }
for my $f (glob "$ARGV[0]/run-*.jsonl") { open my $in, '<', $f or die;
  while (<$in>) { my $s = eval { decode_json($_) } or next; my %seen;
    for my $l (split /\n/, $s->{ours}{builtins} // '') {
      my ($h, $env, $argv) = split /\035/, $l, -1; next unless defined $argv;
      if ($SKIP{$h}) { $skipped{$h eq 'Proc::ShellSpawn::Large::call' ? 'function calls' : $h}++; next }
      my @a = split /\037/, $argv, -1; my @e = grep length, split /\036/, $env;
      if (@a && $TOOL{$a[0]}) { $skipped{"coreutils $a[0]"}++; next }
      my $t = join ' ', (map { my ($n, $v) = split /=/, $_, 2; "$n=" . q1($v) } @e), !@a ? () :
        ($a[0] =~ /^[A-Za-z0-9_.:-]+\z/ ? $a[0] : q1($a[0])),
        !@a ? () : map { $a[0] =~ /^(?:export|readonly|local)\z/ && /^([A-Za-z_]\w*)=(.*)\z/s ? "$1=" . q1($2) : q1($_) } @a[1 .. $#a];   # NAME='value'   # the name bare: the parser takes a quoted export for no declaration
      next if $seen{$t}++; $calls{$t}++; $kind{$t} = $h; push @{$samples{$t}}, $s->{id} if @{$samples{$t} // []} < 3 } } }
print STDERR scalar(keys %calls), " distinct calls; left out: ", join(', ', map "$_ $skipped{$_}", sort keys %skipped) || 'none', "\n";

my %FIXTURE = ('a.txt' => "alpha\nbeta\n", 'b.txt' => "one two\n", 'file.txt' => "hello world\n", 'c.log' => "x\n",
  '.hidden' => "h\n", 'dir/x.txt' => "in dir\n", 'dir/sub/y.sh' => "echo y\n", 'home/.profile' => '', 'empty' => '');
my $u = 'rc9'; my $W = '/var/tmp/runcompare/builtins';
system("id $u >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -d /nonexistent $u") == 0 or die "useradd $u\n";
sub run1 { my @cmd = @_;
  system('pkill', '-9', '-u', $u); remove_tree($W); make_path("$W/run");
  for my $f (sort keys %FIXTURE) { my ($d) = $f =~ m{^(.*)/}; make_path("$W/run/$d") if $d;
    open my $o, '>', "$W/run/$f" or die; print $o $FIXTURE{$f}; close $o }
  system('chown', '-R', "$u:$u", $W); chmod 0755, $W;
  my $pid = fork // die;
  unless ($pid) { chdir "$W/run"; %ENV = (PATH => '/usr/bin:/bin', LANG => 'C', LC_ALL => 'C', HOME => "$W/run/home", USER => $u);
    open STDIN, '<', '/dev/null'; open STDOUT, '>', "$W/out"; open STDERR, '>', "$W/err";
    exec '/usr/bin/setpriv', "--reuid=$u", "--regid=$u", '--clear-groups', '--inh-caps=-all', '--', '/usr/bin/timeout', '-k', '1', '5', @cmd; exit 127 }
  waitpid $pid, 0; my $st = $? >> 8; $st = 'signal ' . ($? & 127) if $? & 127; system('pkill', '-9', '-u', $u);
  my %r = (status => $st); for my $p (qw(out err)) { open my $i, '<:raw', "$W/$p"; local $/; $r{$p} = <$i> // '' }
  my @files; my $walk; $walk = sub { my ($d, $p) = @_; opendir my $dh, $d or return;
    for my $n (sort grep !/^\.\.?\z/, readdir $dh) { my $f = "$d/$n"; push @files, -d $f ? "$p$n/" : "$p$n " . (-s $f // '?');
      $walk->($f, "$p$n/") if -d $f && !-l $f } };
  $walk->("$W/run", ''); $r{files} = join "\n", @files; \%r }
my %PFX = (dash => qr/(?:\S*\/)?dash: \d+: /, bash => qr/(?:\S*\/)?bash: (?:line \d+: )?/, ours => qr/(?:^|(?<=\n))sh: /);
sub msgs { my ($e, $sh) = @_; $e =~ s/$PFX{$sh}//g; join '', sort split //, $e =~ s/\n//gr }

my (%cls, %name, @list); my $j = JSON::PP->new->utf8->canonical; my $db;
open $db, '>', $DB or die "$DB: $!" if $DB;
for my $t (sort keys %calls) {
  my %r = (dash => run1('/usr/bin/dash', '-c', $t), bash => run1('/usr/bin/bash', '--posix', '-c', $t),
           ours => run1($^X, "-I$DIST/blib/lib", "-I$DIST/blib/arch", "$DIST/t/try.pl", $t));
  my ($d, $b, $o) = @r{qw(dash bash ours)};
  my $eq = sub { my ($x, $y) = @_; $x->{status} eq $y->{status} && $x->{out} eq $y->{out} && $x->{files} eq $y->{files} };
  my ($db_, $do, $bo) = ($eq->($d, $b), $eq->($d, $o), $eq->($b, $o));
  my ($md, $mb, $mo) = (msgs($d->{err}, 'dash'), msgs($b->{err}, 'bash'), msgs($o->{err}, 'ours'));
  my $c = $o->{status} eq '255' && $o->{err} =~ /^outside the subset/ ? 'ours rejects it alone'
        : $db_ && $do ? ($md eq $mb && $md eq $mo ? 'same' : $mo eq $md ? 'messages: as dash' : $mo eq $mb ? 'messages: as bash' : 'messages: neither')
        : $db_ ? 'dash=bash, ours differs' : $do ? 'dash=ours, bash differs' : $bo ? 'bash=ours, dash differs' : 'all three differ';
  my $n = $kind{$t} eq 'x_set' ? '(settings)' : $kind{$t} =~ /^(?:not found|denied)\z/ ? "($kind{$t})"
        : $t =~ s/^(?:\w+='(?:[^']|'\\'')*' ?)*'?([^' ]*).*/$1/sr;
  $cls{$c}{calls}++; $cls{$c}{samples} += $calls{$t}; $name{$n}{$c} += $calls{$t};
  print $db $j->encode({ text => $t, samples => $calls{$t}, examples => $samples{$t}, class => $c, %r }), "\n" if $db;
  if ($c ne 'same') { my $f = sub { my $r = shift; (my $x = "$r->{status} $r->{out}|$r->{err}") =~ s/\n/\\n/g; substr($x, 0, 70) };
    push @list, join "\t", $c, $calls{$t}, length $t > 70 ? substr($t, 0, 70) . '...' : $t, $f->($d), $f->($b), $f->($o), join(',', @{$samples{$t}}) } }
my @C = ('same', 'messages: as dash', 'messages: as bash', 'messages: neither', 'dash=bash, ours differs', 'dash=ours, bash differs', 'bash=ours, dash differs', 'all three differ', 'ours rejects it alone');
printf "%-28s %7s %8s\n", 'class', 'calls', 'samples'; printf "%-28s %7d %8d\n", $_, $cls{$_}{calls} // 0, $cls{$_}{samples} // 0 for @C;
print "\nsamples, by builtin:\n"; printf "%-9s %s\n", '', join ' ', map sprintf('%10.10s', $_), @C;
for my $t (sort { my ($x, $y) = map { my $h = $name{$_}; my $s = 0; $s += $_ for values %$h; $s } $a, $b; $y <=> $x } keys %name) {
  printf "%-9s %s\n", $t, join ' ', map sprintf('%10d', $name{$t}{$_} // 0), @C }
if ($LIST) { open my $o, '>', $LIST or die; print $o "class\tsamples\tcall\tdash\tbash\tours\texamples\n", map "$_\n", sort @list }
