#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# ---- the phase 1 gate ------------------------------------------------------
# enqueue -> dequeue -> run -> finish -> job_info shows finished with the
# result, in one process, on SQLite.
{
    my ($q) = make_queue();
    $q->task(add => sub { my ($job, $a, $b) = @_; return $a + $b });

    my $id = $q->enqueue(add => [2, 3]);
    my $job = $q->dequeue;
    ok($job, 'claimed');
    isa_ok($job, 'Punk::Queue::Job');

    ok($q->perform($job), 'perform reports success');

    my $info = $q->job_info($id);
    is($info->{state},  'finished', 'the job finished');
    is($info->{result}, 5,          'and its result was recorded');
    ok($info->{finished} > 0,       'finished timestamp is set');
}

# A structured result.
{
    my ($q) = make_queue();
    $q->task(build => sub { return { pages => 3, ok => 1 } });
    my $id = $q->enqueue('build');
    $q->perform($q->dequeue);
    is_deeply($q->job_info($id)->{result}, { pages => 3, ok => 1 },
              'a hashref result round-trips through JSON');
}

# A die becomes a failure, with the message as the result.
{
    my ($q) = make_queue();
    $q->task(boom => sub { die "went wrong\n" });
    my $id = $q->enqueue('boom');

    ok(!$q->perform($q->dequeue), 'perform reports failure');
    my $info = $q->job_info($id);
    is($info->{state}, 'failed', 'the job failed');
    like($info->{result}, qr/went wrong/, 'the message was recorded');
}

# An unknown task fails the job rather than taking the process down. A queue
# holding work for a task this worker does not know is normal during a
# rolling deploy.
{
    my ($q) = make_queue();
    my $id = $q->enqueue('nobody.registered.this');
    my $job = $q->dequeue;

    my $ok = eval { $q->perform($job); 1 };
    ok($ok, 'perform did not die');
    is($q->job_info($id)->{state}, 'failed', 'the job failed instead');
    like($q->job_info($id)->{result}, qr/no task registered/,
         'and said why');
}

# The job object a body receives.
{
    my ($q) = make_queue();
    my %seen;
    $q->task('inspect' => sub {
        my ($job, @args) = @_;
        %seen = (
            id       => $job->id,
            task     => $job->task,
            queue    => $job->queue,
            state    => $job->state,
            retries  => $job->retries,
            attempts => $job->attempts,
            priority => $job->priority,
            args     => $job->args,
            notes    => $job->notes,
            passed   => \@args,
        );
        return 1;
    });

    my $id = $q->enqueue(inspect => ['x', 'y'],
        queue => 'mail', priority => 3, attempts => 4,
        notes => { a => 1 });
    $q->perform($q->dequeue(queues => 'mail'));

    is($seen{id},       $id,        'job->id');
    is($seen{task},     'inspect',  'job->task');
    is($seen{queue},    'mail',     'job->queue');
    is($seen{state},    'active',   'job->state is active while running');
    is($seen{retries},  0,          'job->retries');
    is($seen{attempts}, 4,          'job->attempts');
    is($seen{priority}, 3,          'job->priority');
    is_deeply($seen{args},   ['x', 'y'], 'job->args');
    is_deeply($seen{notes},  { a => 1 }, 'job->notes');
    is_deeply($seen{passed}, ['x', 'y'], 'args are passed to the body');
}

# A body can settle itself.
{
    my ($q) = make_queue();
    $q->task(early => sub {
        my ($job) = @_;
        $job->finish({ done => 'by hand' });
        return 'ignored - already settled';
    });
    my $id = $q->enqueue('early');
    $q->perform($q->dequeue);

    my $info = $q->job_info($id);
    is($info->{state}, 'finished', 'the explicit finish stood');
    is_deeply($info->{result}, { done => 'by hand' },
              'and perform did not overwrite it');
}

# ---- the optimistic retries guard ------------------------------------------
# This is the mechanism that stops a presumed-dead worker clobbering the
# attempt that replaced it. Repair (phase 6) requeues by bumping retries;
# here we do it by hand.
{
    my ($q) = make_queue();
    my $id = $q->enqueue('t');
    my $job = $q->dequeue;

    # somebody else decides this worker is gone and requeues the job
    $q->dbh->do('UPDATE pq_jobs SET retries = retries + 1, state = ?'
              . ' WHERE id = ?', undef, 'active', $id);

    is($q->finish_job($id, 0, 'stale'), 0,
       'a finish carrying the old retry count is rejected');
    is($q->job_info($id)->{state}, 'active', 'the row was not settled');

    is($q->finish_job($id, 1, 'fresh'), 1,
       'the current attempt can finish');
    is($q->job_info($id)->{state}, 'finished', 'and it did');
}

# finish/fail only apply to an active job.
{
    my ($q) = make_queue();
    my $id = $q->enqueue('t');
    is($q->finish_job($id, 0, 'x'), 0, 'an unclaimed job cannot be finished');
    is($q->job_info($id)->{state}, 'inactive', 'it stayed inactive');
}

# drain: the helper the later phases lean on.
{
    my ($q) = make_queue();
    my $ran = 0;
    $q->task(count => sub { $ran++; return $ran });
    $q->enqueue('count') for 1 .. 5;

    is(drain($q), 5, 'drain ran every job');
    is($ran, 5, 'the bodies ran');

    my ($n) = $q->dbh->selectrow_array(
        "SELECT count(*) FROM pq_jobs WHERE state = 'finished'");
    is($n, 5, 'all five are finished');
}

# job_info on a missing id.
{
    my ($q) = make_queue();
    ok(!defined $q->job_info(999999), 'job_info returns undef for no such id');
}

done_testing();
