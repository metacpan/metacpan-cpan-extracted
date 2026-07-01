#!/usr/bin/env perl

# End-to-end integration tests for Params::Get.
#
# Strategy: test workflows that cross module boundaries.  Every section
# exercises a real multi-module interaction; none of these are covered by
# the unit or function tests.
#
# Integrations under test:
#   Params::Get   -> Params::Validate::Strict (SYNOPSIS workflow)
#   Params::Get   -> Return::Set              (output-type contract)
#   Params::Get   -> OO constructors          (multiple independent instances)
#   Params::Get   -> optional-dep fallback    (Test::Without::Module)
#   Test::Mockingbird spy on Params::Get::get_params (argument passthrough)
#
# All external calls use the \@_ convention so the spy section can confirm
# the correct calling form reaches get_params.

use strict;
use warnings;

use Test::Most;
use Test::Needs qw(
    Params::Validate::Strict
    Test::Without::Module
    Test::Returns
    Test::Mockingbird
);
use Params::Validate::Strict qw(validate_strict);
use Test::Mockingbird 0.08;
use Test::Returns;
use Readonly;
use Scalar::Util ();
use Params::Get qw(get_params);

# -------------------------------------------------------------------------
# Named constants -- no magic strings/numbers in assertions.
# -------------------------------------------------------------------------
Readonly::Scalar my $PKG      => 'Params::Get';
Readonly::Scalar my $USAGE_RE => qr/Usage:/;

# =========================================================================
# Test classes -- defined once; used across multiple sections.
# Using fully-qualified Params::Get::get_params (not imported) so that
# Test::Mockingbird spies on the canonical symbol can intercept these calls.
# =========================================================================

{
	package Integration::Geo;
	# Stateless geographic calculator: normalises args then validates coords.

	sub locate {
		my $class = shift;
		return Params::Get::get_params(undef, \@_);
	}

	sub where_am_i {
		my $class  = shift;
		my $params = Params::Get::get_params(undef, \@_);
		return Params::Validate::Strict::validate_strict({
			args   => $params,
			schema => {
				latitude  => { type => 'number', min => -90,  max => 90  },
				longitude => { type => 'number', min => -180, max => 180 },
			},
		});
	}
}

{
	package Integration::User;
	# OO class with a constructor that accepts multiple calling conventions.

	sub new {
		my $class  = shift;
		# Flat @_ (not \@_): when named pairs are passed the even-length branch
		# fires and $default='name' is used only for the scalar-only form.
		my $params = Params::Get::get_params('name', @_);
		return bless { %{$params} }, $class;
	}

	sub name  { $_[0]->{name} }
	sub email { $_[0]->{email} }
	sub role  { $_[0]->{role} }
}

{
	package Integration::Configurable;
	# Factory that uses the optional Params::Validate::Strict if available.

	sub build {
		my ($class, @args) = @_;

		my $raw    = Params::Get::get_params(undef, \@args);
		my $result = eval {
			require Params::Validate::Strict;
			Params::Validate::Strict::validate_strict({
				args   => $raw,
				schema => {
					width  => { type => 'integer', min => 1, max => 10_000 },
					height => { type => 'integer', min => 1, max => 10_000 },
				},
			});
		};

		# Graceful degradation: when PVS is unavailable, return the raw hashref.
		return $@ ? $raw : $result;
	}
}

# =========================================================================
# SECTION 1: SYNOPSIS workflow
#
# The POD SYNOPSIS demonstrates the canonical pipeline:
#   get_params(undef, \@_)  ->  validate_strict({ args => ..., schema => ... })
#
# All standard calling conventions must survive the full pipeline.
# =========================================================================

subtest 'SYNOPSIS: named pairs survive full get_params -> validate_strict pipeline' => sub {
	my $result = Integration::Geo->where_am_i(latitude => 51.5, longitude => -0.1);

	ok(defined $result, 'validate_strict returned defined value');
	is(ref($result), 'HASH', 'result is a hashref');
	is($result->{latitude},   51.5,  'latitude preserved through pipeline');
	is($result->{longitude},  -0.1,  'longitude preserved through pipeline');

	returns_ok($result, { type => 'hashref' }, 'return schema: hashref');

	diag explain $result if $ENV{TEST_VERBOSE};
};

