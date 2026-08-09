#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# An empty queue.
{
    my ($q) = make_queue();
    ok(!defined $q->dequeue, 'an empty queue returns undef');
}

# Priority order, then FIFO within a priority. The index is
# (queue, priority DESC, id), so id is the tiebreaker and gives insertion
# order for free with no second timestamp column to read.
{
    my ($q) = make_queue();
    my $low  = $q->enqueue('t' => ['low'],  priority => 0);
    my $high = $q->enqueue('t' => ['high'], priority => 10);
    my $mid  = $q->enqueue('t' => ['mid'],  priority => 5);
    my $low2 = $q->enqueue('t' => ['low2'], priority => 0);

    my @got;
    while (my $j = $q->dequeue) { push @got, $j->id }
    is_deeply(\@got, [$high, $mid, $low, $low2],
              'highest priority first, FIFO within a priority');
}

# A claim marks the row and stamps the worker.
{
    my ($q) = make_queue();
    my $id  = $q->enqueue('t' => [1]);

    my $before = $q->job_info($id);
    is($before->{state}, 'inactive', 'inactive before the claim');

    my $job = $q->dequeue(worker => 42);
    is($job->id, $id, 'claimed the job');
    is($job->state, 'active', 'the returned job reads as active');

    my $after = $q->job_info($id);
    is($after->{state},  'active', 'and so does the row');
    is($after->{worker}, 42,       'the worker id is stamped');
    ok($after->{started} > 0,      'started is set');

    ok(!defined $q->dequeue, 'a claimed job is not claimable again');
}

# Delayed jobs are not claimed early.
{
    my ($q) = make_queue();
    my $soon = $q->enqueue('t' => ['now']);
    my $late = $q->enqueue('t' => ['later'], delay => 3600);

    my $job = $q->dequeue;
    is($job->id, $soon, 'the ready job is claimed');
    ok(!defined $q->dequeue, 'the delayed job is not');

    # Reach past the API to move it into the past, which is the only way to
    # test the boundary without sleeping.
    $q->dbh->do('UPDATE pq_jobs SET delayed = delayed - 7200 WHERE id = ?',
                undef, $late);
    my $j2 = $q->dequeue;
    ok($j2 && $j2->id == $late, 'and is claimed once its delay has passed');
}

# Expired jobs are never claimed.
{
    my ($q) = make_queue();
    my $id = $q->enqueue('t' => [1], expire => 3600);
    $q->dbh->do('UPDATE pq_jobs SET expires = expires - 7200 WHERE id = ?',
                undef, $id);
    ok(!defined $q->dequeue, 'an expired job is not claimed');
}

# Unfinished parents block a job. Phase 1 has no parents API, but the
# predicate is on the hot path from day one and a regression in it would be
# invisible until phase 4.
{
    my ($q) = make_queue();
    my $id = $q->enqueue('t' => [1]);
    $q->dbh->do('UPDATE pq_jobs SET parents_left = 1 WHERE id = ?',
                undef, $id);
    ok(!defined $q->dequeue, 'a job with unfinished parents is not claimed');

    $q->dbh->do('UPDATE pq_jobs SET parents_left = 0 WHERE id = ?',
                undef, $id);
    ok($q->dequeue, 'and is claimed once they are done');
}

# Queue selection.
{
    my ($q) = make_queue();
    my $d = $q->enqueue('t' => ['default']);
    my $m = $q->enqueue('t' => ['mail'], queue => 'mail');

    ok(!defined $q->dequeue(queues => ['sms']), 'an unwatched queue is ignored');

    my $j = $q->dequeue(queues => ['mail']);
    is($j->id, $m, 'claims from the named queue');

    $j = $q->dequeue(queues => 'default');
    is($j->id, $d, 'a bare string works as a one-element list');
}

# Task selection, for a worker started with a narrow --task list.
{
    my ($q) = make_queue();
    my $a = $q->enqueue('alpha');
    my $b = $q->enqueue('beta');

    my $j = $q->dequeue(tasks => ['beta']);
    is($j->id, $b, 'claims only the named task');

    $j = $q->dequeue(tasks => ['alpha', 'gamma']);
    is($j->id, $a, 'a list of task names works');
}

# Two queue objects on the same database do not both get the same job. This
# is the property the whole design exists to provide; the real multi-process
# version arrives in phase 2's concurrency test.
{
    my ($q, $file) = make_queue();
    require Punk::Queue;
    my $q2 = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file");

    my $id = $q->enqueue('t' => [1]);
    my $j1 = $q->dequeue;
    my $j2 = $q2->dequeue;

    ok($j1 && $j1->id == $id, 'the first claimer gets the job');
    ok(!defined $j2,          'the second gets nothing');
}

done_testing();
