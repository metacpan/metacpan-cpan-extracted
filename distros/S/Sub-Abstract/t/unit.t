#!/usr/bin/perl
# t/unit.t -- black-box unit tests for Sub::Abstract's public API.
#
# Every test is derived strictly from the POD documentation.
# No private functions are called directly; only the documented public
# interface is exercised: import(), the :Abstract attribute, $BYPASS,
# and %config.
#
# Test::Mockingbird is used to:
#   * force the validate_strict failure path in import()
#   * verify that set_return is invoked with the correct arguments
#   * confirm validate_strict is called once per sub name

use strict;
use warnings;

# Untaint $HOME so prove -lt is happy with the local lib paths
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
use Readonly;
use Scalar::Util qw(reftype);

# Loading the module fires CHECK, wrapping all :Abstract and declarative
# methods defined in the package fixtures below.
use Sub::Abstract;

# -------------------------------------------------------------------
# Constants -- no magic strings anywhere in this file
# -------------------------------------------------------------------

Readonly::Scalar my $SA         => 'Sub::Abstract';
Readonly::Scalar my $ATTR_OWNER => 'UT::AttrOwner';
Readonly::Scalar my $DECL_OWNER => 'UT::DeclOwner';
Readonly::Scalar my $PC_OWNER   => 'UT::PostCheck';

# Human-readable labels used in test parameters
my %config = (
	attr_method    => 'speak',
	decl_method    => 'greet',
	pc_method      => 'render',
	multi_method_a => '_alpha',
	multi_method_b => '_beta',
	impl_result    => 'woof',
	invalid_digit  => '123bad',
	invalid_hyphen => 'has-hyphen',
	invalid_empty  => q{},
	documented_ver => '0.01',
);

# -------------------------------------------------------------------
# Package fixtures -- defined at compile time so :Abstract and
# declarative wrapping happen at CHECK time, exactly as documented.
# -------------------------------------------------------------------

# Base class with :Abstract attribute form.
# The stub body is required for Attribute::Handlers (per POD).
{
	package UT::AttrOwner;
	use Sub::Abstract;

	sub new   { bless {}, shift }
	sub speak :Abstract { }    # stub required; handler replaces it at CHECK
}

# Subclass that DOES implement speak -- wrapper in base class never fires.
{
	package UT::AttrImpl;
	our @ISA = ('UT::AttrOwner');

	sub new   { bless {}, shift }
	sub speak { 'woof' }     # concrete implementation
}

# Subclass that does NOT implement speak -- wrapper fires and croaks.
{
	package UT::AttrNoImpl;
	our @ISA = ('UT::AttrOwner');

	sub new { bless {}, shift }
}

# Declarative form: no stub body needed for the greet method.
{
	package UT::DeclOwner;
	use Sub::Abstract qw(greet);

	sub new { bless {}, shift }
}

# Subclass that implements greet.
{
	package UT::DeclImpl;
	our @ISA = ('UT::DeclOwner');

	sub new   { bless {}, shift }
	sub greet { 'hello' }
}

# Subclass that does NOT implement greet.
{
	package UT::DeclNoImpl;
	our @ISA = ('UT::DeclOwner');

	sub new { bless {}, shift }
}

# Base class for post-CHECK wrapping tests (render is NOT yet abstract here).
{
	package UT::PostCheck;

	sub new    { bless {}, shift }
	sub render { 'raw render' }    # will be wrapped post-CHECK in tests
}

# Subclass used to verify post-CHECK stranger behaviour.
{
	package UT::PostNoImpl;
	our @ISA = ('UT::PostCheck');

	sub new { bless {}, shift }
}

# Multiple declarative abstract methods in one import() call.
{
	package UT::MultiDecl;
	use Sub::Abstract qw(_alpha _beta);

	sub new { bless {}, shift }
}

# Subclass that implements both.
{
	package UT::MultiImpl;
	our @ISA = ('UT::MultiDecl');

	sub new    { bless {}, shift }
	sub _alpha { 'alpha' }
	sub _beta  { 'beta'  }
}

# Package for the set_return spy test.
{
	package UT::SetReturnSpy;
	sub _spy_sub { 'spy' }
}

