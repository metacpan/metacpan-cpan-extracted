#!/usr/bin/perl
# t/edge_cases.t -- pathological, boundary-condition, and security tests for
# Sub::Abstract.
#
# Deliberately tries to break or subvert the module through:
#   * undef/0/""/refs as import() arguments
#   * Perl-truthy "false"/"off" strings as BYPASS / HARNESS_ACTIVE values
#   * Pathological invocant values in the abstract wrapper
#   * DESTROY / AUTOLOAD / can / isa / new declared as abstract
#   * Runtime glob replacement of the installed wrapper
#   * Diamond (multiple) inheritance
#   * Re-wrapping the same method twice
#   * Context sensitivity and $_ / @_ preservation
#   * Symbol-table injection to probe the private-caller guard
#   * Mock upstream calls (validate_strict, croak) to return edge-case values

use strict;
use warnings;

# Taint-safe INC manipulation for local dev library copies
BEGIN {
	my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms);
	unshift @INC, 'lib',
		"$home/src/njh/Test-Mockingbird/lib",
		"$home/src/njh/Test-Returns/lib";
}

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Scalar::Util qw(reftype blessed weaken);
use Readonly;

# -------------------------------------------------------------------
# Constants -- avoid magic strings and numbers throughout
# -------------------------------------------------------------------

Readonly::Scalar my $SA           => 'Sub::Abstract';
Readonly::Scalar my $LONG_NAME    => 'x' x 1_000;     # 1000-char identifier stub
Readonly::Scalar my $LONG_VALUE   => 'y' x 100_000;   # 100 kB invocant string

my %config = (
	long_name_len     => 1_000,
	long_value_len    => 100_000,
	# Truthy Perl strings that users might mistakenly assign to suppress bypass
	truthy_false_vals => [qw(false off 0E0 no FALSE)],
	# Falsy Perl strings that turn bypass OFF even though they look positive
	falsy_zero_vals   => ['0', ''],
);

# -------------------------------------------------------------------
# Load the module -- must succeed before any fixture packages compile
# -------------------------------------------------------------------

use Sub::Abstract;

# -------------------------------------------------------------------
# Package fixtures -- ALL at compile time so :Abstract wraps at CHECK
# -------------------------------------------------------------------

# ===== Basic class used by many sections =====
{
	package EC::Base;
	use Sub::Abstract;
	sub new   { bless {}, shift }
	sub foo   :Abstract { }
	sub _bare { 'bare' }    # an unwrapped sub used in $_ clobber tests
}

# Subclass that implements foo() -- wrapper must never fire
{
	package EC::Impl;
	our @ISA = ('EC::Base');
	sub new { bless {}, shift }
	sub foo { 'result' }
}

# ===== DESTROY declared abstract =====
{
	package EC::DestrBase;
	use Sub::Abstract;
	sub new     { bless {}, shift }
	sub DESTROY :Abstract { }
}

{
	package EC::DestrImpl;
	our @ISA = ('EC::DestrBase');
	sub new     { bless {}, shift }
	sub DESTROY { }    # concrete DESTROY -- safe to collect
}

{
	package EC::DestrNoImpl;
	our @ISA = ('EC::DestrBase');
	sub new { bless {}, shift }
	# DESTROY intentionally NOT implemented
}

# ===== AUTOLOAD declared abstract =====
{
	package EC::AutoBase;
	use Sub::Abstract;
	sub new     { bless {}, shift }
	sub AUTOLOAD :Abstract { }
}

{
	package EC::AutoImpl;
	our @ISA = ('EC::AutoBase');
	our $AUTOLOAD;
	sub new      { bless {}, shift }
	sub AUTOLOAD { "autoloaded: $AUTOLOAD" }
}

# ===== can() declared abstract -- shadows UNIVERSAL::can =====
{
	package EC::CanBase;
	use Sub::Abstract qw(can);    # declarative form makes can() abstract
	sub new { bless {}, shift }
}

{
	package EC::CanImpl;
	our @ISA = ('EC::CanBase');
	sub new { bless {}, shift }
	sub can { UNIVERSAL::can($_[0], $_[1]) }    # forwards to UNIVERSAL
}

# ===== new() declared abstract =====
{
	package EC::NewBase;
	use Sub::Abstract qw(new);    # construction itself is abstract
}

{
	package EC::NewImpl;
	our @ISA = ('EC::NewBase');
	sub new { bless {}, shift }    # provides concrete constructor
}

