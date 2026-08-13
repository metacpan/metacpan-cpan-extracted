package Punk::Queue;

use 5.010;
use strict;
use warnings;
use XSLoader ();

our $VERSION = '0.03';

XSLoader::load(__PACKAGE__, $VERSION);

# The house bootstrap convention. No C ABI ships (decision 2026-08-07:
# the only would-be consumer is same-dist), but the flag is kept so the
# choice stays open without a re-release if that ever changes.
sub dl_load_flags { 0x01 }

1;

__END__

=head1 NAME

Punk::Queue - a job queue for Perl, with a C core

=head1 SYNOPSIS

    use Punk::Queue;

    my $q = Punk::Queue->new(dsn => 'dbi:SQLite:dbname=queue.db');
    $q->migrate;

    $q->task(add => sub {
        my ($job, $a, $b) = @_;
        return $a + $b;                 # becomes the job's result
    });

    my $id = $q->enqueue(add => [2, 3], priority => 5);

    # ... in a worker process
    my $job = $q->dequeue;
    $q->perform($job) if $job;

    my $info = $q->job_info($id);
    print "$info->{state}: $info->{result}\n";   # finished: 5

=head1 DESCRIPTION

A durable, multi-process job queue. Jobs are rows in a database, claimed
atomically by workers, run once, and recorded with their result.

