package Punk::Txn;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.49';

1;

__END__

=head1 NAME

Punk::Txn - the transaction a C<< $c->txn >> block receives

=head1 SYNOPSIS

    my $order = $c->txn(sub {
        my ($tx) = @_;
        my $o = $tx->model('Order')->create(\%data);
        $tx->model('Stock')->update({ id => $sku, held => $held + 1 });
        return $o;
    });

    $c->txn(analytics => sub { my ($tx) = @_; ... });

    # on Punk::Model::DBIx::Loop the block's result is a future, and so
    # is txn's - return it from the handler
    return $c->txn(sub {
        my ($tx) = @_;
        return $tx->model('Order')->create(\%data)
          ->then(sub { $tx->model('Stock')->update({ ... }) });
    })->then(sub { $c->json($_[0]) });

=head1 DESCRIPTION

A transaction belongs to a database, not to a model, so it is started from
the context - L<Punk::Context/txn> - on the default database or one the
C<database> keyword named, and the block is handed this object. What comes
back is what the block returns: the value itself on L<Punk::Model::DBI>, a
L<Punk::Future> of it on L<Punk::Model::DBIx::Loop>, in both cases after
C<COMMIT>. A die inside the block is a C<ROLLBACK> and a rethrow; on the
async backend a failed future from the block is the same.

=head2 What C<< $tx->model >> means, per backend

C<< $tx->model($name) >> is the registered model bound to this
transaction: a copy of the per-worker instance whose statements run on the
transaction's connection. The shared instance is untouched, so nothing
leaks out of the block. The two backends differ in what that binding
buys, and the difference is the reason the method exists:

=over 4

=item * B<Punk::Model::DBI> holds one connection per database per worker.
A transaction is C<begin_work> / C<commit> / C<rollback> on that handle,
and every model on the database is inside it for the length of the block
whether it came through C<< $tx->model >> or C<< $c->model >>. Here the
binding is a check - a model on another database croaks - and a reminder
of which database the block is on.

=item * B<Punk::Model::DBIx::Loop> runs statements on a pool, and
L<DBIx::Loop> pins a transaction to one slot: its own rule is that plain
statements during a transaction run on other slots and never join. So a
model reached through C<< $c->model >> inside the block is B<outside> the
transaction - its writes commit on their own - and C<< $tx->model >> is the
only way in. A worker-wide "current transaction" would be wrong under the
event loop, where the requests served between two of this block's queries
belong to somebody else; binding the copy is what keeps one request's
transaction its own.

=back

=head1 METHODS

=head2 model($name)

The registered model, bound to this transaction. Croaks for a model that
lives on another database, and after the block has ended.

=head2 handle

The connection the transaction is on, for a raw statement that has no
model: the DBI C<$dbh> on L<Punk::Model::DBI>, the L<DBIx::Loop::Txn> on
L<Punk::Model::DBIx::Loop> (whose C<query> and C<do> return futures).

=head2 name

The database's name as the C<database> keyword gave it; C<default> for the
unnamed one.

=head2 backend

The backend class the transaction runs on.

=head2 is_active

True while the block is running (on the async backend, until its future
settles); false after. C<model> croaks once it is false.

=head1 NESTING, AND WHAT JOINS

On L<Punk::Model::DBI> a C<txn> inside a C<txn> croaks. There is one
connection, and a silent join would stop a rollback covering what the
outer block thought it covered; savepoints are a later addition, not an
implicit one. On L<Punk::Model::DBIx::Loop> an inner C<txn> is an
independent transaction on another slot - DBIx::Loop's behaviour - and
awaiting it while the outer one holds the last slot waits forever.

Anything on the DBI backend's connection joins: every model on the
database, a raw statement on C<< $tx->handle >>, and anything else an
application pointed at the same C<$dbh>. L<Punk::Queue> holds its own
connection and does not.

=head1 SEE ALSO

L<Punk::Context>, L<Punk::Model>, L<Punk::Model::DBI>,
L<Punk::Model::DBIx::Loop>, L<DBIx::Loop/txn>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
