#!/usr/bin/perl
# t/unit.t -- black-box unit tests for Sub::Protected's public API
#
# Every test is derived strictly from the POD.  Only the documented public
# interface is exercised: import(), the :Protected attribute, $BYPASS and
# %config.  No private function is called directly.
#
# Mocks are used to:
#   * force validation and argument-normalisation branches in import()
#   * verify that documented external dependencies are invoked
#
# A ledger lists every documented message and return state.  Each is
# deleted when a test triggers it, and the script fails if any remain.

use strict;
use warnings;

# Untaint $HOME so prove -lt is happy with the local lib paths
BEGIN {
	# HOME is often unset on Windows
	if(defined($ENV{HOME}) && (my ($home) = ($ENV{HOME} =~ /\A(.+)\z/ms))) {
		unshift @INC,
			"$home/src/njh/Test-Mockingbird/lib",
			"$home/src/njh/Test-Returns/lib";
	}
	unshift @INC, 'lib';
}

use Test::Most;

# Test::Mockingbird needs Perl 5.16.3, so it is an optional test dependency
BEGIN {
	eval { require Test::Mockingbird; Test::Mockingbird->import(); 1 }
		or plan(skip_all => 'Test::Mockingbird not installed');
}
use Test::Returns;
use Readonly;

# Loading the module before CHECK means the :Protected and declarative
# fixtures below are wrapped at CHECK time, exactly as documented.
use Sub::Protected;

# -------------------------------------------------------------------
# Constants and configuration -- no magic strings
# -------------------------------------------------------------------

Readonly::Scalar my $SP         => 'Sub::Protected';
Readonly::Scalar my $ATTR_OWNER => 'UT::AttrOwner';
Readonly::Scalar my $PC_OWNER   => 'UT::PostCheck';
Readonly::Scalar my $ALARM_SECS => 60;

my %config = (
	attr_result    => 'attr_secret',
	decl_result    => 'decl_secret',
	pc_result      => 'pc_secret',
	invalid_digit  => '123bad',
	invalid_hyphen => 'has-hyphen',
	invalid_empty  => q{},
	nonexistent    => '_no_such_sub_xyz',
	errno_sentinel => 2,
	eval_sentinel  => "earlier error\n",
	topic_sentinel => 'topic sentinel',
);

# -------------------------------------------------------------------
# API ledger: every message and return state documented in the POD.
# -------------------------------------------------------------------

my %ledger = (
	'msg: import invalid identifier'             => q{Sub::Protected->import: 'NAME' is not a valid Perl identifier},
	'msg: import invalid identifier (undef/ref)' => q{NAME is shown as '' when undef or a reference},
	'msg: import sub not defined'                => q{Sub::Protected: PKG::NAME is not defined},
	'msg: protected access violation'            => q{NAME() is a protected method of OWNER and cannot be called from CALLER},
	'ret: import() with no names returns $class' => 'Returns $class',
	'ret: import() with names returns $class'    => 'Returns $class',
);

# Mark a ledger entry as exercised
sub covered {
	my $key = shift;
	die "Unknown ledger entry '$key'" unless exists $ledger{$key};
	delete $ledger{$key};
	diag "ledger: covered '$key'" if $ENV{TEST_VERBOSE};
	return;
}

# Build the exact documented access-violation message
sub violation_re {
	my ($name, $owner, $caller) = @_;
	return qr/\A\Q$name\E\(\) is a protected method of \Q$owner\E and cannot be called from \Q$caller\E at /;
}

# Build the exact documented invalid-identifier message
sub invalid_re {
	my $name = shift;
	return qr/\A\Q$SP\E->import: '\Q$name\E' is not a valid Perl identifier at /;
}

# -------------------------------------------------------------------
# Package fixtures -- defined at compile time so wrapping happens at
# CHECK time, as documented.
# -------------------------------------------------------------------

# Attribute form
{
	package UT::AttrOwner;
	use Sub::Protected;

	sub new          { bless {}, shift }
	sub _attr_secret :Protected { 'attr_secret' }
	sub call_secret  { (shift)->_attr_secret }
}