# ===== Diamond (multiple) inheritance =====
{
	package EC::DiamondA;
	use Sub::Abstract;
	sub new     { bless {}, shift }
	sub diamond :Abstract { }
}

{
	package EC::DiamondB;
	our @ISA = ('EC::DiamondA');
	sub new { bless {}, shift }
}

{
	package EC::DiamondC;
	our @ISA = ('EC::DiamondA');
	sub new { bless {}, shift }
}

# DiamondD implements diamond() -- wrapper never fires
{
	package EC::DiamondD;
	our @ISA = ('EC::DiamondB', 'EC::DiamondC');
	sub new     { bless {}, shift }
	sub diamond { 'diamond-impl' }
}

# DiamondNoImpl does NOT implement diamond() -- wrapper must fire
{
	package EC::DiamondNoImpl;
	our @ISA = ('EC::DiamondB', 'EC::DiamondC');
	sub new { bless {}, shift }
}

# ===== Deeply nested package =====
{
	package EC::A::B::C::D::Deep;
	use Sub::Abstract;
	sub new  { bless {}, shift }
	sub deep :Abstract { }
}

{
	package EC::A::B::C::D::Deep::Impl;
	our @ISA = ('EC::A::B::C::D::Deep');
	sub new  { bless {}, shift }
	sub deep { 'deep ok' }
}

# ===== Package for re-wrapping test =====
{
	package EC::ReWrap;
	use Sub::Abstract;
	sub new   { bless {}, shift }
	sub rewrapped :Abstract { }
}

# ===== Class for invocant edge-case tests =====
{
	package EC::Invocant;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub action :Abstract { }
}

# ===== Declarative AUTOLOAD (distinct from attribute form above) =====
{
	package EC::DeclAutoloadBase;
	use Sub::Abstract qw(AUTOLOAD);    # declarative form -- no stub body needed
	sub new { bless {}, shift }
}

# -------------------------------------------------------------------
# TESTS
# -------------------------------------------------------------------

diag "Starting edge-case and security tests for $SA" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: Pathological import() inputs
#
# Every non-identifier value passed to import() must produce the exact
# documented error -- it must never produce an uninitialized-value
# warning or an internal Perl error instead.
# ===================================================================

subtest 'import(): undef in the sub-name list' => sub {
	plan tests => 1;

	# undef is silently coerced to "" and rejected as not-a-valid-identifier.
	# We test the croak message; warnings from upstream validate_strict are
	# not our responsibility to test here.
	throws_ok { Sub::Abstract->import(undef) }
		qr/\Q$SA\E->import: '' is not a valid Perl identifier/,
		'undef coerced to empty string and rejected with exact message';
};

subtest 'import(): empty string, "0", and 0 in the sub-name list' => sub {
	plan tests => 3;

	# Empty string is not a valid Perl identifier
	throws_ok { Sub::Abstract->import('') }
		qr/is not a valid Perl identifier/,
		'empty string "" rejected as invalid identifier';

	# String "0" starts with a digit -- invalid
	throws_ok { Sub::Abstract->import('0') }
		qr/\Q$SA\E->import: '0' is not a valid Perl identifier/,
		'string "0" rejected with exact message';

	# Numeric 0 is stringified to "0" and rejected
	throws_ok { Sub::Abstract->import(0) }
		qr/is not a valid Perl identifier/,
		'numeric 0 rejected (stringifies to "0")';
};

subtest 'import(): reference types in the sub-name list' => sub {
	plan tests => 4;

	# Each reference type must be coerced to "" and rejected
	throws_ok { Sub::Abstract->import([]) }
		qr/is not a valid Perl identifier/, 'arrayref rejected';
	throws_ok { Sub::Abstract->import({}) }
		qr/is not a valid Perl identifier/, 'hashref rejected';
	throws_ok { Sub::Abstract->import(\1) }
		qr/is not a valid Perl identifier/, 'scalar ref rejected';
	throws_ok { Sub::Abstract->import(sub {}) }
		qr/is not a valid Perl identifier/, 'coderef rejected';
};

# A name starting with a digit is invalid even if the rest is fine
subtest 'import(): digit-prefixed names are invalid' => sub {
	plan tests => 2;

	throws_ok { Sub::Abstract->import('9lives') }
		qr/\Q$SA\E->import: '9lives' is not a valid Perl identifier/,
		'"9lives" (digit-prefix) exact error message';

	throws_ok { Sub::Abstract->import('1') }
		qr/is not a valid Perl identifier/, '"1" (bare digit) rejected';
};

