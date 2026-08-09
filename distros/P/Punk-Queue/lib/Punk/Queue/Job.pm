package Punk::Queue::Job;

use 5.010;
use strict;
use warnings;
use Punk::Queue ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Queue::Job - a claimed job

=head1 SYNOPSIS

    $q->task('report.build' => sub {
        my ($job, $year) = @_;

        warn "job ", $job->id, " on ", $job->queue;
        return { pages => build_report($year) };
    });

=head1 DESCRIPTION

What C<dequeue> returns and what a task body receives as its first
argument. A thin reader over the claimed row, plus the two methods that
settle it.

A job object is a blessed hashref rather than the IV-ref-to-a-struct
pattern used elsewhere in this ecosystem. That is deliberate: one is
constructed per job run, which already costs a database round trip, so the
allocation is noise - and a hashref needs no C<DESTROY>, cannot leak, and
can be subclassed by a hand-written runner. The IV-ref pattern earns its
keep on per-request objects; this is not one.

=head1 METHODS

=head2 id / task / queue / state / priority / retries / attempts

Fields of the claimed row.

C<retries> is the count so far and C<attempts> the maximum, so
C<< $job->retries + 1 == $job->attempts >> means this is the last try -
useful for a task that wants to escalate rather than fail quietly.

=head2 args

The decoded argument list as an arrayref. The same values are passed to the
task body directly, so a body rarely needs this.

=head2 notes

The decoded notes hashref.

=head2 note

    $job->note(pct => 50);
    $job->note(stale_key => undef);      # deletes the key

Merge into the job's notes - the progress mechanism. A key set to undef
is removed. The in-memory row is updated too, so C<< $job->notes >>
reflects the write without a re-read. Works while the job is active,
which is the point.

=head2 log

    $job->log('resizing image 3 of 10');
    $job->log(warn => 'thumbnail source missing, using placeholder');

Append a line to the job's persistent log, readable later via
C<< $q->job_log($id) >>, C<punk-queue job ID --log>, and the admin UI's
job page. One argument is an C<info> line; two make the first the level
(C<debug>, C<info>, C<warn> or C<error>). The queue writes the lifecycle
rows around these automatically - claim, finish, failures with their
retries - so a task only logs what the lifecycle cannot know. Always
writes, whatever the queue's C<logging> option says: a call the task
author typed is not lifecycle noise.

=head2 info

The whole row as a plain hashref, without a round trip.

=head2 queue_object

The L<Punk::Queue> this job was claimed from.

=head2 finish

    $job->finish;
    $job->finish($result);

Record the job as finished. Returns true when the transition applied. A
task body does not need to call this: returning a value from the body does
it, with the return value as the result.

=head2 fail

    $job->fail($error);

Record the job as failed. As with C<finish>, a body can simply die
instead.

Both carry the row's retry count as an optimistic guard, so a job that was
requeued while this worker was busy cannot be settled by the stale attempt.

=head1 SEE ALSO

L<Punk::Queue>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
