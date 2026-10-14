#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;
use HAMT::Map;

# undo, redo, the counts and clear_history.

{
    my $s = State::Store->new('a');
    ok(!$s->can_undo, 'a new store has nothing to undo');
    ok(!$s->can_redo, 'or to redo');
    is($s->undo_count, 0, 'undo_count is 0');
    is($s->redo_count, 0, 'redo_count is 0');
    is($s->undo, 0, 'undo with nothing to undo takes no step');
    is($s->redo, 0, 'nor does redo');
    is($s->current, 'a', 'and the value is unchanged');

    $s->set('b')->set('c')->set('d');
    is($s->undo_count, 3, 'three changes are three steps');
    ok($s->can_undo, 'can_undo');
    ok(!$s->can_redo, 'and nothing to redo yet');

    is($s->undo, 1, 'undo takes one step');
    is($s->current, 'c', 'back to the value before');
    is($s->undo_count, 2, 'two left to undo');
    is($s->redo_count, 1, 'one to redo');
    ok($s->can_redo, 'can_redo');

    is($s->undo, 1, 'again');
    is($s->current, 'b', 'and again');
    is($s->redo, 1, 'redo takes one back');
    is($s->current, 'c', 'to the value it was');
    is($s->redo, 1, 'and the next');
    is($s->current, 'd', 'to the last');
    is($s->redo, 0, 'and then there is nothing to redo');
    is($s->current, 'd', 'and nothing changes');

    is($s->undo, 1, 'undo');
    is($s->undo, 1, 'undo');
    is($s->undo, 1, 'undo');
    is($s->current, 'a', 'to the very first value');
    is($s->undo, 0, 'and no further');
    is($s->current, 'a', 'staying there');
    is($s->redo_count, 3, 'with three to redo');
}

# Several at once.
{
    my $s = State::Store->new(0);
    $s->set($_) for 1 .. 10;
    is($s->undo(3), 3, 'undo(3) takes three steps');
    is($s->current, 7, 'to three back');
    is($s->redo_count, 3, 'and three can be redone');
    is($s->redo(2), 2, 'redo(2) takes two back');
    is($s->current, 9, 'to where that leaves it');
    is($s->undo(100), 9, 'undo(100) with nine to take takes nine');
    is($s->current, 0, 'all the way back');
    is($s->redo(100), 10, 'redo(100) takes all ten back');
    is($s->current, 10, 'all the way forward');
    is($s->undo(0), 0, 'undo(0) takes none');
    is($s->current, 10, 'and changes nothing');
    is($s->undo('2'), 2, 'a count can be a string of digits');
    is($s->current, 8, 'and is counted');
    $s->redo(2);
    my @one_by_one;
    my $t = State::Store->new(0);
    $t->set($_) for 1 .. 10;
    $t->undo for 1 .. 4;
    is($t->current, $s->undo(4) && $s->current, 'undo(4) is four single undos');
    is_deeply([State::Store::_stacks($t)], [State::Store::_stacks($s)], 'with the same stacks after');
    $t->redo for 1 .. 3;
    $s->redo(3);
    is_deeply([State::Store::_stacks($t)], [State::Store::_stacks($s)], 'and redo(3) is three redos');
}

for my $bad (-1, 1.5, 'two', undef, '', [1]) {
    my $s = State::Store->new(1)->set(2);
    ok(!eval { $s->undo($bad); 1 }, 'undo(' . (defined $bad ? (ref $bad ? 'a reference' : "'$bad'") : 'undef') . ') dies');
    like($@, qr/^State::Store::undo: the number of steps/, 'saying so');
    is($s->current, 2, 'and takes no step');
}
ok(!eval { State::Store->new->redo(1, 2); 1 }, 'redo with two counts dies');

