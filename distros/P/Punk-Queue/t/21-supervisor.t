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

# The phase-3 gate: a real forked pool drains a 50-job queue and exits 0
# on SIGTERM inside the graceful window, with no orphans - run over both
# execution paths.

my $has_hm = eval { require Hyperman; 1 };
my @paths = (['poll', { PUNK_QUEUE_NO_HM_ABI => 1 }]);
push @paths, ['loop', {}] if $has_hm;

for my $p (@paths) {
    my ($name, $env) = @$p;

    subtest "$name path: the gate" => sub {
        my ($q, $file) = make_queue();
        my $app = task_app("dbi:SQLite:dbname=$file");
        $q->enqueue(add => [$_, $_]) for 1 .. 50;

        my $h = pq_start(['worker', '--app', $app, '-j', '2'], env => $env);

        # wait for the pool to drain, bounded
        my $deadline = time + 30;
        while (time < $deadline) {
            last if $q->stats->{finished_jobs} == 50;
            select undef, undef, undef, 0.2;
        }
        is($q->stats->{finished_jobs}, 50, 'all 50 jobs finished');

        # While alive: one supervisor row, two child rows. A drained queue
        # does not imply both children have registered - one child can take
        # every job while the other is still coming up, which is exactly what
        # a loaded smoker sees - so wait for the registry to settle first,
        # bounded like the drain above. A count that never arrives still
        # fails, just after the wait rather than before it.
        my $ws;
        $deadline = time + 15;
        while (time < $deadline) {
            $ws = $q->list_workers;
            last if $ws->{total} == 3;
            select undef, undef, undef, 0.2;
        }
        is($ws->{total}, 3, 'supervisor + 2 children registered');
        is(scalar(grep { $_->{role} eq 'supervisor' } @{ $ws->{workers} }),
           1, 'one supervisor row');
        is(scalar(grep { $_->{role} eq 'child' } @{ $ws->{workers} }),
           2, 'one row per child - the departure from Minion');

        my ($code, $out) = pq_finish($h, 'TERM');
        is($code, 0, 'exit 0 on SIGTERM inside the graceful window')
            or diag @$out;

        is($q->list_workers->{total}, 0, 'every worker row unregistered');
        ok(!kill(0, $h->{pid}), 'the supervisor is gone');
        unlink $app;
    };
}

# SIGHUP recycles: children exit and come back with fresh pids.
{
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file");
    my $h = pq_start(['worker', '--app', $app, '-j', '1'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });

    my $deadline = time + 15;
    my @before;
    while (time < $deadline) {
        @before = map { $_->{pid} }
                  grep { $_->{role} eq 'child' }
                  @{ $q->list_workers->{workers} };
        last if @before == 1;
        select undef, undef, undef, 0.2;
    }
    is(scalar @before, 1, 'one child running');

    kill 'HUP', $h->{pid};

    $deadline = time + 15;
    my @after;
    while (time < $deadline) {
        @after = map { $_->{pid} }
                 grep { $_->{role} eq 'child' }
                 @{ $q->list_workers->{workers} };
        last if @after == 1 && $after[0] != $before[0];
        select undef, undef, undef, 0.2;
    }
    is(scalar @after, 1, 'one child after the recycle');
    isnt($after[0], $before[0], 'and it is a fresh process');

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean exit after a recycle');
    unlink $app;
}

done_testing();