diag "Black-box unit tests for $SA" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: import() with no arguments
#
# POD: "With no arguments: makes the :Abstract attribute globally
#       available.  Returns the class name."
# ===================================================================

# No-args import must return the class name as a plain string.
subtest 'import(): no-args returns the class name' => sub {
	plan tests => 2;

	# Call import() with no sub names; the return value is the class name
	my $result = Sub::Abstract->import();
	is $result, $SA, 'import() returns the class name';

	# Verify that the return value satisfies the documented "string" schema
	returns_ok($result, { type => 'string' }, 'return value satisfies string schema');
};

# Confirm set_return is invoked with the class name (the mechanism behind the return value).
subtest 'import(): no-args passes class name to set_return' => sub {
	plan tests => 2;

	# Spy on the set_return alias installed in Sub::Abstract's namespace
	my $spy = spy 'Sub::Abstract::set_return';

	my $result = Sub::Abstract->import();

	# Extract the captured call records
	my @calls = $spy->();
	is scalar(@calls), 1, 'set_return called exactly once for no-args import()';
	is $calls[0][1], $SA, 'set_return receives the class name as its first value arg';

	restore_all();
};

# ===================================================================
# SECTION 2: import() identifier validation
#
# POD MESSAGES: "Sub::Abstract->import: 'NAME' is not a valid Perl identifier"
# Names must match /\A[_a-zA-Z]\w*\z/.
# ===================================================================

# A name starting with a digit is not a valid Perl identifier.
subtest 'import(): rejects identifier starting with a digit' => sub {
	plan tests => 2;

	my $bad = $config{invalid_digit};

	# The exact documented error message must be produced
	throws_ok {
		Sub::Abstract->import($bad)
	} qr/\Q$SA\E->import: '\Q$bad\E' is not a valid Perl identifier/,
		'digit-start identifier croaks with exact documented message';

	# Confirm the required phrase appears in the error
	my $err;
	eval { Sub::Abstract->import($bad) };
	$err = $@;
	like $err, qr/is not a valid Perl identifier/, 'error contains required phrase';
};

# A hyphen-containing name is not a valid Perl identifier.
subtest 'import(): rejects identifier containing a hyphen' => sub {
	plan tests => 1;

	my $bad = $config{invalid_hyphen};
	throws_ok {
		Sub::Abstract->import($bad)
	} qr/\Q$SA\E->import: '\Q$bad\E' is not a valid Perl identifier/,
		'hyphen-containing identifier croaks with exact documented message';
};

# Empty string is not a valid sub name.
subtest 'import(): rejects empty-string identifier' => sub {
	plan tests => 1;

	throws_ok {
		Sub::Abstract->import($config{invalid_empty})
	} qr/is not a valid Perl identifier/,
		'empty-string identifier croaks';
};

# POD explicitly lists undef as a rejected value.
subtest 'import(): rejects undef sub name' => sub {
	plan tests => 1;

	throws_ok { Sub::Abstract->import(undef) }
		qr/is not a valid Perl identifier/,
		'import(undef) croaks with "not a valid Perl identifier"';
};

# References (arrayref, hashref, etc.) are not valid sub names.
subtest 'import(): rejects a reference as sub name' => sub {
	plan tests => 1;

	throws_ok { Sub::Abstract->import([]) }
		qr/is not a valid Perl identifier/,
		'import(arrayref) croaks with "not a valid Perl identifier"';
};

# Mock validate_strict to throw an unexpected error; import() must still produce
# the exact documented message and not leak the raw validation failure.
subtest 'import(): any validate_strict failure produces the documented error message' => sub {
	plan tests => 1;

	# Replace validate_strict with one that always throws
	my $g = mock_scoped 'Sub::Abstract::validate_strict' =>
		sub { die "UNEXPECTED_INTERNAL_ERROR\n" };

	throws_ok {
		package UT::AttrOwner;
		Sub::Abstract->import('_looks_valid');
	} qr/\Q$SA\E->import: '_looks_valid' is not a valid Perl identifier/,
		'import() wraps any validate_strict failure with the documented message';
};