{
	package UT::AttrChild;
	our @ISA = ('UT::AttrOwner');
	sub new { bless {}, shift }
	sub child_call { (shift)->_attr_secret }
}

{
	package UT::AttrStranger;
	sub new   { bless {}, shift }
	sub probe { UT::AttrOwner->new->_attr_secret }
}

# Declarative form, scheduled before CHECK
{
	package UT::DeclOwner;
	use Sub::Protected qw(_decl_secret);

	sub new          { bless {}, shift }
	sub _decl_secret { 'decl_secret' }
	sub call_secret  { (shift)->_decl_secret }
}

{
	package UT::DeclChild;
	our @ISA = ('UT::DeclOwner');
	sub new { bless {}, shift }
	sub child_call { (shift)->_decl_secret }
}

{
	package UT::DeclStranger;
	sub new   { bless {}, shift }
	sub probe { UT::DeclOwner->new->_decl_secret }
}

# Not wrapped until a test calls import() after CHECK
{
	package UT::PostCheck;
	sub new        { bless {}, shift }
	sub _pc_secret { 'pc_secret' }
	sub call_pc    { (shift)->_pc_secret }
}

{
	package UT::PCStranger;
	sub new   { bless {}, shift }
	sub probe { UT::PostCheck->new->_pc_secret }
}

# Several names in one import()
{
	package UT::MultiDecl;
	use Sub::Protected qw(_alpha _beta);

	sub new       { bless {}, shift }
	sub _alpha    { 'alpha' }
	sub _beta     { 'beta'  }
	sub get_alpha { (shift)->_alpha }
	sub get_beta  { (shift)->_beta  }
}

{
	package UT::MultiStranger;
	sub new       { bless {}, shift }
	sub try_alpha { UT::MultiDecl->new->_alpha }
	sub try_beta  { UT::MultiDecl->new->_beta  }
}

# One package per documented argument style, each wrapped after CHECK
{
	package UT::StyleList;
	sub _s1 { 'list' }
	sub _s2 { 'list' }
	sub _s3 { 'list' }
	sub _s4 { 'list' }
	sub _s5 { 'list' }
}
{
	package UT::StyleArray;
	sub _s1 { 'array' }
	sub _s2 { 'array' }
}
{
	package UT::StyleHash;
	sub _s1 { 'hash' }
	sub _s2 { 'hash' }
}
{
	# A sub literally called "subs" must be protectable like any other
	package UT::StyleSubs;
	sub subs { 'subs' }
	sub _x   { 'x' }
}

diag "Black-box unit tests for $SP" if $ENV{TEST_VERBOSE};

# ===================================================================
# SECTION 1: import() return value
#
# POD: "Returns: $class (the importing class name)", with or without names.
# ===================================================================

subtest 'import(): no names returns the class name' => sub {
	plan tests => 2;

	my $result = Sub::Protected->import();
	is $result, $SP, 'returns the class name';
	returns_ok($result, { type => 'string' }, 'return value satisfies the documented schema');

	covered('ret: import() with no names returns $class');
};

subtest 'import(): with names returns the class name' => sub {
	plan tests => 2;

	{
		package UT::ReturnPkg;
		sub _any { 1 }
	}
	my $result;
	{
		package UT::ReturnPkg;
		$result = Sub::Protected->import('_any');
	}
	is $result, $SP, 'returns the class name';
	returns_ok($result, { type => 'string' }, 'return value satisfies the documented schema');

	covered('ret: import() with names returns $class');
};

subtest 'import(): return value is produced by Return::Set' => sub {
	plan tests => 2;

	# The API SPECIFICATION names Return::Set for the output schema
	my $spy = spy 'Sub::Protected::set_return';
	Sub::Protected->import();
	my @calls = $spy->();
	restore_all();

	is scalar(@calls), 1, 'set_return called exactly once';
	is $calls[0][1], $SP, 'set_return is given the class name';
};

# ===================================================================
# SECTION 2: import() identifier validation
#
# POD MESSAGES: "Sub::Protected->import: 'NAME' is not a valid Perl
# identifier"; NAME is '' for undef or a reference.
# ===================================================================

