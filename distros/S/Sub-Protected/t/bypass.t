use strict;
use warnings;
use Test::Most;
use Sub::Protected;

# Tests 5-6: $BYPASS and HARNESS_ACTIVE each independently bypass all checks.
# Start with both off so we can test enabling them selectively.
local $ENV{HARNESS_ACTIVE}    = 0;
local $Sub::Protected::BYPASS = 0;

{
    package BPFoo;
    use Sub::Protected;
    sub new     { bless {}, shift }
    sub _secret :Protected { 'secret' }
}

my $obj = BPFoo->new;

# Baseline: external call is blocked when both are off
throws_ok { BPFoo::_secret($obj) }
    qr/protected method/,
    'baseline: external call blocked with both bypass mechanisms off';

# Test 5: $Sub::Protected::BYPASS=1 alone is sufficient
{
    local $Sub::Protected::BYPASS = 1;
    lives_and { is BPFoo::_secret($obj), 'secret' }
        '$BYPASS=1 disables the check globally';
}

# Test 6: $ENV{HARNESS_ACTIVE} alone is sufficient
{
    local $ENV{HARNESS_ACTIVE} = 1;
    lives_and { is BPFoo::_secret($obj), 'secret' }
        'HARNESS_ACTIVE=1 disables the check globally';
}

# Confirm neither bled out of scope
throws_ok { BPFoo::_secret($obj) }
    qr/protected method/,
    'check re-enabled after both bypass scopes exit';

done_testing;
