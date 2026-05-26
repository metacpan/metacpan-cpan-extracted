#!/usr/bin/env perl

# White-box function tests for Params::Validate::Strict.
# Each private helper is exercised directly via its full package name.
# mock_scoped is used as a scope-guard (RAII): store the return value to keep
# the mock live, let it go out of scope to restore the original.
# Unicode::GCString is mocked for the non-ASCII character-counting subtest.
# Logger methods are mocked for the _error/_warn subtests.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock_scoped);

use Params::Validate::Strict qw(validate_strict);

# ── Tiny in-process classes used by object/can/isa subtests ──────────────────
{
	package PVS::Test::Searcher;
	sub new   { bless {}, shift }
	sub search { 'found' }
	sub index  { 0 }
}
{
	package PVS::Test::Base;
	sub new { bless {}, shift }
}
{
	package PVS::Test::Child;
	our @ISA = ('PVS::Test::Base');
	sub new { bless {}, shift }
}

# Stub logger — stub methods must exist for mock_scoped to replace them.
{
	package MockLogger;
	sub new   { bless {}, shift }
	sub error { }
	sub warn  { }
}

# Lightweight Unicode::GCString stand-in used by the non-ASCII test.
# Defined as a real package so that mocking only new() is needed —
# length() avoids the ($) prototype that the real module carries.
{
	package PVS::Test::GCString;
	sub new    { bless {}, shift }
	sub length { 5 }
}

# ── Test helpers ──────────────────────────────────────────────────────────────

# Run validate_strict with a pre-built $params hashref.
# Params::Get is an installed dependency and works correctly with named args,
# so we call validate_strict directly — no mocking of get_params needed.
sub _vs {
	my ($p) = @_;
	$p->{custom_types} //= {};
	return validate_strict(%$p);
}

# Same, but asserts that validate_strict croaks matching $pattern.
sub _vs_throws {
	my ($p, $pattern, $label) = @_;
	$p->{custom_types} //= {};
	throws_ok { validate_strict(%$p) } $pattern, $label;
}

# ══════════════════════════════════════════════════════════════════════════════
# _number_of_characters
# ══════════════════════════════════════════════════════════════════════════════

subtest '_number_of_characters: undef input returns undef' => sub {
	ok(
		!defined(Params::Validate::Strict::_number_of_characters(undef)),
		'returns undef for undef input'
	);
};

subtest '_number_of_characters: ASCII strings use core length()' => sub {
	is(Params::Validate::Strict::_number_of_characters(''),        0,   'empty string → 0');
	is(Params::Validate::Strict::_number_of_characters('hello'),   5,   '5-char ASCII word');
	is(Params::Validate::Strict::_number_of_characters('a' x 80), 80,  '80-char ASCII string');
};

subtest '_number_of_characters: non-ASCII delegates to Unicode::GCString' => sub {
	# Use a Perl character string (utf8 flag set) so the decode_utf8 branch is
	# skipped and we go straight to Unicode::GCString->new($value)->length().
	my $unicode = "\x{00e9}l\x{00e8}ve";	# élève — 5 grapheme clusters
	# Mock only new() — returning a PVS::Test::GCString whose length() has no
	# prototype avoids the ($) prototype mismatch on the real module's length.
	my $m_new = mock_scoped('Unicode::GCString', 'new',
		sub { PVS::Test::GCString->new });
	is(
		Params::Validate::Strict::_number_of_characters($unicode),
		5, 'returns GCString->length for non-ASCII character string'
	);
	# $m_new goes out of scope at end of subtest → new() restored
};

# ══════════════════════════════════════════════════════════════════════════════
# _apply_nested_defaults
# ══════════════════════════════════════════════════════════════════════════════

subtest '_apply_nested_defaults: existing keys preserved, absent keys without default stay absent' => sub {
	my $r = Params::Validate::Strict::_apply_nested_defaults(
		{ a => 1 },
		{ a => { type => 'integer' }, b => { type => 'string' } }
	);
	is($r->{a}, 1,         'existing key preserved');
	ok(!exists($r->{b}),   'absent key without default stays absent');
};

subtest '_apply_nested_defaults: missing keys populated from defaults' => sub {
	my $r = Params::Validate::Strict::_apply_nested_defaults(
		{},
		{
			colour => { type => 'string',  optional => 1, default => 'blue' },
			count  => { type => 'integer', optional => 1, default => 0 },
		}
	);
	is($r->{colour}, 'blue', 'string default applied for absent key');
	is($r->{count},  0,      'integer zero default applied for absent key');
};

subtest '_apply_nested_defaults: caller value wins over default' => sub {
	my $r = Params::Validate::Strict::_apply_nested_defaults(
		{ colour => 'red' },
		{ colour => { type => 'string', optional => 1, default => 'blue' } }
	);
	is($r->{colour}, 'red', 'caller-supplied value not overwritten by default');
};

subtest '_apply_nested_defaults: recurses into nested hashref schemas' => sub {
	my $r = Params::Validate::Strict::_apply_nested_defaults(
		{ user => { name => 'Alice' } },
		{
			user => {
				type   => 'hashref',
				schema => {
					name => { type => 'string' },
					role => { type => 'string', optional => 1, default => 'viewer' },
				},
			},
		}
	);
	is($r->{user}{name}, 'Alice',  'nested existing key preserved');
	is($r->{user}{role}, 'viewer', 'nested missing key populated from default');
};

# ══════════════════════════════════════════════════════════════════════════════
# _error
# ══════════════════════════════════════════════════════════════════════════════

subtest '_error: croaks with message when no logger' => sub {
	throws_ok {
		Params::Validate::Strict::_error(undef, 'something went wrong')
	} qr/something went wrong/, 'croaks with the supplied message';
};

