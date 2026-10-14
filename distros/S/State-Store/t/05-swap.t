#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;
use HAMT::Map;

# swap: the value becomes what a sub makes of the current one.

{
    my $s = State::Store->new(10);
    my @args;
    my $r = $s->swap(sub { @args = @_; $_[0] + 1 });
    is(refaddr($r), refaddr($s), 'swap returns the store');
    is($s->current, 11, 'the value is what the sub returned');
    is_deeply(\@args, [10], 'the sub was given the current value and nothing else');

    $s->swap(sub { my ($current, $by, $times) = @_; $current + $by * $times }, 5, 2);
    is($s->current, 21, 'further arguments are passed on after the value');
    is($s->swap(sub { $_[0] * 2 })->swap(sub { $_[0] + 1 })->current, 43, 'and calls chain');
}

{
    my $s = State::Store->new('x');
    my ($calls, $context) = (0);
    $s->swap(sub { $calls++; $context = wantarray; 'y' });
    is($calls, 1, 'the sub is called once');
    is($context, '', 'in scalar context');
    $s->swap(sub { (1, 2, 3) });
    is($s->current, 3, 'so a list is its last element');
    $s->swap(sub { my @list = (7, 8); @list });
    is($s->current, 2, 'and an array is its length');
    $s->swap(sub { return });
    is($s->current, undef, 'a sub that returns nothing sets undef');
    $s->swap(sub { });
    is($s->current, undef, 'as does an empty one');
}

# What the sub is handed is the stored scalar.
{
    my $s = State::Store->new('held');
    my $addr;
    $s->swap(sub { $addr = refaddr(\$_[0]); ok(!eval { $_[0] = 'no'; 1 }, 'the argument is read-only'); 'next' });
    isnt($addr, undef, 'the sub saw a value');
    is($s->current, 'next', 'and its return was stored');
}

# Returning the value it was given changes nothing.
{
    my $obj = bless [], 'Local::Thing';
    my $s = State::Store->new($obj);
    my $before = refaddr(\$s->current);
    $s->swap(sub { $_[0] });
    is(refaddr(\$s->current), $before, 'a sub that returns its argument leaves the very scalar in place');
    $s->swap(sub { my $copy = $_[0]; $copy });
    is(refaddr(\$s->current), $before, 'and so does one that returns a copy of it');
    my $n = State::Store->new(5);
    $before = refaddr(\$n->current);
    $n->swap(sub { $_[0] + 0 });
    is(refaddr(\$n->current), $before, 'an equal number is no change');
    $n->swap(sub { '5' });
    is(refaddr(\$n->current), $before, 'nor is the string that spells it');
    $n->swap(sub { 6 });
    isnt(refaddr(\$n->current), $before, 'a different one is');
}

# A die leaves the store as it was.
{
    my $s = State::Store->new('safe');
    my $before = refaddr(\$s->current);
    ok(!eval { $s->swap(sub { die "refused\n" }); 1 }, 'a sub that dies');
    is($@, "refused\n", 'dies with its own error');
    is($s->current, 'safe', 'and the store holds what it held');
    is(refaddr(\$s->current), $before, 'the very scalar');
    my $err = bless { code => 7 }, 'Local::Error';
    ok(!eval { $s->swap(sub { die $err }); 1 }, 'an exception object');
    is($@, $err, 'arrives as itself');
    is($s->swap(sub { 'after' })->current, 'after', 'and the store works afterwards');
}

# The sub may use the store.
{
    my $s = State::Store->new('start');
    my $seen;
    $s->swap(sub { $seen = $s->current; 'done' });
    is($seen, 'start', 'get inside the sub sees the current value');
    $s->swap(sub { my $current = shift; $s->set('from inside'); "$current, then swapped" });
    is($s->current, 'done, then swapped', 'a sub that sets the store: what it returns is what stays');
    $s->swap(sub { $s->set('inner'); $_[0] });
    is($s->current, 'done, then swapped', 'even when what it returns is the value it was given');
    $s->swap(sub { $s->swap(sub { 'nested' }); $s->current . ' and outer' });
    is($s->current, 'nested and outer', 'a swap inside a swap');
}

# The sub may drop the store.
{
    my $s = State::Store->new(1);
    my $r = $s->swap(sub { undef $s; 2 });
    ok(!defined $s, 'a sub that undefs the only variable holding the store');
    pass('does not crash the swap');
}

# With a map, which is what it is for.
{
    my $s = State::Store->new(HAMT::Map->new(count => 0));
    $s->swap(sub { $_[0]->set(count => $_[0]->get('count') + 1) }) for 1 .. 1000;
    is($s->current->get('count'), 1000, 'a thousand increments of a key in a map');
    my $addr = refaddr($s->current);
    $s->swap(sub { $_[0]->set(count => $_[0]->get('count')) });
    is(refaddr($s->current), $addr, 'an update that changes nothing is no change to the store');
}

# What is not a sub.
for my $bad (undef, 'name', 42, [], {}, \'x') {
    my $s = State::Store->new('kept');
    ok(!eval { $s->swap($bad); 1 }, 'swap with ' . (defined $bad ? (ref $bad || "'$bad'") : 'undef') . ' dies');
    like($@, qr/^State::Store::swap: not a code reference/, 'saying what it wanted');
    is($s->current, 'kept', 'and the store is untouched');
}
ok(!eval { State::Store->new->swap; 1 }, 'swap with nothing dies');

# No leak of temporaries across many swaps.
{
    my $s = State::Store->new(0);
    my $tmps = State::Store::_tmps_ix();
    $s->swap(sub { $_[0] + 1 }) for 1 .. 5000;
    is($s->current, 5000, '5,000 swaps');
    cmp_ok(State::Store::_tmps_ix() - $tmps, '<', 10, 'leave nothing on the temporaries stack');
}

done_testing;
