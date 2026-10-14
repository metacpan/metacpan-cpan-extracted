package State::Store;

use 5.010;
use strict;
use warnings;

use HAMT ();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('State::Store', $VERSION);

1;

__END__

=head1 NAME

State::Store - state with undo, redo and watchers

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use State::Store;
    use HAMT::Map;

    my $s = State::Store->new(HAMT::Map->new(count => 0), history => 100);

    $s->watch(sub {
        my ($was, $now) = @_;
        printf "count %d -> %d\n", $was->get('count'), $now->get('count');
    });

    $s->swap(sub { $_[0]->set(count => $_[0]->get('count') + 1) }) for 1 .. 3;
    # count 0 -> 1, count 1 -> 2, count 2 -> 3

    $s->undo;                       # count 3 -> 2
    $s->undo;                       # count 2 -> 1
    $s->redo;                       # count 1 -> 2
    $s->current->get('count');      # 2

    $s->txn(sub {                   # one step: count 2 -> 10
        my ($store) = @_;
        $store->swap(sub { $_[0]->set(count => 10) });
        $store->swap(sub { $_[0]->set(seen => 1) });
    });

    $s->checkpoint('ten');
    $s->swap(sub { $_[0]->set(count => 0) });   # count 10 -> 0
    $s->restore('ten');                         # count 0 -> 10

The value can be any scalar. With an ordinary hash reference, give the
store a new hash for each change rather than changing the one it holds,
since every step that refers to that hash would see the change:

    my $config = State::Store->new({ debug => 0, level => 1 }, history => 20);

    $config->swap(sub { { %{ $_[0] }, debug => 1 } });
    $config->set({ %{ $config->current }, level => 3 });
    $config->current->{level};      # 3

    $config->undo(2);
    $config->current->{debug};      # 0
    $config->current->{level};      # 1

    # Not $config->current->{level} = 5: that changes a hash the store
    # shares with its history, and no watcher is told.

=head1 DESCRIPTION

A store holds one value and is the place a program asks for the current
one. It is meant for values from L<HAMT>, where an update returns a new
value and keeping the old one costs almost nothing; but it holds any scalar.

=head2 When not to use one

A store keeps every value it is given, by reference or by copy, for as
long as the step that holds it can be undone. That is cheap when each new
value shares most of itself with the last, which is what a L<HAMT>
container does. An ordinary hash or array is the opposite case: to keep
its old contents a program must store a copy of the whole of it at every
step, and the store will then hold every one of those copies. It is
correct, and it costs what a stack of copies costs. Give such a store a
history limit, or use HAMT's containers.

=head2 Subs the store calls

A store calls subs it is given: by L</swap>, as watchers, as a validator and
by L</txn>. Each is called as an ordinary sub would be, with two
differences. C<last>, C<next> and C<redo> cannot leave one to reach a loop
outside it: they are the error perl gives for a loop that is not there, and
the store treats that error as any other. And a call that works leaves
C<$@> as it was.

=head2 Values

A value is copied when it is stored and the copy is read-only. L</current> hands
out that stored scalar itself and not another copy of it, so:

    my $v = $s->current;        # an ordinary copy, yours to change
    $_++ for $s->current;       # dies: Modification of a read-only value

The variable a value was stored from is not made read-only and is not
watched: changing it afterwards does not change the store.

This is shallow. A stored reference is a second reference to the same
thing, which is what makes a container in a store still that container, and
what makes an ordinary array or hash in a store still the caller's to
change behind its back. Store data you do not intend to change in place.

=head2 Unchanged

Storing the value a store already holds is not a change. Two values are the
same value when they are the same scalar, or two references to the same
thing, or two things that are not references and are the same string; two
undefs are the same and an undef is the same as nothing else. So a number
and the string that spells it are one value, and two different arrays with
the same contents are two.

=head2 History

Every change is kept. Undoing a change makes the value before it current
again, and redoing it makes the value it was changed to current again, as
an editor's undo does: a new change after an undo throws away what could
have been redone.

Keeping a step costs very little when the value is a L<HAMT> container,
since the old version and the new share almost all of their memory. It
costs a copy of the value when the value is a string, and nothing more than
a second reference when it is a reference: but an ordinary array or hash
changed in place has the same contents in every step, because every step
refers to the one array.

A change that is no change, as L</Unchanged> has it, is not a step.

A store keeps every step unless it is told otherwise. One that runs for a
long time should be given a limit, with the C<history> option to L</new> or
with L</history_limit>: it then keeps that many steps to undo, and forgets
the oldest as new ones are made.

=head2 Watchers

A watcher is a sub called after every change with the value before, the
value after, and the store:

    $s->watch(sub {
        my ($was, $now, $store) = @_;
        print "count went from ", $was->get('count'), " to ", $now->get('count'), "\n";
    });