subtest '_error: calls logger->error then still croaks' => sub {
	my $logger = MockLogger->new;
	my @logged;
	# Use the class name so mock_scoped installs at the symbol-table level
	# where normal ->method dispatch will find it.
	my $m_err = mock_scoped('MockLogger', 'error',
		sub { push @logged, join('', @_[1 .. $#_]) });
	throws_ok {
		Params::Validate::Strict::_error($logger, 'db failure')
	} qr/db failure/, 'still croaks even with a logger present';
	is(scalar @logged, 1,             'logger->error called exactly once');
	like($logged[0],  qr/db failure/, 'logger receives the error message');
};

# ══════════════════════════════════════════════════════════════════════════════
# _warn
# ══════════════════════════════════════════════════════════════════════════════

subtest '_warn: carps to STDERR when no logger' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	Params::Validate::Strict::_warn(undef, 'heads up');
	is(scalar @warnings, 1,           'exactly one warning emitted');
	like($warnings[0],  qr/heads up/, 'warning text contains the message');
};

subtest '_warn: delegates to logger->warn and does not carp' => sub {
	my $logger = MockLogger->new;
	my (@logged, @warnings);
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	# Use the class name so mock_scoped installs at the symbol-table level.
	my $m_warn = mock_scoped('MockLogger', 'warn',
		sub { push @logged, join('', @_[1 .. $#_]) });
	Params::Validate::Strict::_warn($logger, 'notice');
	is(scalar @logged,   1,        'logger->warn called once');
	is(scalar @warnings, 0,        'no carp emitted when logger present');
	like($logged[0], qr/notice/,   'logger receives the warning message');
};

# ══════════════════════════════════════════════════════════════════════════════
# _validate_mutually_exclusive
# ══════════════════════════════════════════════════════════════════════════════

subtest '_validate_mutually_exclusive: both absent → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_mutually_exclusive(
			{},
			{ params => ['file', 'content'] },
			undef, 'test'
		)
	} 'no error when both members absent';
};

subtest '_validate_mutually_exclusive: only one present → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_mutually_exclusive(
			{ file => 'foo.txt' },
			{ params => ['file', 'content'] },
			undef, 'test'
		)
	} 'no error when only one member present';
};

subtest '_validate_mutually_exclusive: both present → croaks' => sub {
	throws_ok {
		Params::Validate::Strict::_validate_mutually_exclusive(
			{ file => 'foo.txt', content => 'raw text' },
			{ params => ['file', 'content'] },
			undef, 'test'
		)
	} qr/Cannot specify both/, 'croaks when both mutually-exclusive params present';
};

subtest '_validate_mutually_exclusive: custom description used in error' => sub {
	throws_ok {
		Params::Validate::Strict::_validate_mutually_exclusive(
			{ file => 'x', content => 'y' },
			{ params => ['file', 'content'], description => 'file XOR content' },
			undef, 'test'
		)
	} qr/file XOR content/, 'relationship description propagated to error message';
};

# ══════════════════════════════════════════════════════════════════════════════
# _validate_required_group
# ══════════════════════════════════════════════════════════════════════════════

subtest '_validate_required_group: at least one present → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_required_group(
			{ id => 42 },
			{ params => ['id', 'name'] },
			undef, 'test'
		)
	} 'no error when one member of group is present';
};

subtest '_validate_required_group: all absent → croaks' => sub {
	throws_ok {
		Params::Validate::Strict::_validate_required_group(
			{},
			{ params => ['id', 'name'] },
			undef, 'test'
		)
	} qr/Must specify at least one of/, 'croaks when no member of group present';
};

# ══════════════════════════════════════════════════════════════════════════════
# _validate_conditional_requirement
# ══════════════════════════════════════════════════════════════════════════════

subtest '_validate_conditional_requirement: if param absent → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_conditional_requirement(
			{},
			{ if => 'async', then_required => 'callback' },
			undef, 'test'
		)
	} 'no error when the condition param is absent';
};

subtest '_validate_conditional_requirement: if param falsy → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_conditional_requirement(
			{ async => 0 },
			{ if => 'async', then_required => 'callback' },
			undef, 'test'
		)
	} 'no error when the condition param is present but falsy';
};

subtest '_validate_conditional_requirement: if truthy, then present → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_conditional_requirement(
			{ async => 1, callback => sub {} },
			{ if => 'async', then_required => 'callback' },
			undef, 'test'
		)
	} 'no error when condition met and required param present';
};

subtest '_validate_conditional_requirement: if truthy, then absent → croaks' => sub {
	throws_ok {
		Params::Validate::Strict::_validate_conditional_requirement(
			{ async => 1 },
			{ if => 'async', then_required => 'callback' },
			undef, 'test'
		)
	} qr/callback is required/, 'croaks when condition met but required param absent';
};

# ══════════════════════════════════════════════════════════════════════════════
# _validate_dependency
# ══════════════════════════════════════════════════════════════════════════════

subtest '_validate_dependency: dependent param absent → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_dependency(
			{},
			{ param => 'port', requires => 'host' },
			undef, 'test'
		)
	} 'no error when the dependent param is absent';
};

subtest '_validate_dependency: both present → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_dependency(
			{ port => 8080, host => 'localhost' },
			{ param => 'port', requires => 'host' },
			undef, 'test'
		)
	} 'no error when dependent param and its requirement are both present';
};

subtest '_validate_dependency: param present but requirement absent → croaks' => sub {
	throws_ok {
		Params::Validate::Strict::_validate_dependency(
			{ port => 8080 },
			{ param => 'port', requires => 'host' },
			undef, 'test'
		)
	} qr/port requires host/, 'croaks when dependency not satisfied';
};

# ══════════════════════════════════════════════════════════════════════════════
# _validate_value_constraint
# ══════════════════════════════════════════════════════════════════════════════

subtest '_validate_value_constraint: condition param absent → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_value_constraint(
			{},
			{ if => 'ssl', then => 'port', operator => '==', value => 443 },
			undef, 'test'
		)
	} 'no error when the if param is absent';
};

