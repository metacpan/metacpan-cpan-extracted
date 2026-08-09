package Punk::Queue::Worker;

use 5.010;
use strict;
use warnings;
use Punk::Queue ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Queue::Worker - a worker child

=head1 SYNOPSIS

    my $q = Punk::Queue->new(dsn => ...);
    $q->task(add => sub { my ($job, $a, $b) = @_; $a + $b });

    $q->worker(queues => ['default', 'mail'])->run;

    # or, supervised:
    #   punk-queue worker -q default,mail -j 4 --app app.pl

=head1 DESCRIPTION

One claiming process: register a worker row, claim jobs, run them,
heartbeat, exit cleanly on TERM or INT. Exactly one job is in flight at a
time - the concurrency knob is the supervisor's C<-j> (one process, one
row, per unit of concurrency), not per-child parallelism.

=head2 The two execution paths

With L<Hyperman> installed, the worker builds a private event loop and
runs jobs from inside it. That is not a performance feature; it is what
puts a live loop under the task body, so a L<Punk::Future> (or anything
loop-aware) the task creates awaits in loop mode - and because the
worker's own heartbeat shares the loop, a task that awaits keeps the
worker's timers firing.

Without Hyperman - or with C<PUNK_QUEUE_NO_HM_ABI=1>, the test seam - the
worker sleeps in C<poll(2)> instead. Fully functional; task-created
futures fall back to block mode.

=head2 What a task can return

A plain value becomes the result. A die becomes the failure. A job whose
task name has no registered body fails with a clear message rather than
taking the worker down - a queue holding work this process does not know
is normal during a rolling deploy.

=head2 How an idle worker waits

On PostgreSQL, every enqueue emits a notification on its queue's channel
and the worker holds a second, dedicated C<LISTEN> connection - never the
work handle, whose socket carries claim traffic. A new job wakes the
worker in milliseconds however long the dequeue interval; the interval
(default 5 seconds, C<interval>) is only a backstop. The LISTEN
connection is monitored for the quiet death PostgreSQL actually
exhibits - the socket goes readable, C<pg_notifies> returns nothing, and
C<Active> still claims health - and is reconnected, re-subscribed and
re-watched automatically.

On SQLite there is nothing to listen to, so the worker polls with
decorrelated jitter: sleeps grow from 50ms toward a 1-second cap by a
randomised factor, so a pool of children does not hammer the file in
lockstep, and any claim resets the sleep to 50ms.

Either way the sleep is clamped to the delayed-job horizon - the time
until the next delayed job in the subscribed queues becomes claimable -
so a C<< delay => 3 >> job starts on time even under a long interval.

=head2 Environment

C<PUNK_QUEUE_ONESHOT=1> claims at most one job, runs it, and exits - how
the test suite drives a real worker without hanging. C<PUNK_QUEUE_NO_HM_ABI=1>
forces the poll path.

=head1 METHODS

=head2 run

Run until stopped. Returns the number of jobs performed. Options were
given at construction: C<queues>, C<tasks> (restrict to these task
names), C<interval> (idle claim interval, default 0.5s), C<heartbeat_interval>
(default 10s), C<max_jobs> (recycle after N jobs; 0 = unlimited - the
leak containment story for large app classes).

=head2 id

The worker row id this run registered, once running.

=head2 queue

The L<Punk::Queue> this worker claims from.

=head1 SEE ALSO

L<Punk::Queue>, L<Punk::Queue::Command>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