# Hyphen, space, and dot are not valid in Perl identifiers
subtest 'import(): names with invalid characters' => sub {
	plan tests => 3;

	throws_ok { Sub::Abstract->import('has-hyphen') }
		qr/is not a valid Perl identifier/, 'hyphen in name rejected';
	throws_ok { Sub::Abstract->import('has space') }
		qr/is not a valid Perl identifier/, 'space in name rejected';
	throws_ok { Sub::Abstract->import('has.dot') }
		qr/is not a valid Perl identifier/, 'dot in name rejected';
};

# ===================================================================
# SECTION 2: $BYPASS with Perl-truthy "false" strings
#
# Users sometimes write $BYPASS = "false" intending to DISABLE bypass.
# In Perl, any non-"0" non-"" string is truthy, so "false" ENABLES it.
# This section documents and tests that surprising behavior.
# ===================================================================

subtest '$BYPASS: truly truthy values (incl. misleading "false") all suppress croak' => sub {
	plan tests => scalar @{$config{truthy_false_vals}} + 1;
	local $ENV{HARNESS_ACTIVE} = 0;

	diag 'Verifying that all truthy strings suppress enforcement' if $ENV{TEST_VERBOSE};

	# The canonical BYPASS=1 suppresses the croak
	{ local $Sub::Abstract::BYPASS = 1;
	  lives_ok { EC::Base->new->foo } 'BYPASS=1 suppresses croak (baseline)'; }

	# Every string that looks like "false" but is Perl-truthy also suppresses
	for my $val (@{$config{truthy_false_vals}}) {
		local $Sub::Abstract::BYPASS = $val;
		lives_ok { EC::Base->new->foo }
			"BYPASS='$val' (truthy) suppresses croak (potential user surprise)";
	}
};

subtest '$BYPASS: truly falsy values all keep enforcement on' => sub {
	plan tests => scalar @{$config{falsy_zero_vals}} + 1;
	local $ENV{HARNESS_ACTIVE} = 0;

	# BYPASS=0 keeps enforcement on (baseline)
	{ local $Sub::Abstract::BYPASS = 0;
	  throws_ok { EC::Base->new->foo } qr/abstract method/,
		'BYPASS=0 keeps enforcement on (baseline)'; }

	# String "0" and "" are also falsy -- enforcement stays on
	for my $val (@{$config{falsy_zero_vals}}) {
		local $Sub::Abstract::BYPASS = $val;
		throws_ok { EC::Base->new->foo } qr/abstract method/,
			"BYPASS='$val' (falsy) keeps enforcement on";
	}
};

# ===================================================================
# SECTION 3: HARNESS_ACTIVE with surprising truthy values
#
# The test harness sets HARNESS_ACTIVE="1".  But any truthy string
# (including "false", "off") also triggers the bypass.  This is
# surprising because "HARNESS_ACTIVE=false" looks like it disables
# the bypass but actually enables it.
# ===================================================================

subtest 'HARNESS_ACTIVE: truthy non-"1" strings still activate bypass' => sub {
	plan tests => scalar @{$config{truthy_false_vals}};
	local $Sub::Abstract::BYPASS = 0;

	diag 'Truthy HARNESS_ACTIVE values all bypass enforcement' if $ENV{TEST_VERBOSE};

	for my $val (@{$config{truthy_false_vals}}) {
		local $ENV{HARNESS_ACTIVE} = $val;
		lives_ok { EC::Base->new->foo }
			"HARNESS_ACTIVE='$val' (truthy) bypasses enforcement";
	}
};

subtest 'HARNESS_ACTIVE: falsy strings keep enforcement on' => sub {
	plan tests => scalar @{$config{falsy_zero_vals}};
	local $Sub::Abstract::BYPASS = 0;

	for my $val (@{$config{falsy_zero_vals}}) {
		local $ENV{HARNESS_ACTIVE} = $val;
		throws_ok { EC::Base->new->foo } qr/abstract method/,
			"HARNESS_ACTIVE='$val' (falsy) keeps enforcement on";
	}
};

# ===================================================================
# SECTION 4: Pathological invocant values in the wrapper closure
#
# The wrapper resolves the invocant as: ref($_[0]) || $_[0] // '<undef>'
# Each unusual value of $_[0] must produce a valid (non-crashing)
# error message with no uninitialized-value warnings.
# ===================================================================

subtest 'invocant: undef => "<undef>" in error message' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# When $_[0] is undef, ref(undef)||undef = undef, then undef // '<undef>'
	# The croak must fire and the error must contain "<undef>".
	throws_ok { EC::Invocant::action(undef) }
		qr/must be implemented by <undef>/,
		'undef invocant: error contains "<undef>" (not an empty string or crash)';
};

