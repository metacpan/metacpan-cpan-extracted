#!/usr/bin/perl
# t/function.t -- white-box function-level tests for Sub::Abstract.
#
# Tests every internal helper and public entry point in isolation.
# Where Test::Mockingbird is available, non-core dependencies are spied
# on or mocked so each function is exercised on its own behaviour.
#
# Key differences from the sister modules:
#   * _wrap() takes no $code argument (the wrapper never delegates)
#   * _process_one() does NOT require the named sub to pre-exist
#   * There is no _check_access() or _assert_known_mode()
#   * The closure always croaks regardless of who calls it (no caller check)

use strict;
use warnings;

# Taint-safe INC manipulation: untaint $HOME for local lib paths
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC,
		'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(reftype);

# Loading the module fires CHECK, wrapping all :Abstract and declarative
# methods defined in the package fixtures below.
use Sub::Abstract;

# -------------------------------------------------------------------
# Constants -- avoid magic strings throughout this file
# -------------------------------------------------------------------

Readonly::Scalar my $SA      => 'Sub::Abstract';
Readonly::Scalar my $OWNER   => 'FT::Owner';
Readonly::Scalar my $NOIMPL  => 'FT::NoImpl';

# Test configuration hash for parameters that appear in multiple places
my %config = (
	attr_method     => 'abstract_op',
	decl_method     => 'decl_op',
	impl_result     => 'implemented',
	invalid_digit   => '123bad',
	invalid_hyphen  => 'has-hyphen',
	invalid_empty   => q{},
	nonexistent_sub => '_ft_nonexistent_xyz',
	proc_target     => '_proc_tgt',
	wrap_sub        => '_wrap_target',
);

# -------------------------------------------------------------------
# Package fixtures -- defined at compile time so :Abstract and
# declarative wrapping happen at CHECK time, exactly as documented.
# -------------------------------------------------------------------

# Base class for attribute-form tests.
{
	package FT::Owner;
	use Sub::Abstract;

	sub new         { bless {}, shift }
	sub abstract_op :Abstract { }    # stub required for Attribute::Handlers
	sub _bare       { 'bare' }       # an unwrapped sub used in _wrap tests
}

# Subclass that provides an implementation -- wrapper must never fire.
{
	package FT::Impl;
	our @ISA = ('FT::Owner');

	sub new         { bless {}, shift }
	sub abstract_op { 'implemented' }    # concrete implementation
}

# Subclass that omits the implementation -- wrapper must fire and croak.
{
	package FT::NoImpl;
	our @ISA = ('FT::Owner');

	sub new { bless {}, shift }
}

# Base class for declarative-form tests.
{
	package FT::DeclOwner;
	use Sub::Abstract qw(decl_op);
	sub new { bless {}, shift }
}

# Implementing subclass for declarative form.
{
	package FT::DeclImpl;
	our @ISA = ('FT::DeclOwner');
	sub new     { bless {}, shift }
	sub decl_op { 'decl implemented' }
}

# Fixture for direct _assert_private_caller() testing from an external package.
# _guard_helper plays the role of the guarded private function (_wrap, _process_one);
# try_assert plays the external code that invokes it.  The two-hop chain ensures
# caller(1) inside _assert_private_caller sees FT::External (the caller of
# _guard_helper), matching how the guard works in production code.
{
	package FT::External;
	sub _guard_helper { Sub::Abstract::_assert_private_caller('_test_method') }
	sub try_assert    { FT::External::_guard_helper() }
}

# Two-hop chain inside Sub::Abstract's own namespace to exercise the allow path.
# These subs are compiled as part of Sub::Abstract so caller(1) reports Sub::Abstract.
{
	package Sub::Abstract;
	## no critic (Subroutines::ProhibitBuiltinHomonyms)
	sub _ft_inner_assert { Sub::Abstract::_assert_private_caller('_ft_inner_assert') }
	sub _ft_outer_assert { Sub::Abstract::_ft_inner_assert() }
}

# Fixture for _process_one() tests -- has a pre-existing body for the target sub.
{
	package FT::ProcExisting;
	sub new      { bless {}, shift }
	sub _proc_tgt { 'original' }
}