The backend contract is Perl-visible but the implementations are C: SQL
assembly, bind vectors, positional row decode, the JSON codec (through
L<File::Raw::JSON>'s C ABI) and the claim state machine all live in the XS
tier. DBI is reached from C, so an enqueue is one C frame calling DBI
rather than three Perl frames doing it.

Two backends ship: SQLite, and (from phase 2) PostgreSQL. A third-party
backend is any class implementing the contract - there is no base class to
inherit and no registration to perform beyond naming it.

=head2 Every task must be idempotent

A job can run more than once. A worker can be killed between finishing the
work and recording it; a crashed worker's job is requeued by C<repair>; a
job that exceeds its timeout is killed by the supervisor, and the work it
started may still be in flight.

This is not a defect being apologised for - it is the guarantee an
at-least-once queue can actually keep, and every durable queue that claims
otherwise is either lying or much slower. Write tasks that can run twice
without harm.

=head1 METHODS

=head2 new

    my $q = Punk::Queue->new(dsn => 'dbi:SQLite:dbname=queue.db');
    my $q = Punk::Queue->new(dbh => $existing_handle);
    my $q = Punk::Queue->new(dsn => ..., backend => '+My::Backend');

Options: C<dsn>, C<user>, C<password>, C<attr> (a hashref merged into the
DBI connect attributes), C<dbh> (an existing handle, used as-is and never
pooled or reconnected), and C<backend> to override the class inferred from
the dsn. A leading C<+> on C<backend> means a literal class name.

Connections are pooled per dsn and per process. The pool carries the pid,
so a fork gets a fresh handle rather than a corrupted shared one - which
matters here more than in a web application, because forking is the worker
pool's whole design.

=head2 migrate

    my $version = $q->migrate;
    my $version = $q->migrate($to);

Bring the schema up to date, or to a specific version. Idempotent, safe to
call from every process at boot, and internally locked so two workers
starting together cannot race. Forward-only in this release.

=head2 schema_version

The version currently recorded in the database. Zero before the first
migration.

=head2 task

    $q->task(name => sub { my ($job, @args) = @_; ... });
    my $code = $q->task('name');

Register a task body, or look one up. Returns the queue when registering,
so calls chain. A body receives a L<Punk::Queue::Job> followed by the
job's arguments; its return value becomes the result, and a die becomes
the failure.

=head2 tasks

The registered task names.

=head2 enqueue

    my $id = $q->enqueue($task);
    my $id = $q->enqueue($task => \@args, %opts);

Options: C<queue> (default C<'default'>), C<priority> (higher runs first,
default 0), C<delay> (seconds before the job becomes claimable),
C<attempts> (default 1), C<expire> (seconds after which an unclaimed job is
abandoned), C<notes> (a hashref stored alongside the job), C<timeout>
(seconds a run may take - see L</"Timeouts">), C<parents> (an arrayref of
job ids this job waits for), C<lax> (a failed parent unblocks too),
C<unique> (a dedupe key: a second enqueue while a job with the same key is
inactive or active returns the existing id instead of inserting).

A parent id that no longer exists is treated as already done, so a chain
can be enqueued even after early members were removed by retention.
Duplicate parent ids count once.

=head2 Retries and backoff

A job whose task dies is retried while attempts remain, after a randomised
backoff: uniform between zero and C<attempts_delay * 2 ** retries>
seconds, capped at C<max_backoff> (constructor options, defaults 5 and
3600). Full jitter rather than plain doubling, because a burst of jobs
that all failed against the same downed dependency must not come back in
lockstep. The last error stays visible in C<result> while the job waits.
The final failure is terminal.

=head2 Timeouts

Three layers, honestly labelled:

An off-loop (no Hyperman) run wraps the task in C<alarm> with a dying
handler - best effort, since safe signals cannot interrupt a blocking C
call. An on-loop run arms a loop timer that fails a returned future
instead, so nothing ever dies across the event loop. Only the supervisor
is a guarantee: past C<timeout * 1.5 + 5> seconds it SIGKILLs the child
and records the job as failed itself.

Which is one of the reasons B<every task must be idempotent>: the killed
child's work may have partly happened.

=head2 queue_defaults / task_defaults

    $q->queue_defaults(mail => { attempts => 5, timeout => 30 });
    $q->task_defaults('mail.send' => { queue => 'mail' });

Defaults merged into enqueue options at a fixed precedence: explicit
options, then the task's defaults, then the queue's, then the built-ins.
The queue name resolves after the task defaults merge, so a task whose
defaults route it to a queue picks up that queue's defaults too.
Application configuration - it lives on this object, not in the database.

Task and queue names are validated on the way in: 1 to 64 characters of
C<[A-Za-z0-9_.:-]>. The rule is narrow on purpose - it is what makes the
PostgreSQL C<LISTEN> identifier assembly safe by construction rather than
by remembering to escape.

=head2 dequeue

    my $job = $q->dequeue;
    my $job = $q->dequeue(queues => ['default', 'mail'], worker => $id);

Claim the highest-priority ready job, or return undef. Returns a
L<Punk::Queue::Job>. Options: C<queues>, C<tasks> (restrict to these task
names), C<worker> (the worker id to stamp on the row).

The claim is atomic against other workers. A job is ready when it is
inactive, its delay has elapsed, it has no unfinished parents, and it has
not expired.

=head2 perform

    my $ok = $q->perform($job);

Run a claimed job: look up its task body, call it with the job and its
arguments, and record the outcome. True when the job finished, false when
it failed. A job whose task is not registered in this process fails with a
clear message rather than taking the process down - a queue holding work
for a task this worker does not know is normal during a rolling deploy.

=head2 job_info

    my $info = $q->job_info($id);

The job as a plain hashref, with C<args>, C<notes> and C<result> decoded.
Undef when there is no such job.

=head2 job_log

    for my $line (@{ $q->job_log($id) }) {
        printf "%s %-5s %s\n",
            scalar localtime $line->{created},
            $line->{level}, $line->{message};
    }

The job's log, oldest first: hashrefs of C<created> (epoch), C<level>
(C<debug>, C<info>, C<warn> or C<error>) and C<message>. Two writers feed
it - the queue logs the lifecycle (claimed with worker and attempt,
finished, an attempt failing with the retry it scheduled, terminal
failure, operator retry) and the task body writes through
C<< $job->log >>. The whole story survives retries, so inspecting a
finished or failed job shows every attempt. An unknown id is an empty
list, not an error.

Lifecycle rows can be shed on a throughput-sensitive queue with
C<< logging => 0 >> on the constructor; explicit C<< $job->log >> calls
write regardless. Log rows live and die with their job: C<remove_job>
and repair's retention sweep take them along, so retention is
C<remove_after>'s.

=head2 finish_job / fail_job

    $q->finish_job($id, $retries, $result);
    $q->fail_job($id, $retries, $error);

Settle a job directly. C<$retries> is an optimistic guard: the update
applies only if the row's retry count still matches, so a worker that was
presumed dead and had its job requeued cannot clobber the new attempt.
Returns true when the transition applied, false when the guard rejected it.
A false return is information, not an error - the caller lost a race it is
allowed to lose.

=head2 retry_job

    $q->retry_job($id, $retries, \%opts);

Requeue a job from any state - including C<active>, deliberately: the
retry bump invalidates the running attempt's optimistic guard, which is
exactly how a stuck job is recovered from the outside. Options: C<delay>,
C<priority>, C<queue>, C<attempts>.

=head2 remove_job

    $q->remove_job($id);

Delete a job. An active job is refused - retry it first (which strands
the running attempt), then remove.

=head2 list_jobs

    my $r = $q->list_jobs($offset, $limit, { state => 'failed' });
    # { jobs => [...], total => N }

Newest first. The filter vocabulary - C<id>, C<state>, C<queue>, C<task>,
C<worker> - is shared verbatim by C<punk-queue jobs> and the admin UI, so
there is one dialect to learn.

=head2 list_workers

    my $r = $q->list_workers($offset, $limit, { role => 'child' });

=head2 stats

    my $s = $q->stats;

Per-state job counts, the delayed subset, worker count, total, and the
schema version. C<queues> and C<tasks> hold the same per-state counts
broken down by queue and by task name -
C<< { name => { inactive => n, active => n, failed => n,
finished => n } } >> - with absent states absent rather than zero;
these feed the admin UI's overview tables.

=head2 reset

Empty every table except the schema version. The CLI gates this behind
C<--yes>; the method does not second-guess.

=head2 lock / renew_lock / unlock / list_locks

    $q->lock('leader', 30, owner => $worker_id)   or return;   # lease
    $q->lock('api-slots', 60, limit => 5)         or return;   # counted
    $q->renew_lock('leader', $worker_id, 30)      or die 'lease lost';
    $q->unlock('api-slots');

Two disciplines behind one call. With the default C<limit> of 1 a lock is
a I<lease>: an owned row arbitrated by a unique index, so contending
acquirers race an INSERT and exactly one wins - no counting anywhere.
C<renew_lock> returning false means the lease was B<lost> (expired, and
possibly taken); re-acquire, never assume. With a higher C<limit> it is a
counted lock in Minion's style: ownerless holds, released oldest-first by
C<unlock>. Expired holds stop counting immediately, before any repair
sweeps the rows.

=head2 broadcast

    $q->broadcast('stop');                    # every worker
    $q->broadcast('jobs', [4], [$id1, $id2]); # a named few

Append a command to workers' inboxes, drained on their heartbeat. C<stop>
(and its impatient spelling C<kill>) makes a worker exit after its
current job - a supervised worker is then respawned fresh, which makes
broadcast-stop the fleet-recycle button. A running job cannot be
interrupted from inside a single-threaded worker; the supervisor's
timeout kill is the mid-job tool.

=head2 repair

    my $counts = $q->repair;
    my $counts = $q->repair(deep => 1);

Fix what crashes leave behind: unregister workers silent past
C<missing_after> (constructor option, default 1800s), requeue their
orphaned active jobs with the guard-invalidating retries bump, delete
expired inactive jobs and terminal jobs older than C<remove_after>
(default 172800s), fail non-lax children of terminally failed parents
(with lax descendants unblocking through a whole chain), and sweep
expired locks. C<< deep => 1 >> additionally recomputes every dependency
counter from the deps table - the correctness backstop, off by default
because it is a full scan.

Every pass is predicated: repair on a healthy queue changes nothing, and
the returned hashref of per-pass counts says exactly what it did.

=head2 history

    my $h = $q->history;   # { hourly => [...], daily => [...] }

Finished-versus-failed counts, hourly over the last day and daily over
the last week, each bucket C<{ epoch, finished, failed }>, sparse and
ascending. History only reaches as far back as C<remove_after> keeps
terminal rows.

=head2 worker

    my $n = $q->worker(queues => ['mail'])->run;

A L<Punk::Queue::Worker> bound to this queue.

=head2 backend / dbh

The backend object, and its database handle.

=head1 SEE ALSO

L<Punk::Queue::Job>, L<Punk::Queue::Backend>,
L<Punk::Queue::Backend::SQLite>, L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-punk-queue at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Punk-Queue>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