subtest 'invocant: numeric 0 => "0" in error message' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# ref(0)||0 = 0, then 0//'<undef>' = 0 (defined) -> invocant = "0"
	throws_ok { EC::Invocant::action(0) }
		qr/must be implemented by 0/,
		'numeric 0 invocant: error contains "0"';
};

subtest 'invocant: empty string "" => "" in error message (no crash)' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# ref("")||"" = "" (defined), ""//... = "" -> invocant = "" (empty string)
	# The croak must fire cleanly; the "must be implemented by" clause will be
	# empty, which is confusing but not a crash.
	throws_ok { EC::Invocant::action('') }
		qr/action\(\) is an abstract method/,
		'empty string invocant: croak fires without crash';
};

subtest 'invocant: unblessed ARRAY ref => "ARRAY" in error message' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# ref([]) = "ARRAY" (truthy) -> invocant = "ARRAY"
	throws_ok { EC::Invocant::action([]) }
		qr/must be implemented by ARRAY/,
		'unblessed arrayref invocant: "ARRAY" appears in message';
};

subtest 'invocant: unblessed CODE ref => "CODE" in error message' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { EC::Invocant::action(sub {}) }
		qr/must be implemented by CODE/,
		'unblessed coderef invocant: "CODE" appears in message';
};

subtest 'invocant: blessed arrayref uses blessed class, not "ARRAY"' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# ref() on a blessed ref returns the class name, not "ARRAY"
	my $obj = bless [], 'EC::BlessedArray';
	throws_ok { EC::Invocant::action($obj) }
		qr/must be implemented by EC::BlessedArray/,
		'blessed arrayref: invocant is the class name, not "ARRAY"';
};

subtest 'invocant: very long string does not cause crash' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag "Passing a $config{long_value_len}-char string as invocant" if $ENV{TEST_VERBOSE};

	# A very long string as invocant must not cause memory errors or crashes
	throws_ok { EC::Invocant::action($LONG_VALUE) }
		qr/action\(\) is an abstract method/,
		"$config{long_value_len}-char invocant: wrapper fires without crash";
};

# ===================================================================
# SECTION 5: Special Perl method names declared as abstract
# ===================================================================

# DESTROY: declaring it abstract means it fires at GC time.
# When called inside an eval block, the croak propagates to the eval.
subtest 'DESTROY as abstract: implementing subclass GC is clean' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	lives_ok {
		# EC::DestrImpl has a concrete DESTROY -- clean collection
		my $obj = EC::DestrImpl->new;
		undef $obj;
	} 'implementing DESTROY subclass collected without croak';
};

subtest 'DESTROY as abstract: non-impl subclass croak swallowed as "(in cleanup)" STDERR' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# In modern Perl, when a destructor dies the exception is NOT propagated
	# as a catchable exception.  Instead, Perl emits it to STDERR as:
	#   "(in cleanup) DESTROY() is an abstract method..."
	# This is a known edge-case consequence of using DESTROY :Abstract.
	# The program continues normally; the croak does not reach an eval block.
	lives_ok {
		my $obj = EC::DestrNoImpl->new;
		undef $obj;    # explicit GC -- wrapper fires, exception swallowed by Perl
	} 'DESTROY abstract croak swallowed by Perl cleanup; program does not die';
};

# AUTOLOAD: declaring it abstract means calling any unknown method croaks.
subtest 'AUTOLOAD as abstract: implementing subclass resolves unknown methods' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# EC::AutoImpl has a concrete AUTOLOAD -- unknown methods work
	lives_ok { EC::AutoImpl->new->any_unknown_method }
		'implementing AUTOLOAD subclass handles unknown method call';
};

subtest 'AUTOLOAD as abstract: non-impl base class croaks on unknown method' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Perl sees no concrete method, falls back to AUTOLOAD wrapper, which croaks
	throws_ok { EC::AutoBase->new->any_unknown_method }
		qr/AUTOLOAD\(\) is an abstract method of EC::AutoBase/,
		'abstract AUTOLOAD fires when no concrete method or AUTOLOAD exists';
};