# Fixture for _process_one() tests -- NO pre-existing body for the target sub.
{
	package FT::ProcBodyless;
	sub new { bless {}, shift }
	# _proc_tgt is intentionally NOT defined here
}

# Fixture for the set_return spy test -- a sub to protect
{
	package FT::SetReturnSpy;
	sub _sr_sub { 'sr' }
}

diag "Starting white-box function tests for $SA" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: import()
#
# Tests every branch inside import(): no-args early-return, identifier
# validation, the fail-fast loop, and the pre-/post-CHECK dispatch.
# ===================================================================

# No-args: must return the class name immediately without touching the stash.
subtest 'import(): no-args returns the class name' => sub {
	plan tests => 2;

	my $result = Sub::Abstract->import();

	# The return value must be the class name as a plain string
	is $result, $SA, 'import() returns the class name';
	returns_ok($result, { type => 'string' }, 'return value satisfies string schema');
};

# No-args: must not wrap any existing sub in the calling package.
subtest 'import(): no-args does not modify any stash entry' => sub {
	plan tests => 1;

	# Capture the coderef of an unwrapped sub before and after the call
	my $before = \&FT::Owner::_bare;
	Sub::Abstract->import();
	my $after  = \&FT::Owner::_bare;

	# The coderef must be the same object -- nothing was replaced
	is $before, $after, 'import() no-args left _bare untouched';
};

# Identifier starting with a digit is not a valid Perl sub name.
subtest 'import(): rejects identifier starting with a digit' => sub {
	plan tests => 2;

	my $bad = $config{invalid_digit};

	# The exact documented message must appear in the exception
	throws_ok { Sub::Abstract->import($bad) }
		qr/\Q$SA\E->import: '\Q$bad\E' is not a valid Perl identifier/,
		'digit-start: exact documented error message';

	# Also confirm the required phrase appears (separate check for clarity)
	throws_ok { Sub::Abstract->import($bad) }
		qr/is not a valid Perl identifier/,
		'digit-start: error contains required phrase';
};

# A hyphen in the middle of a name is not a valid Perl identifier.
subtest 'import(): rejects identifier containing a hyphen' => sub {
	plan tests => 1;

	throws_ok { Sub::Abstract->import($config{invalid_hyphen}) }
		qr/\Q$SA\E->import: '\Q$config{invalid_hyphen}\E' is not a valid Perl identifier/,
		'hyphen identifier: exact documented error message';
};

# Empty string is not a valid sub name.
subtest 'import(): rejects empty-string identifier' => sub {
	plan tests => 1;

	throws_ok { Sub::Abstract->import($config{invalid_empty}) }
		qr/is not a valid Perl identifier/,
		'empty string: croaks with the documented phrase';
};

# undef must be coerced to '' and then rejected, not cause an uninitialized warning.
subtest 'import(): rejects undef in the sub name list' => sub {
	plan tests => 1;

	throws_ok { Sub::Abstract->import(undef) }
		qr/is not a valid Perl identifier/,
		'undef in import list: croaks with documented phrase';
};

# A reference in the list is also not a valid identifier.
subtest 'import(): rejects a reference in the sub name list' => sub {
	plan tests => 1;

	throws_ok { Sub::Abstract->import([]) }
		qr/is not a valid Perl identifier/,
		'arrayref in import list: croaks with documented phrase';
};

# Validation is fail-fast and all-or-nothing: if any name is invalid, nothing
# gets wrapped -- the good name before the bad one must remain unwrapped.
subtest 'import(): fail-fast all-or-nothing -- no partial wrapping' => sub {
	plan tests => 2;

	# Define a fresh package with a sub that should remain callable after the failure
	{ package FT::FailFast; sub _ff_good { 'good' } }

	# The bad name comes second; the good name must NOT be wrapped
	throws_ok {
		package FT::FailFast;
		Sub::Abstract->import('_ff_good', $config{invalid_digit});
	} qr/is not a valid Perl identifier/,
		'import() croaks on bad name in the list';

	# If _ff_good were wrapped, calling it would croak (it is now "abstract").
	# Calling it from outside FT::FailFast must still succeed -- no wrapping happened.
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;
	lives_ok {
		FT::FailFast::_ff_good();
	} '_ff_good was NOT wrapped (all-or-nothing guarantee)';
};

