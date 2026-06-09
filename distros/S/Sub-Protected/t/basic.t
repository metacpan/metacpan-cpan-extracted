use strict;
use warnings;
use Test::Most;
use Sub::Protected;

# Tests 1-2, 7-8: block/allow, BYPASS scoping, error message format.
# Disable both bypass mechanisms for this file so checks actually fire.
local $ENV{HARNESS_ACTIVE}       = 0;
local $Sub::Protected::BYPASS    = 0;

{
    package Foo;
    use Sub::Protected;
    sub new        { bless {}, shift }
    sub _helper    :Protected { 'helper result' }
    sub public_call { (shift)->_helper }
}

{
    package External;
    sub probe { Foo->new->_helper }
}

# Test 1: external caller blocked
throws_ok { External::probe() }
    qr/\Q_helper() is a protected method of Foo and cannot be called from External\E/,
    'external package is blocked';

# Test 2: owner package call allowed
my $foo = Foo->new;
lives_and { is $foo->public_call, 'helper result' }
    'owner package can call its own protected sub';

# Test 7: local $BYPASS restores correctly after block
{
    local $Sub::Protected::BYPASS = 1;
    lives_ok { Foo::_helper($foo) } 'BYPASS=1 allows external call';
}
throws_ok { Foo::_helper($foo) }
    qr/protected method/,
    'BYPASS restored to 0 after scope exits';

# Test 8: error message matches spec exactly
eval { External::probe() };
like $@,
    qr/\Q_helper() is a protected method of Foo and cannot be called from External\E/,
    'error message format matches spec';

done_testing;
