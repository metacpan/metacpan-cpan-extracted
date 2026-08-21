package Punk::Model::DBIx::Loop;

use 5.010;
use strict;
use warnings;
use Punk ();
use DBIx::Loop ();

our $VERSION = '0.27';

1;

__END__

=head1 NAME

Punk::Model::DBIx::Loop - a non-blocking backend for Punk models

=head1 SYNOPSIS

    # in the app class
    database dsn     => 'dbi:SQLite:dbname=myapp.db',
             backend => 'Punk::Model::DBIx::Loop';
    model 'Book';

=head1 DESCRIPTION

A L<Punk::Model> backend. Same six-method contract as the default
L<Punk::Model::DBI>, same SQL, same result shapes - but every method returns
a L<Punk::Future> instead of a value, and the statement runs on
L<DBIx::Loop> over the worker's own event loop.

That is the whole point. Under the DBI backend a worker blocks for the whole
database round trip and serves nobody; here it goes back to the loop and
picks up other requests, which is what the rest of Punk already does for
every other kind of I/O. The cost is that handlers have to be written for it
- see L</"WRITING HANDLERS"> - which is why it is not the default.

Everything below the call goes through DBIx::Loop's C ABI: the statement and
its reshape are one call, and the continuation that settles the future is a C
function. No closure is compiled per query, and no Perl frame runs when the
rows land.

=head1 WRITING HANDLERS

A handler hands the future straight back - the dispatcher awaits any future a
handler returns:

    sub show {
        my ($c) = @_;
        return $c->model('Book')->get( id => $c->param('id') );
    }

Post-processing is a C<then>:

    sub show {
        my ($c) = @_;
        return $c->model('Book')->get( id => $c->param('id') )->then(sub {
            my ($book) = @_;
            return $c->not_found unless $book;
            $c->render('book/view', { book => $book });
        });
    }

C<$c-E<gt>await> works too, and is occasionally clearer, but it stops the
worker for the duration - which is the thing this backend exists to avoid.
Prefer the chain.

Concurrent queries are C<Punk::Future-E<gt>needs_all>:

    my $f = Punk::Future->needs_all(
        $c->model('Book')->all,
        $c->model('Author')->all,
    )->then(sub {
        my ($books, $authors) = @_;
        $c->render('index', { books => $books->{rows},
                              authors => $authors->{rows} });
    });

=head1 CONFIGURATION

From the C<database> keyword, as the DBI backend plus the pool sizes:

    database
        backend   => 'Punk::Model::DBIx::Loop',   # required: not the default
        dsn       => 'dbi:SQLite:dbname=myapp.db',
        user      => $user,       # optional
        password  => $pass,       # optional
        attr      => { ... },     # optional, merged into the connect attrs
        workers   => 4,           # optional, DBIx::Loop pool size
        max_queue => 0;           # optional, 0 = unbounded

One L<DBIx::Loop> per distinct connection (dsn, credentials B<and> pool
sizes) is shared by every model on it, built lazily on the first statement
so C<punk console> and tests that only instantiate never fork a pool. Two
C<database> blocks naming one dsn with different pool sizes get different
pools rather than silently sharing one.

The handle carries the pid that built it and is rebuilt after a fork, so a
preforking worker never inherits another process's pool.

=head1 THE CONTRACT

Identical to the default L<Punk::Model::DBI>, wrapped in a future. C<get> resolves to the
row hashref or undef; C<search> to
C<< { rows => [...], has_more_data => 0|1, next => $token|undef } >>;
C<all> to C<search({}, {})>; C<create> and C<update> to the stored row;
C<delete> to the affected row count.

Pagination tokens are the B<same> opaque encoding both backends use, so a
C<next> token minted by one decodes on the other and switching backends does
not break paginated URLs already in flight.

Two things are deliberately synchronous, because both are programming errors
rather than query failures, and a failed future would surface them as a 500
where a croak surfaces them at the call site:

=over 4

=item * Field validation (C<create>/C<update>) runs before the statement is
built, exactly as it does on the DBI backend.

=item * A malformed pagination token croaks from C<search> rather than
failing its future.

=back

A query that fails B<in the database> fails the future, and the error reaches
your C<else> or the dispatcher's error handler.

=head1 METHODS BEYOND THE CONTRACT

=head2 db

The L<DBIx::Loop> connection for this backend's dsn. Custom model methods run
their own SQL through it:

    sub recent {
        my ($self, $room, $limit) = @_;
        return $self->backend->future(
            $self->backend->db->selectall_rowhash(
                'SELECT * FROM messages WHERE room = ?
                  ORDER BY id DESC LIMIT ?', $room, $limit)
        );
    }

=head2 future($dbil_future)

Bridges a raw L<DBIx::Loop::Future> into a L<Punk::Future>, so a custom
method returns the same type as the contract ones.

=head2 await($future)

Resolves one of this backend's futures outside a worker, by pumping the
adapter's own loop; returns the settled values and croaks on failure, like
C<< $future->get >>. Inside a worker C<$c-E<gt>await> already does this
against the worker's loop. Scripts and tests can also just call
C<< $future->get >>.

=head2 dbh

DBIx::Loop's own parent L<DBI> handle. Statements do B<not> run on it - the
pool workers hold their own connections - but it is the right place for boot
work such as creating a schema, and it is what quotes identifiers.

=head2 adapter

The L<DBIx::Loop> loop adapter this connection runs on. Inside a worker it is
built on the worker's own loop, named explicitly; an adapter left to pick a
loop for itself would construct one nothing ever runs, and every future would
hang.

=head1 SEE ALSO

L<Punk::Model>, L<Punk::Model::DBI>, L<Punk::Future>, L<DBIx::Loop>, L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
