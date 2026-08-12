#!/usr/bin/env perl

# Path-coverage tests for Params::Validate::Strict.
#
# Covers execution paths NOT exercised by the existing test suite.
# One subtest per unique CFG branch; each proves a specific guard fires
# at the earliest possible point.

use strict;
use warnings;
use Test::Most tests => 20;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

Readonly my %SCHEMAS => (
	one_string => { name => { type => 'string' } },
);

# ---------------------------------------------------------------------------
# Path group 1: _schema_from_arrayref internal guards
#
# The arrayref-to-hashref normaliser runs before any per-field logic.
# All three error paths must fire before validate_strict processes values.
# ---------------------------------------------------------------------------

subtest '_schema_from_arrayref: element is not a hashref → croaks early' => sub {
	throws_ok {
		validate_strict(
			schema => ['not_a_hashref'],
			input  => {},
		);
	} qr/each arrayref schema element must be a hashref/,
	'non-hashref element in arrayref schema detected before validation';
};

subtest '_schema_from_arrayref: element missing name key → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => [ { type => 'string' } ],    # no 'name' key
			input  => {},
		);
	} qr/arrayref schema element must have a 'name' key/,
	'arrayref schema element without name key caught';
};

subtest '_schema_from_arrayref: duplicate name key → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => [
				{ name => 'x', type => 'string' },
				{ name => 'x', type => 'integer' },    # duplicate
			],
			input  => { x => 'hello' },
		);
	} qr/duplicate parameter 'x'/,
	'duplicate name in arrayref schema caught';
};

# ---------------------------------------------------------------------------
# Path group 2: validate / validator rule with non-CODE value
#
# Premise: the rule dispatch checks ref($rule_value) eq 'CODE'.
# When the value is a string the else-branch fires immediately.
# ---------------------------------------------------------------------------

subtest "validate rule: non-CODE value → croaks \"only supports coderef\"" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', validate => 'not_a_sub' } },
			input  => { x => 'hello' },
		);
	} qr/only supports coderef/,
	'validate rule with string value triggers the non-CODE error';
};

subtest "validator rule: non-CODE value → same error path" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', validator => 42 } },
			input  => { x => 'hello' },
		);
	} qr/only supports coderef/,
	'"validator" synonym also triggers non-CODE error';
};

# ---------------------------------------------------------------------------
# Path group 3: unknown relationship type
#
# The _validate_relationships dispatcher has an else branch for unrecognised
# types; it must fire before any per-field validation side effects occur.
# ---------------------------------------------------------------------------

subtest 'unknown relationship type → croaks with type name' => sub {
	throws_ok {
		validate_strict(
			schema        => { a => { type => 'string' } },
			input         => { a => 'ok' },
			relationships => [ { type => 'nonexistent_rel' } ],
		);
	} qr/Unknown relationship type nonexistent_rel/,
	'unrecognised relationship type fires the catch-all error';
};

# ---------------------------------------------------------------------------
# Path group 4: position rule value guards
#
# The position rule handler checks its own value before using it.
# Both the alpha-character and negative-integer guards must be reachable.
# ---------------------------------------------------------------------------

subtest 'position rule: value containing \\D → croaks "must be an integer"' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', position => 'abc' } },
			input  => ['hello'],
		);
	} qr/must be a positive integer/,
	'non-numeric position value fires the \\D guard';
};

# NOTE: the position < 0 guard (line after the /\D/ check) is dead code:
# any negative integer stringifies with a leading '-' which already matches
# /\D/, so the earlier guard always fires first.  See TODO annotation in the
# module.  No test is written for that path because it is unreachable.

# ---------------------------------------------------------------------------
# Path group 5: duplicate position in return loop
#
# When two schema keys claim the same position the return-loop detects the
# collision.  This guard lives in the positional-return section, after all
# per-field validation has succeeded.
# ---------------------------------------------------------------------------

subtest 'two keys share a position → croaks "appears twice"' => sub {
	# Both keys must pass their own type checks so that the return loop (not
	# a type guard) is the first thing to see the collision.  Use the same
	# type so both accept the same value at position 0.
	throws_ok {
		validate_strict(
			schema => {
				a => { type => 'string', position => 0 },
				b => { type => 'string', position => 0 },    # collision
			},
			input => ['hello'],
		);
	} qr/position 0 appears twice/,
	'duplicate position detected in return loop';
};