subtest '_validate_value_constraint: == satisfied → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_value_constraint(
			{ ssl => 1, port => 443 },
			{ if => 'ssl', then => 'port', operator => '==', value => 443 },
			undef, 'test'
		)
	} 'no error when == constraint is satisfied';
};

subtest '_validate_value_constraint: == violated → croaks' => sub {
	throws_ok {
		Params::Validate::Strict::_validate_value_constraint(
			{ ssl => 1, port => 80 },
			{ if => 'ssl', then => 'port', operator => '==', value => 443 },
			undef, 'test'
		)
	} qr/port must be == 443/, 'croaks when == constraint is violated';
};

subtest '_validate_value_constraint: all six operators' => sub {
	my $rel_base = { if => 'cond', then => 'val' };

	my @cases = (
		['==',  5,  5, 1, 'eq: equal passes'],
		['==',  5,  6, 0, 'eq: unequal fails'],
		['!=',  5,  6, 1, 'ne: unequal passes'],
		['!=',  5,  5, 0, 'ne: equal fails'],
		['<',   5,  3, 1, 'lt: less passes'],
		['<',   5,  5, 0, 'lt: equal fails'],
		['<=',  5,  5, 1, 'le: equal passes'],
		['<=',  5,  6, 0, 'le: greater fails'],
		['>',   5,  7, 1, 'gt: greater passes'],
		['>',   5,  5, 0, 'gt: equal fails'],
		['>=',  5,  5, 1, 'ge: equal passes'],
		['>=',  5,  4, 0, 'ge: less fails'],
	);

	for my $case (@cases) {
		my ($op, $limit, $actual, $ok, $label) = @{$case};
		my $rel = { %$rel_base, operator => $op, value => $limit };
		my $args = { cond => 1, val => $actual };
		if($ok) {
			lives_ok { Params::Validate::Strict::_validate_value_constraint($args, $rel, undef, 'test') } $label;
		} else {
			throws_ok { Params::Validate::Strict::_validate_value_constraint($args, $rel, undef, 'test') } qr/must be $op $limit/, $label;
		}
	}
};

# ══════════════════════════════════════════════════════════════════════════════
# _validate_value_conditional
# ══════════════════════════════════════════════════════════════════════════════

subtest '_validate_value_conditional: if param absent → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_value_conditional(
			{},
			{ if => 'mode', equals => 'secure', then_required => 'key' },
			undef, 'test'
		)
	} 'no error when the if param is absent';
};

subtest '_validate_value_conditional: if value does not match → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_value_conditional(
			{ mode => 'public' },
			{ if => 'mode', equals => 'secure', then_required => 'key' },
			undef, 'test'
		)
	} 'no error when if param value differs from equals';
};

subtest '_validate_value_conditional: value matches, then present → ok' => sub {
	lives_ok {
		Params::Validate::Strict::_validate_value_conditional(
			{ mode => 'secure', key => 's3cr3t' },
			{ if => 'mode', equals => 'secure', then_required => 'key' },
			undef, 'test'
		)
	} 'no error when condition is met and required param is present';
};

subtest '_validate_value_conditional: value matches, then absent → croaks' => sub {
	throws_ok {
		Params::Validate::Strict::_validate_value_conditional(
			{ mode => 'secure' },
			{ if => 'mode', equals => 'secure', then_required => 'key' },
			undef, 'test'
		)
	} qr/key is required/, 'croaks when conditional requirement is unmet';
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — setup and schema handling
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: undef schema → passthrough' => sub {
	my $r = _vs({ schema => undef, input => { x => 42 } });
	is($r->{x}, 42, 'input returned unchanged when schema is undef');
};

subtest 'validate_strict: non-hashref schema → croaks' => sub {
	_vs_throws(
		{ schema => 'oops', input => {} },
		qr/schema must be a hash reference/,
		'croaks when schema is not a hashref'
	);
};

subtest 'validate_strict: Data::Processor-style wrapped schema unwrapped' => sub {
	my $r = _vs({
		schema => {
			description => 'User record',
			members     => { name => { type => 'string' } },
		},
		input => { name => 'Bob' },
	});
	is($r->{name}, 'Bob', 'members-wrapped schema handled correctly');
};

subtest 'validate_strict: unknown parameter handler: die (default)' => sub {
	_vs_throws(
		{
			schema => { name => { type => 'string' } },
			input  => { name => 'Alice', extra => 'surprise' },
		},
		qr/Unknown parameter 'extra'/,
		'croaks on unknown parameter by default'
	);
};

subtest 'validate_strict: unknown parameter handler: warn' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok {
		_vs({
			schema                    => { name => { type => 'string' } },
			input                     => { name => 'Alice', extra => 'ok' },
			unknown_parameter_handler => 'warn',
		});
	} 'no croak on unknown parameter with warn handler';
	ok(scalar @warnings > 0,        'warning emitted for unknown param');
	like($warnings[0], qr/Unknown parameter 'extra'/, 'warning names the param');
};

subtest 'validate_strict: unknown parameter handler: ignore' => sub {
	lives_ok {
		_vs({
			schema                    => { name => { type => 'string' } },
			input                     => { name => 'Alice', extra => 'silenced' },
			unknown_parameter_handler => 'ignore',
		});
	} 'no error for unknown parameter when handler is ignore';
};