# Validation must be fail-fast and all-or-nothing: if any name is invalid,
# nothing in the list should be wrapped.
subtest 'import(): fail-fast -- no partial wrapping when any name is invalid' => sub {
	plan tests => 2;

	# Define a package with a sub that should remain unwrapped after the failed import
	{ package UT::FailFast; sub _ff_good { 'good' } }

	# _ff_good comes before the invalid name but must still not be wrapped
	throws_ok {
		package UT::FailFast;
		Sub::Abstract->import('_ff_good', $config{invalid_digit});
	} qr/is not a valid Perl identifier/,
		'import() croaks when any name in the list is invalid';

	# If _ff_good were wrapped, calling it would croak (abstract method enforcement).
	# It must still be callable because no wrapping occurred (all-or-nothing guarantee).
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;
	lives_ok {
		UT::FailFast::_ff_good();
	} '_ff_good NOT wrapped (all-or-nothing: no partial wrapping applied)';
};

# ===================================================================
# SECTION 3: import() with valid sub names -- post-CHECK wrapping
#
# POD: "With one or more method names: installs abstract-croak wrappers
#       for those methods in the calling package at CHECK time (or
#       immediately if CHECK has already fired)."
# ===================================================================

# At this point in the test file, CHECK has already fired.
# Calling import() now must apply wrapping immediately.
subtest 'import(): post-CHECK wrapping installs the croak wrapper immediately' => sub {
	plan tests => 3;

	# Wrap UT::PostCheck::render right now (post-CHECK, immediate wrapping).
	# The import() call must come from UT::PostCheck so caller() sees it as owner.
	{
		package UT::PostCheck;
		Sub::Abstract->import('render');
	}

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# UT::PostCheck itself no longer provides render -- the wrapper fires
	throws_ok { UT::PostCheck->new->render }
		qr/abstract method/,
		'post-CHECK: calling the wrapped method on the owner class croaks';

	# A subclass that provides its own render must NOT croak
	{ package UT::PCImpl; our @ISA = ('UT::PostCheck'); sub render { 'impl' } }
	lives_ok { UT::PCImpl->new->render } 'post-CHECK: subclass with implementation is ok';

	# A subclass without render must croak
	throws_ok { UT::PostNoImpl->new->render }
		qr/abstract method/,
		'post-CHECK: subclass without implementation croaks';
};

# post-CHECK import() must return the class name (documented in all cases).
subtest 'import(): post-CHECK form returns the class name' => sub {
	plan tests => 2;

	# Define a fresh package so we can import() without side-effects on other tests
	{ package UT::ReturnCheck; sub _rc_meth { 1 } }

	my $result;
	{ package UT::ReturnCheck; $result = Sub::Abstract->import('_rc_meth'); }

	is $result, $SA, 'import() returns class name when given sub names (post-CHECK)';
	returns_ok($result, { type => 'string' }, 'return satisfies the documented string schema');
};

# ===================================================================
# SECTION 4: :Abstract attribute form -- enforcement
#
# POD: "A stub body (even an empty one) is required because
#       Attribute::Handlers needs a CODE ref.  The stub is replaced
#       at CHECK time."
# ===================================================================

# Subclass that provides an implementation must NOT croak.
subtest 'attribute form: implementing subclass -- wrapper never fires' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $result;
	lives_ok { $result = UT::AttrImpl->new->speak }
		'attribute form: implementing subclass: no croak';

	# The concrete method's return value must pass through unchanged
	is $result, $config{impl_result}, 'implementing subclass returns correct value';
};

# Subclass that omits the implementation must croak with the documented message.
subtest 'attribute form: non-implementing subclass -- wrapper croaks' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# UT::AttrNoImpl does not implement speak; the wrapper in UT::AttrOwner fires
	throws_ok { UT::AttrNoImpl->new->speak }
		qr/abstract method/,
		'attribute form: non-implementing subclass: wrapper fires and croaks';
};

# Multiple abstract methods in the same package must each enforce independently.
subtest 'attribute form: multiple abstract methods enforce independently' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Verify both _alpha and _beta are abstract in UT::MultiDecl
	throws_ok { UT::MultiDecl->new->_alpha }
		qr/abstract method/, 'attribute-declared _alpha: croaks';
	throws_ok { UT::MultiDecl->new->_beta  }
		qr/abstract method/, 'attribute-declared _beta: croaks';
};

