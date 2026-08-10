package Punk::Queue::Backend::SQLite;

use 5.010;
use strict;
use warnings;
use Punk::Queue ();

our @ISA = ('Punk::Queue::Backend');
our $VERSION = '0.02';

1;

__END__

=head1 NAME

Punk::Queue::Backend::SQLite - the SQLite backend

=head1 SYNOPSIS

    my $q = Punk::Queue->new(dsn => 'dbi:SQLite:dbname=queue.db');

=head1 DESCRIPTION

Selected automatically for a C<dbi:SQLite:> dsn. Requires SQLite 3.8 for
partial indexes; C<RETURNING> is used where available (3.35+) and a second
read stands in below that.

Suited to a single host: one process or several, one machine. For a queue
shared across machines, use the PostgreSQL backend.

=head2 Connection setup

Every connection gets four pragmas, applied at connect:

    journal_mode = WAL       readers must not block the claim transaction
    synchronous  = NORMAL    durable enough with WAL, much faster
    busy_timeout = 5000      SQLITE_BUSY becomes a wait, not an error
    foreign_keys = ON        or the dependency cascade silently does nothing

WAL is not optional. C<migrate> refuses to run without it, naming the
reason, because the failure it prevents - workers contending badly under
load - shows up far from its cause. An in-memory database is exempt: it
cannot do WAL and is single-process by definition.

=head2 How a job is claimed

    BEGIN IMMEDIATE TRANSACTION
    SELECT ... WHERE state = 'inactive' AND queue IN (...)
               AND delayed <= ? AND parents_left = 0
               AND (expires IS NULL OR expires > ?)
     ORDER BY priority DESC, id LIMIT 1
    UPDATE ... SET state = 'active' WHERE id = ? AND state = 'inactive'
    COMMIT

C<BEGIN IMMEDIATE> takes the reserved lock up front, so contending workers
serialise at the beginning of the transaction rather than deadlocking at
the commit.

The C<state = 'inactive'> guard on the update should be redundant given the
transaction. It is there anyway: a silently duplicated job is the worst
failure a queue has, and the guard turns that possibility into a harmless
miss for no measurable cost.

C<ORDER BY priority DESC, id> gives FIFO within a priority for free, with
no second timestamp column to read.

=head1 METHODS

Everything in L<Punk::Queue::Backend>, plus:

=head2 dequeue

    my $row = $backend->dequeue($worker_id, \@queues, \@tasks);

=head2 begin_immediate / commit / rollback

Transaction control, exposed so a conformance suite can drive it directly
rather than only through the operations that use it.

=head1 SEE ALSO

L<Punk::Queue>, L<Punk::Queue::Backend>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