subtest 'validate_strict: required param missing → croaks' => sub {
	_vs_throws(
		{ schema => { name => { type => 'string' } }, input => {} },
		qr/Required parameter 'name' is missing/,
		'croaks when required parameter absent from input'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: string
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type string — valid scalar' => sub {
	my $r = _vs({
		schema => { name => { type => 'string' } },
		input  => { name => 'Alice' },
	});
	is($r->{name}, 'Alice', 'string value returned unchanged');
};

subtest 'validate_strict: type string — ref value rejected' => sub {
	_vs_throws(
		{ schema => { name => { type => 'string' } }, input => { name => [] } },
		qr/must be a string/,
		'croaks when string param is a reference'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: integer
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type integer — string coerced to int' => sub {
	my $r = _vs({
		schema => { age => { type => 'integer' } },
		input  => { age => '30' },
	});
	is($r->{age}, 30, 'string coerced to integer');
	ok($r->{age} == 30, 'coerced value compares numerically');
};

subtest 'validate_strict: type integer — float string rejected' => sub {
	_vs_throws(
		{ schema => { n => { type => 'integer' } }, input => { n => '3.14' } },
		qr/must be an integer/,
		'croaks for floating-point string'
	);
};

subtest 'validate_strict: type integer — alphabetic rejected' => sub {
	_vs_throws(
		{ schema => { n => { type => 'integer' } }, input => { n => 'foo' } },
		qr/must be an integer/,
		'croaks for non-numeric string'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: number / float
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type number — string coerced' => sub {
	my $r = _vs({
		schema => { price => { type => 'number' } },
		input  => { price => '9.99' },
	});
	ok($r->{price} == 9.99, 'string coerced to number');
};

subtest 'validate_strict: type float — synonym for number' => sub {
	my $r = _vs({
		schema => { pi => { type => 'float' } },
		input  => { pi => '3.14159' },
	});
	ok(abs($r->{pi} - 3.14159) < 1e-5, 'float coerced correctly');
};

subtest 'validate_strict: type number — non-numeric rejected' => sub {
	_vs_throws(
		{ schema => { x => { type => 'number' } }, input => { x => 'abc' } },
		qr/must be a number/,
		'croaks for non-numeric string'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: arrayref
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type arrayref — valid' => sub {
	my $r = _vs({
		schema => { tags => { type => 'arrayref' } },
		input  => { tags => ['a', 'b', 'c'] },
	});
	is_deeply($r->{tags}, ['a', 'b', 'c'], 'arrayref returned unchanged');
};

subtest 'validate_strict: type arrayref — scalar rejected' => sub {
	_vs_throws(
		{ schema => { tags => { type => 'arrayref' } }, input => { tags => 'foo' } },
		qr/must be an arrayref/,
		'croaks when scalar supplied instead of arrayref'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: hashref
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type hashref — valid' => sub {
	my $r = _vs({
		schema => { meta => { type => 'hashref' } },
		input  => { meta => { k => 'v' } },
	});
	is_deeply($r->{meta}, { k => 'v' }, 'hashref returned unchanged');
};

subtest 'validate_strict: type hashref — arrayref rejected' => sub {
	_vs_throws(
		{ schema => { meta => { type => 'hashref' } }, input => { meta => [] } },
		qr/must be an hashref/,
		'croaks when arrayref supplied instead of hashref'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: scalar
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type scalar — plain string accepted' => sub {
	my $r = _vs({
		schema => { x => { type => 'scalar' } },
		input  => { x => 'hello' },
	});
	is($r->{x}, 'hello', 'plain string returned unchanged');
};

subtest 'validate_strict: type scalar — integer accepted' => sub {
	my $r = _vs({
		schema => { x => { type => 'scalar' } },
		input  => { x => 42 },
	});
	is($r->{x}, 42, 'integer returned unchanged');
};

subtest 'validate_strict: type scalar — zero accepted' => sub {
	my $r = _vs({
		schema => { x => { type => 'scalar' } },
		input  => { x => 0 },
	});
	is($r->{x}, 0, 'zero (falsy scalar) accepted and returned unchanged');
};

subtest 'validate_strict: type scalar — empty string accepted' => sub {
	my $r = _vs({
		schema => { x => { type => 'scalar' } },
		input  => { x => '' },
	});
	is($r->{x}, '', 'empty string accepted and returned unchanged');
};

subtest 'validate_strict: type scalar — undef skips validation, _error not called' => sub {
	my @error_calls;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @error_calls, 1; die join('', @_[1 .. $#_]) . "\n" });
	lives_ok {
		_vs({
			schema => { x => { type => 'scalar', optional => 1 } },
			input  => { x => undef },
		});
	} 'undef value for optional scalar field does not croak';
	is(scalar @error_calls, 0, '_error not called when value is undef');
};

subtest 'validate_strict: type scalar — arrayref rejected, error names ARRAY type' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalar' } }, input => { x => [1, 2, 3] } });
	} qr/must be a scalar/, 'croaks when arrayref supplied';
	like($errors[0], qr/ARRAY/, 'error message identifies the ARRAY reference type');
};

subtest 'validate_strict: type scalar — hashref rejected, error names HASH type' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalar' } }, input => { x => { a => 1 } } });
	} qr/must be a scalar/, 'croaks when hashref supplied';
	like($errors[0], qr/HASH/, 'error message identifies the HASH reference type');
};

subtest 'validate_strict: type scalar — coderef rejected, error names CODE type' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalar' } }, input => { x => sub {} } });
	} qr/must be a scalar/, 'croaks when coderef supplied';
	like($errors[0], qr/CODE/, 'error message identifies the CODE reference type');
};

subtest 'validate_strict: type scalar — blessed object rejected, error names class' => sub {
	my $obj = PVS::Test::Searcher->new;
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalar' } }, input => { x => $obj } });
	} qr/must be a scalar/, 'croaks when blessed object supplied';
	like($errors[0], qr/PVS::Test::Searcher/, 'error message identifies the object class');
};

subtest 'validate_strict: type scalar — error_msg overrides default message' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalar', error_msg => 'not a plain value' } },
		      input  => { x => [] } });
	} qr/not a plain value/, 'custom error_msg used when reference supplied';
	is($errors[0], 'not a plain value', '_error called with only the custom message, no reference type appended');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: scalarref
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type scalarref — reference to string accepted' => sub {
	my $s = 'hello';
	my $r = _vs({
		schema => { x => { type => 'scalarref' } },
		input  => { x => \$s },
	});
	is($r->{x}, \$s, 'scalar reference returned unchanged');
};

