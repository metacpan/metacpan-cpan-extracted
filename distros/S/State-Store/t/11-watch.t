#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;
use HAMT::Map;

# Watchers: who is called, with what, when and in what order.

{
    my $s = State::Store->new('a');
    my @calls;
    is($s->watchers, 0, 'a new store has no watchers');
    my $id = $s->watch(sub { push @calls, [@_] });
    like($id, qr/^\d+$/, 'watch returns an id');
    is($s->watchers, 1, 'and the store has one watcher');

    $s->set('b');
    is(scalar @calls, 1, 'a set calls the watcher once');
    is($calls[0][0], 'a', 'with the value before');
    is($calls[0][1], 'b', 'the value after');
    is(refaddr($calls[0][2]), refaddr($s), 'and the store');
    is(scalar @{ $calls[0] }, 3, 'and nothing else');

    @calls = ();
    $s->swap(sub { $_[0] . 'c' });
    is_deeply([ map { [@$_[0, 1]] } @calls ], [['b', 'bc']], 'a swap calls it');

    @calls = ();
    $s->undo;
    is_deeply([ map { [@$_[0, 1]] } @calls ], [['bc', 'b']], 'an undo calls it, from the value left to the value arrived at');
    @calls = ();
    $s->redo;
    is_deeply([ map { [@$_[0, 1]] } @calls ], [['b', 'bc']], 'a redo calls it');
    @calls = ();
    $s->undo(2);
    is_deeply([ map { [@$_[0, 1]] } @calls ], [['bc', 'a']], 'undo(2) is one change, from where it was to where it ends');

    @calls = ();
    $s->set('a');
    $s->swap(sub { $_[0] });
    $s->undo for 1 .. 3;
    $s->clear_history;
    is(scalar @calls, 0, 'no change, an undo with nothing to undo and clear_history call nobody');
}

# The store has settled by the time a watcher runs.
{
    my $s = State::Store->new(1);
    my @seen;
    $s->watch(sub { my (undef, $now, $store) = @_; push @seen, [$store->current, $store->undo_count, $now] });
    $s->set(2);
    is_deeply($seen[0], [2, 1, 2], 'the watcher sees the new value and the step already recorded');
}

# The values are the stored scalars.
{
    my $m1 = HAMT::Map->new(n => 1);
    my $s = State::Store->new($m1);
    my ($was, $now, $ro);
    $s->watch(sub { ($was, $now) = @_; $ro = Internals::SvREADONLY($_[1]) });
    $s->swap(sub { $_[0]->set(n => 2) });
    is(refaddr($was), refaddr($m1), 'was is the first map');
    is($now->get('n'), 2, 'now is the second');
    is(refaddr($now), refaddr($s->current), 'the one the store holds');
    ok($ro, 'handed over read-only');
    ok($was->get('n') == 1 && $now->get('n') == 2, 'and two versions can be compared');
}

# Order, ids, removal.
{
    my $s = State::Store->new(0);
    my @order;
    my @ids = map { my $n = $_; $s->watch(sub { push @order, $n }) } 1 .. 5;
    is(scalar(keys %{{ map { ($_ => 1) } @ids }}), 5, 'five watchers, five different ids');
    $s->set(1);
    is("@order", '1 2 3 4 5', 'called in the order added');

    ok($s->unwatch($ids[1]), 'unwatch is true for a watcher there');
    ok(!$s->unwatch($ids[1]), 'and false the second time');
    ok(!$s->unwatch(999_999), 'false for an id never given');
    ok(!$s->unwatch('nonsense'), 'false for something that is not an id');
    ok(!$s->unwatch(undef), 'and for undef');
    is($s->watchers, 4, 'four left');
    @order = ();
    $s->set(2);
    is("@order", '1 3 4 5', 'and the removed one is not called');

    my $new = $s->watch(sub { push @order, 'new' });
    ok($new > $ids[-1], 'a new id is larger than any given before');
    $s->unwatch($_) for @ids;
    @order = ();
    $s->set(3);
    is("@order", 'new', 'only the one left is called');
    my $again = $s->watch(sub { push @order, 'again' });
    isnt($again, $ids[0], 'ids are not reused');
}

# A watcher that is the same sub twice is two watchers.
{
    my $s = State::Store->new(0);
    my $n = 0;
    my $code = sub { $n++ };
    my $a = $s->watch($code);
    my $b = $s->watch($code);
    isnt($a, $b, 'the same sub added twice has two ids');
    $s->set(1);
    is($n, 2, 'and is called twice');
    $s->unwatch($a);
    $s->set(2);
    is($n, 3, 'removing one leaves the other');
}

# What is not a sub.
for my $bad (undef, 'main::foo', 1, [], {}) {
    my $s = State::Store->new;
    ok(!eval { $s->watch($bad); 1 }, 'watch with ' . (defined $bad ? (ref $bad || "'$bad'") : 'undef') . ' dies');
    like($@, qr/^State::Store::watch: not a code reference/, 'saying what it wanted');
    is($s->watchers, 0, 'and adds nothing');
}

# A store with no watchers and one with them hold the same history.
{
    my $plain = State::Store->new(0);
    my $watched = State::Store->new(0);
    my $n = 0;
    $watched->watch(sub { $n++ });
    for my $op (1 .. 200) {
        for my $st ($plain, $watched) {
            if ($op % 7 == 0) { $st->undo(2) } elsif ($op % 11 == 0) { $st->redo } else { $st->set($op) }
        }
    }
    is($watched->current, $plain->current, 'watching changes nothing about the value');
    is_deeply([State::Store::_stacks($watched)], [State::Store::_stacks($plain)], 'or the history');
    cmp_ok($n, '>', 150, "and the watcher was called $n times");
}

# Lifetime: values queued for a watcher are released.
{
    my %gone;
    {
        package Local::Counted;
        sub new { bless { n => $_[1] }, $_[0] }
        sub DESTROY { $gone{ $_[0]{n} }++ }
    }
    {
        my $s = State::Store->new(Local::Counted->new(0), history => 0);
        my $kept;
        $s->watch(sub { $kept = $_[0] });
        $s->set(Local::Counted->new($_)) for 1 .. 5;
        is(join(',', sort keys %gone), '0,1,2,3', 'with no history, each value goes once the watcher lets go of it');
        undef $kept;
        is($gone{4}, 1, 'including the last one it held');
    }
    is(scalar(grep { $_ == 1 } values %gone), 6, 'six values, each destroyed once');
    is(State::Store::_live_blocks(), 0, 'and the store is gone');
}

done_testing;
