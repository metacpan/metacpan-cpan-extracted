# K3, the user's choice B (post-0.04): a background chain moves on between run() calls, while Perl does
# other work; the cost (documented): the program's own sleep returns early when a child ends.
use strict; use warnings;
use Test::More; use File::Temp 'tempdir'; use Time::HiRes qw(time sleep);
use Proc::ShellSubset::Large; use Proc::ShellSpawn;
my $d = tempdir(CLEANUP => 1);
my $t0 = time;
Proc::ShellSpawn::run("sleep 1 && echo b > $d/b &");
ok time - $t0 < 0.5, 'run returns at once';
my $at; while (time - $t0 < 4) { sleep 0.05; $at //= time - $t0 if -s "$d/b" }   # busy with other things
ok defined $at && $at < 2.5, sprintf 'the chain went on while Perl was busy (b after %.1f s)', $at // -1;
my $t1 = time; Proc::ShellSpawn::run('sleep 1 &'); my $slept = CORE::sleep 3;
ok time - $t1 < 2.5, sprintf "Perl's own sleep 3 returned early when the job ended (after %.1f s)", time - $t1;
# X55: the deferred SIGCHLD handler leaves the program's $? and $! as they were (it reaped the job, waitpid set $?)
{ my $bad = 0;
  for (1 .. 5) { Proc::ShellSpawn::run('sh -c "sleep 0.05; exit 3" &'); $? = 42 << 8; $! = 0;
    select undef, undef, undef, 0.3; my $x = 1; $bad++ if $? != 42 << 8 }   # ($!: select itself says EINTR)
  is $bad, 0, "a job ending between calls leaves \$? alone (X55)" }
done_testing;