subtest 'validate_strict: type scalarref — reference to integer accepted' => sub {
	my $n = 42;
	my $r = _vs({
		schema => { x => { type => 'scalarref' } },
		input  => { x => \$n },
	});
	is($r->{x}, \$n, 'reference to integer returned unchanged');
};

subtest 'validate_strict: type scalarref — undef skips validation, _error not called' => sub {
	my @error_calls;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @error_calls, 1; die join('', @_[1 .. $#_]) . "\n" });
	lives_ok {
		_vs({
			schema => { x => { type => 'scalarref', optional => 1 } },
			input  => { x => undef },
		});
	} 'undef value for optional scalarref field does not croak';
	is(scalar @error_calls, 0, '_error not called when value is undef');
};

subtest 'validate_strict: type scalarref — plain scalar rejected, error says "plain scalar"' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalarref' } }, input => { x => 'hello' } });
	} qr/must be a scalar reference/, 'croaks when plain scalar supplied';
	like($errors[0], qr/plain scalar/, 'error message identifies value as a plain scalar');
};

subtest 'validate_strict: type scalarref — arrayref rejected, error names ARRAY type' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalarref' } }, input => { x => [1, 2, 3] } });
	} qr/must be a scalar reference/, 'croaks when arrayref supplied';
	like($errors[0], qr/ARRAY/, 'error message identifies the ARRAY reference type');
};

subtest 'validate_strict: type scalarref — hashref rejected, error names HASH type' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalarref' } }, input => { x => { a => 1 } } });
	} qr/must be a scalar reference/, 'croaks when hashref supplied';
	like($errors[0], qr/HASH/, 'error message identifies the HASH reference type');
};

subtest 'validate_strict: type scalarref — coderef rejected, error names CODE type' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalarref' } }, input => { x => sub {} } });
	} qr/must be a scalar reference/, 'croaks when coderef supplied';
	like($errors[0], qr/CODE/, 'error message identifies the CODE reference type');
};

subtest 'validate_strict: type scalarref — blessed object rejected, error names class' => sub {
	my $obj = PVS::Test::Searcher->new;
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalarref' } }, input => { x => $obj } });
	} qr/must be a scalar reference/, 'croaks when blessed object supplied';
	like($errors[0], qr/PVS::Test::Searcher/, 'error message identifies the object class');
};

