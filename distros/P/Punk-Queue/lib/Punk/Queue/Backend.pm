package Punk::Queue::Backend;

use 5.010;
use strict;
use warnings;
use Punk::Queue ();

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Punk::Queue::Backend - the storage contract, and the shared implementation

=head1 SYNOPSIS

    package My::Backend;
    use parent 'Punk::Queue::Backend';   # optional

    sub dequeue { ... }                  # the parts you do differently

=head1 DESCRIPTION

A backend is any class implementing the contract below. There is no base
class you must inherit and no registry to enter: C<< Punk::Queue->new(dsn
=> ..., backend => '+My::Backend') >> is the whole integration.

What inheriting from this class buys you is every shared method for free -
enqueue, the terminal transitions, the migration runner, the clock probe -
implemented in C, leaving only the genuinely divergent parts to write.

=head1 THE CONTRACT

Twelve required methods. A class answering to these is a working backend.

    new(\%opts)                            -> $backend
    dbh                                    -> $dbh
    migrate($to?)                          -> $version
    enqueue($task, \@args, \%opts)         -> $id
    dequeue($worker_id, $timeout, \%opts)  -> \%job | undef
    finish_job($id, $retries, $result)     -> 0|1
    fail_job($id, $retries, $err)          -> 0|1
    retry_job($id, $retries, \%opts)       -> 0|1
    remove_job($id)                        -> 0|1
    job_info($id)                          -> \%info | undef
    register_worker($id?, \%opts)          -> $worker_id
    stats()                                -> \%stats

Optional groups are probed with C<can> and defaulted where a portable
default exists: listing (C<list_jobs>, C<list_workers>, C<list_locks>,
C<history>, C<note>), the worker registry (C<unregister_worker>,
C<broadcast>, C<receive>), locks (C<lock>, C<unlock>, C<renew_lock>), cron
(C<upsert_cron>, C<disable_missing_crons>, C<due_crons>, C<advance_cron>),
the job log (C<log_job>, C<job_log>) and housekeeping (C<repair>,
C<reset>, C<notify>).

Two signature details are load-bearing.

C<dequeue>'s C<$timeout> is "how long you may wait", and the backend owns
I<how> it waits. That is what lets PostgreSQL block on C<LISTEN> and SQLite
poll with a jittered backoff behind one signature, without the caller
knowing which it got.

C<finish_job>, C<fail_job> and C<retry_job> take C<$retries> and use it as
an optimistic guard. Repair requeues a vanished worker's job by bumping the
retry count, and without the guard that worker - which may still be alive
and about to report success - would clobber the new attempt.

=head1 METHODS

=head2 dbh

The pooled database handle for this backend's dsn, connected on first use
in this process.

=head2 migrate / schema_version / latest_version

The version the database is at, and the version this build knows how to
apply. C<latest_version> above C<schema_version> means a migration is
pending.

=head2 now / clock_delta

C<now> is the current time in the database's frame of reference: this
host's clock plus a delta probed once per connection.

Every timestamp this distribution binds comes from C<now>, never from the
local clock directly. Two hosts a minute apart is enough to claim a delayed
job early, and "the job ran an hour before its delay" is a baffling symptom
to debug from the inside.

=head2 has_returning

Whether the connection supports C<RETURNING> - PostgreSQL always, SQLite
from 3.35. When it does, an insert reads back its own id without a second
round trip.

=head2 enqueue / job_info / finish_job / fail_job / retry_job / remove_job

=head2 list_jobs / list_workers / stats / reset

As documented in L<Punk::Queue>, which delegates to them.

=head2 register_worker

    my $id = $backend->register_worker(0, { role => 'child',
                                            queues => \@queues });
    $backend->register_worker($id);      # refresh, keeping the id

One row per claiming process. A refresh whose row has been swept (by
repair) falls through to a fresh registration rather than failing.

=head2 unregister_worker

    $backend->unregister_worker($id);

=head2 worker_heartbeat

    $backend->worker_heartbeat($id, \%status);

Prove the worker is alive; C<%status> is stored as JSON for the admin UI,
and undef keeps whatever is there. From phase 6 this is also where the
broadcast inbox is drained.

=head1 SEE ALSO

L<Punk::Queue>, L<Punk::Queue::Backend::SQLite>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