# Post-CHECK path (CHECK has already fired by the time this runs): import()
# must call _process_one() immediately rather than queuing to @_pending.
subtest 'import(): post-CHECK wrapping installs wrapper immediately' => sub {
	plan tests => 2;

	# A fresh package whose sub we will turn abstract after CHECK
	{ package FT::PostCheckTarget; sub new { bless {}, shift } sub _dynamic { 'dyn' } }
	{ package FT::PostCheckImpl;   our @ISA = ('FT::PostCheckTarget');
	  sub new { bless {}, shift } sub _dynamic { 'impl' } }

	# Wrap _dynamic now (post-CHECK, from FT::PostCheckTarget's perspective)
	{ package FT::PostCheckTarget; Sub::Abstract->import('_dynamic'); }

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# The base class no longer provides _dynamic -- the wrapper fires
	throws_ok { FT::PostCheckTarget->new->_dynamic }
		qr/abstract method/,
		'post-CHECK: base class call croaks after wrapping';

	# The implementing subclass must still succeed (wrapper in base never reached)
	lives_ok { FT::PostCheckImpl->new->_dynamic }
		'post-CHECK: implementing subclass still works';
};

# import() must return the class name even when given sub names.
subtest 'import(): post-CHECK form returns the class name' => sub {
	plan tests => 2;

	{ package FT::ReturnCheck2; sub _rc2 { 1 } }

	my $result;
	{ package FT::ReturnCheck2; $result = Sub::Abstract->import('_rc2'); }

	is $result, $SA, 'import() with sub names returns the class name';
	returns_ok($result, { type => 'string' }, 'return value satisfies string schema');
};

# import() must not clobber $_ on any execution path.
subtest 'import(): does not clobber $_' => sub {
	plan tests => 2;

	# Happy path (no-args)
	{
		local $_ = 'preserve_me';
		Sub::Abstract->import();
		is $_, 'preserve_me', 'import() no-args path did not clobber $_';
	}

	# Croak path (invalid identifier)
	{
		local $_ = 'preserve_me';
		eval { Sub::Abstract->import($config{invalid_digit}) };
		is $_, 'preserve_me', 'import() croak path did not clobber $_';
	}
};

# ===================================================================
# SECTION 2: _wrap()
#
# _wrap() is a private helper that builds the croak-closure.
# Unlike Sub::Private's _wrap, it takes no $code argument -- the
# wrapper never delegates because calling an abstract method is always
# an error.
# ===================================================================

# The private guard must block direct external calls when both bypasses are off.
subtest '_wrap(): private guard blocks call from outside Sub::Abstract' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Both the method name and the caller package must appear in the error
	throws_ok {
		Sub::Abstract::_wrap($OWNER, $config{wrap_sub});
	} qr/_wrap\(\) is a private method of \Q$SA\E/,
		'_wrap() croaks when called directly from main::';

	throws_ok {
		Sub::Abstract::_wrap($OWNER, $config{wrap_sub});
	} qr/_wrap\(\) is a private method of \Q$SA\E and cannot be called from main/,
		'_wrap() croak names the offending caller package';
};

# BYPASS=1 allows the call and a CODE ref must be returned.
subtest '_wrap(): BYPASS=1 skips guard and returns a CODE ref' => sub {
	plan tests => 2;

	local $Sub::Abstract::BYPASS = 1;

	diag '_wrap() with BYPASS=1' if $ENV{TEST_VERBOSE};

	my $wrapper;
	lives_ok {
		$wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub});
	} '_wrap() lives when BYPASS=1';

	# The returned value must be a coderef, not undef or a scalar
	ok defined($wrapper) && reftype($wrapper) eq 'CODE',
		'_wrap() returns a CODE ref when BYPASS=1';
};

# HARNESS_ACTIVE=1 (with default harness_bypass=1) also skips the guard.
subtest '_wrap(): HARNESS_ACTIVE=1 skips guard and returns a CODE ref' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 1;
	local $Sub::Abstract::BYPASS = 0;

	my $wrapper;
	lives_ok {
		$wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub});
	} '_wrap() lives when HARNESS_ACTIVE=1';

	ok defined($wrapper) && reftype($wrapper) eq 'CODE',
		'_wrap() returns a CODE ref when HARNESS_ACTIVE=1';
};

