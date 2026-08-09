package Punk::Queue::Backend::Pg;

use 5.010;
use strict;
use warnings;
use Punk::Queue ();

our @ISA = ('Punk::Queue::Backend');
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Queue::Backend::Pg - the PostgreSQL backend

=head1 SYNOPSIS

    my $q = Punk::Queue->new(dsn => 'dbi:Pg:dbname=myapp');

=head1 DESCRIPTION

Selected automatically for a C<dbi:Pg:> dsn. Requires PostgreSQL 9.5 for
C<FOR UPDATE SKIP LOCKED>, which the claim depends on entirely.

This is the backend for a queue shared across machines. For a single host,
L<Punk::Queue::Backend::SQLite> needs no server.

=head2 How a job is claimed

One statement, on a connection with C<AutoCommit> on, so the claim is its
own transaction:

    UPDATE pq_jobs SET state = 'active', started = ?, worker = ?
     WHERE id = (SELECT id FROM pq_jobs
                  WHERE state = 'inactive' AND queue IN (...)
                    AND delayed <= ? AND parents_left = 0
                    AND (expires IS NULL OR expires > ?)
                  ORDER BY priority DESC, id
                  LIMIT 1 FOR UPDATE SKIP LOCKED)
       AND state = 'inactive'
    RETURNING ...

C<SKIP LOCKED> lets contending workers step over each other's in-flight
candidate rows rather than queueing behind them. That is what makes the
claim scale past one worker; without it every worker in the fleet
serialises on the same highest-priority row.

The redundant C<state = 'inactive'> on the outer update closes the
re-evaluation race between the subquery and the write. Minion omits it. A
silently duplicated job is the worst failure a queue has, and the guard
turns that possibility into a harmless miss for no measurable cost.

C<RETURNING> means the claim reads back its own row without a second round
trip.

=head2 Queue and task lists

The C<IN> lists are expanded to placeholders in C rather than passed as an
array with C<= ANY(?)>. Two reasons: the array literal needs PostgreSQL
quoting that has to be right for names containing commas or braces, and it
does not port to SQLite. A worker's queue and task sets are fixed at boot,
so the statement text is stable for the life of the process and
C<prepare_cached> sees exactly one statement.

=head2 Times

Columns are C<DOUBLE PRECISION> epoch seconds, not C<TIMESTAMPTZ>, so binds
and comparisons are identical to SQLite's and no driver timestamp parsing
happens anywhere. The cost is readability at a C<psql> prompt, and the
apology for that is the C<pq_jobs_human> view, which the schema creates:

    SELECT * FROM pq_jobs_human WHERE state = 'failed';

=head2 JSON columns

C<args>, C<notes> and C<result> are C<TEXT>, not C<JSONB>. JSONB would
normalise key order, whitespace and numbers differently from SQLite's TEXT,
and a job payload that round-trips differently depending on the backend
would defeat the conformance suite. The queue never queries inside a
payload, so JSONB's indexing would buy nothing.

=head1 METHODS

Everything in L<Punk::Queue::Backend>, plus:

=head2 dequeue

    my $row = $backend->dequeue($worker_id, \@queues, \@tasks);

=head2 notify

    $backend->notify($queue, $id);

Emit a wakeup on the queue's channel, through C<pg_notify> rather than a
C<NOTIFY> statement - it takes the channel as a text parameter, so no
identifier quoting is involved at all. The listening side arrives in phase
5. On SQLite the same method is a no-op, so callers never have to ask which
backend they are on.

=head2 begin_immediate / commit / rollback

Transaction control. Named for symmetry with the SQLite backend; here
C<begin_immediate> starts a transaction and takes a transaction-scoped
advisory lock, which is what serialises concurrent migrations. Being
transaction-scoped, it is released even if the process dies mid-migration.

=head1 SEE ALSO

L<Punk::Queue>, L<Punk::Queue::Backend>,
L<Punk::Queue::Backend::SQLite>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
