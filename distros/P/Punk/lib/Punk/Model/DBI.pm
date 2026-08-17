package Punk::Model::DBI;

use 5.010;
use strict;
use warnings;
use Punk ();
use File::Raw::JSON ();

our $VERSION = '0.14';

1;

__END__

=head1 NAME

Punk::Model::DBI - the default DBI backend for Punk models

=head1 DESCRIPTION

The shipped L<Punk::Model> backend: plain L<DBI>, no ORM. Connections are
pooled by C<dsn> and shared across every model that uses them, so a
hundred models on one database open one handle per worker, not a hundred;
a C<$$> check reconnects after a fork. C<RaiseError> and C<AutoCommit> are
on, and generated SQL is prepared through C<prepare_cached> so each
distinct statement is compiled once.

It is selected by default; C<< database backend => 'Class' >> swaps it
for any class honouring the same six methods. Every call blocks the worker
for the whole database round trip - L<Punk::Model::DBIx::Loop> is the
non-blocking alternative, at the cost of handlers written against futures.

=head1 CONFIGURATION

From the C<database> keyword:

    database
        dsn      => 'dbi:SQLite:dbname=myapp.db',
        user     => $user,        # optional
        password => $pass,        # optional
        attr     => { ... };      # optional, merged into the connect attrs

=head1 CONSTRUCTOR

=head2 new

    Punk::Model::DBI->new(database => \%conn, table => $t,
                          primary => $pk, columns => \@names);

Built by L<Punk::Model/_instantiate> from the C<database> options and the
model's table, primary key and columns. Not called directly.

=head2 dbh

The live per-worker L<DBI> handle for this backend's C<dsn>, connected on
first use and shared with every other backend on the same database.

=head1 THE CONTRACT

=head2 get(%key)

C<SELECT * ... WHERE key = ? ...> - the row hashref, or undef.

=head2 search(\%filter, \%opts)

Equality filters only (C<WHERE a = ? AND b = ?>), C<ORDER BY> the primary
key, C<LIMIT>. C<$opts> takes C<limit> (default 20) and C<after> - an
opaque keyset token. Returns

    { rows => [ \%row, ... ], has_more_data => 0|1, next => $token|undef }

C<has_more_data> comes from fetching one row past the limit; C<next> is a
url-safe, opaque encoding of the last row's primary key. Pass it back as
C<< after => $token >> to fetch the following page - a C<WHERE pk > ?>
continuation, so pagination is seek-based, not offset-based.

=head2 all()

C<search({}, {})>.

=head2 create(\%data)

Inserts the known columns and returns the stored row (via C<RETURNING>
where the driver supports it - SQLite 3.35+ or PostgreSQL, detected once
per connection - otherwise re-fetched by primary key).

=head2 update(\%key_and_changes)

Updates the row named by the primary key with the remaining columns;
returns the stored row.

=head2 delete(%key)

Deletes and returns the affected row count.

=head1 SEE ALSO

L<Punk::Model>, L<Punk>, L<DBI>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