# ===================================================================
# SECTION 5: Declarative form -- enforcement
#
# POD: "Each named method is installed as an abstract-croak wrapper
#       at CHECK time.  No stub body is needed."
# ===================================================================

# Implementing subclass must NOT croak.
subtest 'declarative form: implementing subclass -- wrapper never fires' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $result;
	lives_ok { $result = UT::DeclImpl->new->greet }
		'declarative form: implementing subclass: no croak';
	is $result, 'hello', 'implementing subclass returns correct value';
};

# Non-implementing subclass must croak.
subtest 'declarative form: non-implementing subclass -- wrapper croaks' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { UT::DeclNoImpl->new->greet }
		qr/abstract method/,
		'declarative form: non-implementing subclass: croaks';
};

# Both forms must produce equivalent enforcement behaviour.
subtest 'attribute form and declarative form produce equivalent enforcement' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Both wrappers must croak; the forms are interchangeable
	throws_ok { UT::AttrNoImpl->new->speak }  qr/abstract method/, 'attr form: croaks';
	throws_ok { UT::DeclNoImpl->new->greet }  qr/abstract method/, 'decl form: croaks';
};

# Multiple sub names in one import() call are all wrapped independently.
subtest 'declarative form: multiple sub names wrapped in one import()' => sub {
	plan tests => 4;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# UT::MultiImpl provides both -- neither must croak
	my ($ra, $rb);
	lives_ok { $ra = UT::MultiImpl->new->_alpha } 'implementing subclass: _alpha ok';
	lives_ok { $rb = UT::MultiImpl->new->_beta  } 'implementing subclass: _beta ok';

	# UT::MultiDecl has no implementation -- both must croak independently
	throws_ok { UT::MultiDecl->new->_alpha }
		qr/abstract method/, '_alpha: croaks when not implemented';
	throws_ok { UT::MultiDecl->new->_beta  }
		qr/abstract method/, '_beta: croaks when not implemented';
};

# ===================================================================
# SECTION 6: Error message format
#
# POD documents the exact format:
#   "speak() is an abstract method of Animal and must be implemented by Dog"
# ===================================================================

# Each component of the error must match the documented template exactly.
subtest 'error message matches the documented format (attribute form)' => sub {
	plan tests => 3;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my $err;
	eval { UT::AttrNoImpl->new->speak };
	$err = $@;

	diag "Actual error: $err" if $ENV{TEST_VERBOSE};

	# Each of the three documented components must appear
	like $err,
		qr/\Qspeak()\E/,
		'error contains sub name followed by ()';
	like $err,
		qr/is an abstract method of \Q$ATTR_OWNER\E/,
		'error contains "is an abstract method of" + owner package';
	like $err,
		qr/and must be implemented by UT::AttrNoImpl/,
		'error contains "and must be implemented by" + invocant class';
};

# Error message format for the declarative form must be identical.
subtest 'error message format (declarative form)' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { UT::DeclNoImpl->new->greet }
		qr/\Qgreet()\E is an abstract method of \Q$DECL_OWNER\E and must be implemented by UT::DeclNoImpl/,
		'declarative form: exact documented error message format';
};

# Full structural regex matching the documented template.
subtest 'error message structure matches the documented template' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Template: "NAME() is an abstract method of PKG and must be implemented by PKG"
	throws_ok { UT::AttrNoImpl->new->speak }
		qr/\w+\(\) is an abstract method of \w[\w:]* and must be implemented by \w[\w:]*/,
		'error message structure matches the documented template';
};

# ===================================================================
# SECTION 7: Invocant determination in the error message
#
# POD error format uses the CONCRETE class (e.g. Dog), not the abstract
# base.  The code uses ref($_[0])||$_[0] to resolve the invocant.
# ===================================================================

# Object method call: invocant is the blessed class of the object.
subtest 'invocant: object method call names the concrete subclass' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# $obj = UT::AttrNoImpl->new; calling $obj->speak should name UT::AttrNoImpl
	throws_ok { UT::AttrNoImpl->new->speak }
		qr/must be implemented by UT::AttrNoImpl/,
		'object call: invocant is the blessed class';
};