subtest 'validate_strict: type scalarref — error_msg overrides default message' => sub {
	my @errors;
	my $m_err = mock_scoped('Params::Validate::Strict', '_error',
		sub { push @errors, join('', @_[1 .. $#_]); die join('', @_[1 .. $#_]) . "\n" });
	throws_ok {
		_vs({ schema => { x => { type => 'scalarref', error_msg => 'give me a ref!' } },
		      input  => { x => 'oops' } });
	} qr/give me a ref!/, 'custom error_msg used when plain scalar supplied';
	is($errors[0], 'give me a ref!', '_error called with only the custom message');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: boolean
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type boolean — truthy strings' => sub {
	for my $val (qw(1 true yes on)) {
		my $r = _vs({
			schema => { flag => { type => 'boolean' } },
			input  => { flag => $val },
		});
		ok($r->{flag}, "'$val' accepted as truthy boolean");
	}
};

subtest 'validate_strict: type boolean — falsy strings' => sub {
	for my $val (qw(0 false no off)) {
		my $r = _vs({
			schema => { flag => { type => 'boolean' } },
			input  => { flag => $val },
		});
		ok(!$r->{flag}, "'$val' accepted as falsy boolean");
	}
};

subtest 'validate_strict: type boolean — unrecognised value rejected' => sub {
	_vs_throws(
		{ schema => { flag => { type => 'boolean' } }, input => { flag => 'maybe' } },
		qr/must be a boolean/,
		'croaks for unrecognised boolean string'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: coderef
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type coderef — valid' => sub {
	my $cb = sub { 1 };
	my $r  = _vs({
		schema => { handler => { type => 'coderef' } },
		input  => { handler => $cb },
	});
	is($r->{handler}, $cb, 'coderef returned unchanged');
};

subtest 'validate_strict: type coderef — scalar rejected' => sub {
	_vs_throws(
		{ schema => { handler => { type => 'coderef' } }, input => { handler => 'nope' } },
		qr/must be a coderef/,
		'croaks when scalar supplied instead of coderef'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — type: object
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: type object — blessed ref accepted' => sub {
	my $obj = PVS::Test::Searcher->new;
	my $r   = _vs({
		schema => { svc => { type => 'object' } },
		input  => { svc => $obj },
	});
	is($r->{svc}, $obj, 'blessed object returned unchanged');
};

subtest 'validate_strict: type object — unblessed hashref rejected' => sub {
	_vs_throws(
		{ schema => { svc => { type => 'object' } }, input => { svc => {} } },
		qr/must be an object/,
		'croaks when unblessed ref supplied'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — can
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: can (scalar) — object has method → ok' => sub {
	my $obj = PVS::Test::Searcher->new;
	lives_ok {
		_vs({
			schema => { svc => { type => 'object', can => 'search' } },
			input  => { svc => $obj },
		});
	} 'no error when object responds to the required method';
};

subtest 'validate_strict: can (scalar) — method absent → croaks' => sub {
	my $obj = PVS::Test::Searcher->new;	# has no 'delete' method
	_vs_throws(
		{ schema => { svc => { type => 'object', can => 'delete' } },
		  input  => { svc => $obj } },
		qr/must be an object that understands the delete method/,
		'croaks when required method is absent'
	);
};

subtest 'validate_strict: can (arrayref) — all methods present → ok' => sub {
	my $obj = PVS::Test::Searcher->new;	# has both search and index
	lives_ok {
		_vs({
			schema => { svc => { type => 'object', can => ['search', 'index'] } },
			input  => { svc => $obj },
		});
	} 'no error when object responds to all required methods';
};

subtest 'validate_strict: can — optional param absent → check skipped' => sub {
	lives_ok {
		_vs({
			schema => { svc => { type => 'object', can => 'search', optional => 1 } },
			input  => {},
		});
	} 'can check skipped for absent optional param';
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — isa
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: isa — correct class (via inheritance) → ok' => sub {
	my $obj = PVS::Test::Child->new;
	lives_ok {
		_vs({
			schema => { obj => { type => 'object', isa => 'PVS::Test::Base' } },
			input  => { obj => $obj },
		});
	} 'no error when isa check satisfied through inheritance';
};

subtest 'validate_strict: isa — wrong class → croaks' => sub {
	my $obj = PVS::Test::Searcher->new;
	_vs_throws(
		{ schema => { obj => { type => 'object', isa => 'PVS::Test::Base' } },
		  input  => { obj => $obj } },
		qr/must be a 'PVS::Test::Base' object/,
		'croaks when object fails isa check'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — min / max
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: min — string shorter than min → croaks' => sub {
	_vs_throws(
		{ schema => { s => { type => 'string', min => 5 } }, input => { s => 'hi' } },
		qr/too short/,
		'croaks when string length is below min'
	);
};

subtest 'validate_strict: min — string at min length → ok' => sub {
	my $r = _vs({
		schema => { s => { type => 'string', min => 3 } },
		input  => { s => 'hey' },
	});
	is($r->{s}, 'hey', 'string meeting min length accepted');
};

subtest 'validate_strict: max — string longer than max → croaks' => sub {
	_vs_throws(
		{ schema => { s => { type => 'string', max => 3 } }, input => { s => 'hello' } },
		qr/too long/,
		'croaks when string length exceeds max'
	);
};

subtest 'validate_strict: min — integer below min → croaks' => sub {
	_vs_throws(
		{ schema => { n => { type => 'integer', min => 10 } }, input => { n => 5 } },
		qr/must be at least 10/,
		'croaks when integer is below min'
	);
};

subtest 'validate_strict: max — integer above max → croaks' => sub {
	_vs_throws(
		{ schema => { n => { type => 'integer', max => 100 } }, input => { n => 200 } },
		qr/must be no more than 100/,
		'croaks when integer exceeds max'
	);
};

subtest 'validate_strict: min > max in schema → croaks on schema error' => sub {
	_vs_throws(
		{ schema => { n => { type => 'integer', min => 10, max => 5 } },
		  input  => { n => 7 } },
		qr/min must be <= max/,
		'croaks when schema itself has min > max'
	);
};

subtest 'validate_strict: min — arrayref shorter than min → croaks' => sub {
	_vs_throws(
		{ schema => { a => { type => 'arrayref', min => 3 } }, input => { a => [1] } },
		qr/must be at least length/,
		'croaks when arrayref has fewer elements than min'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — matches / nomatch
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: matches — pattern satisfied → ok' => sub {
	my $r = _vs({
		schema => { code => { type => 'string', matches => qr/^\d{4}$/ } },
		input  => { code => '1234' },
	});
	is($r->{code}, '1234', 'value satisfying matches pattern accepted');
};

subtest 'validate_strict: matches — pattern fails → croaks' => sub {
	_vs_throws(
		{ schema => { code => { type => 'string', matches => qr/^\d{4}$/ } },
		  input  => { code => 'abcd' } },
		qr/must match pattern/,
		'croaks when value does not satisfy matches pattern'
	);
};

subtest 'validate_strict: nomatch — value matches forbidden pattern → croaks' => sub {
	_vs_throws(
		{ schema => { s => { type => 'string', nomatch => qr/admin/ } },
		  input  => { s => 'admin_user' } },
		qr/must not match pattern/,
		'croaks when value matches the nomatch pattern'
	);
};

subtest 'validate_strict: nomatch — value does not match forbidden pattern → ok' => sub {
	my $r = _vs({
		schema => { s => { type => 'string', nomatch => qr/admin/ } },
		input  => { s => 'regular_user' },
	});
	is($r->{s}, 'regular_user', 'value not matching nomatch pattern accepted');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — memberof / notmemberof / case_sensitive
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: memberof — valid member' => sub {
	my $r = _vs({
		schema => { status => { type => 'string', memberof => [qw(draft published)] } },
		input  => { status => 'draft' },
	});
	is($r->{status}, 'draft', 'memberof: valid member accepted');
};

subtest 'validate_strict: enum — valid member' => sub {
	my $r = _vs({
		schema => { status => { type => 'string', enum => [qw(draft published)] } },
		input  => { status => 'draft' },
	});
	is($r->{status}, 'draft', 'enum: valid member accepted');
};

subtest 'validate_strict: values — valid member' => sub {
	my $r = _vs({
		schema => { status => { type => 'string', values => [qw(draft published)] } },
		input  => { status => 'draft' },
	});
	is($r->{status}, 'draft', 'values: valid member accepted');
};

subtest 'validate_strict: memberof — not a member → croaks' => sub {
	_vs_throws(
		{ schema => { status => { type => 'string', memberof => [qw(draft published)] } },
		  input  => { status => 'deleted' } },
		qr/must be one of/,
		'croaks when value not in memberof list'
	);
};

subtest 'validate_strict: memberof — case_sensitive => 0 accepts any case' => sub {
	my $r = _vs({
		schema => { code => {
			type => 'string', memberof => ['ABC'], case_sensitive => 0
		} },
		input => { code => 'abc' },
	});
	is($r->{code}, 'abc', 'case-insensitive memberof accepted, original case preserved');
};

subtest 'validate_strict: memberof — numeric equality for integer type' => sub {
	my $r = _vs({
		schema => { level => { type => 'integer', memberof => [1, 2, 3] } },
		input  => { level => '2' },
	});
	is($r->{level}, 2, 'integer memberof uses numeric equality after coercion');
};

subtest 'validate_strict: notmemberof — blacklisted value → croaks' => sub {
	_vs_throws(
		{ schema => { user => { type => 'string', notmemberof => [qw(admin root)] } },
		  input  => { user => 'admin' } },
		qr/must not be one of/,
		'croaks when value is in the notmemberof blacklist'
	);
};

subtest 'validate_strict: notmemberof — value not on blacklist → ok' => sub {
	my $r = _vs({
		schema => { user => { type => 'string', notmemberof => [qw(admin root)] } },
		input  => { user => 'alice' },
	});
	is($r->{user}, 'alice', 'value not on notmemberof blacklist accepted');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — element_type
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: element_type integer — all integers → ok' => sub {
	my $r = _vs({
		schema => { ids => { type => 'arrayref', element_type => 'integer' } },
		input  => { ids => [1, 2, 3] },
	});
	is_deeply($r->{ids}, [1, 2, 3], 'all-integer array accepted');
};

subtest 'validate_strict: element_type integer — non-integer element → croaks' => sub {
	_vs_throws(
		{ schema => { ids => { type => 'arrayref', element_type => 'integer' } },
		  input  => { ids => [1, 'two', 3] } },
		qr/can only contain integers/,
		'croaks when array contains a non-integer element'
	);
};

subtest 'validate_strict: element_type string — non-string element → croaks' => sub {
	_vs_throws(
		{ schema => { tags => { type => 'arrayref', element_type => 'string' } },
		  input  => { tags => ['ok', []] } },
		qr/can only contain strings/,
		'croaks when array contains a ref element'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — transform
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: transform applied before type validation' => sub {
	my $r = _vs({
		schema => { name => {
			type      => 'string',
			transform => sub { lc $_[0] },
		} },
		input => { name => 'ALICE' },
	});
	is($r->{name}, 'alice', 'transform lowercased the value before it was validated');
};

subtest 'validate_strict: transform result validated — bad result croaks' => sub {
	_vs_throws(
		{ schema => { n => {
			  type      => 'integer',
			  transform => sub { 'not_a_number' },	# makes it fail the integer check
		  } },
		  input => { n => 42 } },
		qr/must be an integer/,
		'croaks when transformed value fails type validation'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — optional / default
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: optional param absent → not in result' => sub {
	my $r = _vs({
		schema => {
			name    => { type => 'string' },
			surname => { type => 'string', optional => 1 },
		},
		input => { name => 'Alice' },
	});
	ok(!exists($r->{surname}), 'absent optional param not present in validated result');
};

subtest 'validate_strict: optional param present → validated and returned' => sub {
	my $r = _vs({
		schema => { role => { type => 'string', optional => 1 } },
		input  => { role => 'admin' },
	});
	is($r->{role}, 'admin', 'present optional param returned normally');
};

subtest 'validate_strict: default applied when optional param absent' => sub {
	my $r = _vs({
		schema => { role => { type => 'string', optional => 1, default => 'guest' } },
		input  => {},
	});
	is($r->{role}, 'guest', 'default value inserted for absent optional param');
};

subtest 'validate_strict: optional coderef evaluated with value and all args' => sub {
	my $r = _vs({
		schema => {
			payload  => { type => 'string', optional => 1 },
			required => {
				type     => 'string',
				optional => sub {
					my ($val, $args) = @_;
					return defined($args->{payload}) ? 1 : 0;
				},
			},
		},
		input => { payload => 'data' },	# makes 'required' optional
	});
	ok(!exists($r->{required}), 'coderef optional: param treated as optional when coderef returns true');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — callback
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: callback returning true → ok' => sub {
	my $r = _vs({
		schema => { n => {
			type     => 'integer',
			callback => sub { $_[0] % 2 == 0 },	# must be even
		} },
		input => { n => 4 },
	});
	is($r->{n}, 4, 'value passing callback accepted');
};

subtest 'validate_strict: callback returning false → croaks' => sub {
	_vs_throws(
		{ schema => { n => {
			  type     => 'integer',
			  callback => sub { $_[0] % 2 == 0 },
		  } },
		  input => { n => 3 } },
		qr/failed custom validation/,
		'croaks when callback returns false'
	);
};

subtest 'validate_strict: callback receives value, all args, and schema' => sub {
	my (@cb_args);
	_vs({
		schema => { a => {
			type     => 'integer',
			callback => sub { @cb_args = @_; 1 },
		} },
		input => { a => 7 },
	});
	is($cb_args[0], 7,          'callback receives the parameter value as first arg');
	is(ref($cb_args[1]), 'HASH', 'callback receives all args hashref as second arg');
	is(ref($cb_args[2]), 'HASH', 'callback receives the schema hashref as third arg');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — validate / validator
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: validate coderef returning undef → ok' => sub {
	lives_ok {
		_vs({
			schema => { pw => {
				type     => 'string',
				validate => sub { undef },
			} },
			input => { pw => 'secret' },
		});
	} 'no error when validate coderef returns undef';
};

subtest 'validate_strict: validate coderef returning error string → croaks' => sub {
	_vs_throws(
		{ schema => { pw => {
			  type     => 'string',
			  validate => sub { 'Too weak' },
		  } },
		  input => { pw => '123' } },
		qr/Too weak/,
		'croaks with message returned by validate coderef'
	);
};

subtest 'validate_strict: validator is a synonym of validate' => sub {
	lives_ok {
		_vs({
			schema => { x => {
				type      => 'string',
				validator => sub { undef },
			} },
			input => { x => 'ok' },
		});
	} '"validator" key accepted as synonym of "validate"';
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — cross_validation
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: cross_validation passes → ok' => sub {
	lives_ok {
		_vs({
			schema => {
				password => { type => 'string' },
				confirm  => { type => 'string' },
			},
			input => { password => 'abc', confirm => 'abc' },
			cross_validation => {
				match => sub { $_[0]{password} eq $_[0]{confirm} ? undef : 'No match' },
			},
		});
	} 'no error when cross_validation coderef returns undef';
};

subtest 'validate_strict: cross_validation returns error → croaks' => sub {
	_vs_throws(
		{
			schema => {
				password => { type => 'string' },
				confirm  => { type => 'string' },
			},
			input => { password => 'abc', confirm => 'xyz' },
			cross_validation => {
				match => sub { $_[0]{password} eq $_[0]{confirm} ? undef : 'Passwords do not match' },
			},
		},
		qr/Passwords do not match/,
		'croaks with message returned by failing cross_validation coderef'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — union type  (type => ['a', 'b'])
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: union type — first candidate matches' => sub {
	my $r = _vs({
		schema => { x => { type => ['string', 'arrayref'] } },
		input  => { x => 'hello' },
	});
	is($r->{x}, 'hello', 'string branch of union type accepted');
};

subtest 'validate_strict: union type — second candidate matches' => sub {
	my $r = _vs({
		schema => { x => { type => ['string', 'arrayref'] } },
		input  => { x => ['a', 'b'] },
	});
	is_deeply($r->{x}, ['a', 'b'], 'arrayref branch of union type accepted');
};

subtest 'validate_strict: union type — coercion from winning branch propagated' => sub {
	my $r = _vs({
		schema => { n => { type => ['integer', 'string'] } },
		input  => { n => '42' },
	});
	is($r->{n}, 42, 'integer coercion from winning branch returned to caller');
};

subtest 'validate_strict: union type — no branch matches → croaks' => sub {
	_vs_throws(
		{ schema => { x => { type => ['integer', 'arrayref'] } },
		  input  => { x => { k => 1 } } },
		qr/must be one of/,
		'croaks when no branch of the union type matches'
	);
};

subtest 'validate_strict: union type — empty list → croaks' => sub {
	_vs_throws(
		{ schema => { x => { type => [] } }, input => { x => 'foo' } },
		qr/union type list must not be empty/,
		'croaks for empty union type list'
	);
};

subtest 'validate_strict: union type — optional absent → no croak' => sub {
	lives_ok {
		_vs({
			schema => { x => { type => ['string', 'integer'], optional => 1 } },
			input  => {},
		});
	} 'absent optional union-type param does not croak';
};

subtest 'validate_strict: union type — shared constraints applied per branch' => sub {
	# min => 5 applies to both branches; a 2-char string fails, a non-arrayref
	# also fails, so the overall union fails → must be one of
	_vs_throws(
		{ schema => { x => { type => ['string', 'arrayref'], min => 5 } },
		  input  => { x => 'hi' } },
		qr/must be one of/,
		'union-level error when value fails all branches including shared constraint'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — explicit array-of-rules  (rules as arrayref of hashes)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: array-of-rules — matching branch accepted' => sub {
	my $r = _vs({
		schema => { id => [
			{ type => 'string',  min => 3 },
			{ type => 'integer', min => 1 },
		] },
		input => { id => 42 },
	});
	is($r->{id}, 42, 'integer branch matched and value accepted');
};

subtest 'validate_strict: array-of-rules — coercion from matching branch returned' => sub {
	my $r = _vs({
		schema => { n => [
			{ type => 'integer', min => 1 },
			{ type => 'string' },
		] },
		input => { n => '7' },
	});
	is($r->{n}, 7, 'integer coercion propagated from array-of-rules branch');
};

subtest 'validate_strict: array-of-rules — no branch matches → croaks' => sub {
	_vs_throws(
		{ schema => { x => [
			  { type => 'integer' },
			  { type => 'arrayref' },
		  ] },
		  input => { x => 'neither' } },
		qr/must be one of integer, arrayref|must be one of arrayref, integer/,
		'croaks listing types when no branch matches'
	);
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — positional arguments
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: positional args → returns arrayref in order' => sub {
	my $r = _vs({
		schema => {
			first  => { type => 'string',  position => 0 },
			second => { type => 'integer', position => 1 },
		},
		input => ['hello', '7'],
	});
	is(ref($r),  'ARRAY',  'positional mode returns an arrayref');
	is($r->[0], 'hello',  'first positional arg correct');
	is($r->[1],  7,        'second positional arg coerced to integer');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — nested schemas
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: nested hashref schema validated recursively' => sub {
	my $r = _vs({
		schema => {
			user => {
				type   => 'hashref',
				schema => {
					name => { type => 'string' },
					age  => { type => 'integer', min => 0 },
				},
			},
		},
		input => { user => { name => 'Alice', age => '30' } },
	});
	is($r->{user}{name}, 'Alice', 'nested string field returned');
	is($r->{user}{age},  30,      'nested integer coerced');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate_strict — relationships enforced end-to-end
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: mutually_exclusive relationship enforced' => sub {
	_vs_throws(
		{
			schema => {
				file    => { type => 'string', optional => 1 },
				content => { type => 'string', optional => 1 },
			},
			input => { file => 'x.txt', content => 'raw' },
			relationships => [
				{ type => 'mutually_exclusive', params => ['file', 'content'] }
			],
		},
		qr/Cannot specify both/,
		'mutually_exclusive relationship enforced via validate_strict'
	);
};

subtest 'validate_strict: dependency relationship enforced' => sub {
	_vs_throws(
		{
			schema => {
				port => { type => 'integer', optional => 1 },
				host => { type => 'string',  optional => 1 },
			},
			input => { port => 8080 },
			relationships => [
				{ type => 'dependency', param => 'port', requires => 'host' }
			],
		},
		qr/port requires host/,
		'dependency relationship enforced via validate_strict'
	);
};

done_testing;
