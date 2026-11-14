# Memory with the large constructs (2026-11-01, sigprobe/mem-large.pl of the old Project; a test since post-0.11):
# functions, local, traps, here-documents, eval, getopts, background jobs and wait, run 1,500 times after 100 to warm
# up: the resident size must stay flat; a growing one means data kept alive, e.g. by a reference cycle (it found the
# arithmetic leak E21; known issue X15).  Only for a release (RELEASE_TESTING=1, or make probe-memory), and where
# /proc/self/status tells the resident size (Linux).
use strict; use warnings; use Test::More;
plan skip_all => 'set RELEASE_TESTING=1 (make probe-memory; about a minute)' unless $ENV{RELEASE_TESTING};
plan skip_all => 'needs /proc/self/status (Linux)' unless -r '/proc/self/status';
use FindBin; use lib map "$FindBin::Bin/../$_", qw(blib/lib blib/arch lib);
use Proc::ShellSpawn; use Proc::ShellSubset::Large;   # the large subset: run() takes the largest parser loaded
my $cmd = q{f() { local x=$1; trap 'echo t' EXIT; g() { return $(($# + 1)); }; g a b; echo $? $x; };
  f 1; cat <<E >/dev/null
$x body
E
eval 'y=2'; while getopts ab o -a -b; do :; done; true & wait $!; (trap 'echo s' EXIT; exit 3)};
sub rss { open my $s, '<', '/proc/self/status' or return 0; (map /^VmRSS:\s+(\d+)/, <$s>)[0] // 0 }
open my $keep, '>&', \*STDOUT or die; open STDOUT, '>', '/dev/null' or die;   # the commands print; TAP must not see it
my @st; push @st, (Proc::ShellSpawn::run($cmd))[0] for 1 .. 100; my $r0 = rss();
push @st, (Proc::ShellSpawn::run($cmd))[0] for 1 .. 1500; my $r1 = rss();
open STDOUT, '>&', $keep or die;
my $LIMIT = $ENV{MEMORY_LIMIT_KB} // 1024;
is(scalar(grep !defined || $_ != 3, @st), 0, '1,600 runs, every one status 3 (the last command, the subshell exit 3)');
cmp_ok($r1 - $r0, '<=', $LIMIT, "resident size $r0 -> $r1 kB after 1,500 more runs (at most $LIMIT kB more)");
done_testing;