subtest 'SYNOPSIS: single hashref calling convention through full pipeline' => sub {
	# Fast path: lone hashref passes through get_params unchanged; PVS then validates it.
	my $result = Integration::Geo->where_am_i({ latitude => -33.9, longitude => 151.2 });

	ok(defined $result, 'hashref input survived full pipeline');
	is($result->{latitude},  -33.9,  'latitude correct');
	is($result->{longitude}, 151.2,  'longitude correct');
};

subtest 'SYNOPSIS: \@_ arrayref convention through full pipeline' => sub {
	# The callee uses get_params(undef, \@_); verify the \@_ passthrough works
	# end-to-end into validate_strict.
	my @args   = (latitude => 40.7, longitude => -74.0);
	my $result = Integration::Geo->where_am_i(@args);

	ok(defined $result, '\@_ convention: result defined');
	is($result->{latitude},   40.7,  'latitude correct');
	is($result->{longitude}, -74.0,  'longitude correct');
};

# =========================================================================
# SECTION 2: Validation pipeline -- invalid values rejected by PVS
#
# get_params normalises successfully; Params::Validate::Strict rejects the
# values for violating schema constraints.  The error must reach the caller.
# =========================================================================

subtest 'validation pipeline: out-of-range latitude rejected by PVS (croaks)' => sub {
	# get_params normalises correctly; PVS croaks on the constraint violation.
	# The croak must propagate out of where_am_i to the caller.
	throws_ok(
		sub { Integration::Geo->where_am_i(latitude => 999, longitude => 0) },
		qr/latitude.*must be no more than/i,
		'out-of-range latitude: PVS croak propagates to caller',
	);

	diag 'PVS croak confirmed for out-of-range latitude' if $ENV{TEST_VERBOSE};
};

subtest 'validation pipeline: get_params error (odd arg list) propagates before PVS' => sub {
	# An odd-length argument list causes get_params to croak.
	# That croak must escape Integration::Geo->where_am_i.
	throws_ok(
		sub { Integration::Geo->where_am_i(latitude => 10, longitude => 20, 'orphan') },
		$USAGE_RE,
		'get_params croak propagates through the wrapper method',
	);
};

subtest 'validation pipeline: zero args + undef $default returns undef from get_params' => sub {
	# get_params(undef, \@_) with empty @_ returns undef.
	# validate_strict receives undef for args -> undef result.
	# The function should not croak -- it returns undef gracefully.
	my $params = Integration::Geo->locate();
	ok(!defined $params, 'empty call returns undef through the locate wrapper');
};

# =========================================================================
# SECTION 3: OO constructor patterns -- multiple independent instances
#
# Instantiate several Integration::User objects using different calling
# conventions.  Mutating one object must not affect any other.
# =========================================================================

subtest 'OO: plain scalar (mandatory $default) constructor' => sub {
	my $u = Integration::User->new('Alice');
	is($u->name, 'Alice', 'name set via scalar arg');
	returns_ok($u, { type => 'object' }, 'instance is an object');
};

subtest 'OO: named-pair constructor' => sub {
	my $u = Integration::User->new(name => 'Bob', email => 'bob@example.com', role => 'admin');
	is($u->name,  'Bob',              'name from named pair');
	is($u->email, 'bob@example.com', 'email from named pair');
	is($u->role,  'admin',           'role from named pair');
};

subtest 'OO: mandatory + options-hashref constructor' => sub {
	my $u = Integration::User->new('Carol', { email => 'carol@example.com', role => 'viewer' });
	is($u->name,  'Carol',              'name from mandatory arg');
	is($u->email, 'carol@example.com', 'email from options hashref');
	is($u->role,  'viewer',            'role from options hashref');
};

