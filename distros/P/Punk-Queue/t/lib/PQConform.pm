package PQConform;

# The behavioural battery, run identically against every backend.
#
# This file is the contract's enforcement arm. The rule (phase-2 gate):
# no behavioural assertion may live outside it, except the two concurrency
# tests whose mechanics are genuinely per-backend. If a behaviour cannot be
# expressed here, that is a contract bug - fix the contract, not the test
# organisation.
#
# Usage:
#     conformance(\&make_queue, 'sqlite');
#
# where make_queue returns a fresh, empty, migrated Punk::Queue every call.
# Later phases append subtests here rather than adding backend-specific
# test files.

use 5.010;
use strict;
use warnings;
use Exporter 'import';
use Test::More;

our @EXPORT = ('conformance');

# The parents_left drift check: recompute the truth from pq_job_deps and
# assert every counter matches. Called after every transition the parents
# subtest performs, so a missed bookkeeping rule fails at the transition
# that broke it, not three assertions later.
sub _counters_ok {
    my ($q, $label) = @_;
    my $bad = $q->dbh->selectall_arrayref(q{
        SELECT c.id, c.parents_left,
               (SELECT count(*) FROM pq_job_deps d
                  JOIN pq_jobs p ON p.id = d.parent_id
                 WHERE d.job_id = c.id
                   AND CASE WHEN c.lax = 1
                       THEN p.state NOT IN ('finished', 'failed')
                       ELSE p.state <> 'finished' END) AS truth
          FROM pq_jobs c
         WHERE c.parents_left <>
               (SELECT count(*) FROM pq_job_deps d
                  JOIN pq_jobs p ON p.id = d.parent_id
                 WHERE d.job_id = c.id
                   AND CASE WHEN c.lax = 1
                       THEN p.state NOT IN ('finished', 'failed')
                       ELSE p.state <> 'finished' END)
    });
    Test::More::is(scalar @$bad, 0,
        "$label: parents_left matches the NOT EXISTS truth")
        or Test::More::diag(join "\n",
            map { "job $_->[0]: counter $_->[1], truth $_->[2]" } @$bad);
    return;
}