# The returned closure must croak when called without bypass, regardless of caller.
# This is the key difference from Sub::Private: there is no caller check.
subtest '_wrap(): returned closure always croaks without bypass' => sub {
	plan tests => 2;

	# Obtain a closure while bypassed, then test it without bypass
	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub}); }

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# The closure croaks even when called from the owner package
	{
		throws_ok {
			package FT::Owner;    # owner context -- still croaks!
			$wrapper->();
		} qr/\Q$config{wrap_sub}\E\(\) is an abstract method of \Q$OWNER\E/,
			'closure: croaks even when called from the owner package';
	}

	# The exact invocant in the error is whatever $_[0] resolves to
	throws_ok {
		package FT::SomeStranger;
		$wrapper->('FT::SomeStranger');
	} qr/must be implemented by FT::SomeStranger/,
		'closure: invocant in error names the first argument';
};

# The closure must respect $BYPASS -- bypass=1 suppresses the croak.
subtest '_wrap(): returned closure respects $BYPASS' => sub {
	plan tests => 2;

	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub}); }

	# Baseline: without bypass the closure must croak
	{
		local $ENV{HARNESS_ACTIVE}   = 0;
		local $Sub::Abstract::BYPASS = 0;
		throws_ok { $wrapper->() } qr/abstract method/,
			'closure: croaks when $BYPASS=0';
	}

	# With bypass: the croak must be suppressed
	{
		local $Sub::Abstract::BYPASS = 1;
		lives_ok { $wrapper->() }
			'closure: does not croak when $BYPASS=1';
	}
};

# The closure must also respect HARNESS_ACTIVE (with default harness_bypass=1).
subtest '_wrap(): returned closure respects HARNESS_ACTIVE' => sub {
	plan tests => 2;

	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub}); }

	# Baseline: both bypasses off -> croak
	{
		local $ENV{HARNESS_ACTIVE}   = 0;
		local $Sub::Abstract::BYPASS = 0;
		throws_ok { $wrapper->() } qr/abstract method/,
			'closure: croaks when HARNESS_ACTIVE=0 and $BYPASS=0';
	}

	# HARNESS_ACTIVE=1 alone suppresses the croak
	{
		local $ENV{HARNESS_ACTIVE}   = 1;
		local $Sub::Abstract::BYPASS = 0;
		lives_ok { $wrapper->() }
			'closure: does not croak when HARNESS_ACTIVE=1';
	}
};

# harness_bypass=0 must disable the HARNESS_ACTIVE shortcut inside the closure.
subtest '_wrap(): closure: harness_bypass=0 disables HARNESS_ACTIVE bypass' => sub {
	plan tests => 1;

	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub}); }

	# Both HARNESS_ACTIVE=1 and harness_bypass=0 together -- the croak must still fire
	local $ENV{HARNESS_ACTIVE}                   = 1;
	local $Sub::Abstract::BYPASS                 = 0;
	local $Sub::Abstract::config{harness_bypass} = 0;

	throws_ok { $wrapper->() } qr/abstract method/,
		'closure: harness_bypass=0 re-enables enforcement even with HARNESS_ACTIVE=1';
};

# The error message must include all three documented components.
subtest '_wrap(): error message format contains all required components' => sub {
	plan tests => 3;

	Readonly::Scalar my $WRAP_OWNER => 'FT::WrapMsgOwner';
	Readonly::Scalar my $WRAP_SUB   => 'msg_method';

	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap($WRAP_OWNER, $WRAP_SUB); }

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $err;
	eval { $wrapper->('FT::ConcreteClass') };
	$err = $@;

	diag "Error from _wrap closure: $err" if $ENV{TEST_VERBOSE};

	# Each documented component of the error format must appear
	like $err, qr/\Q$WRAP_SUB\E\(\)/,
		'error contains method name followed by ()';
	like $err, qr/is an abstract method of \Q$WRAP_OWNER\E/,
		'error contains "is an abstract method of" and the owner package';
	like $err, qr/must be implemented by FT::ConcreteClass/,
		'error contains "must be implemented by" and the invocant';
};

