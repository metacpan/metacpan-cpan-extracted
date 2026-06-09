use strict;
use warnings;
use Test::Most;
use Sub::Protected;

# Test 11: attribute form — sub foo :Protected.

local $ENV{HARNESS_ACTIVE}    = 0;
local $Sub::Protected::BYPASS = 0;

{
    package AttrFoo;
    use Sub::Protected;
    sub new    { bless {}, shift }
    sub _inner :Protected { 'inner' }
    sub outer  { (shift)->_inner }
}

{
    package AttrBar;
    sub probe { AttrFoo->new->_inner }
}

my $obj = AttrFoo->new;

# External blocked
throws_ok { AttrBar::probe() }
    qr/\Q_inner() is a protected method of AttrFoo and cannot be called from AttrBar\E/,
    'attribute form: external caller blocked';

# Owner allowed
lives_and { is $obj->outer, 'inner' }
    'attribute form: owner package can call protected sub';

# Multiple protected subs in the same package
{
    package AttrMulti;
    use Sub::Protected;
    sub new { bless {}, shift }
    sub _x  :Protected { 'x' }
    sub _y  :Protected { 'y' }
    sub run { my $s = shift; $s->_x . $s->_y }
}

my $got;
lives_ok { $got = AttrMulti->new->run } 'attribute form: owner can call multiple protected subs';
is $got, 'xy', 'attribute form: two protected subs in same package both callable by owner';

throws_ok { AttrMulti::_x(AttrMulti->new) }
    qr/protected method/, 'attribute form: _x blocked from outside';
throws_ok { AttrMulti::_y(AttrMulti->new) }
    qr/protected method/, 'attribute form: _y blocked from outside independently';

done_testing;