=over 4

=item *

It is called once the change is complete, so the store it is handed already
holds C<$now>. C<$was> and C<$now> are the stored values themselves, and
read-only.

=item *

L</set>, L</swap>, L</undo> and L</redo> all call the watchers. A change that
is no change calls none, and neither does L</clear_history>, which changes
no value.

=item *

Watchers are called in the order they were added.

=item *

A watcher may change the store. That change is made at once, and the
watchers are told of it after they have all been told of the one before, so
each sees every change in the order it happened. A watcher that changes the
store every time it is called would never stop, and the store stops it with
an error after ten thousand changes in one round.

=item *

A watcher that dies does not stop the others being called, and does not
undo the change, which has already happened. Once every watcher has been
called, the first error is thrown again from the method that made the
change.

=item *

A watcher may remove itself or another. One removed is not called again,
even later in the same round. One added while watchers are being called is
first called for the next change.

=item *

What a watcher returns is ignored.

=back

An undo is a change like any other, and is told to the watchers like any
other. A watcher that enforces a rule on every change, by changing the
store again, enforces it on an undo too, and can make the undo appear to do
nothing. L</restore> is told to them as well.

The store is handed to every watcher so that none needs to close over it. A
watcher that does refer to its own store from inside the sub keeps the store
alive for as long as the watcher is attached, which is for as long as the
store is: remove it with L</unwatch>, or use the argument.

=head2 The validator

A store may have one validator: a sub that decides whether a new value may
be stored.

    $s->validator(sub {
        my ($new, $old, $store) = @_;
        return $new->get('count') >= 0;
    });

=over 4

=item *

It is called by L</set> and L</swap> before anything changes, with the value
proposed, the value held and the store. The value it is shown is the very scalar that
will be stored, read-only.

=item *

If it returns false the method dies, saying the validator refused the value;
if it dies, the method dies with its error. Either way the store is as it
was: no step is recorded and no watcher is called.

=item *

It is not called for a change that is no change, and not by L</undo> or
L</redo>: those values were accepted when they were first stored.

=item *

It may not change the store. Any method that would, called while the
validator is running, dies.

=item *

Setting a validator does not check the value the store already holds. A
validator given to L</new> checks the first value, with C<undef> as the one
before it, and C<undef> for the store, which does not exist yet.

The store is handed to the validator so that it need not close over it: a
validator that refers to its own store from inside the sub keeps the store
alive for as long as the validator is set.

=back

=head2 Transactions

A transaction makes several changes into one:

    $s->txn(sub {
        my ($store) = @_;
        $store->swap(sub { $_[0]->set(a => 1) });
        $store->swap(sub { $_[0]->set(b => 2) });
    });

=over 4

=item *

Once it is over, the changes made inside it are one step to undo, and the
watchers are told of one change, from the value before it to the value
after. If the value after is the value before, there is no step and nobody
is told.

=item *

If the sub dies, the store is put back exactly as it was before the
transaction began, history included, and the error goes on up.

=item *

Inside, L</current> sees the changes made so far, and the validator is asked
about each of them as it is made. A refusal is a die like any other: the
transaction is undone unless the sub catches it.

=item *

A transaction inside a transaction is part of the outer one: it is not a
step of its own, and the watchers are told nothing until the outer one is
over. If it dies, what it did is undone and the error goes on to the outer
one, which may catch it and carry on.

=item *

L</undo>, L</redo>, L</clear_history> and setting L</history_limit> are not
allowed inside a transaction.

=back

=head2 Checkpoints

A checkpoint is a name for a value, to come back to later whatever has
happened in between:

    $s->checkpoint('saved');
    ...
    $s->restore('saved');

=over 4

=item *

Restoring is a change like any other: it is a step that can be undone, it
throws away what could have been redone, and the watchers are told of it.
The validator is not asked, since the value was accepted when it was first
stored. Restoring the value the store already holds does nothing.

=item *

A checkpoint keeps its value for as long as it exists, whatever the history
limit has forgotten and whatever L</clear_history> has cleared.

=item *

Naming a checkpoint that exists replaces it. Restoring or dropping one that
does not exist is an error.

=item *

Two names are the same name exactly when a Perl hash would say so.

=item *

Naming and dropping checkpoints inside a transaction is allowed, and is
undone with the rest of it if the transaction fails. Restoring one inside a
transaction is not allowed.

=back

=head1 METHODS

=head2 new

    my $s = State::Store->new;
    my $s = State::Store->new($value);
    my $s = State::Store->new($value, history => 100);

A store holding C<$value>, or C<undef>. Called on an object, it makes a
store of that object's class. The options:

=over 4

=item history

The most steps to keep to undo; see L</history_limit>. Without it every
step is kept.

=item validator

A sub that decides whether a value may be stored; see L</The validator>.
The first value must satisfy it, or no store is made.

=back

An option the store does not know is an error.

=head2 current

    my $value = $s->current;

The current value.

=head2 set

    $s->set($value);

Replaces the value. Returns the store, so calls can be chained.

=head2 swap

    $s->swap(sub { my ($current, @args) = @_; ...; $new }, @args);

Replaces the value with what the sub returns. The sub is called once, in
scalar context, with the current value and any further arguments. Returns
the store.

If the sub dies, the store is left as it was and the error goes on up. If
it returns the value it was given, nothing changes.

=head2 undo

    $s->undo;
    $s->undo($n);

Makes the value before the current one current again, or the value C<$n>
steps back. Returns how many steps it took: fewer than asked for, or none,
when there were fewer to take. C<$n> must be a whole number, and zero takes
none.

=head2 redo

    $s->redo;
    $s->redo($n);

Takes back the last undo, or the last C<$n>. Returns how many it took back.

=head2 can_undo

True when there is a step to undo.

=head2 can_redo

True when there is an undo to take back.

=head2 undo_count

How many steps can be undone.

=head2 redo_count

How many undos can be taken back.

=head2 clear_history

    $s->clear_history;

Forgets every step, both ways. The value stays. Returns the store.

=head2 history_limit

    my $limit = $s->history_limit;
    $s->history_limit(10);
    $s->history_limit(undef);

The most steps the store keeps to undo, or C<undef> when it keeps them all.
With an argument, sets the limit and returns the store. A limit lower than
the steps already kept forgets the oldest of them at once; raising it
brings none back. A step forgotten as new ones are made may keep its value
alive for up to 32 changes more before letting it go; it can never be
undone to. Zero keeps none, so nothing can be undone.

A lower limit does not forget anything that could be redone. Redoing it
forgets the oldest steps as it goes, so that no more than the limit can
then be undone.

=head2 watch

    my $id = $s->watch(sub { my ($was, $now, $store) = @_; ... });

Adds a watcher; see L</Watchers>. Returns an id for L</unwatch>. Ids are not
reused.

=head2 unwatch

    $s->unwatch($id);

Removes the watcher with that id. True if there was one.

=head2 watchers

How many watchers the store has.

=head2 validator

    my $code = $s->validator;
    $s->validator(sub { my ($new, $old, $store) = @_; ... });
    $s->validator(undef);

The store's validator, or C<undef>. With an argument, replaces it, or
removes it with C<undef>, and returns the store.

=head2 txn

    my @results = $s->txn(sub { my ($store) = @_; ...; @results });

Runs the sub as one transaction; see L</Transactions>. The sub is given the
store, and called in the context C<txn> was called in; C<txn> returns what
it returns.

=head2 in_txn

True while a transaction is running.

=head2 checkpoint

    $s->checkpoint($name);

Names the current value; see L</Checkpoints>. Returns the store.

=head2 restore

    $s->restore($name);

Makes the value named current again. Returns the store.

=head2 has_checkpoint

    if ($s->has_checkpoint($name)) { ... }

True if there is a checkpoint with that name.

=head2 drop_checkpoint

    $s->drop_checkpoint($name);

Forgets a checkpoint. Returns the store.

=head2 checkpoints

    my @names = $s->checkpoints;
    my $how_many = $s->checkpoints;

The names of the checkpoints, sorted; in scalar context, how many there
are.

=head1 C ABI

Everything a store does from Perl can be done from another extension's C:
making a store, reading and changing it, undo and redo, watchers and a
validator written in C, transactions opened and closed from C, and
checkpoints. A store is the same object either way, so one made in C can be
handed to Perl and one from Perl used in C, and Perl and C watchers on one
store are told of every change, in the order they were added.

The interface is one header, F<state_store_abi.h>, installed with the
module. A consuming distribution finds it with L<ExtUtils::Depends>:

    my $pkg = ExtUtils::Depends->new('My::Module', 'State::Store');

and resolves the table once, when it loads; the header shows how. Nothing
is linked against, and the table is versioned, so the two distributions can
be upgraded independently. It is at version 1.

A validator set from C is not a sub, so L</validator> reads it as C<undef>;
setting a sub replaces it.

=head1 SUBCLASSING

A subclass works as expected. An object of this class cannot be made by
blessing something else into it: every method refuses such an object by
name.

=head1 THREADS

A store belongs to the interpreter that made it. A new thread does not
inherit the stores of the thread that started it: there those variables
hold a reference that is not a store.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-state-store at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=State-Store>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