# can() as abstract: shadows UNIVERSAL::can in the package.
# This is a security / correctness edge case: declaring can() abstract
# means $obj->can('anything') croaks instead of doing an MRO lookup.
subtest 'can() as abstract: base class can() croaks (shadows UNIVERSAL::can)' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# EC::CanBase has can() declared abstract -- can() calls on it must croak
	throws_ok { EC::CanBase->new->can('any_method') }
		qr/can\(\) is an abstract method of EC::CanBase/,
		'abstract can() shadows UNIVERSAL::can and croaks on base';
};

subtest 'can() as abstract: implementing subclass can() works normally' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# EC::CanImpl provides a concrete can() that forwards to UNIVERSAL::can
	lives_ok { EC::CanImpl->new->can('new') }
		'implementing can() subclass can() works normally';
};

# new() as abstract: constructing the base class directly must croak.
subtest 'new() as abstract: base class construction croaks' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# EC::NewBase has new() declared abstract: EC::NewBase->new must croak
	throws_ok { EC::NewBase->new }
		qr/new\(\) is an abstract method of EC::NewBase/,
		'abstract new() fires when base class is constructed directly';
};

subtest 'new() as abstract: implementing subclass constructs cleanly' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# EC::NewImpl provides new() -- construction must succeed
	lives_ok { EC::NewImpl->new }
		'implementing new() subclass constructs cleanly';
};

# ===================================================================
# SECTION 6: Diamond (multiple) inheritance
#
# In a diamond: DiamondD is a subclass of DiamondB AND DiamondC, both
# of which extend DiamondA (which has the abstract method).
# Perl's MRO must only visit the wrapper once and the concrete
# implementation in DiamondD must satisfy the contract.
# ===================================================================

subtest 'diamond inheritance: concrete leaf satisfies abstract from shared base' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'EC::DiamondD inherits via B and C from A (diamond)' if $ENV{TEST_VERBOSE};

	lives_and { is(EC::DiamondD->new->diamond, 'diamond-impl') }
		'diamond: concrete leaf provides implementation, wrapper never fires';
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	EC::DiamondD->new->diamond;
	is scalar(@warnings), 0, 'diamond: no warnings about redefined or ambiguous method';
};

subtest 'diamond inheritance: non-implementing leaf still croaks once (not twice)' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# The wrapper fires for the first match in MRO -- must croak exactly once
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	throws_ok { EC::DiamondNoImpl->new->diamond }
		qr/diamond\(\) is an abstract method of EC::DiamondA/,
		'diamond: non-implementing leaf croaks with the correct owner';
	is scalar(@warnings), 0, 'diamond: no spurious warnings during MRO resolution';
};

# ===================================================================
# SECTION 7: Deeply nested package names
# ===================================================================

subtest 'deeply nested package: abstract method enforces correctly' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'EC::A::B::C::D::Deep has abstract deep()' if $ENV{TEST_VERBOSE};

	# Implementing subclass works
	lives_ok { EC::A::B::C::D::Deep::Impl->new->deep }
		'deeply nested: implementing subclass lives';

	# Base class still croaks, naming the full package path
	throws_ok { EC::A::B::C::D::Deep->new->deep }
		qr/deep\(\) is an abstract method of EC::A::B::C::D::Deep/,
		'deeply nested: full package name appears in error message';
};

# ===================================================================
# SECTION 8: Runtime glob replacement of the wrapper
#
# Replacing the wrapper with a concrete sub via typeglob assignment at
# runtime (post-CHECK) is legal Perl and must work correctly.
# This is NOT a security bypass -- it is expected Perl semantics.
# ===================================================================

subtest 'runtime glob replacement: replacing wrapper with concrete sub' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Fresh package so we don't disturb other tests
	{ package EC::RuntimeReplace;
	  use Sub::Abstract;
	  sub new  { bless {}, shift }
	  sub meth :Abstract { } }

	# Baseline: must croak before replacement
	throws_ok { EC::RuntimeReplace->new->meth }
		qr/abstract method/, 'baseline: wrapper croaks before glob replacement';

	# Replace via typeglob at runtime
	{ no warnings 'redefine'; *EC::RuntimeReplace::meth = sub { 'replaced' } }

	# After replacement the new sub must be called, not the wrapper
	my $result;
	lives_ok { $result = EC::RuntimeReplace->new->meth }
		'after glob replacement: new sub is called without croak';
	is $result, 'replaced', 'correct return value from runtime-installed sub';
};

# ===================================================================
# SECTION 9: Re-wrapping the same method (import() called twice)
# ===================================================================