# ---------------------------------------------------------------------------
# Path group 6: cross_validation with a non-CODE validator
#
# The cross_validation block checks ref($validator) eq 'CODE' before calling.
# The else-branch (non-CODE) must be reachable.
# ---------------------------------------------------------------------------

subtest 'cross_validation: non-CODE validator → croaks' => sub {
	throws_ok {
		validate_strict(
			schema           => { x => { type => 'string' } },
			input            => { x => 'ok' },
			cross_validation => { check_x => 'not_a_sub' },
		);
	} qr/cross_validation.*is not a code snippet/i,
	'non-CODE cross_validation entry triggers the type guard';
};

# ---------------------------------------------------------------------------
# Path group 7: nested arrayref schema — field-schema form
#
# When the per-element schema hash has no top-level 'type' key the
# $is_field_schema flag is set and each array element is validated as a
# named-parameter hashref against that schema directly.
#
# This path is DISTINCT from the rule-hash form (which has type => '...').
# ---------------------------------------------------------------------------

subtest 'nested arrayref schema: field-schema form — valid elements pass' => sub {
	my $r = validate_strict(
		schema => {
			orders => {
				type   => 'arrayref',
				schema => {
					# No top-level 'type' key → is_field_schema = true
					item => { type => 'string'  },
					qty  => { type => 'integer' },
				},
			},
		},
		input => { orders => [
			{ item => 'book', qty => 1 },
			{ item => 'pen',  qty => 5 },
		] },
	);
	ok(defined($r), 'field-schema arrayref path: valid elements accepted');
	is(scalar @{$r->{orders}}, 2, 'both elements returned');
};

subtest 'nested arrayref schema: field-schema form — invalid element rejected' => sub {
	throws_ok {
		validate_strict(
			schema => {
				orders => {
					type   => 'arrayref',
					schema => {
						item => { type => 'string'  },
						qty  => { type => 'integer' },
					},
				},
			},
			input => { orders => [
				{ item => 'book', qty => 1 },
				{ item => 'pen',  qty => 'bad_qty' },    # non-integer
			] },
		);
	} qr/must be an integer/,
	'field-schema arrayref path: invalid inner field triggers type error';
};

# ---------------------------------------------------------------------------
# Path group 8: element_type with unsupported type
#
# The element_type dispatch has a final else that fires for types beyond
# string / integer / number / float.  The error message begins "BUG:".
# ---------------------------------------------------------------------------

subtest 'element_type with unsupported type → croaks BUG message' => sub {
	throws_ok {
		validate_strict(
			schema => { ids => { type => 'arrayref', element_type => 'hashref' } },
			input  => { ids => [{}] },
		);
	} qr/BUG: Add hashref to element_type list/,
	'unsupported element_type fires the fallback BUG error';
};

# ---------------------------------------------------------------------------
# Path group 9: _validate_required_group guard — fewer than 2 params
#
# The function returns immediately when @params < 2.  This guard prevents a
# no-op call from accidentally triggering the "must specify at least one" error.
# ---------------------------------------------------------------------------

subtest 'required_group with only one param listed → guard fires, no error' => sub {
	lives_ok {
		validate_strict(
			schema        => { a => { type => 'string', optional => 1 } },
			input         => {},
			relationships => [ { type => 'required_group', params => ['a'] } ],
		);
	} 'required_group with < 2 params returns silently';
};

# ---------------------------------------------------------------------------
# Path group 10: _validate_value_constraint — unrecognised operator
#
# The operator dispatch covers ==, !=, <, <=, >, >=.
# An unrecognised operator leaves $valid=0, causing the "must be" error.
# ---------------------------------------------------------------------------