# Class method call: invocant is the string passed as the first argument.
subtest 'invocant: class method call names the caller class' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# UT::AttrOwner->speak -- first arg is the string 'UT::AttrOwner'
	throws_ok { UT::AttrOwner->speak }
		qr/must be implemented by \Q$ATTR_OWNER\E/,
		'class method call: invocant is the class name string';
};

# ===================================================================
# SECTION 8: $BYPASS public variable
#
# POD: "Set to a true value to disable the abstract-method croak for
#       all wrapped subs.  Either condition alone (OR logic) suppresses
#       the croak."
# ===================================================================

# $BYPASS=1 must suppress the croak from any caller.
subtest '$BYPASS=1 suppresses the abstract croak' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 1;

	# Without bypass this would croak; with bypass it must succeed silently
	lives_ok { UT::AttrNoImpl->new->speak }
		'$BYPASS=1: abstract method does not croak';
};

# Using local must restore $BYPASS to 0 when the scope exits.
subtest '$BYPASS is restored after local scope exits' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE} = 0;

	# Inside the scope: bypass active
	{
		local $Sub::Abstract::BYPASS = 1;
		lives_ok { UT::AttrNoImpl->new->speak }
			'$BYPASS=1 active inside the local scope';
	}

	# After the scope: bypass must be gone and enforcement resumes
	throws_ok { UT::AttrNoImpl->new->speak }
		qr/abstract method/,
		'$BYPASS restored to 0 after the scope exits';
};

# ===================================================================
# SECTION 9: $ENV{HARNESS_ACTIVE} and %config{harness_bypass}
#
# POD: "Either condition alone (OR logic) suppresses the croak."
# "The HARNESS_ACTIVE bypass can be disabled:
#   $Sub::Abstract::config{harness_bypass} = 0;"
# ===================================================================

# HARNESS_ACTIVE=1 alone must suppress the croak (default behaviour).
subtest 'HARNESS_ACTIVE=1 suppresses the abstract croak (default behaviour)' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}   = 1;
	local $Sub::Abstract::BYPASS = 0;

	# harness_bypass defaults to 1, so HARNESS_ACTIVE should bypass enforcement
	lives_ok { UT::AttrNoImpl->new->speak }
		'HARNESS_ACTIVE=1 suppresses abstract croak by default';
};

# config{harness_bypass}=0 must disable the HARNESS_ACTIVE shortcut.
subtest 'config{harness_bypass}=0 disables the HARNESS_ACTIVE bypass' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}                   = 1;
	local $Sub::Abstract::BYPASS                 = 0;
	local $Sub::Abstract::config{harness_bypass} = 0;

	# Now HARNESS_ACTIVE should be ignored; enforcement must resume
	throws_ok { UT::AttrNoImpl->new->speak }
		qr/abstract method/,
		'harness_bypass=0: HARNESS_ACTIVE no longer suppresses the croak';
};

# %config{harness_bypass} must default to 1, as documented.
subtest 'config{harness_bypass} defaults to 1' => sub {
	plan tests => 1;

	is $Sub::Abstract::config{harness_bypass}, 1,
		'%config{harness_bypass} default is 1 as documented';
};

# ===================================================================
# SECTION 10: OR logic -- all four BYPASS x HARNESS_ACTIVE combinations
#
# POD: "Either condition alone (OR logic) suppresses the croak."
# Enforcement fires only when BOTH are false.
# ===================================================================

