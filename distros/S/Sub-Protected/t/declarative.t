use strict;
use warnings;
use Test::Most;

# Test 10: declarative import form — use Sub::Protected qw(sub_name).
# Subs are defined in the same file; wrapping happens at CHECK time.

local $ENV{HARNESS_ACTIVE}    = 0;
local $Sub::Protected::BYPASS = 0;

{
    package DecFoo;
    use Sub::Protected qw(_private);

    sub new     { bless {}, shift }
    sub _private { 'private value' }
    sub public  { (shift)->_private }
}

{
    package DecExternal;
    sub probe { DecFoo->new->_private }
}

my $obj = DecFoo->new;

# External caller blocked
throws_ok { DecExternal::probe() }
    qr/\Q_private() is a protected method of DecFoo and cannot be called from DecExternal\E/,
    'declarative form: external caller blocked';

# Owner allowed
lives_and { is $obj->public, 'private value' }
    'declarative form: owner package can call protected sub';

# Multiple subs in one import
{
    package DecMulti;
    use Sub::Protected qw(_a _b);

    sub new { bless {}, shift }
    sub _a  { 'a' }
    sub _b  { 'b' }
    sub run { my $s = shift; $s->_a . $s->_b }
}

my $got;
lives_ok { $got = DecMulti->new->run } 'declarative form: owner can call multiple wrapped subs';
is $got, 'ab', 'declarative form: multiple subs wrapped in one import';

throws_ok { DecMulti::_a(DecMulti->new) }
    qr/protected method/,
    'declarative form: first of multiple subs still protected from outside';

done_testing;