sub conformance {
    my ($make, $name) = @_;

    subtest "$name: migration" => sub {
        my $q = $make->();
        my $v = $q->schema_version;
        ok($v > 0, 'migrated');
        is($q->migrate, $v, 're-running migrate is a no-op');
        is($q->backend->latest_version, $v, 'and matches the build');
    };

    subtest "$name: clock" => sub {
        my $q = $make->();
        ok(abs($q->backend->clock_delta) < 5,
           'clock delta is small against a local server');
        ok(abs($q->backend->now - time()) < 5, 'now() is near wall clock');
    };

    subtest "$name: enqueue defaults" => sub {
        my $q = $make->();
        my $id = $q->enqueue('add');
        ok($id > 0, 'returns an id');
        my $j = $q->job_info($id);
        is($j->{task},         'add',      'task');
        is($j->{queue},        'default',  'queue');
        is($j->{state},        'inactive', 'state');
        is($j->{priority},     0,          'priority');
        is($j->{attempts},     1,          'attempts');
        is($j->{retries},      0,          'retries');
        is($j->{parents_left}, 0,          'parents_left');
        is_deeply($j->{args},  [],         'args');
        is_deeply($j->{notes}, {},         'notes');
        ok(!defined $j->{result},  'no result');
        ok(!defined $j->{started}, 'not started');
        ok(!defined $j->{expires}, 'no expiry');
        ok(abs($j->{delayed} - $j->{created}) < 0.01, 'delayed == created');
    };

    subtest "$name: enqueue options" => sub {
        my $q = $make->();
        my $id = $q->enqueue('mail.send' => ['a@b.c', 'hi'],
            queue => 'mail', priority => 7, attempts => 5,
            delay => 60, expire => 3600,
            notes => { source => 'conform' });
        my $j = $q->job_info($id);
        is($j->{queue},    'mail', 'queue');
        is($j->{priority}, 7,      'priority');
        is($j->{attempts}, 5,      'attempts');
        is_deeply($j->{args},  ['a@b.c', 'hi'],       'args');
        is_deeply($j->{notes}, { source => 'conform' }, 'notes');
        ok($j->{delayed} - $j->{created} >= 59,   'delay');
        ok($j->{expires} - $j->{created} >= 3599, 'expire');
    };

    subtest "$name: payload round-trip" => sub {
        my $q = $make->();
        my $payload = {
            nested => [ 1, 2, { deep => 'yes' } ],
            uni    => "caf\x{e9} \x{263a}",
            empty  => [],
            zero   => 0,
        };
        my $j = $q->job_info($q->enqueue('shape' => [$payload]));
        is_deeply($j->{args}[0], $payload, 'nested structure survives');
        is($j->{args}[0]{uni}, "caf\x{e9} \x{263a}", 'unicode survives');
    };

    subtest "$name: name validation" => sub {
        my $q = $make->();
        for my $bad ('has space', 'quote"s', "new\nline", '', 'x' x 65) {
            eval { $q->enqueue($bad) };
            like($@, qr/invalid task name/, 'rejects a bad task name');
        }
        ok($q->enqueue('ns:task-1.ok_2'), 'accepts the documented class');
        eval { $q->enqueue('ok', [], queue => 'bad queue') };
        like($@, qr/invalid queue name/, 'queue names get the same rule');
    };

    subtest "$name: attempts and backoff" => sub {
        # deterministic-ish bounds: base 4, cap 8
        my $q = $make->(attempts_delay => 4, max_backoff => 8);
        $q->task(boom => sub { die "no\n" });
        my $id = $q->enqueue('boom', [], attempts => 3);

        # first failure: retries 0 -> backoff in [0, 4)
        $q->perform($q->dequeue);
        my $j = $q->job_info($id);
        is($j->{state},   'inactive', 'first failure went back to inactive');
        is($j->{retries}, 1,          'retries bumped');
        like($j->{result}, qr/no/,    'the error stays visible during backoff');
        my $b1 = $j->{delayed} - $j->{retried};
        ok($b1 >= 0 && $b1 <= 4, "first backoff within [0, base] ($b1)");

        # second failure: retries 1 -> backoff in [0, 8)
        $q->dbh->do('UPDATE pq_jobs SET delayed = ? WHERE id = ?',
                    undef, $j->{retried} - 1, $id);
        $q->perform($q->dequeue);
        $j = $q->job_info($id);
        is($j->{retries}, 2, 'second failure');
        my $b2 = $j->{delayed} - $j->{retried};
        ok($b2 >= 0 && $b2 <= 8, "second backoff within [0, cap] ($b2)");

        # third failure: retries+1 == attempts -> terminal
        $q->dbh->do('UPDATE pq_jobs SET delayed = ? WHERE id = ?',
                    undef, $j->{retried} - 1, $id);
        $q->perform($q->dequeue);
        $j = $q->job_info($id);
        is($j->{state}, 'failed', 'the attempt limit is terminal');
        ok($j->{finished} > 0, 'and stamped finished');
    };

    subtest "$name: timeout column" => sub {
        my $q = $make->();
        my $id = $q->enqueue('t', [], timeout => 30);
        is($q->job_info($id)->{timeout}, 30, 'timeout round-trips');
        ok(!defined $q->job_info($q->enqueue('t'))->{timeout},
           'and defaults to none');
    };

    subtest "$name: parents" => sub {
        my $q = $make->();
        $q->task(ok => sub { 1 });
        $q->task(boom => sub { die "x\n" });
        my $check = sub { _counters_ok($q, "$name: $_[0]") };

        # a chain: child waits for both parents
        my $p1 = $q->enqueue('ok');
        my $p2 = $q->enqueue('ok');
        my $c  = $q->enqueue('ok', [], parents => [$p1, $p2]);
        is($q->job_info($c)->{parents_left}, 2, 'two blocking parents');
        $check->('after enqueue');

        my $j = $q->dequeue;
        is($j->id, $p1, 'the child is not claimable');
        $q->perform($j);
        $check->('after first parent finished');
        is($q->job_info($c)->{parents_left}, 1, 'one left');

        $q->perform($q->dequeue);
        $check->('after second parent finished');
        is($q->job_info($c)->{parents_left}, 0, 'unblocked');
        is($q->dequeue->id, $c, 'and claimable');
        $q->finish_job($c, 0);
        $check->('after child finished');

        # a finished parent at enqueue time does not block
        my $c2 = $q->enqueue('ok', [], parents => [$p1]);
        is($q->job_info($c2)->{parents_left}, 0,
           'a finished parent never blocked');
        # a nonexistent parent is treated as gone
        my $c3 = $q->enqueue('ok', [], parents => [999999]);
        is($q->job_info($c3)->{parents_left}, 0, 'a missing parent is gone');
        # duplicates count once
        my $p3 = $q->enqueue('ok');
        my $c4 = $q->enqueue('ok', [], parents => [$p3, $p3, $p3]);
        is($q->job_info($c4)->{parents_left}, 1, 'duplicate parents dedupe');
        $check->('after dedupe enqueue');

        # non-lax: a terminally failed parent keeps blocking
        my $pf = $q->enqueue('boom', [], queue => 'x');
        my $cs = $q->enqueue('ok', [], parents => [$pf]);
        my $cl = $q->enqueue('ok', [], parents => [$pf], lax => 1);
        $q->perform($q->dequeue(queues => 'x'));      # fails terminally
        $check->('after parent failed');
        is($q->job_info($cs)->{parents_left}, 1, 'strict child still blocked');
        is($q->job_info($cl)->{parents_left}, 0, 'lax child unblocked');

        # retrying the failed parent re-blocks the lax child
        my $pfj = $q->job_info($pf);
        ok($q->retry_job($pf, $pfj->{retries}), 'retry the failed parent');
        $check->('after failed parent retried');
        is($q->job_info($cl)->{parents_left}, 1, 'lax child re-blocked');
        is($q->job_info($cs)->{parents_left}, 1, 'strict child unchanged');

        # finish it: everyone unblocks
        $q->dequeue(queues => 'x');
        $q->finish_job($pf, $pfj->{retries} + 1);
        $check->('after retried parent finished');
        is($q->job_info($cs)->{parents_left}, 0, 'strict unblocked');
        is($q->job_info($cl)->{parents_left}, 0, 'lax unblocked');

        # retrying a FINISHED parent re-blocks everyone
        ok($q->retry_job($pf, $pfj->{retries} + 1), 'retry the finished parent');
        $check->('after finished parent retried');
        is($q->job_info($cs)->{parents_left}, 1, 'strict re-blocked');
        is($q->job_info($cl)->{parents_left}, 1, 'lax re-blocked');

        # removing an inactive parent unblocks everyone
        ok($q->remove_job($pf), 'remove the inactive parent');
        $check->('after parent removed');
        is($q->job_info($cs)->{parents_left}, 0, 'strict unblocked by removal');
        is($q->job_info($cl)->{parents_left}, 0, 'lax unblocked by removal');

        # removing a FAILED parent unblocks only the strict child (the lax
        # one already got its decrement at the fail)
        my $pf2 = $q->enqueue('boom', [], queue => 'y');
        my $cs2 = $q->enqueue('ok', [], parents => [$pf2]);
        my $cl2 = $q->enqueue('ok', [], parents => [$pf2], lax => 1);
        $q->perform($q->dequeue(queues => 'y'));
        $check->('failed-parent-removal setup');
        ok($q->remove_job($pf2), 'remove the failed parent');
        $check->('after failed parent removed');
        is($q->job_info($cs2)->{parents_left}, 0, 'strict unblocked');
        is($q->job_info($cl2)->{parents_left}, 0, 'lax not double-decremented');
    };

    subtest "$name: unique jobs" => sub {
        my $q = $make->();
        my $a = $q->enqueue('t', [], unique => 'nightly');
        my $b = $q->enqueue('t', [], unique => 'nightly');
        is($b, $a, 'a second live enqueue returns the existing id');
        is($q->stats->{total_jobs}, 1, 'and inserted nothing');

        $q->dequeue;
        my $c = $q->enqueue('t', [], unique => 'nightly');
        is($c, $a, 'active still counts as live');

        $q->finish_job($a, 0);
        my $d = $q->enqueue('t', [], unique => 'nightly');
        isnt($d, $a, 'a finished job does not block re-enqueue');
    };

    subtest "$name: notes merge" => sub {
        my $q = $make->();
        my $id = $q->enqueue('t', [], notes => { a => 1, b => 2 });

        ok($q->backend->note($id, { b => 3, c => [1, 2] }), 'merge');
        is_deeply($q->job_info($id)->{notes},
                  { a => 1, b => 3, c => [1, 2] },
                  'merged, not replaced');

        ok($q->backend->note($id, { a => undef }), 'delete by undef');
        is_deeply($q->job_info($id)->{notes},
                  { b => 3, c => [1, 2] }, 'the key is gone');

        ok(!$q->backend->note(999999, { x => 1 }), 'no such job is false');

        # from inside a task, via the job object
        my $seen;
        $q->task(noter => sub {
            my ($job) = @_;
            $job->note(pct => 50);
            $seen = $job->notes->{pct};
            1;
        });
        my $id2 = $q->enqueue('noter');
        $q->perform($q->dequeue(tasks => 'noter'));
        is($seen, 50, 'the in-memory row reflects the write');
        is($q->job_info($id2)->{notes}{pct}, 50, 'and so does the database');
    };

    subtest "$name: job log" => sub {
        my $q = $make->();
        $q->task(chatty => sub {
            my ($job) = @_;
            $job->log('starting up');
            $job->log(debug => 'checked the cache');
            $job->log(warn => 'input looked odd');
            'done';
        });
        my $id = $q->enqueue('chatty');
        $q->perform($q->dequeue(worker => 7));

        my $log = $q->job_log($id);
        is_deeply([map { $_->{level} } @$log],
                  [qw(info info debug warn info)],
                  'lifecycle rows frame the task rows, in order');
        like($log->[0]{message}, qr/claimed by worker 7 \(attempt 1 of 1\)/,
             'the claim is logged with worker and attempt');
        is($log->[1]{message}, 'starting up', 'a plain log line is info');
        is($log->[3]{message}, 'input looked odd', 'a levelled one keeps it');
        is($log->[-1]{message}, 'finished', 'the finish is logged');
        ok($log->[0]{created} <= $log->[-1]{created}, 'oldest first');

        # a failing job keeps its whole story across attempts
        $q->task(flaky => sub { die "flake\n" });
        my $f = $q->enqueue('flaky', [], attempts => 2);
        $q->perform($q->dequeue(tasks => 'flaky'));
        $q->dbh->do('UPDATE pq_jobs SET delayed = 0 WHERE id = ?',
                    undef, $f);                       # skip the backoff
        $q->perform($q->dequeue(tasks => 'flaky'));
        my $fl = $q->job_log($f);
        is_deeply([map { $_->{level} } @$fl],
                  [qw(info warn info error)],
                  'claim, retry scheduled, claim, terminal - both attempts');
        like($fl->[1]{message},
             qr/attempt 1 of 2 failed: flake - retry due in/,
             'the retry row names the error and the backoff');
        like($fl->[3]{message}, qr/failed after 2 of 2 attempts: flake/,
             'the terminal row too');

        # an operator retry is part of the story as well
        $q->retry_job($f, $q->job_info($f)->{retries});
        like($q->job_log($f)->[-1]{message}, qr/retried from 'failed'/,
             'an operator retry is recorded');

        ok(!eval { $q->backend->log_job($id, 'x', 'fatal'); 1 },
           'an unknown level is rejected');
        like($@, qr/log level must be/, 'with the vocabulary');

        $q->remove_job($id);
        is_deeply($q->job_log($id), [], 'remove_job takes the log with it');
        is_deeply($q->job_log(999999), [], 'an unknown id is just empty');
    };

    subtest "$name: job log - the logging option" => sub {
        my $q = $make->();
        $q->backend->{opts}{logging} = 0;
        $q->task(quiet => sub { $_[0]->log('still here'); 1 });
        my $id = $q->enqueue('quiet');
        $q->perform($q->dequeue);
        my $log = $q->job_log($id);
        is(scalar @$log, 1, 'logging => 0 sheds the lifecycle rows');
        is($log->[0]{message}, 'still here',
           'but an explicit $job->log always writes');
        delete $q->backend->{opts}{logging};
    };

    subtest "$name: defaults precedence" => sub {
        my $q = $make->();
        $q->queue_defaults(mail => { attempts => 5, priority => 2 });
        $q->task_defaults('mail.send' => { queue => 'mail', priority => 3 });

        my $j = $q->job_info($q->enqueue('mail.send'));
        is($j->{queue},    'mail', 'task default routed the queue');
        is($j->{priority}, 3,      'task default beats queue default');
        is($j->{attempts}, 5,      'queue default fills the rest');

        $j = $q->job_info($q->enqueue('mail.send', [], priority => 9));
        is($j->{priority}, 9, 'explicit beats both');

        $j = $q->job_info($q->enqueue('other', [], queue => 'mail'));
        is($j->{attempts}, 5, 'queue defaults apply without task defaults');

        is_deeply($q->queue_defaults('mail'),
                  { attempts => 5, priority => 2 }, 'reader form');
    };

    subtest "$name: claim order" => sub {
        my $q = $make->();
        my $low  = $q->enqueue('t' => ['low'],  priority => 0);
        my $high = $q->enqueue('t' => ['high'], priority => 10);
        my $mid  = $q->enqueue('t' => ['mid'],  priority => 5);
        my $low2 = $q->enqueue('t' => ['low2'], priority => 0);
        my @got;
        while (my $j = $q->dequeue) { push @got, $j->id }
        is_deeply(\@got, [$high, $mid, $low, $low2],
                  'priority DESC, then FIFO within a priority');
    };

    subtest "$name: claim effects" => sub {
        my $q = $make->();
        my $id = $q->enqueue('t');
        my $job = $q->dequeue(worker => 42);
        is($job->id, $id, 'claimed');
        is($job->state, 'active', 'job reads active');
        my $j = $q->job_info($id);
        is($j->{state},  'active', 'row reads active');
        is($j->{worker}, 42,       'worker stamped');
        ok($j->{started} > 0,      'started set');
        ok(!defined $q->dequeue,   'not claimable twice');
    };

    subtest "$name: claim predicate" => sub {
        my $q = $make->();
        ok(!defined $q->dequeue, 'empty queue returns undef');

        my $late = $q->enqueue('t', [], delay => 3600);
        ok(!defined $q->dequeue, 'a delayed job is not claimed early');
        $q->dbh->do(
            'UPDATE pq_jobs SET delayed = delayed - 7200 WHERE id = ?',
            undef, $late);
        ok($q->dequeue, 'and is claimed once due');

        my $exp = $q->enqueue('t', [], expire => 3600);
        $q->dbh->do(
            'UPDATE pq_jobs SET expires = expires - 7200 WHERE id = ?',
            undef, $exp);
        ok(!defined $q->dequeue, 'an expired job is never claimed');

        my $dep = $q->enqueue('t');
        $q->dbh->do(
            'UPDATE pq_jobs SET parents_left = 1 WHERE id = ?', undef, $dep);
        ok(!defined $q->dequeue, 'unfinished parents block');
        $q->dbh->do(
            'UPDATE pq_jobs SET parents_left = 0 WHERE id = ?', undef, $dep);
        ok($q->dequeue, 'and unblock');
    };

    subtest "$name: queue and task selection" => sub {
        my $q = $make->();
        my $d = $q->enqueue('alpha');
        my $m = $q->enqueue('beta', [], queue => 'mail');
        ok(!defined $q->dequeue(queues => ['sms']), 'unwatched queue ignored');
        is($q->dequeue(queues => ['mail'])->id, $m, 'named queue claimed');
        is($q->dequeue(queues => 'default', tasks => ['alpha'])->id, $d,
           'task filter and bare-string queue');
    };

    subtest "$name: perform" => sub {
        my $q = $make->();
        $q->task(add => sub { my ($job, $a, $b) = @_; $a + $b });
        my $id = $q->enqueue(add => [2, 3]);
        ok($q->perform($q->dequeue), 'success');
        my $j = $q->job_info($id);
        is($j->{state},  'finished', 'finished');
        is($j->{result}, 5,          'result recorded');
        ok($j->{finished} > 0,       'finished stamped');
    };

    subtest "$name: perform failure paths" => sub {
        my $q = $make->();
        $q->task(boom => sub { die "went wrong\n" });
        my $id = $q->enqueue('boom');
        ok(!$q->perform($q->dequeue), 'a die reports failure');
        like($q->job_info($id)->{result}, qr/went wrong/, 'message kept');

        my $u = $q->enqueue('nobody.registered.this');
        my $ok = eval { $q->perform($q->dequeue); 1 };
        ok($ok, 'unknown task does not kill the process');
        like($q->job_info($u)->{result}, qr/no task registered/,
             'and the job says why');
    };

    subtest "$name: retries guard" => sub {
        my $q = $make->();
        my $id = $q->enqueue('t');
        $q->dequeue;
        $q->dbh->do(
            'UPDATE pq_jobs SET retries = retries + 1 WHERE id = ?',
            undef, $id);
        is($q->finish_job($id, 0, 'stale'), 0, 'stale retries rejected');
        is($q->job_info($id)->{state}, 'active', 'row untouched');
        is($q->finish_job($id, 1, 'fresh'), 1, 'current retries accepted');
        is($q->job_info($id)->{state}, 'finished', 'row settled');
    };

    subtest "$name: settle requires active" => sub {
        my $q = $make->();
        my $id = $q->enqueue('t');
        is($q->finish_job($id, 0, 'x'), 0, 'inactive cannot be finished');
        is($q->fail_job($id, 0, 'x'),   0, 'nor failed');
        is($q->job_info($id)->{state}, 'inactive', 'still inactive');
    };

    subtest "$name: job object surface" => sub {
        my $q = $make->();
        my %seen;
        $q->task(inspect => sub {
            my ($job, @args) = @_;
            %seen = (id => $job->id, task => $job->task,
                     queue => $job->queue, retries => $job->retries,
                     attempts => $job->attempts, priority => $job->priority,
                     args => $job->args, notes => $job->notes,
                     passed => \@args);
            1;
        });
        my $id = $q->enqueue(inspect => ['x'], queue => 'mail',
                             priority => 3, attempts => 4,
                             notes => { a => 1 });
        $q->perform($q->dequeue(queues => 'mail'));
        is($seen{id}, $id, 'id');
        is($seen{task}, 'inspect', 'task');
        is($seen{queue}, 'mail', 'queue');
        is($seen{attempts}, 4, 'attempts');
        is($seen{priority}, 3, 'priority');
        is_deeply($seen{passed}, ['x'], 'args passed to the body');
        is_deeply($seen{notes}, { a => 1 }, 'notes');
    };

    subtest "$name: self-settling body" => sub {
        my $q = $make->();
        $q->task(early => sub {
            my ($job) = @_;
            $job->finish({ done => 'by hand' });
            'ignored';
        });
        my $id = $q->enqueue('early');
        $q->perform($q->dequeue);
        is_deeply($q->job_info($id)->{result}, { done => 'by hand' },
                  'the explicit settle stood');
    };

    subtest "$name: retry" => sub {
        my $q = $make->();
        $q->task(boom => sub { die "no\n" });
        my $id = $q->enqueue('boom');
        $q->perform($q->dequeue);
        is($q->job_info($id)->{state}, 'failed', 'failed once');

        ok($q->retry_job($id, 0), 'retry from failed');
        my $j = $q->job_info($id);
        is($j->{state},   'inactive', 'inactive again');
        is($j->{retries}, 1,          'retries bumped');
        ok(!defined $j->{started},    'started cleared');
        ok(!defined $j->{result},     'result cleared');
        ok($j->{retried} > 0,         'retried stamped');

        ok(!$q->retry_job($id, 0), 'a stale retries count is rejected');

        ok($q->retry_job($id, 1, { delay => 3600, priority => 9,
                                   queue => 'later', attempts => 7 }),
           'retry with overrides');
        $j = $q->job_info($id);
        is($j->{priority}, 9,       'priority override');
        is($j->{queue},    'later', 'queue override');
        is($j->{attempts}, 7,       'attempts override');
        ok($j->{delayed} - $j->{retried} >= 3599, 'delay override');

        # retrying an ACTIVE job is the recover-a-stuck-worker move: the
        # bump invalidates the running attempt's guard
        my $id2 = $q->enqueue('boom');
        $q->dequeue;
        ok($q->retry_job($id2, 0), 'retry from active');
        is($q->finish_job($id2, 0, 'stale'), 0,
           'and the stale attempt can no longer settle it');
    };

    subtest "$name: remove" => sub {
        my $q = $make->();
        $q->task(ok => sub { 1 });

        my $i1 = $q->enqueue('ok');
        ok($q->remove_job($i1), 'remove inactive');
        ok(!defined $q->job_info($i1), 'gone');

        my $i2 = $q->enqueue('ok');
        $q->dequeue;
        ok(!$q->remove_job($i2), 'an active job is refused');
        ok($q->job_info($i2), 'and still there');

        $q->finish_job($i2, 0, 'done');
        ok($q->remove_job($i2), 'remove finished');
        ok(!$q->remove_job(999999), 'no such id is false, not fatal');
    };

    subtest "$name: worker registry" => sub {
        my $q = $make->();
        my $b = $q->backend;

        my $id = $b->register_worker(0, { role => 'child',
                                          queues => ['default', 'mail'] });
        ok($id > 0, 'registered');

        my $list = $q->list_workers;
        is($list->{total}, 1, 'listed');
        my ($w) = @{ $list->{workers} };
        is($w->{id},   $id,     'id');
        is($w->{pid},  $$,      'pid');
        is($w->{role}, 'child', 'role');
        is_deeply($w->{queues}, ['default', 'mail'], 'queues decoded');
        ok($w->{started} > 0 && $w->{notified} > 0, 'timestamps');

        is($b->register_worker($id), $id, 'refresh keeps the id');
        ok($b->worker_heartbeat($id, { current => 42 }), 'heartbeat');
        my ($w2) = @{ $q->list_workers->{workers} };
        ok($w2->{notified} >= $w->{notified}, 'notified advanced');
        is_deeply($w2->{status}, { current => 42 }, 'status stored');

        ok($b->unregister_worker($id), 'unregistered');
        is($q->list_workers->{total}, 0, 'gone');

        my $sup = $b->register_worker(0, { role => 'supervisor',
                                           jobs => 0 });
        is($q->list_workers(0, 0, { role => 'supervisor' })->{total}, 1,
           'role filter');
        $b->unregister_worker($sup);
    };

    subtest "$name: list_jobs" => sub {
        my $q = $make->();
        $q->task(ok => sub { 1 });
        my @ids;
        push @ids, $q->enqueue('ok', [], queue => 'a') for 1 .. 3;
        push @ids, $q->enqueue('other', [], queue => 'b') for 1 .. 2;
        $q->perform($q->dequeue(queues => 'a'));   # one finished

        my $all = $q->list_jobs;
        is($all->{total}, 5, 'total');
        is(scalar @{ $all->{jobs} }, 5, 'rows');
        is($all->{jobs}[0]{id}, $ids[-1], 'newest first');

        is($q->list_jobs(0, 0, { queue => 'a' })->{total}, 3,
           'queue filter');
        is($q->list_jobs(0, 0, { task => 'other' })->{total}, 2,
           'task filter');
        is($q->list_jobs(0, 0, { state => 'finished' })->{total}, 1,
           'state filter');
        is($q->list_jobs(0, 0, { queue => 'a', state => 'inactive' })
              ->{total}, 2, 'filters combine');

        my $page = $q->list_jobs(1, 2);
        is(scalar @{ $page->{jobs} }, 2, 'limit');
        is($page->{total}, 5, 'total unaffected by paging');
        is($page->{jobs}[0]{id}, $ids[-2], 'offset');
    };

    subtest "$name: list search" => sub {
        my $q = $make->();
        $q->enqueue('mail.send',   [], queue => 'outbound');
        $q->enqueue('mail.digest', [], queue => 'outbound');
        $q->enqueue('report_100pct', [], queue => 'analytics');

        is($q->list_jobs(0, 0, { search => 'mail' })->{total}, 2,
           'substring across tasks');
        is($q->list_jobs(0, 0, { search => 'MAIL' })->{total}, 2,
           'case-insensitive on both backends');
        is($q->list_jobs(0, 0, { search => 'outbound' })->{total}, 2,
           'matches the queue column too');
        is($q->list_jobs(0, 0, { search => 'inactive' })->{total}, 3,
           'and the state column');
        is($q->list_jobs(0, 0, { search => 'digest', queue => 'outbound' })
              ->{total}, 1, 'search combines with exact filters');
        is($q->list_jobs(0, 0, { search => 'zzz-nothing' })->{total}, 0,
           'a miss is empty, not an error');

        # LIKE metacharacters are data, not wildcards
        is($q->list_jobs(0, 0, { search => '100pct' })->{total}, 1,
           'the literal-token control matches');
        is($q->list_jobs(0, 0, { search => '100%' })->{total}, 0,
           'a percent is literal - it matches nothing here');
        is($q->list_jobs(0, 0, { search => 'report_1' })->{total}, 1,
           'an underscore is literal too');
        is($q->list_jobs(0, 0, { search => 'reportX1' })->{total}, 0,
           'and does not wildcard a single character');

        # a numeric term reaches the id through the text cast
        my $id = $q->enqueue('findme');
        is($q->list_jobs(0, 0, { search => "$id" })->{jobs}[0]{task},
           'findme', 'searching an id finds the job');

        my $w = $q->backend->register_worker(0, { role => 'supervisor' });
        is($q->list_workers(0, 0, { search => 'superv' })->{total}, 1,
           'workers search by role substring');
        is($q->list_workers(0, 0, { search => 'zzz' })->{total}, 0,
           'workers search misses cleanly');
        $q->backend->unregister_worker($w);

        $q->lock('nightly-report', 60);
        is($q->list_locks(0, 0, { search => 'NIGHT' })->{total}, 1,
           'locks search by name, case-folded');
        is($q->list_locks(0, 0, { search => 'zzz' })->{total}, 0,
           'locks search misses cleanly');
    };

    subtest "$name: stats" => sub {
        my $q = $make->();
        $q->task(ok => sub { 1 });
        $q->task(boom => sub { die "x\n" });
        $q->enqueue('ok');
        $q->enqueue('ok', [], delay => 3600);
        $q->enqueue('boom');
        $q->perform($q->dequeue) for 1 .. 2;   # one ok, one boom
        $q->dequeue;                            # none ready (delayed)

        my $s = $q->stats;
        is($s->{finished_jobs}, 1, 'finished');
        is($s->{failed_jobs},   1, 'failed');
        is($s->{inactive_jobs}, 1, 'inactive');
        is($s->{active_jobs},   0, 'active');
        is($s->{delayed_jobs},  1, 'delayed');
        is($s->{total_jobs},    3, 'total');
        ok($s->{schema_version} > 0, 'schema version');
    };

    subtest "$name: reset" => sub {
        my $q = $make->();
        $q->enqueue('t');
        $q->backend->register_worker(0, {});
        my $v = $q->schema_version;
        $q->reset;
        is($q->stats->{total_jobs}, 0, 'jobs gone');
        is($q->list_workers->{total}, 0, 'workers gone');
        is($q->schema_version, $v, 'the schema itself survives');
    };

    subtest "$name: locks - the lease" => sub {
        my $q = $make->();
        ok($q->lock('leader', 60, owner => 1), 'acquired');
        ok(!$q->lock('leader', 60, owner => 2), 'a second holder is refused');
        ok($q->renew_lock('leader', 1, 60), 'the holder renews');
        ok(!$q->renew_lock('leader', 2, 60), 'a non-holder cannot renew');

        # expiry honoured on read, before any repair sweeps it
        $q->dbh->do('UPDATE pq_locks SET expires = ? WHERE name = ?',
                    undef, time - 10, 'leader');
        ok(!$q->renew_lock('leader', 1, 60),
           'an expired lease cannot be renewed - it was LOST');
        ok($q->lock('leader', 60, owner => 2),
           'and is acquirable by the next candidate');

        ok($q->unlock('leader', 2), 'released by owner');
        ok(!$q->unlock('leader', 2), 'releasing twice is false');
    };

    subtest "$name: locks - counted" => sub {
        my $q = $make->();
        ok($q->lock('slots', 60, limit => 3), "hold $_") for 1 .. 3;
        ok(!$q->lock('slots', 60, limit => 3), 'the limit refuses a fourth');

        ok($q->unlock('slots'), 'one released');
        ok($q->lock('slots', 60, limit => 3), 'and the slot is reusable');

        # expired holds do not count
        $q->dbh->do('UPDATE pq_locks SET expires = ? WHERE name = ?',
                    undef, time - 10, 'slots');
        ok($q->lock('slots', 60, limit => 3), 'expired holds free slots');

        is($q->list_locks(0, 0, { name => 'slots' })->{total}, 4,
           'list_locks sees the rows (expired ones await repair)');
    };

    subtest "$name: broadcast and receive" => sub {
        my $q = $make->();
        my $b = $q->backend;
        my $w1 = $b->register_worker(0, {});
        my $w2 = $b->register_worker(0, {});

        is($q->broadcast('stop'), 2, 'broadcast reaches every worker');
        is($q->broadcast('jobs', [4], [$w1]), 1, 'or a named set');

        my $got = $b->receive($w1);
        is_deeply($got, [['stop'], ['jobs', 4]],
                  'commands arrive in order with their arguments');
        is_deeply($b->receive($w1), [], 'and the drain is a drain');
        is_deeply($b->receive($w2), [['stop']],
                  'the other worker has its own inbox');

        # atomicity: a command queued between read and clear must survive -
        # simulated by two broadcasts then one receive seeing both
        $q->broadcast('a', [], [$w1]);
        $q->broadcast('b', [], [$w1]);
        is_deeply($b->receive($w1), [['a'], ['b']], 'nothing lost');

        $b->unregister_worker($_) for $w1, $w2;
    };

    subtest "$name: repair - the passes" => sub {
        my $q = $make->(missing_after => 60, remove_after => 3600);
        my $b = $q->backend;
        my $now = $b->now;

        # 1+2: a stale worker holding an active job
        my $dead = $b->register_worker(0, {});
        my $stuck = $q->enqueue('t');
        $q->dequeue(worker => $dead);
        $q->dbh->do('UPDATE pq_workers SET notified = ? WHERE id = ?',
                    undef, $now - 120, $dead);

        # 3: an expired inactive job
        my $exp = $q->enqueue('t', [], queue => 'other', expire => 1);
        $q->dbh->do('UPDATE pq_jobs SET expires = ? WHERE id = ?',
                    undef, $now - 10, $exp);

        # 4: an ancient finished job
        my $old = $q->enqueue('t', [], queue => 'other2');
        $q->dequeue(queues => 'other2');
        $q->finish_job($old, 0, 'done');
        $q->dbh->do('UPDATE pq_jobs SET finished = ? WHERE id = ?',
                    undef, $now - 7200, $old);

        # 5: a strict child of a terminally failed parent, plus a lax
        # grandchild that must unblock when the child fails
        $q->task(boom => sub { die "x\n" });
        my $p  = $q->enqueue('boom', [], queue => 'dep', attempts => 1);
        my $c  = $q->enqueue('t', [], parents => [$p]);
        my $gc = $q->enqueue('t', [], parents => [$c], lax => 1);
        $q->perform($q->dequeue(queues => 'dep'));

        # 6: a stale lock
        $q->lock('stale', 1);
        $q->dbh->do('UPDATE pq_locks SET expires = ? WHERE name = ?',
                    undef, $now - 10, 'stale');

        # 7: a log row whose job was deleted behind the queue's back
        $q->dbh->do('INSERT INTO pq_job_logs'
                  . ' (job_id, created, level, message)'
                  . ' VALUES (999999, ?, ?, ?)',
                    undef, $now, 'info', 'orphaned');

        my $r = $q->repair;
        is($r->{stale_workers},     1, 'pass 1: stale worker swept');
        is($r->{orphaned_jobs},     1, 'pass 2: its job requeued');
        is($r->{expired_jobs},      1, 'pass 3: expired job deleted');
        is($r->{ancient_jobs},      1, 'pass 4: ancient job deleted');
        is($r->{stranded_children}, 1, 'pass 5: stranded child failed');
        is($r->{stale_locks},       1, 'pass 6: stale lock deleted');
        is($r->{orphaned_logs},     1, 'pass 7: orphaned log line swept');

        # the effects, not just the counts
        my $j = $q->job_info($stuck);
        is($j->{state},   'inactive', 'requeued job is claimable again');
        is($j->{retries}, 1, 'with the guard-invalidating bump');
        ok(!defined $q->job_info($exp), 'expired gone');
        ok(!defined $q->job_info($old), 'ancient gone');
        like($q->job_info($c)->{result}, qr/parent.*failed/,
             'the stranded child says why it failed');
        is($q->job_info($gc)->{parents_left}, 0,
           'and its lax child unblocked in the same repair');
        _counters_ok($q, "$name: after repair");

        # a second repair on the now-healthy queue does nothing
        my $r2 = $q->repair;
        is($r2->{$_}, 0, "second pass: $_ untouched") for sort keys %$r2;
    };

    subtest "$name: repair - healthy queue row-by-row no-op" => sub {
        my $q = $make->();
        $q->task(ok => sub { 1 });
        my $w = $q->backend->register_worker(0, {});
        $q->enqueue('ok', [], notes => { keep => 1 });
        my $p = $q->enqueue('ok');
        $q->enqueue('ok', [], parents => [$p], delay => 60);
        $q->perform($q->dequeue(worker => $w));
        $q->lock('live', 3600);

        my $before = {
            jobs    => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_jobs ORDER BY id'),
            deps    => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_job_deps ORDER BY job_id'),
            workers => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_workers ORDER BY id'),
            locks   => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_locks ORDER BY id'),
            logs    => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_job_logs ORDER BY id'),
        };
        my $r = $q->repair(deep => 1);
        my $after = {
            jobs    => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_jobs ORDER BY id'),
            deps    => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_job_deps ORDER BY job_id'),
            workers => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_workers ORDER BY id'),
            locks   => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_locks ORDER BY id'),
            logs    => $q->dbh->selectall_arrayref(
                           'SELECT * FROM pq_job_logs ORDER BY id'),
        };
        is_deeply($after, $before,
                  'repair --deep left a healthy queue byte-identical');
        is($r->{$_}, 0, "$_ reported 0") for sort keys %$r;
        $q->backend->unregister_worker($w);
    };

    subtest "$name: repair - drift then --deep" => sub {
        my $q = $make->();
        my $p = $q->enqueue('t');
        my $c = $q->enqueue('t', [], parents => [$p]);

        # corrupt the counter directly - the drift no transition should
        # ever produce, planted to prove the backstop recomputes it
        $q->dbh->do('UPDATE pq_jobs SET parents_left = 5 WHERE id = ?',
                    undef, $c);

        my $r = $q->repair;
        is($q->job_info($c)->{parents_left}, 5,
           'a plain repair does not touch counters');
        $r = $q->repair(deep => 1);
        is($r->{recomputed_counters}, 1, '--deep found exactly the one');
        is($q->job_info($c)->{parents_left}, 1, 'and restored the truth');
        _counters_ok($q, "$name: after deep repair");
    };

    subtest "$name: history" => sub {
        my $q = $make->();
        $q->task(ok => sub { 1 });
        $q->task(boom => sub { die "x\n" });
        $q->enqueue('ok');
        $q->enqueue('ok');
        $q->enqueue('boom', [], attempts => 1);
        $q->perform($q->dequeue) for 1 .. 3;

        my $h = $q->history;
        is(ref $h->{hourly}, 'ARRAY', 'hourly series');
        is(ref $h->{daily},  'ARRAY', 'daily series');
        my ($bucket) = @{ $h->{hourly} };
        ok($bucket, 'the current hour has a bucket');
        is($bucket->{finished}, 2, 'finished counted');
        is($bucket->{failed},   1, 'failed counted');
        is($bucket->{epoch} % 3600, 0, 'hourly buckets align to the hour');

        my $s = $q->stats;
        is($s->{active_workers}, 0, 'stats: no live workers');
        ok($s->{enqueued_jobs} >= 3, 'stats: lifetime enqueue count');
        is($s->{queues}{default}{finished}, 2, 'stats: per-queue counts');
        is($s->{queues}{default}{failed},   1, 'stats: per-queue failed');
        is($s->{tasks}{ok}{finished},   2, 'stats: per-task counts');
        is($s->{tasks}{boom}{failed},   1, 'stats: per-task failed');
        ok(!exists $s->{tasks}{boom}{finished},
           'stats: absent states are absent, not zero');
    };

    # ---- cron storage and the tick (phase 9) -------------------------------
    #
    # The scheduler's leader election and process story live in t/81-82;
    # what belongs here is the storage contract and the tick, which must
    # behave identically on both backends.

    subtest "$name: cron upsert" => sub {
        my $q = $make->();
        $q->upsert_cron({ name => 'nightly', expr => '0 3 * * *',
                          task => 'report', args => [7],
                          queue => 'mail', priority => 2, attempts => 3 });
        my $c = $q->cron_info('nightly');
        is($c->{expr},  '0 3 * * *', 'expr');
        is($c->{task},  'report',    'task');
        is_deeply($c->{args}, [7],   'args');
        is($c->{queue}, 'mail',      'queue');
        is($c->{tz},    'UTC',       'tz defaults to UTC');
        is($c->{catchup}, 'once',    'catchup defaults to once');
        ok($c->{enabled}, 'enabled');
        ok(!defined $c->{last_run}, 'never ran');
        ok($c->{next_run} > time - 60, 'next_run is ahead');
        my @gm = gmtime $c->{next_run};
        is($gm[2], 3, 'next_run lands on the 03:00 UTC boundary');
        is($gm[1], 0, 'minute-aligned');

        my $before = $c->{next_run};
        $q->upsert_cron({ name => 'nightly', expr => '0 3 * * *',
                          task => 'report', args => [7],
                          queue => 'mail', priority => 2, attempts => 3 });
        is($q->cron_info('nightly')->{next_run}, $before,
           'an identical upsert never moves the schedule');
        is($q->list_crons->{total}, 1, 'and never duplicates');

        $q->upsert_cron({ name => 'nightly', expr => '0 3 * * *',
                          task => 'report', priority => 9 });
        my $c2 = $q->cron_info('nightly');
        is($c2->{priority}, 9, 'defaults update in place');
        is($c2->{next_run}, $before,
           'a defaults-only change never moves the schedule');

        $q->upsert_cron({ name => 'nightly', expr => '0 4 * * *',
                          task => 'report' });
        my $c3 = $q->cron_info('nightly');
        is((gmtime $c3->{next_run})[2], 4,
           'an expr change recomputes next_run');

        ok(!defined $q->cron_info('missing'), 'cron_info misses cleanly');
        my $bad = eval {
            $q->upsert_cron({ name => 'x', expr => '0 3 30 2 *',
                              task => 't' });
            1;
        };
        ok(!$bad, 'an unmatchable expression is rejected at upsert');
        like($@, qr/can never fire/, 'with the parser message');
    };

    subtest "$name: cron enable and disable" => sub {
        my $q = $make->();
        $q->upsert_cron({ name => 'n1', expr => '*/5 * * * *',
                          task => 't' });
        ok($q->enable_cron('n1', 0), 'disable');
        ok(!$q->cron_info('n1')->{enabled}, 'disabled');

        # boot reconciliation must never undo an operator's pause
        $q->upsert_cron({ name => 'n1', expr => '*/5 * * * *',
                          task => 't' });
        ok(!$q->cron_info('n1')->{enabled},
           'an upsert never resets enabled');

        $q->dbh->do('UPDATE pq_crons SET next_run = 0 WHERE name = ?',
                    undef, 'n1');
        ok($q->enable_cron('n1', 1), 're-enable');
        my $c = $q->cron_info('n1');
        ok($c->{enabled}, 'enabled again');
        ok($c->{next_run} > time - 60,
           're-enabling recomputes next_run from now - the paused window '
         . 'is not a backlog');

        ok(!$q->enable_cron('missing', 1), 'enabling a missing cron is false');
    };

    subtest "$name: disable_missing_crons" => sub {
        my $q = $make->();
        $q->upsert_cron({ name => $_, expr => '0 3 * * *', task => 't' })
            for qw(keep drop1 drop2);
        is($q->disable_missing_crons(['keep']), 2, 'two disabled');
        ok($q->cron_info('keep')->{enabled},   'the declared one stays');
        ok(!$q->cron_info('drop1')->{enabled}, 'the undeclared ones pause');
        ok(!$q->cron_info('drop2')->{enabled}, 'both of them');
        is($q->list_crons->{total}, 3,
           'nothing was deleted - history survives removal');
        is($q->disable_missing_crons(['keep']), 0, 'and it is idempotent');
    };

    subtest "$name: cron tick fires exactly once" => sub {
        my $q = $make->();
        my $b = $q->backend;
        $q->upsert_cron({ name => 'minutely', expr => '* * * * *',
                          task => 'tick.task', args => ['x'],
                          queue => 'crons', priority => 4 });

        # a fresh occurrence: the last minute boundary is due, less than
        # a minute stale, and - the next boundary still being ahead -
        # the only one. (Unaligned "now - 10" would sometimes put TWO
        # occurrences in the past.) Step over the boundary first if it
        # is about to move under us.
        sleep 61 - time % 60 if time % 60 > 55;
        my $occ = int(time / 60) * 60;
        $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                    undef, $occ, 'minutely');
        is($b->_cron_tick, 1, 'one job fired');
        my $c = $q->cron_info('minutely');
        is($c->{last_run}, $occ, 'last_run records the occurrence');
        ok($c->{next_run} > time, 'next_run advanced past now');
        ok($c->{last_job}, 'last_job recorded');
        my $j = $q->job_info($c->{last_job});
        is($j->{task},  'tick.task', 'the job is the cron task');
        is($j->{queue}, 'crons',     'on the cron queue');
        is($j->{priority}, 4,        'at the cron priority');
        is_deeply($j->{args}, ['x'], 'with the cron args');

        is($b->_cron_tick, 0, 'a second tick has nothing to do');

        # rewind the schedule to a fired occurrence: the per-occurrence
        # dedupe key makes even a leader that beats the optimistic guard
        # at-most-once
        $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                    undef, $occ, 'minutely');
        $b->_cron_tick;
        is($q->list_jobs(0, 0, { task => 'tick.task' })->{total}, 1,
           'a rewound occurrence dedupes to the same job');

        # disabled crons never fire
        $q->enable_cron('minutely', 0);
        $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                    undef, $occ, 'minutely');
        is($b->_cron_tick, 0, 'a disabled cron does not fire');
    };

    subtest "$name: cron catch-up policies" => sub {
        my $q = $make->();
        my $b = $q->backend;
        my $behind = int(time) - 600;      # ten missed minutes

        $q->upsert_cron({ name => 'c.once', expr => '* * * * *',
                          task => 'c.once' });
        $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                    undef, $behind, 'c.once');
        is($b->_cron_tick, 1, 'once: fires the oldest missed occurrence');
        ok($q->cron_info('c.once')->{next_run} > time,
           'once: then jumps to the future');

        $q->backend->{opts}{catchup_max} = 3;
        $q->upsert_cron({ name => 'c.all', expr => '* * * * *',
                          task => 'c.all', catchup => 'all' });
        $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                    undef, $behind, 'c.all');
        is($b->_cron_tick, 3, 'all: fires up to catchup_max');
        ok($q->cron_info('c.all')->{next_run} > time,
           'all: then jumps to the future');
        is($q->list_jobs(0, 0, { task => 'c.all' })->{total}, 3,
           'all: three distinct occurrence jobs');
        delete $q->backend->{opts}{catchup_max};

        $q->upsert_cron({ name => 'c.skip', expr => '* * * * *',
                          task => 'c.skip', catchup => 'skip' });
        $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                    undef, $behind, 'c.skip');
        is($b->_cron_tick, 0, 'skip: a stale occurrence never fires');
        my $cs = $q->cron_info('c.skip');
        ok($cs->{next_run} > time, 'skip: jumped to the future');
        ok(!defined $cs->{last_run}, 'skip: nothing ran, last_run stays');

        sleep 61 - time % 60 if time % 60 > 55;
        $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                    undef, int(time / 60) * 60, 'c.skip');
        is($b->_cron_tick, 1, 'skip: a fresh occurrence still fires');
    };

    subtest "$name: cron tick disables a corrupt expression" => sub {
        my $q = $make->();
        my $b = $q->backend;
        $q->upsert_cron({ name => 'rotten', expr => '* * * * *',
                          task => 't' });
        # corrupt it behind the parser's back - the DB is not trusted
        $q->dbh->do('UPDATE pq_crons SET expr = ?, next_run = ?'
                  . ' WHERE name = ?',
                    undef, 'not a cron', int(time) - 10, 'rotten');
        my @warned;
        my $fired = do {
            local $SIG{__WARN__} = sub { push @warned, @_ };
            $b->_cron_tick;
        };
        is($fired, 0, 'nothing fired');
        ok(!$q->cron_info('rotten')->{enabled},
           'the rotten cron disabled itself');
        like("@warned", qr/disabling/, 'and said so');
    };

    subtest "$name: notify is callable" => sub {
        my $q = $make->();
        my $id = $q->enqueue('t', [], queue => 'mail');
        my $ok = eval {
            $q->backend->can('notify')
                ? $q->backend->notify('mail', $id)
                : 1;
            1;
        };
        ok($ok, 'notify (or its absence) does not die') or diag $@;
    };

    return;
}

1;