subtest 'bypass OR logic: all four BYPASS x HARNESS_ACTIVE combinations' => sub {
	plan tests => 4;

	diag 'Testing all four combinations of $BYPASS and HARNESS_ACTIVE' if $ENV{TEST_VERBOSE};

	# (0, 0) -> enforce -- both off means the croak must fire
	{
		local $Sub::Abstract::BYPASS = 0;
		local $ENV{HARNESS_ACTIVE}   = 0;
		throws_ok { UT::AttrNoImpl->new->speak }
			qr/abstract method/, 'BYPASS=0, HARNESS_ACTIVE=0: enforced';
	}

	# (1, 0) -> bypass via $BYPASS alone
	{
		local $Sub::Abstract::BYPASS = 1;
		local $ENV{HARNESS_ACTIVE}   = 0;
		lives_ok { UT::AttrNoImpl->new->speak }
			'BYPASS=1, HARNESS_ACTIVE=0: suppressed by $BYPASS';
	}

	# (0, 1) -> bypass via HARNESS_ACTIVE alone
	{
		local $Sub::Abstract::BYPASS = 0;
		local $ENV{HARNESS_ACTIVE}   = 1;
		lives_ok { UT::AttrNoImpl->new->speak }
			'BYPASS=0, HARNESS_ACTIVE=1: suppressed by HARNESS_ACTIVE';
	}

	# (1, 1) -> bypass (both active simultaneously)
	{
		local $Sub::Abstract::BYPASS = 1;
		local $ENV{HARNESS_ACTIVE}   = 1;
		lives_ok { UT::AttrNoImpl->new->speak }
			'BYPASS=1, HARNESS_ACTIVE=1: suppressed (both active)';
	}
};

# ===================================================================
# SECTION 11: Public variables and module defaults
#
# Each documented default value must match the actual initial state.
# ===================================================================

# $BYPASS must default to 0 (false -- enforcement on by default).
subtest 'public variable: $BYPASS default value matches documentation' => sub {
	plan tests => 1;

	is $Sub::Abstract::BYPASS, 0,
		'$BYPASS starts at 0 (enforcement active by default) as documented';
};

# $VERSION must match the value declared in the POD.
subtest 'module: $VERSION matches the documented value' => sub {
	plan tests => 1;

	is $Sub::Abstract::VERSION, $config{documented_ver},
		"\$VERSION is '$config{documented_ver}' as documented";
};

# UNIVERSAL::Abstract must be installed as a documented side effect of loading.
subtest 'side effect: UNIVERSAL::Abstract attribute handler is installed' => sub {
	plan tests => 1;

	# Use defined &{} to inspect the symbol table; UNIVERSAL->can() is unreliable here
	ok defined &UNIVERSAL::Abstract,
		'UNIVERSAL::Abstract is defined (documented side effect of loading the module)';
};

# ===================================================================
# SECTION 12: Known limitation -- can() returns the croak-stub
#
# POD KNOWN LIMITATIONS: "Because the stash entry is replaced with a
#   wrapper closure, Animal->can('speak') returns the wrapper (truthy)
#   rather than undef."
# ===================================================================

subtest 'known limitation: can() returns the croak-stub (truthy)' => sub {
	plan tests => 1;

	# The POD documents this as a known limitation, not a bug.
	# We test it here to confirm the behaviour matches the documentation.
	my $coderef = UT::AttrOwner->can($config{attr_method});
	ok $coderef, 'can() returns the croak-stub wrapper (truthy) -- documented limitation';
};

# ===================================================================
# SECTION 13: POD/code consistency checks
# ===================================================================

# The documented identifier regex /\A[_a-zA-Z]\w*\z/ allows leading underscore.
subtest 'POD/code: import() accepts identifiers starting with an underscore' => sub {
	plan tests => 1;

	lives_ok {
		package UT::LeadingUnderscore;
		sub _valid_name { 1 }
		Sub::Abstract->import('_valid_name');
	} 'identifier starting with _ is accepted by import()';
};

# The documented bypass semantics: when both bypass mechanisms are off,
# the croak must fire regardless of who calls the method.
subtest 'POD/code: enforcement is caller-independent (no caller check)' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Unlike Sub::Private/Protected, abstract enforcement is unconditional --
	# it does not matter who calls the method, only that no override was found.
	throws_ok { UT::AttrOwner->speak }
		qr/abstract method/, 'calling abstract method on the base class croaks';
	throws_ok { UT::AttrNoImpl->new->speak }
		qr/abstract method/, 'calling abstract method on a non-implementing subclass croaks';
};