subtest 'OO: multiple independent instances share no state' => sub {
	# Create several instances concurrently (same process, sequential ops).
	# Verify that each holds only its own data.
	my $u1 = Integration::User->new('Dave', { role => 'author' });
	my $u2 = Integration::User->new('Eve',  { role => 'editor' });
	my $u3 = Integration::User->new(name => 'Frank', email => 'frank@example.com');

	is($u1->name, 'Dave',   'u1 name unchanged');
	is($u2->name, 'Eve',    'u2 name unchanged');
	is($u3->name, 'Frank',  'u3 name unchanged');

	is($u1->role, 'author', 'u1 role unchanged');
	is($u2->role, 'editor', 'u2 role unchanged');

	isnt($u1, $u2,         'u1 and u2 are distinct objects');
	isnt($u2, $u3,         'u2 and u3 are distinct objects');

	# Mutate u1's backing hash and confirm u2 is unaffected.
	$u1->{name} = 'Modified';
	is($u2->name, 'Eve', 'mutating u1 does not affect u2');

	diag sprintf('u1=%s u2=%s u3=%s', $u1->name, $u2->name, $u3->name)
		if $ENV{TEST_VERBOSE};
};

subtest 'OO: hashref calling convention passed through to constructor' => sub {
	my $u = Integration::User->new({ name => 'Grace', role => 'guest' });
	# Single hashref hits the fast path; the $default='name' is bypassed.
	# Result is the hashref itself, blessed as Integration::User.
	is($u->name, 'Grace', 'name from hashref calling convention');
	is($u->role, 'guest', 'role from hashref calling convention');
};

# =========================================================================
# SECTION 4: Return::Set output-type contract across the pipeline
#
# Validates that every integration-level return value satisfies the output
# schema declared in the POD: hashref or undef (optional hashref).
# =========================================================================

subtest 'Return::Set: pipeline output satisfies hashref schema' => sub {
	my @cases = (
		[ 'named pairs -> PVS',
			Integration::Geo->where_am_i(latitude => 0, longitude => 0) ],
		[ 'hashref -> PVS',
			Integration::Geo->where_am_i({ latitude => 1, longitude => 1 }) ],
		[ 'OO scalar default',
			do { my $u = Integration::User->new('X'); +{ %{$u} } } ],
		[ 'OO named pairs',
			do { my $u = Integration::User->new(name => 'Y'); +{ %{$u} } } ],
	);

	for my $case (@cases) {
		my ($label, $val) = @{$case};
		returns_ok($val, { type => 'hashref' }, "hashref schema: $label");
	}
};

subtest 'Return::Set: get_params undef return satisfies optional hashref schema' => sub {
	# When get_params(undef, \@_) is called with zero args it returns undef.
	# That return value must satisfy the optional hashref output spec in the POD.
	my $raw_undef = get_params();
	returns_ok($raw_undef, { type => 'hashref', optional => 1 },
		'get_params() undef satisfies optional hashref spec');
};

# =========================================================================
# SECTION 5: Graceful degradation via Test::Without::Module
#
# Integration::Configurable::build uses an eval { require } pattern to
# optionally invoke Params::Validate::Strict.  When PVS is hidden by
# Test::Without::Module, build returns the raw get_params hashref instead
# of the validated one.
# =========================================================================

subtest 'optional PVS: valid input validated when PVS is available' => sub {
	my $result = Integration::Configurable->build(width => 800, height => 600);

	ok(defined $result, 'result defined when PVS available');
	is($result->{width},  800, 'width validated and preserved');
	is($result->{height}, 600, 'height validated and preserved');

	diag explain $result if $ENV{TEST_VERBOSE};
};

subtest 'optional PVS: get_params still works when PVS is hidden' => sub {
	# Simulate PVS not being installed by removing it from %INC so that
	# Test::Without::Module's @INC hook intercepts the require inside build().
	local %INC = %INC;
	delete $INC{'Params/Validate/Strict.pm'};

	Test::Without::Module->import('Params::Validate::Strict');

	my $result = Integration::Configurable->build(width => 1024, height => 768);

	# PVS unavailable: build() should fall back to the raw get_params hashref.
	ok(defined $result, 'fallback result defined even without PVS');
	is($result->{width},  1024, 'width present in fallback hashref');
	is($result->{height}, 768,  'height present in fallback hashref');
	is(ref($result), 'HASH', 'fallback result is still a hashref');

	Test::Without::Module->unimport('Params::Validate::Strict');

	diag 'Fallback triggered: PVS was hidden' if $ENV{TEST_VERBOSE};
};