subtest 're-wrapping: calling import() twice for the same method is idempotent' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Re-wrapping EC::ReWrap::rewrapped post-CHECK' if $ENV{TEST_VERBOSE};

	# First wrap happened at CHECK time via :Abstract attribute
	# Second wrap via import() post-CHECK overwrites with an identical wrapper
	{ package EC::ReWrap; Sub::Abstract->import('rewrapped'); }

	# Must still croak (not silently succeed or double-croak)
	throws_ok { EC::ReWrap->new->rewrapped }
		qr/rewrapped\(\) is an abstract method of EC::ReWrap/,
		're-wrapped method still croaks correctly after second wrapping';

	# BYPASS must still work after re-wrapping
	{ local $Sub::Abstract::BYPASS = 1;
	  lives_ok { EC::ReWrap->new->rewrapped }
		  'BYPASS suppresses croak even after re-wrapping'; }
};

# ===================================================================
# SECTION 10: Context sensitivity -- list vs scalar context
#
# The croak fires before any return value is produced, so list vs
# scalar context should make no difference to the behaviour.
# ===================================================================

subtest 'context: croak fires regardless of list vs scalar context' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Scalar context
	throws_ok { my $r = EC::Base->new->foo }
		qr/abstract method/, 'scalar context: croak fires';

	# List context
	throws_ok { my @r = EC::Base->new->foo }
		qr/abstract method/, 'list context: croak fires';

	# Void context
	throws_ok { EC::Base->new->foo }
		qr/abstract method/, 'void context: croak fires';
};

# ===================================================================
# SECTION 11: Global variable preservation
#
# The wrapper closure must not clobber $_, @_, $!, or $@ during its
# execution path.  These are easy to pollute with string operations.
# ===================================================================

# $_ must survive an abstract method call (the croak lives in eval)
subtest 'wrapper: $_ not clobbered on the croak path' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	local $_ = 'preserve_this';
	eval { EC::Base->new->foo };    # catches the croak
	is $_, 'preserve_this', '$_ not clobbered by abstract wrapper croak';
};

# $_ must also survive when bypass is active (early-return path)
subtest 'wrapper: $_ not clobbered on the bypass early-return path' => sub {
	plan tests => 1;

	local $_ = 'preserve_this';
	local $Sub::Abstract::BYPASS = 1;
	EC::Base->new->foo;    # returns early due to bypass
	is $_, 'preserve_this', '$_ not clobbered on bypass early-return path';
};

# @_ must be passed through without modification (checked via an unwrapped sub)
subtest 'wrapper: the installed closure does not corrupt @_ in the caller' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# After the croak is caught, the outer @_ must be intact
	my @outer = (1, 2, 3);
	eval { EC::Base->new->foo(@outer) };
	is_deeply \@outer, [1, 2, 3], '@_ in caller not corrupted by abstract wrapper';
};

# ===================================================================
# SECTION 12: Symbol-table injection as a security probe
#
# The private-caller guard uses caller(1) to identify who called
# _wrap() or _process_one().  By injecting a sub into Sub::Abstract's
# own namespace, an external caller can spoof caller() to pass the
# guard.  This section documents the known limitation: the guard is a
# lint aid, not a security boundary.
# ===================================================================

subtest 'security: symbol-table injection can spoof _assert_private_caller' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Inject a helper into Sub::Abstract's namespace -- now caller(1) = Sub::Abstract
	{ package Sub::Abstract;
	  sub _ec_injected_wrap { Sub::Abstract::_wrap('EC::Base', 'foo') } }

	# The injected sub can now call _wrap() without triggering the guard
	my $wrapper;
	lives_ok {
		$wrapper = Sub::Abstract::_ec_injected_wrap();
	} 'injected sub can call _wrap() -- guard is spoofed via caller()';

	ok defined($wrapper) && reftype($wrapper) eq 'CODE',
		'_wrap() returns a coderef even when called via injected sub';

	# Note: this documents that the guard is a lint tool, not a security fence.
	# Removing sensitive logic from the wrappers is the correct defense.
};

# ===================================================================
# SECTION 13: Long method names
# ===================================================================

subtest 'long method name (1000 chars): import() validates and croaks correctly' => sub {
	plan tests => 2;

	diag "Testing $config{long_name_len}-char method name in import()" if $ENV{TEST_VERBOSE};

	# A 1000-char identifier that passes the regex (\A[_a-zA-Z]\w*\z)
	my $long_valid = 'a' . ('x' x ($config{long_name_len} - 1));

	# Fresh package to install the long-named abstract wrapper
	{ package EC::LongName; sub new { bless {}, shift } }

	lives_ok {
		package EC::LongName;
		Sub::Abstract->import($long_valid);
	} "1000-char valid identifier accepted by import()";

	# Calling the long-named abstract method must croak with the right owner
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { EC::LongName->new->$long_valid() }
		qr/is an abstract method of EC::LongName/,
		'1000-char abstract method: croak fires with correct owner package';
};

