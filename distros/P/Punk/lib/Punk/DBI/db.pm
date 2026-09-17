package Punk::DBI::db;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.50';
our @ISA = ('DBI::db');

# The wrappers are C (include/punk/punk_dbiobs.h + xs/dbi.xs), installed into
# this package at load. This file is documentation.

1;

__END__

=head1 NAME

Punk::DBI::db - the observed database handle

=head1 DESCRIPTION

The database-handle half of L<Punk::DBI>. Wraps the statement-running methods
DBI implements in its own dispatch - C<do> and the C<select*> family - so a
C<pk_abi> query observer sees them.

These are the ones that matter. C<< $sth->execute >> is covered by
L<Punk::DBI::st>, and a hand-written statement is far more likely to be a
C<selectall_arrayref> than a prepared handle the caller drives itself.

=head2 Why a subclass and not Callbacks

DBI's C<Callbacks> cannot do this, for two independent reasons. The C<select*>
methods are DBI's own dispatch and reach the inner execute without firing an
C<execute> callback at all, so exactly the hand-written statements this exists
for are the ones a callback misses. And callbacks run B<before> the method, so
there is no way to report that a statement finished or whether it worked - and
the observer contract is a start and a done.

=head2 One report per statement, at the altitude the caller asked for

Whether DBI answers one of these itself or falls back to C<prepare> and
C<execute> is a per-driver, per-call detail. DBD::SQLite runs a bind-free
C<do> natively and takes the prepare/execute path the moment there is a
placeholder - so the same statement reaches L<Punk::DBI::st> on one branch and
not the other.

Left alone that would report a statement once or twice depending on whether it
had bind values, and double count the duration of every one that did. A
re-entrancy guard means the outermost wrapper is the only one that reports:
the caller asked for C<selectall_arrayref>, so that is the statement.

The generated methods in L<Punk::Model::DBI> use C<prepare_cached> and
C<execute> directly, which is the C<st> path, and are reported once there.

=head2 What the observer is told

The statement text and the number of bind values. Never the values: they are
the literal data, and the SQL carries placeholders exactly where they would
have been.

A statement is reported as having succeeded when it ran. These methods return
data rather than a status, and a query that matched no rows has not failed;
one that went wrong raised, because C<RaiseError> is this framework's default,
and the wrapper reports that before rethrowing.

=head1 SEE ALSO

L<Punk::DBI>, L<Punk::DBI::st>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