# Invocant resolution: ref($_[0]) for blessed objects, $_[0] for strings.
subtest '_wrap(): invocant resolution -- blessed object vs bare string' => sub {
	plan tests => 2;

	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap($OWNER, 'test_method'); }

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Blessed object: invocant must be the class name, not the stringified ref
	{
		my $obj = bless {}, 'FT::BlessedClass';
		my $err;
		eval { $wrapper->($obj) };
		$err = $@;
		like $err, qr/must be implemented by FT::BlessedClass/,
			'blessed object: invocant is the class name';
	}

	# Bare string: invocant is the string itself
	{
		my $err;
		eval { $wrapper->('FT::StringClass') };
		$err = $@;
		like $err, qr/must be implemented by FT::StringClass/,
			'bare string: invocant is the string';
	}
};

# The closure must have no circular references so the garbage collector can free it.
subtest '_wrap(): returned closure has no circular references' => sub {
	plan tests => 1;

	local $Sub::Abstract::BYPASS = 1;
	my $wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub});

	# Test::Memory::Cycle verifies the object graph can be fully collected
	memory_cycle_ok($wrapper, 'wrapper closure has no circular references');
};

# _wrap() must not clobber $_ on any execution path.
subtest '_wrap(): does not clobber $_' => sub {
	plan tests => 2;

	# Guard-fires path (both bypasses off)
	{
		local $_ = 'preserve_me';
		local $ENV{HARNESS_ACTIVE}   = 0;
		local $Sub::Abstract::BYPASS = 0;
		eval { Sub::Abstract::_wrap($OWNER, $config{wrap_sub}) };
		is $_, 'preserve_me', '_wrap() guard path: $_ not clobbered';
	}

	# Normal path (BYPASS=1)
	{
		local $_ = 'preserve_me';
		local $Sub::Abstract::BYPASS = 1;
		Sub::Abstract::_wrap($OWNER, $config{wrap_sub});
		is $_, 'preserve_me', '_wrap() normal path: $_ not clobbered';
	}
};

# ===================================================================
# SECTION 3: _process_one()
#
# _process_one() installs the abstract-croak wrapper into the stash.
# Key white-box property: unlike Sub::Private, it does NOT require the
# named sub to pre-exist in the stash.
# ===================================================================

# The private guard must block direct external calls.
subtest '_process_one(): private guard blocks call from outside Sub::Abstract' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok {
		Sub::Abstract::_process_one($OWNER, $config{proc_target});
	} qr/_process_one\(\) is a private method of \Q$SA\E/,
		'_process_one() croaks when called directly from main::';
};

# After a successful call the stash entry must contain a CODE ref.
subtest '_process_one(): installs a CODE ref in the stash' => sub {
	plan tests => 2;

	# Call with BYPASS=1 to bypass the private-caller guard
	{ local $Sub::Abstract::BYPASS = 1;
	  Sub::Abstract::_process_one('FT::ProcExisting', $config{proc_target}); }

	# The stash entry must now be a coderef
	no strict 'refs';
	my $installed = \&{"FT::ProcExisting::$config{proc_target}"};

	ok defined($installed) && reftype($installed) eq 'CODE',
		'_process_one() installed a CODE ref in the stash';

	# Calling it (without bypass) must now croak
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { FT::ProcExisting->new->_proc_tgt }
		qr/abstract method/,
		'_process_one() installed an abstract-croak wrapper';
};

# _process_one() must work even when the named sub has NO pre-existing body.
# This is the key difference from Sub::Private::_process_one.
subtest '_process_one(): works without a pre-existing sub body' => sub {
	plan tests => 2;

	# FT::ProcBodyless has no body for _proc_tgt -- this must succeed
	{ local $Sub::Abstract::BYPASS = 1;
	  lives_ok {
		  Sub::Abstract::_process_one('FT::ProcBodyless', $config{proc_target});
	  } '_process_one() does not croak for a bodyless sub'; }

	# The installed wrapper must now croak when called
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { FT::ProcBodyless->new->_proc_tgt }
		qr/abstract method/,
		'_process_one() installs a working wrapper for a bodyless sub';
};