# ===================================================================
# SECTION 14: Error caught at multiple eval depths
#
# The error string must survive being caught at more than one level of
# eval nesting and must not be mutated or lost.
# ===================================================================

subtest 'error: croak string survives multiple eval levels' => sub {
	plan tests => 3;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	my ($outer_err, $inner_err, $re_err);

	# One level of eval
	eval { EC::Base->new->foo };
	$inner_err = $@;

	# Two levels of eval (inner catches and re-throws)
	eval {
		eval { EC::Base->new->foo };
		die $@ if $@;    # re-throw
	};
	$outer_err = $@;

	like $inner_err, qr/foo\(\) is an abstract method of EC::Base/,
		'error string intact after one eval level';
	like $outer_err, qr/foo\(\) is an abstract method of EC::Base/,
		'error string intact after two eval levels (caught and re-thrown)';

	# The error must be a plain string, not an exception object
	ok !ref($outer_err), 'error is a plain string (not an object or ref)';
};

# ===================================================================
# SECTION 15: Mock upstream functions (validate_strict, croak)
# ===================================================================

# If validate_strict is mocked to return undef instead of dying, the
# import() code checks $@ AFTER eval {} -- $@ will be "" if validate_strict
# did not die.  The import should proceed as if the name is valid.
# This demonstrates that the guard relies on validate_strict throwing.
subtest 'mock: validate_strict returns undef -- validation is bypassed' => sub {
	plan tests => 1;

	diag 'Mocking validate_strict to return undef (not die)' if $ENV{TEST_VERBOSE};

	# Use a scoped mock that auto-restores on scope exit
	my $g = mock_scoped 'Sub::Abstract::validate_strict' => sub { return undef };

	# A name that would normally fail validation passes when the mock is active
	# (any name works here; the mock ignores the input and just returns)
	{ package EC::MockedVS; }
	lives_ok {
		package EC::MockedVS;
		Sub::Abstract->import('_mock_test');
	} 'with mocked validate_strict returning undef, import() does not croak';

	# $g goes out of scope here, restoring the real validate_strict
};

# If croak is replaced with a no-op, the abstract wrapper returns normally.
# This confirms the wrapper's entire enforcement path runs through croak,
# and nothing else in the wrapper causes a die.
subtest 'mock: croak silenced -- abstract method call becomes no-op' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	diag 'Replacing Sub::Abstract::croak with a no-op via mock_scoped' if $ENV{TEST_VERBOSE};

	# Track calls via a closure variable; mock_scoped does NOT call the original.
	my $croak_called = 0;
	{
		my $g = mock_scoped 'Sub::Abstract::croak' =>
			sub { $croak_called++ };    # records call, does NOT die

		# With croak silenced, the abstract wrapper returns normally
		lives_ok { EC::Base->new->foo }
			'mocked croak: abstract method call does not die when croak is a no-op';
	}    # $g goes out of scope here, restoring the real croak

	# The mock confirms croak WAS invoked -- enforcement logic ran
	ok $croak_called, 'croak was called by the abstract wrapper (enforcement ran)';
};

# mock validate_strict to throw a non-string exception (hashref)
subtest 'mock: validate_strict throws a non-string exception' => sub {
	plan tests => 1;

	my $g = mock_scoped 'Sub::Abstract::validate_strict' =>
		sub { die { code => 42, msg => 'struct error' } };

	# import() catches any exception from validate_strict via eval {}
	# $@ will be the hashref (truthy) -- import() should still croak with
	# the documented "not a valid Perl identifier" message
	throws_ok { Sub::Abstract->import('_test_non_str_exc') }
		qr/is not a valid Perl identifier/,
		'non-string exception from validate_strict: import() produces documented message';
};

# ===================================================================
# SECTION 16: The original edge-case tests (preserved and annotated)
# ===================================================================

# Both usage forms must produce identical croak behaviour.
subtest 'attr form and declarative form: equivalent enforcement' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	{
		package EC::AttrBase;
		use Sub::Abstract;
		sub new   { bless {}, shift }
		sub greet :Abstract { }
	}

	{
		package EC::DeclBase;
		use Sub::Abstract qw(greet);
		sub new { bless {}, shift }
	}

	throws_ok { EC::AttrBase->new->greet }
		qr/abstract method/, 'attribute form: unimplemented sub croaks';
	throws_ok { EC::DeclBase->new->greet }
		qr/abstract method/, 'declarative form: unimplemented sub croaks';
};