subtest '_validate_value_constraint: unrecognised operator → always fails' => sub {
	throws_ok {
		validate_strict(
			schema        => {
				ssl  => { type => 'boolean', optional => 1 },
				port => { type => 'integer' },
			},
			input         => { ssl => 1, port => 443 },
			relationships => [ {
				type     => 'value_constraint',
				if       => 'ssl',
				then     => 'port',
				operator => '???',    # not a real operator
				value    => 443,
			} ],
		);
	} qr/must be/,
	'unrecognised operator leaves valid=0, triggers the error path';
};

# ---------------------------------------------------------------------------
# Path group 11: _validate_conditional_requirement — missing 'if' param
#
# The guard `my $if_param = $rel->{if} or return` exits immediately when
# the 'if' key is absent.  Absent 'then_required' has the same effect.
# ---------------------------------------------------------------------------

subtest '_validate_conditional_requirement: missing if → silently returns' => sub {
	lives_ok {
		validate_strict(
			schema        => { a => { type => 'string' } },
			input         => { a => 'ok' },
			relationships => [ {
				type         => 'conditional_requirement',
				# no 'if' key
				then_required => 'a',
			} ],
		);
	} 'conditional_requirement with no if key returns without error';
};

subtest '_validate_conditional_requirement: missing then_required → silently returns' => sub {
	lives_ok {
		validate_strict(
			schema        => { a => { type => 'string', optional => 1 } },
			input         => { a => 'ok' },
			relationships => [ {
				type => 'conditional_requirement',
				if   => 'a',
				# no 'then_required' key
			} ],
		);
	} 'conditional_requirement with no then_required key returns without error';
};

# ---------------------------------------------------------------------------
# Path group 12: _validate_dependency guards
# ---------------------------------------------------------------------------

subtest '_validate_dependency: missing param key → silently returns' => sub {
	lives_ok {
		validate_strict(
			schema        => { a => { type => 'string' } },
			input         => { a => 'ok' },
			relationships => [ {
				type     => 'dependency',
				# no 'param' key
				requires => 'a',
			} ],
		);
	} 'dependency with no param key returns without error';
};

# ---------------------------------------------------------------------------
# Path group 13: _validate_value_conditional — if_param != equals → skip
#
# When the if_param value does not equal 'equals', the then_required check
# is never performed.  This is the "condition is false" path.
# ---------------------------------------------------------------------------

subtest '_validate_value_conditional: if_param != equals → then_required not enforced' => sub {
	lives_ok {
		validate_strict(
			schema        => {
				status   => { type => 'string'            },
				reason   => { type => 'string', optional => 1 },
			},
			input         => { status => 'active' },    # not 'deleted'
			relationships => [ {
				type          => 'value_conditional',
				if            => 'status',
				equals        => 'deleted',
				then_required => 'reason',
			} ],
		);
	} 'value_conditional: condition false, then_required not checked';
};

# NOTE: the "missing position value" error fires only when the detection loop
# sees a key WITH position before one WITHOUT.  Perl hash iteration order is
# non-deterministic (randomised since 5.18), so a two-key schema cannot
# reliably trigger the error.  The guard is covered by t/positional.t.

# ---------------------------------------------------------------------------
# Path group 14: positional args → return is arrayref (not hashref)
#
# When every schema key has a 'position', the return path branches to build
# and return \@rc instead of \%validated_args.
# ---------------------------------------------------------------------------

subtest 'all-positional schema → return is arrayref, not hashref' => sub {
	my $r = validate_strict(
		schema => {
			name => { type => 'string',  position => 0 },
			age  => { type => 'integer', position => 1 },
		},
		input => ['Alice', 30],
	);
	ok(ref($r) eq 'ARRAY', 'positional schema returns arrayref');
	is($r->[0], 'Alice', 'position 0 = name');
	is($r->[1], 30,      'position 1 = age (coerced to integer)');
};

# ---------------------------------------------------------------------------
# Path group 15: args is undef but args key was supplied
#
# validate_strict replaces undef args with an empty hashref when the 'args'
# key exists in the call, preventing the "must be a hash or array reference" error.
# ---------------------------------------------------------------------------

subtest 'args => undef with args key present → treated as empty hashref' => sub {
	lives_ok {
		validate_strict(
			schema => { x => { type => 'string', optional => 1 } },
			args   => undef,
		);
	} 'args => undef with key present does not croak';
};

done_testing();