# _process_one() must not clobber $_ on any execution path.
subtest '_process_one(): does not clobber $_' => sub {
	plan tests => 2;

	# Guard-fires path (both bypasses off)
	{
		local $_ = 'preserve_me';
		local $ENV{HARNESS_ACTIVE}   = 0;
		local $Sub::Abstract::BYPASS = 0;
		eval { Sub::Abstract::_process_one($OWNER, $config{proc_target}) };
		is $_, 'preserve_me', '_process_one() guard path: $_ not clobbered';
	}

	# Normal path (BYPASS=1)
	{
		local $_ = 'preserve_me';
		local $Sub::Abstract::BYPASS = 1;
		Sub::Abstract::_process_one('FT::ProcExisting', $config{proc_target});
		is $_, 'preserve_me', '_process_one() normal path: $_ not clobbered';
	}
};

# ===================================================================
# SECTION 4: _assert_private_caller()
#
# _assert_private_caller() croaks when the immediate caller of the
# guarded function is outside Sub::Abstract.  It uses caller(1) so
# it inspects the package that called the guarded function, not the
# one that called _assert_private_caller itself.
# ===================================================================

# Croaks with a descriptive message when called from outside Sub::Abstract.
subtest '_assert_private_caller(): croaks when caller is not Sub::Abstract' => sub {
	plan tests => 3;

	# FT::External::try_assert calls _assert_private_caller directly;
	# caller(1) inside the guard sees FT::External.
	throws_ok { FT::External::try_assert() }
		qr/_test_method\(\) is a private method of \Q$SA\E and cannot be called from/,
		'_assert_private_caller() croaks from non-Sub::Abstract context';

	# Verify the caller package name appears in the error
	throws_ok { FT::External::try_assert() }
		qr/cannot be called from FT::External/,
		'_assert_private_caller() names FT::External in the error';

	# Verify the required phrase is present
	my $err;
	eval { FT::External::try_assert() };
	$err = $@;
	like $err, qr/is a private method of \Q$SA\E/,
		'error contains "is a private method of Sub::Abstract"';
};

# Must return normally when the guarded function is inside Sub::Abstract.
subtest '_assert_private_caller(): allows when caller is Sub::Abstract' => sub {
	plan tests => 1;

	# _ft_outer_assert -> _ft_inner_assert -> _assert_private_caller
	# caller(1) inside the guard sees Sub::Abstract (_ft_inner_assert's package)
	lives_ok { Sub::Abstract::_ft_outer_assert() }
		'_assert_private_caller() returns normally for a Sub::Abstract call chain';
};

# _assert_private_caller() must not clobber $_ on the croak path.
subtest '_assert_private_caller(): does not clobber $_' => sub {
	plan tests => 1;

	local $_ = 'preserve_me';
	eval { FT::External::try_assert() };
	is $_, 'preserve_me',
		'_assert_private_caller() did not clobber $_ on the croak path';
};

# ===================================================================
# SECTION 5: Attribute handler (UNIVERSAL::Abstract :ATTR(CODE,CHECK))
#
# The attribute handler fires at CHECK time and replaces the decorated
# stub body with the croak wrapper.  We can only observe its effect
# at runtime through the installed wrapper.
# ===================================================================

# Implementing subclass: wrapper installed in base must never fire.
subtest 'attribute handler: implementing subclass -- wrapper never fires' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $result;
	lives_ok { $result = FT::Impl->new->abstract_op }
		'attribute handler: implementing subclass does not croak';
	is $result, $config{impl_result},
		'implementing subclass returns its own return value';
};

# Non-implementing subclass: wrapper fires and produces the documented error.
subtest 'attribute handler: non-implementing subclass -- wrapper croaks' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# All three components of the documented error format must appear
	throws_ok { FT::NoImpl->new->abstract_op }
		qr/\Q$config{attr_method}\E\(\) is an abstract method of \Q$OWNER\E and must be implemented by \Q$NOIMPL\E/,
		'attribute handler: exact documented error message';

	my $err;
	eval { FT::NoImpl->new->abstract_op };
	$err = $@;
	like $err, qr/is an abstract method of/, 'error contains "is an abstract method of"';
	like $err, qr/must be implemented by/,   'error contains "must be implemented by"';
};

# UNIVERSAL::Abstract must be installed as a side effect of loading the module.
subtest 'attribute handler: UNIVERSAL::Abstract is installed' => sub {
	plan tests => 1;

	# Using defined &{} rather than ->can() to inspect the symbol table reliably
	ok defined &UNIVERSAL::Abstract,
		'UNIVERSAL::Abstract is defined in the symbol table';
};