subtest 'optional PVS: PVS resumes working after Test::Without::Module is unimported' => sub {
	# Confirm that after unimport the real PVS is available again.
	my $result = Integration::Configurable->build(width => 320, height => 240);
	ok(defined $result, 'PVS available again after unimport');
	is($result->{width},  320, 'width restored after re-import');
	is($result->{height}, 240, 'height restored after re-import');
};

subtest 'optional PVS: invalid args without PVS return raw (unvalidated) hashref' => sub {
	# When PVS is hidden, even out-of-range values pass through unchecked.
	# This documents the known risk of running without validation.
	local %INC = %INC;
	delete $INC{'Params/Validate/Strict.pm'};

	Test::Without::Module->import('Params::Validate::Strict');

	my $result = Integration::Configurable->build(width => 99_999, height => 99_999);

	ok(defined $result,  'out-of-range values passed through without PVS');
	is($result->{width}, 99_999, 'unvalidated width present in raw hashref');

	Test::Without::Module->unimport('Params::Validate::Strict');
};

# =========================================================================
# SECTION 6: Spy verification -- argument passthrough to Params::Get
#
# Integration::Geo->locate uses Params::Get::get_params (fully qualified).
# Spy on Params::Get::get_params to verify the calling code passes the
# correct arguments: (undef, ARRAY_REF) -- the \@_ convention.
# =========================================================================

subtest 'spy: locate passes (undef, \\@_) to Params::Get::get_params' => sub {
	my $spy = spy 'Params::Get::get_params';

	my $result = Integration::Geo->locate(latitude => 48.8, longitude => 2.3);

	my @calls = $spy->();
	ok(@calls >= 1, 'Params::Get::get_params was called at least once');

	# First call: args are [method_name, $default, @remaining]
	my $call = $calls[0];
	ok(!defined($call->[1]), 'first arg ($default) was undef');
	is(ref($call->[2]), 'ARRAY', 'second arg is an ARRAY ref (\\@_ convention)');

	# The array ref must contain the flattened named pairs.
	my %from_spy;
	@from_spy{@{$call->[2]}} = ();    # turn the flat list into hash keys
	ok(exists $from_spy{latitude},  'latitude present in \\@_ passed to get_params');
	ok(exists $from_spy{longitude}, 'longitude present in \\@_ passed to get_params');

	# The real function still ran -- verify the result is valid.
	ok(defined $result,        'get_params call-through returned a defined value');
	is($result->{latitude},   48.8, 'latitude in result');
	is($result->{longitude},   2.3, 'longitude in result');

	diag explain \@calls if $ENV{TEST_VERBOSE};
	restore_all();
};

subtest 'spy: Integration::User->new passes (string_default, flat @_) to get_params' => sub {
	# Integration::User uses the flat @_ convention (not \@_).
	# get_params receives the mandatory scalar then the options hashref as
	# separate positional args: ('name', 'Heidi', { role => 'tester' }).
	my $spy = spy 'Params::Get::get_params';

	Integration::User->new('Heidi', { role => 'tester' });

	my @calls = $spy->();
	ok(@calls >= 1, 'get_params was called');

	my $call = $calls[0];
	is($call->[1],      'name',   '$default was the string "name"');
	is($call->[2],      'Heidi',  'mandatory positional scalar is second element');
	is(ref($call->[3]), 'HASH',   'options hashref is the third element');

	restore_all();
};

subtest 'spy: get_params spy does not interfere with multiple sequential calls' => sub {
	# Install a spy, make two calls, verify both are captured independently.
	my $spy = spy 'Params::Get::get_params';

	Integration::Geo->locate(latitude => 10, longitude => 20);
	Integration::Geo->locate(latitude => 30, longitude => 40);

	my @calls = $spy->();
	cmp_ok(scalar @calls, '>=', 2, 'both calls captured by spy');

	restore_all();
};

done_testing();
