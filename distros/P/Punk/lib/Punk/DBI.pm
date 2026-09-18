package Punk::DBI;

use 5.010;
use strict;
use warnings;
use DBI ();
use Punk::DBI::db ();
use Punk::DBI::st ();

our $VERSION = '0.51';
our @ISA = ('DBI');


1;

__END__

=head1 NAME

Punk::DBI - the DBI subclass that makes every statement observable

=head1 SYNOPSIS

    # nothing calls this directly; Punk::Model::DBI installs it as the
    # handle's RootClass when a C ABI query observer is registered

=head1 DESCRIPTION

C<pk_abi>'s query observer exists so a telemetry layer can see the statements
an application runs. Firing it from L<Punk::Model::DBI>'s six generated methods
sees only some of them: an application reaches C<< $model->backend->dbh >> for
anything the filter language cannot express - an C<OR>, a C<UNION>, a C<FOR
UPDATE>, an upsert - and those statements never touch the generated path.

This is the handle they run on. Every statement, whichever way it was asked
for, goes through one of the wrappers in L<Punk::DBI::db> or
L<Punk::DBI::st>, which report it to whoever registered.

=head2 It is installed only when somebody is listening

The connection takes this C<RootClass> only if a query observer was registered
before the handle was built. With none, the handle is a plain C<DBI::db> and an
uninstrumented application pays nothing at all - which is the deal the rest of
this framework makes and the reason this is not simply always on.

Observers register at boot and connections are built on first use, so in a
worker that serves the answer is known by the time a handle exists. A handle
built before the first registration stays plain for its life; there is no
reconnect that would pick the subclass up.

=head2 What it costs

A Perl frame per statement, for an application that has asked to see its
statements. That is the trade, and it is worth stating plainly in a
distribution whose argument elsewhere is that there isn't one. The alternative
is not a cheaper hook - DBI has none that sees the convenience methods and also
reports when they finish - it is hand-written SQL that no telemetry can see.

=head2 It never takes an application's own RootClass

If the C<attr> passed to the model names a C<RootClass>, that one is used and
this is not installed. An application that has subclassed its own handles keeps
them, and loses the statement observer rather than the subclass.

=head1 SEE ALSO

L<Punk::DBI::db>, L<Punk::DBI::st>, L<Punk::Model::DBI>, L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
