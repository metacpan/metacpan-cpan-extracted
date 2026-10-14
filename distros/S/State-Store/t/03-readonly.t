#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use State::Store;

# The stored scalar is read-only and get hands out that scalar itself. The
# caller's own variable is never touched.

my $s = State::Store->new('value');

is(refaddr(\$s->current), refaddr(\$s->current), 'get returns the same scalar each time');
ok(Internals::SvREADONLY(${ \$s->current }), 'and it is read-only');

ok(!eval { $_ .= 'x' for $s->current; 1 }, 'writing through an alias dies');
like($@, qr/Modification of a read-only value/, 'as a read-only value does');
is($s->current, 'value', 'and the store holds what it held');

ok(!eval { ${ \$s->current } = 'other'; 1 }, 'assigning through a reference dies too');
is($s->current, 'value', 'and changes nothing');

{
    my $mine = 'mine';
    $s->set($mine);
    ok(!Internals::SvREADONLY($mine), 'the variable a value was set from is not made read-only');
    $mine .= ' still';
    is($mine, 'mine still', 'and can be changed');
    is($s->current, 'mine', 'without changing the store');
    isnt(refaddr(\$s->current), refaddr(\$mine), 'they are two scalars');
}

{
    my $copy = $s->current;
    ok(!Internals::SvREADONLY($copy), 'a copy of what get returned is an ordinary scalar');
    $copy = 'changed';
    is($s->current, 'mine', 'and changing it does not reach the store');
}

# A read-only scalar is stored like any other.
{
    my $ro = 'frozen';
    Internals::SvREADONLY($ro, 1);
    $s->set($ro);
    is($s->current, 'frozen', 'a read-only scalar from elsewhere is stored');
    isnt(refaddr(\$s->current), refaddr(\$ro), 'as a copy');
    $s->set('lit');
    is($s->current, 'lit', 'and so is a literal');
}

# Shallow: the reference cannot be replaced, what it refers to can.
{
    my $list = [1, 2];
    $s->set($list);
    ok(Internals::SvREADONLY(${ \$s->current }), 'a stored reference is a read-only scalar');
    ok(!Internals::SvREADONLY(@$list), 'the array it refers to is not');
    push @{ $s->current }, 3;
    is_deeply($list, [1, 2, 3], 'so a push through the store reaches the caller\'s array');
    is(refaddr($s->current), refaddr($list), 'which is the one array');
}

# undef is a stored value too, and not the interpreter's shared one.
{
    $s->set(undef);
    my $r = \$s->current;
    ok(Internals::SvREADONLY($$r), 'a stored undef is read-only');
    isnt(refaddr($r), refaddr(\undef), 'and is not the shared undef');
}

done_testing;
