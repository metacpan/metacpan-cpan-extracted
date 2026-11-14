# The executor under stress (2026-11-01, sigprobe/exec-stress.pl of the old Project; a test since post-0.11): pipelines of
# short-lived children in a loop, so that children end while our own Perl code (continuations, contexts) runs and
# allocates: the signal and reaping races of X14.  Every run must end normally, status 0.  Only for a release
# (RELEASE_TESTING=1, or make probe-stress): it takes STRESS_SECONDS (20).  Not on Windows (true, the program).
use strict; use warnings; use Test::More;
plan skip_all => 'set RELEASE_TESTING=1 (make probe-stress; about 20 seconds)' unless $ENV{RELEASE_TESTING};
plan skip_all => 'POSIX only (runs the program true)' if $^O eq 'MSWin32';
use FindBin; use lib map "$FindBin::Bin/../$_", qw(blib/lib blib/arch lib);
use Proc::ShellSpawn;
my $secs = $ENV{STRESS_SECONDS} // 20; my $end = time + $secs; my ($runs, @bad) = (0);
my $cmd = 'for i in ' . join(' ', 1 .. 30) . '; do true | true | true | true; x=$(true); done';
while (time < $end) { my ($st, $err) = Proc::ShellSpawn::run($cmd);
  push @bad, defined $st ? "status $st" : "outside the subset: $err->{error}" unless defined $st && $st == 0; $runs++; last if @bad > 5 }
is("@bad", '', "$runs runs (" . $runs * 150 . " children) in $secs s, every one status 0");
ok($runs > 0, 'it ran at all');
done_testing;
