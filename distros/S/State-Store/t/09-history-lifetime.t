#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use State::Store;
use HAMT::Map;

# A value is alive while the store or either stack holds it, and destroyed
# once when none does. And a step on a large map costs a step, not a map.

my %gone;
{
    package Local::Counted;
    sub new { bless { name => $_[1] }, $_[0] }
    sub DESTROY { $gone{ $_[0]{name} }++ }
}
sub counted { Local::Counted->new(@_) }

my $base = State::Store::_live_blocks();
my $hamt = HAMT::_live_blocks();

{
    my $s = State::Store->new(counted('a'));
    $s->set(counted('b'))->set(counted('c'));
    is(join(',', sort keys %gone), '', 'replaced values are alive in the past');
    $s->undo(2);
    is(join(',', sort keys %gone), '', 'undone values are alive in the future');
    $s->set(counted('d'));
    is(join(',', sort keys %gone), 'b,c', 'a change after an undo destroys what could have been redone');
    is("@gone{qw(b c)}", '1 1', 'once each');
    $s->clear_history;
    is($gone{a}, 1, 'clear_history destroys what was behind');
    is($gone{d}, undef, 'and not the value');
}
is($gone{d}, 1, 'the store dropped destroys the value');
is(join(',', map { "$_=$gone{$_}" } sort keys %gone), 'a=1,b=1,c=1,d=1', 'every value destroyed exactly once');
is(State::Store::_live_blocks(), $base, 'the store\'s block is freed');
is(HAMT::_live_blocks(), $hamt, 'and every block of both stacks');

# Dropped in each state.
for my $how (qw(after_changes after_undo after_redo after_clear)) {
    %gone = ();
    {
        my $s = State::Store->new(counted(0));
        $s->set(counted($_)) for 1 .. 40;
        $s->undo(15) if $how ne 'after_changes';
        $s->redo(5) if $how eq 'after_redo';
        $s->clear_history if $how eq 'after_clear';
    }
    is(scalar(keys %gone), 41, "$how: all 41 values destroyed when the store goes");
    is(scalar(grep { $_ != 1 } values %gone), 0, "$how: each once");
    is(HAMT::_live_blocks(), $hamt, "$how: and every block given back");
}

# A DESTROY that uses the store, run by a redo stack being emptied.
{
    my $s = State::Store->new(1);
    my @seen;
    {
        package Local::Reenter;
        sub new { bless { store => $_[1] }, $_[0] }
        sub DESTROY { push @seen, [ $_[0]{store}->current, $_[0]{store}->redo_count ] }
    }
    $s->set(Local::Reenter->new($s))->set(2);
    $s->undo(2);
    $s->set(3);
    is(scalar @seen, 1, 'a value thrown off the redo stack runs its DESTROY');
    is_deeply($seen[0], [3, 0], 'and sees the store already holding the change, with nothing to redo');
}

# A value read out and then undone over, in one expression.
{
    %gone = ();
    my $s = State::Store->new(counted('first'));
    $s->set(counted('second'));
    $s->undo;
    $s->set('third');
    my @r = ($s->current, do { $s->undo; $s->clear_history; $gone{first} });
    is($r[1], undef, 'a value read out stays alive through an undo and a clear in the same expression');
}

# The cost of a step.
{
    my $before = HAMT::_live_blocks();
    my $map = HAMT::Map->new(map { ("key$_" => $_) } 1 .. 100_000);
    my $one_map = HAMT::_live_blocks() - $before;
    my $s = State::Store->new($map);
    undef $map;
    my $start = HAMT::_live_blocks();
    $s->swap(sub { $_[0]->set(key5 => $_) }) for 1 .. 1000;
    my $thousand = HAMT::_live_blocks() - $start;
    cmp_ok($thousand, '<', $one_map / 10,
           "1,000 steps on a 100,000-key map hold $thousand blocks, under a tenth of the map's $one_map");
    is($s->undo_count, 1000, 'and all 1,000 can be undone');
    $s->undo(1000);
    is($s->current->get('key5'), 5, 'to the first version');
    $s->redo(1000);
    is($s->current->get('key5'), 1000, 'and redone to the last');
    my $before_undo = HAMT::_live_blocks();
    $s->undo for 1 .. 500;
    cmp_ok(HAMT::_live_blocks() - $before_undo, '<', 2000,
           'five hundred single undos move values, they do not copy the map');
}
is(HAMT::_live_blocks(), $hamt, 'and all of that is given back');
is(State::Store::_live_blocks(), $base, 'with every store');

# Many stores, many steps, nothing on the temporaries stack.
{
    my $tmps = State::Store::_tmps_ix();
    my $s = State::Store->new(0);
    for (1 .. 3000) { $s->set($_); $s->undo; $s->redo }
    cmp_ok(State::Store::_tmps_ix() - $tmps, '<', 10, '9,000 calls leave nothing on the temporaries stack');
}

done_testing;