# The declarative form must NOT require the sub to be pre-defined in the stash.
# This distinguishes Sub::Abstract from Sub::Private (which requires pre-existence).
subtest 'POD/code: declarative form works even without a pre-existing sub body' => sub {
	plan tests => 2;

	# UT::BodylessDecl has no body for its abstract methods
	{
		package UT::BodylessDecl;
		use Sub::Abstract qw(fly);
		sub new { bless {}, shift }
		# Note: fly is NOT defined here -- declarative form only
	}

	{
		package UT::BodylessImpl;
		our @ISA = ('UT::BodylessDecl');
		sub new { bless {}, shift }
		sub fly { 'whoosh' }
	}

	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# The wrapper must be installed even though there was no body
	throws_ok { UT::BodylessDecl->new->fly }
		qr/abstract method/,
		'declarative form without pre-existing body: wrapper is still installed';

	# An implementing subclass must still work correctly
	lives_ok { UT::BodylessImpl->new->fly }
		'implementing subclass of a bodyless-declarative abstract: works correctly';
};

# ===================================================================
# SECTION 14: Mock-based tests
#
# Use Test::Mockingbird to verify internal delegation and spy on
# dependencies to confirm the documented call semantics.
# ===================================================================

# Spy on set_return to verify the class name is passed in both call forms.
subtest 'spy: import() passes class name to set_return in all call forms' => sub {
	plan tests => 2;

	diag 'Spying on set_return across no-args and declarative import()' if $ENV{TEST_VERBOSE};

	# Install spy on set_return before any calls
	my $spy = spy 'Sub::Abstract::set_return';

	# No-args form -- straightforward call
	Sub::Abstract->import();
	my @after_noargs = $spy->();
	is $after_noargs[-1][1], $SA,
		'no-args form: set_return receives the class name as first value';

	# Declarative form -- caller() inside import() must see UT::SetReturnSpy as owner
	{ package UT::SetReturnSpy; Sub::Abstract->import('_spy_sub'); }
	my @after_decl = $spy->();
	is $after_decl[-1][1], $SA,
		'declarative form: set_return receives the class name as first value';

	restore_all();
};

# Spy on validate_strict to confirm it is called once per sub name.
subtest 'spy: import() calls validate_strict once per sub name in the list' => sub {
	plan tests => 1;

	diag 'Spying on validate_strict call count' if $ENV{TEST_VERBOSE};

	# Install spy before the import() calls
	my $spy = spy 'Sub::Abstract::validate_strict';

	{
		package UT::ValidateSpy;
		sub _a { 1 }
		sub _b { 2 }
		sub _c { 3 }
		Sub::Abstract->import('_a', '_b', '_c');
	}

	my @calls = $spy->();

	# Three sub names must produce at least three validate_strict calls
	ok scalar(@calls) >= 3,
		'validate_strict called at least once per sub name (3 names -> >=3 calls)';

	restore_all();
};

# Mock_scoped ensures that mocks installed in one subtest don't leak to others.
subtest 'mock_scoped: validate_strict replacement is scoped correctly' => sub {
	plan tests => 2;

	Readonly::Scalar my $GOOD_NAME => '_scoped_test';

	# Inside the mock scope, validation always fails
	{
		my $g = mock_scoped 'Sub::Abstract::validate_strict' =>
			sub { die "forced failure\n" };

		throws_ok {
			package UT::AttrOwner;
			Sub::Abstract->import($GOOD_NAME);
		} qr/is not a valid Perl identifier/,
			'inside mock_scoped: validate_strict failure -> documented error';
	}

	# Outside the mock scope, validation must work normally
	{ package UT::ScopedCheck; sub _scoped_test { 1 } }
	lives_ok {
		package UT::ScopedCheck;
		Sub::Abstract->import($GOOD_NAME);
	} 'outside mock_scoped: real validate_strict succeeds for a valid name';
};

# ===================================================================
# SECTION 15 (addition): single-underscore method name
#
# The documented regex /\A[_a-zA-Z]\w*\z/ allows a single underscore
# '_' as a complete valid Perl identifier (the \w* matches zero chars).
# This boundary case is not tested by any other existing subtest.
# ===================================================================

# A single underscore is at the minimum-length boundary of the regex.
subtest 'import() accepts single-underscore identifier "_"' => sub {
	plan tests => 1;

	# Create a package and install '_' as an abstract method post-CHECK
	{ package UT::SingleUnderscore; sub new { bless {}, shift } }

	lives_ok {
		package UT::SingleUnderscore;
		Sub::Abstract->import('_');
	} 'import("_") lives: single underscore matches /\\A[_a-zA-Z]\\w*\\z/';
};

done_testing;