# ===================================================================
# SECTION 6: harness_bypass=0 -- private guards fire even with
#            HARNESS_ACTIVE=1 when harness_bypass is disabled
# ===================================================================

# _wrap(): guard must fire when harness_bypass=0 + HARNESS_ACTIVE=1.
subtest '_wrap(): guard fires when harness_bypass=0 and HARNESS_ACTIVE=1' => sub {
	plan tests => 1;

	local $Sub::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                   = 1;
	local $Sub::Abstract::BYPASS                 = 0;

	throws_ok {
		Sub::Abstract::_wrap($OWNER, $config{wrap_sub});
	} qr/_wrap\(\) is a private method of \Q$SA\E/,
		'_wrap() guard fires when harness_bypass=0 + HARNESS_ACTIVE=1';
};

# _process_one(): guard must also fire under the same conditions.
subtest '_process_one(): guard fires when harness_bypass=0 and HARNESS_ACTIVE=1' => sub {
	plan tests => 1;

	local $Sub::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                   = 1;
	local $Sub::Abstract::BYPASS                 = 0;

	throws_ok {
		Sub::Abstract::_process_one($OWNER, $config{proc_target});
	} qr/_process_one\(\) is a private method of \Q$SA\E/,
		'_process_one() guard fires when harness_bypass=0 + HARNESS_ACTIVE=1';
};

# ===================================================================
# SECTION 7: spy / mock verification
#
# Use Test::Mockingbird to confirm that import() delegates to the
# documented internal helpers correctly, and that the croak closure
# calls croak with the right message.
# ===================================================================

# import() must call validate_strict once per sub name supplied.
subtest 'spy: import() calls validate_strict once per sub name' => sub {
	plan tests => 2;

	# Spy on the validate_strict alias installed in Sub::Abstract's namespace
	my $spy = spy 'Sub::Abstract::validate_strict';

	{
		package FT::SpyVS;
		sub _a { 'a' }
		sub _b { 'b' }
		Sub::Abstract->import('_a', '_b');
	}

	my @calls = $spy->();
	diag 'validate_strict call count: ' . scalar(@calls) if $ENV{TEST_VERBOSE};

	# Two sub names -> at least two validate_strict calls
	ok scalar(@calls) >= 2, 'validate_strict called at least once per sub name';

	# Each call must include the 'schema' key (from validate_strict's signature)
	ok(
		(grep { defined $_ && $_ eq 'schema' } @{$calls[0]}),
		'validate_strict called with the "schema" key'
	);

	restore_all();
};

# import() must call set_return in both the no-args and declarative forms.
subtest 'spy: import() calls set_return in all call forms' => sub {
	plan tests => 2;

	diag 'Spying on set_return across no-args and declarative import()' if $ENV{TEST_VERBOSE};

	# Install the spy before any import() calls
	my $spy = spy 'Sub::Abstract::set_return';

	# No-args form
	Sub::Abstract->import();
	my @noargs_calls = $spy->();
	ok scalar(@noargs_calls) >= 1, 'set_return called for no-args import()';

	# Declarative form -- caller() inside import() must see FT::SetReturnSpy as owner
	{ package FT::SetReturnSpy; Sub::Abstract->import('_sr_sub'); }
	my @all_calls = $spy->();
	ok scalar(@all_calls) >= 2, 'set_return called for declarative import() as well';

	restore_all();
};

# _process_one() must call _wrap() with the correct owner and sub name.
subtest 'spy: _process_one() calls _wrap() with correct arguments' => sub {
	plan tests => 3;

	# Fresh package to avoid double-wrapping artefacts from earlier tests
	{ package FT::ProcessSpy; sub new { bless {}, shift } sub _spy_tgt { 'spy' } }

	# Spy on _wrap before _process_one calls it
	my $spy = spy 'Sub::Abstract::_wrap';

	{ local $Sub::Abstract::BYPASS = 1;
	  Sub::Abstract::_process_one('FT::ProcessSpy', '_spy_tgt'); }

	my @calls = $spy->();
	diag '_wrap spy calls: ' . scalar(@calls) if $ENV{TEST_VERBOSE};

	# _process_one must call _wrap exactly once
	is scalar(@calls), 1, '_wrap called exactly once by _process_one()';
	is $calls[0][1], 'FT::ProcessSpy', '_wrap called with correct owner_pkg';
	is $calls[0][2], '_spy_tgt',       '_wrap called with correct sub_name';

	restore_all();
};