# Function-style call (bypasses OO dispatch, invocant comes from @_[0]).
subtest 'function-style call: invocant resolved from $_[0]' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Blessed object as first argument
	throws_ok { EC::Base::foo(EC::Base->new) }
		qr/\Qfoo() is an abstract method of EC::Base and must be implemented by EC::Base\E/,
		'function-style call with blessed object: exact error message';

	# Bare class name string as first argument
	throws_ok { EC::Base::foo('EC::Base') }
		qr/\Qfoo() is an abstract method of EC::Base and must be implemented by EC::Base\E/,
		'function-style call with bare class name: exact error message';
};

# Class-method call: invocant is the class name string, not a blessed ref.
subtest 'class-method call: invocant is the bare class name string' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	throws_ok { EC::Base->foo }
		qr/\Qfoo() is an abstract method of EC::Base and must be implemented by EC::Base\E/,
		'class-method call: invocant resolved to the bare class name';
};

# Two independently wrapped subs enforce each other independently.
subtest 'multiple abstract subs in same package: independent enforcement' => sub {
	plan tests => 2;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	{
		package EC::Multi;
		use Sub::Abstract;
		sub new { bless {}, shift }
		sub foo :Abstract { }
		sub bar :Abstract { }
	}

	{
		package EC::MultiImpl;
		our @ISA = ('EC::Multi');
		sub new { bless {}, shift }
		sub foo { 'foo-val' }
		# bar NOT implemented
	}

	lives_and { is(EC::MultiImpl->new->foo, 'foo-val') }
		'implemented sub works; unimplemented sibling does not interfere';
	throws_ok { EC::MultiImpl->new->bar }
		qr/\Qbar() is an abstract method of EC::Multi and must be implemented by EC::MultiImpl\E/,
		'unimplemented sibling still croaks independently';
};

# Undef passed as first argument (no object, no class string).
# The invocant logic resolves undef to '<undef>' via the // operator.
subtest 'undef as $_[0]: invocant is "<undef>", no crash' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	{
		package EC::NoArgClass;
		use Sub::Abstract qw(class_op);
		sub new { bless {}, shift }
	}

	# Must croak cleanly with '<undef>' as the invocant, not a crash
	throws_ok { EC::NoArgClass::class_op(undef) }
		qr/abstract method/, 'undef as invocant: croak fires cleanly';
};

# ===================================================================
# SECTION 17: Unblessed GLOB reference as invocant
#
# ref(\*STDOUT) = 'GLOB'; the invocant lookup is ref($_[0])||$_[0]//'<undef>'.
# An unblessed GLOB ref produces 'GLOB' (truthy ref() result), distinct
# from ARRAY ('ARRAY') and CODE ('CODE') refs already tested in section 4.
# ===================================================================

subtest 'GLOB ref as invocant: error message names "GLOB"' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Build a wrapper directly so we can pass any value as $_[0]
	my $wrapper;
	{ local $Sub::Abstract::BYPASS = 1;
	  $wrapper = Sub::Abstract::_wrap('EC::Base', 'foo'); }

	# An unblessed GLOB ref: ref(\*STDOUT) = 'GLOB' -- truthy, so ref() branch fires
	throws_ok { $wrapper->(\*STDOUT) }
		qr/must be implemented by GLOB/,
		'GLOB ref as $_[0]: invocant reported as "GLOB" in the error';
};

# ===================================================================
# SECTION 18: Declarative AUTOLOAD (coverage gap from section 5)
#
# Section 5 tests AUTOLOAD via the ATTRIBUTE form (:Abstract).
# This section tests the DECLARATIVE form (use Sub::Abstract qw(AUTOLOAD))
# -- a distinct code path through import() and _process_one().
# ===================================================================

subtest 'declarative AUTOLOAD: undefined method reaches the abstract wrapper' => sub {
	plan tests => 1;
	local $ENV{HARNESS_ACTIVE}   = 0;
	local $Sub::Abstract::BYPASS = 0;

	# Any undefined method call triggers AUTOLOAD (the abstract wrapper)
	throws_ok { EC::DeclAutoloadBase->new->nonexistent_method }
		qr/AUTOLOAD\(\) is an abstract method of EC::DeclAutoloadBase/,
		'declarative AUTOLOAD: undefined-method call reaches abstract wrapper';
};

done_testing;
