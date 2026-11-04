# The batteries (t/batteries/), each string run by dash and by Proc::ShellSpawn (t/try.pl), compared like compare.pl.  A difference
# fails unless t/dash-known.txt lists it.  Skipped without dash.  Runs in a temporary directory, and /tmp in a string means
# that directory's own tmp/, so that test runs at the same time do not remove each other's files.  Where a string turns
# process IDs into N (tr 0-9 N), the number of digits is not compared: dash's and Perl's process IDs may differ in length.
use strict; use warnings;
use Test::More; use Cwd 'abs_path'; use File::Temp 'tempdir'; use File::Copy 'copy';
grep -x "$_/dash", split /:/, $ENV{PATH} // '' or plan skip_all => 'no dash in PATH';
use Proc::Spawner;   # the shell layer needs posix_spawn's chdir extension
my $p = Proc::Spawner::spawn('/bin/true', ['true'], undef, [[chdir => '/']], {}) or plan skip_all => "no posix_spawn chdir in this libc: $!";
waitpid $p, 0;
my $top = abs_path('.'); my %known;
open my $k, '<', 't/dash-known.txt' or die "t/dash-known.txt: $!";
while (<$k>) { next if /^#/; chomp; my ($f, $why, $c) = split /\t/, $_, 3; $known{"$f\t$c"} = $why }
my @files = map "$_.txt", qw(largebattery battery fdbattery sigenv t1 t2 t3 pspawn-d2 pspawn-l10 large-subset-b13 large-subset-p6 large-subset-e);
my @lines = map { my $f = $_; open my $in, '<', "t/batteries/$f" or die "$f: $!"; [$f, grep length, map { chomp; $_ } <$in>] } @files;
my $dir = tempdir(CLEANUP => 1); mkdir "$dir/tmp" or die "$dir/tmp: $!"; copy('t/fds', "$dir/fds") && chmod 0755, "$dir/fds"; chdir $dir or die;
for (@lines) {
  my ($file, @l) = @$_; my ($same, @bad) = 0;
  for my $line (@l) {
    (my $c = $line) =~ s/\@N/\n/g; $c =~ s/\@T/\t/g; $c =~ s{/tmp\b}{$dir/tmp}g; local $ENV{CMD} = $c;
    my $d = qx{timeout 10 dash -c "\$CMD" 2>&1 </dev/null; echo "<\$?>"};
    my $p = qx{timeout 10 $^X -I$top/blib/arch $top/t/try.pl "\$CMD" 2>&1 </dev/null; echo "<\$?>"};
    s/^dash: \d+: //mg for $d; s/^sh: //mg for $p;
    s/N+/N/g for $line =~ /tr 0-9 N/ ? ($d, $p) : ();
    my $why = $known{"$file\t$line"};
    if ($d eq $p) { $same++; note "$file: agrees now: $line ($why)" if $why && $why !~ /^FLAKY/; next }
    push @bad, "$line\n  dash: " . ($d =~ s/\n/|/gr) . "\n  ours: " . ($p =~ s/\n/|/gr) unless $why }
  ok !@bad, "$file: $same of " . @l . " agree with dash, the rest known" or diag join "\n", @bad }
chdir $top; done_testing;
