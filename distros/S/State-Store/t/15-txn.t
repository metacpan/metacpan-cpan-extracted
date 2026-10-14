#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;
use HAMT::Map;

# A transaction is one step and one change, whatever happens inside it.

{
    my $s = State::Store->new(0);
    $s->set(1);
    my @told;
    $s->watch(sub { push @told, "$_[0]>$_[1]" });
    ok(!$s->in_txn, 'not in a transaction outside one');
    my ($inside, $arg, $seen);
    $s->txn(sub {
        ($arg) = @_;
        $inside = $s->in_txn;
        $s->set(2)->set(3);
        $s->swap(sub { $_[0] * 10 });
        $seen = $s->current;
    });
    ok($inside, 'in_txn inside one');
    ok(!$s->in_txn, 'and not after');
    is(refaddr($arg), refaddr($s), 'the sub is given the store');
    is($seen, 30, 'get inside sees the changes made so far');
    is($s->current, 30, 'and the store holds the last of them');
    is("@told", '1>30', 'the watchers are told of one change, from before to after');
    is($s->undo_count, 2, 'and it is one step');
    $s->undo;
    is($s->current, 1, 'undone in one');
    $s->redo;
    is($s->current, 30, 'and redone in one');
}

# Nothing changed is nothing.
{
    my $s = State::Store->new('a');
    $s->set('b');
    $s->undo;
    my $told = 0;
    $s->watch(sub { $told++ });
    $s->txn(sub { $s->set('x')->set('y')->set('a') });
    is($s->current, 'a', 'a transaction that ends where it began');
    is($told, 0, 'tells nobody');
    is($s->undo_count, 0, 'records no step');
    is($s->redo_count, 1, 'and leaves the redo stack as it was, though the changes inside emptied it');
    $s->txn(sub { });
    is($s->redo_count, 1, 'nor does an empty one');
}

# What it returns.
{
    my $s = State::Store->new(0);
    my $r = $s->txn(sub { $s->set(1); 'scalar' });
    is($r, 'scalar', 'in scalar context it returns the sub\'s value');
    my @r = $s->txn(sub { $s->set(2); (1, 2, 3) });
    is_deeply(\@r, [1, 2, 3], 'in list context the sub\'s list');
    my $ctx;
    $s->txn(sub { $ctx = wantarray; 1 });
    is($ctx, undef, 'in void context the sub is called in void context');
    $r = $s->txn(sub { $ctx = wantarray; 1 });
    is($ctx, '', 'in scalar context in scalar');
    @r = $s->txn(sub { $ctx = wantarray; () });
    is($ctx, 1, 'in list in list');
    is_deeply(\@r, [], 'and an empty list is empty');
    $r = $s->txn(sub { return });
    is($r, undef, 'nothing returned in scalar context is undef');
    @r = (7, $s->txn(sub { (8, 9) }), 10);
    is("@r", '7 8 9 10', 'among other values on the stack');
}

# Nested.
{
    my $s = State::Store->new(0);
    my @told;
    $s->watch(sub { push @told, "$_[0]>$_[1]" });
    my $inner_told;
    $s->txn(sub {
        $s->set(1);
        $s->txn(sub { $s->set(2)->set(3) });
        $inner_told = scalar @told;
        $s->set(4);
    });
    is($inner_told, 0, 'an inner transaction tells nobody when it ends');
    is("@told", '0>4', 'the outer one tells of everything, once');
    is($s->undo_count, 1, 'one step for all of it');
}

# Inside, the validator is asked about each change.
{
    my @asked;
    my $s = State::Store->new(0, validator => sub { push @asked, $_[0]; $_[0] < 100 });
    @asked = ();
    $s->txn(sub { $s->set(1)->set(2) });
    is("@asked", '1 2', 'the validator is asked about every change inside');
    my $caught;
    $s->txn(sub {
        $s->set(3);
        $caught = !eval { $s->set(500); 1 };
        $s->set(4);
    });
    ok($caught, 'a refusal inside is a die the sub may catch');
    is($s->current, 4, 'and carry on');
    is($s->undo_count, 2, 'one step for the transaction');
}

# What is not allowed inside.
for my $case (
    [undo          => sub { $_[0]->undo }],
    [redo          => sub { $_[0]->redo }],
    [clear_history => sub { $_[0]->clear_history }],
    [history_limit => sub { $_[0]->history_limit(3) }],
) {
    my ($method, $do) = @$case;
    my $s = State::Store->new(0);
    $s->set(1)->set(2);
    $s->undo;
    my $err;
    $s->txn(sub { eval { $do->($_[0]) }; $err = $@; $_[0]->set(9) });
    like($err, qr/^State::Store::$method: not inside a transaction/, "$method inside a transaction dies");
    is($s->current, 9, '  and the transaction goes on');
}
{
    my $s = State::Store->new(0, history => 4);
    my ($limit, $ok);
    $s->txn(sub { $limit = $_[0]->history_limit; $ok = eval { my $id = $_[0]->watch(sub {}); $_[0]->unwatch($id); $_[0]->validator(undef); 1 } });
    is($limit, 4, 'reading the limit inside is allowed');
    ok($ok, 'as are watching and setting the validator');
}

# Under a history limit.
for my $limit (0, 1, 3) {
    my $s = State::Store->new(0, history => $limit);
    $s->set($_) for 1 .. 5;
    $s->txn(sub { $s->set($_) for 10 .. 20 });
    my $want = $limit;
    is($s->undo_count, $want, "limit $limit: a transaction is one step within the limit");
    if ($limit) {
        $s->undo;
        is($s->current, 5, "limit $limit: and undoes to before it");
    }
    is(State::Store::_check($s), 0, "limit $limit: both stacks well formed");
}

# A watcher may start a transaction.
{
    my $s = State::Store->new(0);
    my @told;
    $s->watch(sub {
        push @told, "$_[0]>$_[1]";
        $_[2]->txn(sub { $_[0]->set(100)->set(101) }) if $_[1] == 1;
    });
    $s->set(1);
    is("@told", '0>1 1>101', 'a transaction inside a watcher is told after the change it followed');
    is($s->undo_count, 2, 'and is a step');
}

# A map.
{
    my $s = State::Store->new(HAMT::Map->new);
    $s->txn(sub { my $st = shift; $st->swap(sub { $_[0]->set("k$_" => $_) }) for 1 .. 100 });
    is($s->current->count, 100, 'a hundred updates of a map in a transaction');
    is($s->undo_count, 1, 'are one step');
    $s->undo;
    is($s->current->count, 0, 'undone in one');
}

# What is not a sub.
for my $bad (undef, 'name', [], {}) {
    my $s = State::Store->new(0);
    ok(!eval { $s->txn($bad); 1 }, 'txn with ' . (defined $bad ? (ref $bad || "'$bad'") : 'undef') . ' dies');
    like($@, qr/^State::Store::txn: not a code reference/, 'saying so');
    ok(!$s->in_txn, 'and leaves no transaction open');
}

done_testing;
