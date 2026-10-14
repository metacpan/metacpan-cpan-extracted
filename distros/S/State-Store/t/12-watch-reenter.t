#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr weaken);
use State::Store;

# Watchers that use the store: change it, undo it, remove themselves, add
# watchers, drop it, die.

# A watcher that changes the store.
{
    my $s = State::Store->new(0);
    my (@first, @second);
    $s->watch(sub {
        my ($was, $now, $store) = @_;
        push @first, "$was>$now";
        $store->set($now + 10) if $now < 10;
    });
    $s->watch(sub { push @second, "$_[0]>$_[1]" });
    $s->set(1);
    is($s->current, 11, 'a watcher may change the store, and the change stands');
    is("@first", '0>1 1>11', 'it is told of its own change, after the first');
    is("@second", '0>1 1>11', 'the next watcher is told of both, in the order they happened');
    is($s->undo_count, 2, 'both are steps');
    $s->undo;
    is($s->current, 11, 'an undo is a change too: the watcher is told of it, and changes the store again');
    is($s->redo_count, 0, 'which leaves nothing to redo');
}

# Every watcher sees every transition in order, whoever changes the store.
{
    my $s = State::Store->new('a');
    my %log;
    for my $name (qw(one two three)) {
        $s->watch(sub {
            my ($was, $now, $store) = @_;
            push @{ $log{$name} }, "$was>$now";
            $store->set("$now+$name") if $name eq 'two' && length($now) < 6;
        });
    }
    $s->set('b');
    my @want = ('a>b', 'b>b+two', 'b+two>b+two+two');
    is_deeply($log{one}, \@want, 'the first watcher sees the second watcher\'s changes, in order');
    is_deeply($log{two}, \@want, 'as does the second');
    is_deeply($log{three}, \@want, 'and the third, which never sees a change before the one it follows');
    for my $name (qw(one two three)) {
        my $ok = 1;
        my @l = @{ $log{$name} };
        for my $i (1 .. $#l) { $ok = 0 unless (split />/, $l[$i])[0] eq (split />/, $l[$i - 1])[1] }
        ok($ok, "$name: each change starts where the one before it ended");
    }
}

# Undo and redo from inside.
{
    my $s = State::Store->new(1);
    my @seen;
    my $once = 0;
    $s->watch(sub { push @seen, "$_[0]>$_[1]"; $_[2]->undo if $_[1] == 3 && !$once++ });
    $s->set(2)->set(3);
    is($s->current, 2, 'a watcher may undo the change it was told of');
    is("@seen", '1>2 2>3 3>2', 'and is told of the undo');
    is($s->redo_count, 1, 'which can be redone');
}

# Removal during a round.
{
    my $s = State::Store->new(0);
    my @order;
    my ($id1, $id2, $id3);
    $id1 = $s->watch(sub { push @order, 1; $_[2]->unwatch($id1) });
    $id2 = $s->watch(sub { push @order, 2; $_[2]->unwatch($id3) });
    $id3 = $s->watch(sub { push @order, 3 });
    $s->set(1);
    is("@order", '1 2', 'a watcher may remove itself, and one it removes later in the list is not called');
    is($s->watchers, 1, 'one left');
    @order = ();
    $s->set(2);
    is("@order", '2', 'and only it is called after');
}

# Removal of every watcher, then a change queued by the last of them.
{
    my $s = State::Store->new(0);
    my @order;
    my @ids;
    push @ids, $s->watch(sub { push @order, "a$_[1]"; $_[2]->unwatch($_) for @ids; $_[2]->set(99) if $_[1] == 1 });
    push @ids, $s->watch(sub { push @order, "b$_[1]" });
    $s->set(1);
    is("@order", 'a1', 'a watcher that removes all of them leaves nobody to tell, of this change or the next');
    is($s->current, 99, 'and the change it made stands');
    is($s->watchers, 0, 'with no watchers');
}

# Adding during a round.
{
    my $s = State::Store->new(0);
    my @order;
    my $added = 0;
    $s->watch(sub {
        my ($was, $now, $store) = @_;
        push @order, "old$now";
        if (!$added++) {
            $store->watch(sub { push @order, "new$_[1]" });
            $store->set(2);
        }
    });
    $s->set(1);
    is("@order", 'old1 old2 new2', 'a watcher added during a round is first told of the next change');
}

# Dropping the last outside reference to the store from a watcher.
{
    my $s = State::Store->new(0);
    my $weak = $s;
    weaken($weak);
    my $after;
    $s->watch(sub { undef $s; $after = defined $_[2] ? $_[2]->current : 'gone' });
    $s->set(1);
    ok(!defined $s, 'a watcher that undefs the only variable holding the store');
    is($after, 1, 'still has the store it was handed, for the rest of its call');
    ok(!defined $weak, 'and the store goes once the round is over');
}

# A watcher that dies.
{
    my $s = State::Store->new(0);
    my @order;
    $s->watch(sub { push @order, 1; die "first\n" });
    $s->watch(sub { push @order, 2 });
    $s->watch(sub { push @order, 3; die "third\n" });
    ok(!eval { $s->set(1); 1 }, 'a set whose watcher dies dies');
    is($@, "first\n", 'with the first error');
    is("@order", '1 2 3', 'after every watcher has been called');
    is($s->current, 1, 'and the change stands');
    is($s->undo_count, 1, 'recorded as a step');

    @order = ();
    my $err = bless { why => 'object' }, 'Local::Error';
    my $t = State::Store->new(0);
    $t->watch(sub { die $err });
    ok(!eval { $t->undo; 1 } || 1, 'an undo with nothing to undo calls nobody');
    ok(!eval { $t->set(5); 1 }, 'an exception object');
    is($@, $err, 'arrives as itself');

    my $u = State::Store->new(0);
    $u->watch(sub { die "always\n" if $_[1] == 1; });
    $u->watch(sub { $_[2]->set(2) if $_[1] == 1 });
    ok(!eval { $u->set(1); 1 }, 'an error in the first change of a round');
    is($u->current, 2, 'does not stop the changes queued after it being made and told');
    $@ = '';
    ok(eval { $u->set(3); 1 }, 'and the store works afterwards');
}

# A watcher that changes the store every time.
{
    my $s = State::Store->new(0);
    $s->watch(sub { $_[2]->set($_[1] + 1) });
    ok(!eval { $s->set(1); 1 }, 'a watcher that changes the store on every call');
    like($@, qr/^State::Store: the watchers changed the store 10000 times in one round/, 'is stopped');
    cmp_ok($s->current, '>', 10000, 'after that many changes');
    my $n = 0;
    $s->watch(sub { $n++ });
    $s->unwatch(1);
    $s->set('done');
    is($n, 1, 'and the store is usable afterwards, with nothing left queued');
}

# swap's sub changing the store, with watchers.
{
    my $s = State::Store->new(0);
    my @seen;
    $s->watch(sub { push @seen, "$_[0]>$_[1]" });
    $s->swap(sub { $s->set('inner'); 'outer' });
    is("@seen", '0>inner inner>outer', 'a set inside a swap is told, then the swap');
}

# Many rounds, nothing on the temporaries stack, no store left over.
{
    my $tmps = State::Store::_tmps_ix();
    my $s = State::Store->new(0);
    my $n = 0;
    $s->watch(sub { $n++ }) for 1 .. 3;
    $s->set($_) for 1 .. 3000;
    is($n, 9000, '3,000 changes, three watchers');
    cmp_ok(State::Store::_tmps_ix() - $tmps, '<', 10, 'leave nothing on the temporaries stack');
}
is(State::Store::_live_blocks(), 0, 'every store in this file is gone');

done_testing;
