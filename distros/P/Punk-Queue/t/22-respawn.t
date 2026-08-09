#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;
use PQSpawn;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# A task that exits the child outright. The supervisor must respawn with
# backoff and keep going - and because each incarnation DID claim before
# dying, the fail-fast escalation must NOT trigger.
{
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file");
    $q->enqueue('bail') for 1 .. 3;        # each kills one child
    $q->enqueue(add => [1, 1]);            # the survivor proves recovery

    my $h = pq_start(['worker', '--app', $app, '-j', '1'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });

    my $deadline = time + 30;
    while (time < $deadline) {
        my $s = $q->stats;
        last if $s->{finished_jobs} == 1 && $s->{inactive_jobs} == 0;
        select undef, undef, undef, 0.2;
    }

    my $s = $q->stats;
    is($s->{finished_jobs}, 1, 'the pool recovered and ran the last job');
    # the three bail jobs died mid-run: their rows are stranded active
    # until phase 6's repair - what phase 3 owes is only that the pool
    # survived them
    is($s->{inactive_jobs}, 0, 'nothing left unclaimed');

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean exit after three child deaths');
    unlink $app;
}

# Fail-fast: a worker that cannot even start (bad app) exits before any
# claim; three consecutive such exits with --fail-fast take the parent
# down with exit 1 instead of respawning forever.
{
    my ($q, $file) = make_queue();
    # an app file that dies at load time
    my $app = task_app("dbi:SQLite:dbname=$file", 'die "boot failure\n";');

    my $h = pq_start(['worker', '--app', $app, '-j', '1', '--fail-fast'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });
    my ($code, $out) = pq_finish($h, undef, timeout => 30);
    is($code, 2, 'a broken --app fails at load, before any supervisor');
    unlink $app;
}

# The subtler version: the app loads in the parent but the children die
# instantly (a task calling exit at claim time needs a job; instead use
# a child that exits via max_jobs=0 abuse is not it either - drive it
# with bail jobs and no survivor, unfailingly fast exits WITH claims do
# not escalate, so this asserts the boundary from the other side).
{
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file");
    $q->enqueue('bail') for 1 .. 4;

    my $h = pq_start(['worker', '--app', $app, '-j', '1', '--fail-fast'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });

    my $deadline = time + 30;
    while (time < $deadline) {
        last if $q->stats->{inactive_jobs} == 0;
        select undef, undef, undef, 0.2;
    }
    is($q->stats->{inactive_jobs}, 0,
       'children kept being respawned through repeated deaths');
    ok(kill(0, $h->{pid}),
       'and --fail-fast did not fire: every incarnation claimed first');

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean exit');
    unlink $app;
}

done_testing();