subtest 'import(): invalid identifiers croak with the exact documented message' => sub {
	plan tests => 3;

	# One example of each way the documented regex can fail
	for my $bad (@config{qw(invalid_digit invalid_hyphen invalid_empty)}) {
		throws_ok { Sub::Protected->import($bad) } invalid_re($bad),
			"'$bad' is rejected";
	}
	covered('msg: import invalid identifier');
};

subtest 'import(): undef and reference names are reported as empty' => sub {
	plan tests => 2;

	throws_ok { Sub::Protected->import(undef) } invalid_re(q{}),
		'undef is rejected and shown as an empty name';

	# A reference inside the list (the list itself may be an arrayref)
	throws_ok { Sub::Protected->import(['_ok', {}]) } invalid_re(q{}),
		'a reference is rejected and shown as an empty name';

	covered('msg: import invalid identifier (undef/ref)');
};

subtest 'import(): any validation failure produces the documented message' => sub {
	plan tests => 1;

	# Force the validator to fail so the croak path is taken even for a
	# well-formed name: import() must report it the documented way
	my $guard = mock_scoped 'Sub::Protected::validate_strict' => sub { die "forced failure\n" };

	throws_ok {
		package UT::AttrOwner;
		Sub::Protected->import('_looks_valid');
	} invalid_re('_looks_valid'), 'validator failure is reported as an invalid identifier';
};

subtest 'import(): leading underscores and mixed case are valid' => sub {
	plan tests => 1;

	# The documented regex allows [_a-zA-Z] then \w*
	lives_ok {
		package UT::LeadingUnderscore;
		sub _Valid_Name2 { 1 }
		Sub::Protected->import('_Valid_Name2');
	} 'a name matching the documented regex is accepted';
};

# ===================================================================
# SECTION 3: import() with a sub that does not exist
#
# POD MESSAGES: "Sub::Protected: PKG::NAME is not defined".  This must work
# with no bypass in effect -- it is a public API error, not a test aid.
# ===================================================================

subtest 'import(): croaks with the documented message for a missing sub' => sub {
	plan tests => 1;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	throws_ok {
		package UT::AttrOwner;
		Sub::Protected->import($config{nonexistent});
	} qr/\A\Q$SP\E: \Q$ATTR_OWNER\E::\Q$config{nonexistent}\E is not defined at /,
		'missing sub croaks with the exact documented message';

	covered('msg: import sub not defined');
};

# ===================================================================
# SECTION 4: import() argument styles
#
# POD Arguments: a plain list, an arrayref and { subs => [...] } are
# equivalent.  A plain list is always a list of names, so qw(subs _x)
# protects both; only a single arrayref or hashref goes to Params::Get.
# ===================================================================

