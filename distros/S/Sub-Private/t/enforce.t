use strict;
use warnings;
use Test::Most;

# Tests for enforce mode: OO-safe private access.
# The critical semantic: private = owner package ONLY.
# Subclasses are BLOCKED (unlike Sub::Protected which allows them).

# Must be set via BEGIN so the value is in place when the CHECK-phase
# attribute handler fires (before any runtime code runs).
BEGIN { $Sub::Private::config{mode} = 'enforce' }

use Sub::Private;

local $ENV{HARNESS_ACTIVE}  = 0;
local $Sub::Private::BYPASS = 0;

# ---- Fixture packages (all compiled with enforce mode active) ----

{
	package EFoo;
	use Sub::Private;

	sub new      { bless {}, shift }
	sub _helper  :Private { 'helper result' }
	sub call_it  { (shift)->_helper }
}

{
	package EFooChild;
	our @ISA = ('EFoo');
	sub new { bless {}, shift }
	# Attempt to call parent's private sub from subclass
	sub try_helper { (shift)->_helper }
}

{
	package EExternal;
	sub new   { bless {}, shift }
	sub probe { EFoo->new->_helper }
}

# ---- Test 1: owner package can call its own private sub ----

my $foo = EFoo->new;
my $result;
lives_and { is $result = $foo->call_it, 'helper result' }
	'enforce mode: owner package can call its own private sub';

# ---- Test 2: external package is blocked ----

throws_ok { EExternal->new->probe }
	qr/\Q_helper() is a private subroutine of EFoo and cannot be called from EExternal\E/,
	'enforce mode: external package blocked with canonical error message';

# ---- Test 3: subclass is BLOCKED (private != protected) ----

my $child = EFooChild->new;
throws_ok { $child->try_helper }
	qr/_helper\(\) is a private subroutine of EFoo/,
	'enforce mode: subclass is blocked (private means owner-only, no isa allowance)';

# ---- Test 4: error message format matches spec exactly ----

eval { EExternal->new->probe };
like $@,
	qr/\Q_helper() is a private subroutine of EFoo and cannot be called from EExternal\E/,
	'enforce mode: error message format matches spec';

# ---- Test 5: caller() inside the private sub sees real caller (goto is load-bearing) ----

{
	package ECallerCheck;
	use Sub::Private;

	sub new         { bless {}, shift }
	sub _inner      :Private { (caller(0))[0] }   # reports caller's package
	sub get_caller  { (shift)->_inner }
}

my $caller_pkg;
lives_ok { $caller_pkg = ECallerCheck->new->get_caller }
	'enforce mode: caller() inside private sub is reachable';
is $caller_pkg, 'ECallerCheck',
	'enforce mode: caller() inside private sub reports real caller (not Sub::Private)';

# ---- Test 6: private sub calling sibling private sub in same package ----

{
	package ESiblings;
	use Sub::Private;

	sub new   { bless {}, shift }
	sub _one  :Private { 'one' }
	sub _two  :Private { my $s = shift; 'two+' . $s->_one }
	sub run   { (shift)->_two }
}

my $got;
lives_ok { $got = ESiblings->new->run } 'enforce mode: private sub can call sibling private sub';
is $got, 'two+one', 'enforce mode: chained private result is correct';

done_testing;