{
    package Local::Steps;
    sub TIESCALAR { my $n = 0; bless \$n, shift }
    sub FETCH { ${ $_[0] }++; 2 }
    sub STORE { }
    package main;
    tie my $steps, 'Local::Steps';
    my $s = State::Store->new(1)->set(2)->set(3);
    is($s->undo($steps), 2, 'a tied count is read');
    is(${ tied $steps }, 1, 'once');
}

# A new change throws away what could have been redone.
{
    my $s = State::Store->new('a');
    $s->set('b')->set('c');
    $s->undo(2);
    is($s->redo_count, 2, 'two to redo');
    $s->set('x');
    is($s->redo_count, 0, 'a change after an undo leaves nothing to redo');
    is($s->undo_count, 1, 'and one step to undo');
    $s->undo;
    is($s->current, 'a', 'which goes back to where the change was made');
    is($s->redo, 1, 'and redoes to');
    is($s->current, 'x', 'the change, not what was thrown away');
}

# A change that is no change is not a step, and keeps the redo stack.
{
    my $s = State::Store->new(1);
    $s->set(2)->set(3);
    $s->undo;
    $s->set(2);
    is($s->redo_count, 1, 'setting the value already held does not empty the redo stack');
    is($s->undo_count, 1, 'and is not a step');
    $s->swap(sub { $_[0] });
    is($s->undo_count, 1, 'nor is a swap that returns what it was given');
    is($s->redo, 1, 'and the redo is still there');
    is($s->current, 3, 'to be taken');
}

# A step back to a value equal to the current one is still a step.
{
    my $s = State::Store->new('same');
    $s->set('other')->set('same');
    is($s->undo_count, 2, 'two changes, back to a value seen before, are two steps');
    $s->undo;
    is($s->current, 'other', 'undo goes through the middle');
}

# swap is a step like set.
{
    my $s = State::Store->new(1);
    $s->swap(sub { $_[0] + 1 }) for 1 .. 5;
    is($s->undo_count, 5, 'five swaps are five steps');
    $s->undo(5);
    is($s->current, 1, 'and undo to the start');
    ok(!eval { $s->swap(sub { die "no\n" }); 1 }, 'a swap that dies');
    is($s->redo_count, 5, 'leaves the redo stack as it was');
}

# clear_history.
{
    my $s = State::Store->new(1);
    $s->set(2)->set(3)->set(4);
    $s->undo;
    is(refaddr($s->clear_history), refaddr($s), 'clear_history returns the store');
    is($s->current, 3, 'and keeps the value');
    is($s->undo_count + $s->redo_count, 0, 'with nothing to undo or redo');
    $s->set(5);
    is($s->undo, 1, 'a change after it is a step');
    is($s->current, 3, 'back to the value it kept');
}

# Values come back as themselves.
{
    my $m1 = HAMT::Map->new(a => 1);
    my $m2 = $m1->set(b => 2);
    my $s = State::Store->new($m1);
    $s->set($m2);
    $s->undo;
    is(refaddr($s->current), refaddr($m1), 'undo makes the first map current, the same object');
    $s->redo;
    is(refaddr($s->current), refaddr($m2), 'redo the second');
    ok(Internals::SvREADONLY(${ \$s->current }), 'and a value undone to is read-only');

    my $t = State::Store->new("caf\x{e9}");
    $t->set("sm\x{263a}le")->set(undef)->set('');
    $t->undo(3);
    is($t->current, "caf\x{e9}", 'a Latin-1 string comes back as it was');
    $t->redo;
    is($t->current, "sm\x{263a}le", 'and a wide one');
    $t->redo;
    is($t->current, undef, 'and undef');
    $t->redo;
    is($t->current, '', 'and the empty string');
}

# A store's stacks are its own.
{
    my $a = State::Store->new(1);
    my $b = State::Store->new(1);
    $a->set(2);
    $b->set(3);
    $a->undo;
    is($b->current, 3, 'undo in one store does nothing to another');
    is($b->undo_count, 1, 'or to its history');
}

done_testing;