# The croak closure must pass the exact documented message to croak.
subtest 'spy: croak closure calls croak with the documented message format' => sub {
	plan tests => 3;

	# Build the wrapper, then spy on croak and invoke the wrapper
	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap('FT::CroakTest', 'croak_method'); }

	# Spy on the croak alias installed in Sub::Abstract's namespace
	my $spy = spy 'Sub::Abstract::croak';

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Call the wrapper; croak will be spied but still execute (spy doesn't mock)
	eval { $wrapper->('FT::Invoker') };

	my @calls = $spy->();
	diag 'croak spy calls: ' . scalar(@calls) if $ENV{TEST_VERBOSE};

	# croak must have been called exactly once with the canonical message
	is scalar(@calls), 1,
		'croak called exactly once by the abstract-method wrapper';
	like $calls[0][1],
		qr/\Qcroak_method()\E is an abstract method of FT::CroakTest/,
		'croak message names the method and owner package';
	like $calls[0][1],
		qr/must be implemented by FT::Invoker/,
		'croak message names the invocant';

	restore_all();
};

# mock_scoped must restore validate_strict after the scope exits.
subtest 'mock_scoped: validate_strict replacement is properly scoped' => sub {
	plan tests => 2;

	Readonly::Scalar my $SCOPED_NAME => '_mock_scoped_test';

	# Inside the mock scope validation always fails
	{
		my $g = mock_scoped 'Sub::Abstract::validate_strict' =>
			sub { die "forced internal error\n" };

		throws_ok {
			package FT::Owner;
			Sub::Abstract->import($SCOPED_NAME);
		} qr/is not a valid Perl identifier/,
			'inside mock_scoped: forced failure still produces documented error';
	}

	# Outside the mock scope, real validation must succeed for a valid name
	{ package FT::ScopedCheck2; sub _mock_scoped_test { 1 } }
	lives_ok {
		package FT::ScopedCheck2;
		Sub::Abstract->import($SCOPED_NAME);
	} 'outside mock_scoped: real validate_strict accepts a valid identifier';
};

# ===================================================================
# SECTION 8 (addition): TER3 guard combinations
#
# The guard in _wrap() is:
#   unless $BYPASS || ($config{harness_bypass} && $ENV{HARNESS_ACTIVE})
# All other tests hit (BYPASS=1,HA=0), (BYPASS=0,HA=1), (BYPASS=0,HA=0).
# The missing TER3 combination is (BYPASS=1, HA=1): BYPASS short-circuits.
# ===================================================================

# Both bypass conditions simultaneously true: BYPASS wins the || short-circuit.
subtest '_wrap() guard: BYPASS=1 AND HARNESS_ACTIVE=1 simultaneously (TER3)' => sub {
	plan tests => 1;

	# Both active at the same time -- the guard must be skipped by BYPASS alone
	local $Sub::Abstract::BYPASS = 1;
	local $ENV{HARNESS_ACTIVE}   = 1;

	lives_ok {
		Sub::Abstract::_wrap($OWNER, $config{wrap_sub});
	} '_wrap() guard: skipped when BYPASS=1 AND HARNESS_ACTIVE=1 (TER3)';
};

# The returned closure: BYPASS=1 short-circuits before harness_bypass is checked.
# Testing BYPASS=1 with harness_bypass=0 confirms the || evaluation order.
subtest '_wrap() closure: BYPASS=1 suppresses croak even when harness_bypass=0' => sub {
	plan tests => 1;

	# Obtain the wrapper while bypassed so the guard does not fire
	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap($OWNER, $config{wrap_sub}); }

	# BYPASS=1 must suppress the croak even though harness_bypass is disabled
	local $Sub::Abstract::BYPASS                 = 1;
	local $Sub::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                   = 0;

	lives_ok { $wrapper->() }
		'closure: BYPASS=1 short-circuits before harness_bypass is consulted';
};

done_testing;
