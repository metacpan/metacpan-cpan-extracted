#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use State::Store;
use HAMT::Map;

# Every value is destroyed exactly once, and when it should be. The values
# are objects whose DESTROY counts.

my %gone;
{
    package Local::Counted;
    sub new { my ($class, $name) = @_; bless { name => $name }, $class }
    sub DESTROY { $gone{ $_[0]{name} }++ }
}
sub counted { Local::Counted->new(@_) }

my $base = State::Store::_live_blocks();

{
    my $s = State::Store->new(counted('first'));
    is(State::Store::_live_blocks(), $base + 1, 'a store is one block of this library\'s');
    is($gone{first}, undef, 'the value is alive while the store holds it');
    $s->set(counted('second'));
    is($gone{first}, undef, 'a value replaced is kept, to be undone to');
    $s->clear_history;
    is($gone{first}, 1, 'and destroyed when the history is cleared');
    is($gone{second}, undef, 'while the new one is alive');
    $s->set(counted('third'))->set(counted('fourth'))->clear_history;
    is("@gone{qw(first second third)}", '1 1 1', 'each replaced value once');
}
is($gone{fourth}, 1, 'a store dropped destroys its value');
is(State::Store::_live_blocks(), $base, 'and frees its block');
is(join(',', map { "$_=$gone{$_}" } sort keys %gone), 'first=1,fourth=1,second=1,third=1',
   'four values, each destroyed once');

# A value held elsewhere outlives the store, and the store outlives nothing.
{
    %gone = ();
    my $held;
    {
        my $s = State::Store->new(counted('kept'));
        $held = $s->current;
    }
    is($gone{kept}, undef, 'a value read out is alive after its store has gone');
    undef $held;
    is($gone{kept}, 1, 'and destroyed when the last holder lets go');
}

# A value read out and then replaced, in one expression.
{
    %gone = ();
    my $s = State::Store->new(counted('early'));
    my @r = ($s->current, do { $s->set('later')->clear_history; $gone{early} });
    is($r[1], undef, 'a value read out is alive while the store replaces it in the same expression');
    isa_ok($r[0], 'Local::Counted');
    @r = ();
    is($gone{early}, 1, 'and destroyed once it is let go');
}

# Setting the value already held destroys nothing.
{
    %gone = ();
    my $obj = counted('same');
    my $s = State::Store->new($obj);
    $s->set($obj) for 1 .. 5;
    $s->set($s->current);
    is($gone{same}, undef, 'setting the value already held leaves it alone');
    undef $obj;
    is($gone{same}, undef, 'the store still holds it');
    undef $s;
    is($gone{same}, 1, 'until the store goes');
}

# A DESTROY that uses the store it is leaving.
{
    %gone = ();
    my $s = State::Store->new;
    my @seen;
    {
        package Local::Reenter;
        sub new { bless { store => $_[1], say => $_[2] }, $_[0] }
        sub DESTROY {
            my $self = shift;
            push @seen, $self->{store}->current;
            $self->{store}->set($self->{say});
        }
    }
    $s->set(Local::Reenter->new($s, 'from DESTROY'));
    $s->set('replacement')->clear_history;
    is($seen[0], 'replacement', 'a value being destroyed sees the store already holding its successor');
    is($s->current, 'from DESTROY', 'and may set the store, which holds what it set');
    is(State::Store::_live_blocks(), $base + 1, 'with one block still');
}

# A DESTROY that drops the last other reference to the store, mid-set.
{
    my $s = State::Store->new;
    my $ref = \$s;
    {
        package Local::Dropper;
        sub new { bless { ref => $_[1] }, $_[0] }
        sub DESTROY { ${ $_[0]{ref} } = undef }
    }
    $s->set(Local::Dropper->new($ref));
    $s->set('after');
    my $returned = $s->clear_history;
    ok(!defined $s, 'a DESTROY that undefs the only variable holding the store');
    pass('does not crash the clear_history that caused it');
}
is(State::Store::_live_blocks(), $base, 'and the store is freed afterwards');

# A HAMT map as the value: versions are released with the store.
{
    my $blocks = HAMT::_live_blocks();
    {
        my $s = State::Store->new(HAMT::Map->new(map { ("k$_" => $_) } 1 .. 500));
        $s->set($s->current->set("new$_" => $_)) for 1 .. 200;
        is($s->current->count, 700, 'two hundred updates stored back');
        cmp_ok(HAMT::_live_blocks(), '>', $blocks, 'held in HAMT\'s blocks');
    }
    is(HAMT::_live_blocks(), $blocks, 'all given back when the store goes');
}

# Many stores, many sets, nothing left.
{
    my $tmps = State::Store::_tmps_ix();
    for my $round (1 .. 2000) {
        my $s = State::Store->new($round);
        $s->set("v$_") for 1 .. 5;
        my $got = $s->current;
    }
    is(State::Store::_live_blocks(), $base, '2,000 stores made and dropped leave no block');
    cmp_ok(State::Store::_tmps_ix() - $tmps, '<', 10, 'and nothing piling up on the temporaries stack');
}

done_testing;