subtest 'import(): every documented argument style protects the subs' => sub {
	plan tests => 3;

	{
		package UT::StyleList;
		Sub::Protected->import(qw(_s1 _s2));
	}
	{
		package UT::StyleArray;
		Sub::Protected->import([ qw(_s1 _s2) ]);
	}
	{
		package UT::StyleHash;
		Sub::Protected->import({ subs => [ qw(_s1 _s2) ] });
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	for my $pkg (qw(UT::StyleList UT::StyleArray UT::StyleHash)) {
		no strict 'refs';
		throws_ok { &{"${pkg}::_s2"}() } violation_re('_s2', $pkg, 'main'),
			"$pkg: every listed name is protected";
	}
};

subtest 'import(): only a single reference is passed to Params::Get' => sub {
	plan tests => 4;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# A plain list must never be reinterpreted as named arguments
	my $spy = spy 'Sub::Protected::get_params';
	{
		package UT::StyleList;
		Sub::Protected->import('_s3');
	}
	my @calls = $spy->();
	restore_all();
	is scalar(@calls), 0, 'a plain list is not passed to Params::Get';

	# Force both shapes Params::Get may return for a reference: a list of
	# names and a single name
	{
		my $guard = mock_scoped 'Sub::Protected::get_params' => sub { { subs => [ '_s4' ] } };
		package UT::StyleList;
		Sub::Protected->import([ '_ignored' ]);
	}
	{
		my $guard = mock_scoped 'Sub::Protected::get_params' => sub { { subs => '_s5' } };
		package UT::StyleList;
		Sub::Protected->import({ subs => '_ignored' });
	}
	throws_ok { UT::StyleList::_s3() } violation_re('_s3', 'UT::StyleList', 'main'),
		'a single plain name is protected';
	throws_ok { UT::StyleList::_s4() } violation_re('_s4', 'UT::StyleList', 'main'),
		'a list of names from Params::Get is honoured';
	throws_ok { UT::StyleList::_s5() } violation_re('_s5', 'UT::StyleList', 'main'),
		'a single name from Params::Get is honoured';
};

subtest 'import(): a sub called "subs" is an ordinary name' => sub {
	plan tests => 2;

	{
		package UT::StyleSubs;
		Sub::Protected->import(qw(subs _x));
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	# qw(subs _x) must not be read as subs => '_x'
	throws_ok { UT::StyleSubs::subs() } violation_re('subs', 'UT::StyleSubs', 'main'),
		'qw(subs _x) protects subs()';
	throws_ok { UT::StyleSubs::_x() } violation_re('_x', 'UT::StyleSubs', 'main'),
		'qw(subs _x) protects _x';
};

# ===================================================================
# SECTION 5: import() after CHECK wraps immediately
# ===================================================================

subtest 'import(): after CHECK the sub is protected immediately' => sub {
	plan tests => 2;

	{
		package UT::PostCheck;
		Sub::Protected->import('_pc_secret');
	}

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	is(UT::PostCheck->new->call_pc, $config{pc_result}, 'owner can call the sub');
	throws_ok { UT::PCStranger->new->probe } violation_re('_pc_secret', $PC_OWNER, 'UT::PCStranger'),
		'unrelated package is blocked with the exact message';
};

# ===================================================================
# SECTION 6: the two usage forms
#
# POD: owner and subclasses may call; anyone else croaks with
#   "NAME() is a protected method of OWNER and cannot be called from CALLER"
# ===================================================================

for my $form (
	[ 'attribute',   'UT::AttrOwner', 'UT::AttrChild', 'UT::AttrStranger', '_attr_secret', $config{attr_result} ],
	[ 'declarative', 'UT::DeclOwner', 'UT::DeclChild', 'UT::DeclStranger', '_decl_secret', $config{decl_result} ],
) {
	my ($label, $owner, $child, $stranger, $name, $value) = @{$form};

	subtest "$label form: owner and subclass allowed, others blocked" => sub {
		plan tests => 3;

		local $ENV{HARNESS_ACTIVE}    = 0;
		local $Sub::Protected::BYPASS = 0;

		is($owner->new->call_secret, $value, 'owner can call the protected sub');
		is($child->new->child_call, $value, 'subclass can call the protected sub');
		throws_ok { $stranger->new->probe } violation_re($name, $owner, $stranger),
			'unrelated package croaks with the exact documented message';
	};
}
covered('msg: protected access violation');

subtest 'declarative form: several names in one import()' => sub {
	plan tests => 4;

	local $ENV{HARNESS_ACTIVE}    = 0;
	local $Sub::Protected::BYPASS = 0;

	is(UT::MultiDecl->new->get_alpha, 'alpha', 'owner: _alpha callable');
	is(UT::MultiDecl->new->get_beta,  'beta',  'owner: _beta callable');
	throws_ok { UT::MultiStranger->new->try_alpha } violation_re('_alpha', 'UT::MultiDecl', 'UT::MultiStranger'),
		'stranger: _alpha blocked';
	throws_ok { UT::MultiStranger->new->try_beta } violation_re('_beta', 'UT::MultiDecl', 'UT::MultiStranger'),
		'stranger: _beta blocked';
};

# ===================================================================
# SECTION 7: bypass and %config
#
# POD: $BYPASS true OR ($ENV{HARNESS_ACTIVE} and harness_bypass) disables
# all checks; harness_bypass defaults to 1; $BYPASS defaults to false.
# ===================================================================

subtest 'documented defaults' => sub {
	plan tests => 2;

	ok !$Sub::Protected::BYPASS, '$BYPASS is false by default';
	is $Sub::Protected::config{harness_bypass}, 1, 'harness_bypass defaults to 1';
};

subtest 'bypass truth table' => sub {
	plan tests => 8;

	# Every combination of the three controls; access is allowed exactly
	# when BYPASS is true or both HARNESS_ACTIVE and harness_bypass are
	for my $bypass (0, 1) {
		for my $harness (0, 1) {
			for my $hb (0, 1) {
				local $Sub::Protected::BYPASS                 = $bypass;
				local $ENV{HARNESS_ACTIVE}                    = $harness;
				local $Sub::Protected::config{harness_bypass} = $hb;

				my $expect_allowed = ($bypass || ($harness && $hb)) ? 1 : 0;
				my $allowed = eval { UT::AttrStranger->new->probe; 1 } ? 1 : 0;
				is $allowed, $expect_allowed,
					"BYPASS=$bypass HARNESS_ACTIVE=$harness harness_bypass=$hb";
			}
		}
	}
};

subtest '$BYPASS set with local is restored at scope exit' => sub {
	plan tests => 2;

	local $ENV{HARNESS_ACTIVE} = 0;
	{
		local $Sub::Protected::BYPASS = 1;
		is(UT::AttrStranger->new->probe, $config{attr_result}, 'allowed inside the scope');
	}
	throws_ok { UT::AttrStranger->new->probe } violation_re('_attr_secret', $ATTR_OWNER, 'UT::AttrStranger'),
		'blocked again after the scope exits';
};

# ===================================================================
# SECTION 8: global state integrity
#
# POD Side effects: $@, $!, $_ and alarm() timers are left unchanged.
# ===================================================================

# Run $code with sentinels in place; report what the globals hold after
sub globals_after {
	my $code = shift;

	local $@ = $config{eval_sentinel};
	local $! = $config{errno_sentinel};
	local $_ = $config{topic_sentinel};
	local $SIG{ALRM} = sub { die "alarm fired\n" };
	alarm $ALARM_SECS;

	$code->();

	# Read $! first: alarm() itself may set it
	my %after = (
		errno => $! + 0,
		eval  => $@,
		topic => $_,
	);
	$after{alarm} = alarm(0);
	return \%after;
}

for my $case (
	[ 'import() with no names', sub { Sub::Protected->import() } ],
	[ 'import() with names', sub {
		package UT::GlobalPkg;
		sub _g { 1 }
		Sub::Protected->import('_g');
	} ],
	[ 'calling a protected sub from its owner', sub {
		local $ENV{HARNESS_ACTIVE}    = 0;
		local $Sub::Protected::BYPASS = 0;
		UT::AttrOwner->new->call_secret;
	} ],
) {
	my ($label, $code) = @{$case};

	subtest "global state: $label" => sub {
		plan tests => 4;

		my $after = globals_after($code);
		diag "globals after $label: " . join(', ', map { "$_=" . ($after->{$_} // 'undef') } sort keys %{$after})
			if $ENV{TEST_VERBOSE};

		is $after->{eval}, $config{eval_sentinel}, '$@ unchanged';
		is $after->{errno}, $config{errno_sentinel}, '$! unchanged';
		is $after->{topic}, $config{topic_sentinel}, '$_ unchanged';
		SKIP: {
			# Windows emulates alarm(), and its alarm() always returns 0
			# rather than the seconds left, so the timer cannot be read back
			skip 'alarm() does not report the time left on Windows', 1 if $^O eq 'MSWin32';
			ok $after->{alarm} > 0 && $after->{alarm} <= $ALARM_SECS, 'pending alarm left running';
		}
	};
}

# ===================================================================
# Ledger: every documented message and return state must be exercised
# ===================================================================

subtest 'API ledger is empty' => sub {
	plan tests => 1;

	if(%ledger) {
		fail('untested POD conditions: ' . join('; ', sort keys %ledger));
	} else {
		pass('every documented message and return state was exercised');
	}
};

done_testing;
