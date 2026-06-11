use strict;
use warnings;
use Test::Most;

# Tests for bypass mechanisms: $BYPASS and HARNESS_ACTIVE, in enforce mode.
# Both bypass mechanisms must independently disable access checks (OR logic).

# Must be set via BEGIN so the value is in place when the CHECK-phase
# attribute handler fires (before any runtime code runs).
BEGIN { $Sub::Private::config{mode} = 'enforce' }

use Sub::Private;

local $ENV{HARNESS_ACTIVE}  = 0;
local $Sub::Private::BYPASS = 0;

{
	package BPFoo;
	use Sub::Private;
	sub new      { bless {}, shift }
	sub _secret  :Private { 'secret' }
}

my $obj = BPFoo->new;

# Baseline: external call blocked when both bypass mechanisms are off
throws_ok { BPFoo::_secret($obj) }
	qr/private subroutine/,
	'baseline: external call blocked with both bypass mechanisms off';

# Test 1: $BYPASS=1 alone is sufficient
{
	local $Sub::Private::BYPASS = 1;
	lives_and { is BPFoo::_secret($obj), 'secret' }
		'$BYPASS=1 disables the access check globally';
}

# Test 2: HARNESS_ACTIVE=1 alone is sufficient (when harness_bypass=1)
{
	local $ENV{HARNESS_ACTIVE} = 1;
	lives_and { is BPFoo::_secret($obj), 'secret' }
		'HARNESS_ACTIVE=1 disables the access check globally';
}

# Test 3: both restored after scope exits -- checks re-enabled
throws_ok { BPFoo::_secret($obj) }
	qr/private subroutine/,
	'check re-enabled after both bypass scopes exit';

# Test 4: $BYPASS restores correctly after local scope
{
	local $Sub::Private::BYPASS = 1;
	lives_ok { BPFoo::_secret($obj) } 'BYPASS=1 active inside scope';
}
throws_ok { BPFoo::_secret($obj) }
	qr/private subroutine/,
	'$BYPASS restored to 0 after scope exits';

# Test 5: harness_bypass=0 with HARNESS_ACTIVE=1 still enforces
{
	local $Sub::Private::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                  = 1;
	local $Sub::Private::BYPASS                 = 0;

	throws_ok { BPFoo::_secret($obj) }
		qr/private subroutine/,
		'harness_bypass=0: HARNESS_ACTIVE=1 no longer bypasses checks';
}

# Test 6: $BYPASS still works regardless of harness_bypass setting
{
	local $Sub::Private::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                  = 0;
	local $Sub::Private::BYPASS                 = 1;

	lives_ok { BPFoo::_secret($obj) }
		'$BYPASS=1 bypasses even when harness_bypass=0';
}

done_testing;
