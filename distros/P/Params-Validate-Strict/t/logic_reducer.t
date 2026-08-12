#!/usr/bin/env perl

# Equivalence-partition tests derived from the logic-reducer pass.
#
# Each block asserts one logical invariant derived from the module's design.
# Tests are grouped by the premise being proven, not by feature.

use strict;
use warnings;
use Test::Most tests => 23;
use Params::Validate::Strict qw(validate_strict);

# ---------------------------------------------------------------------------
# Invariant 1: type fires before min/max (type-first dispatch ordering).
#
# Premise 1: validate_strict processes the 'type' rule before all others.
# Premise 2: a non-array scalar with type=>arrayref must fail the TYPE check.
# Conclusion: the error comes from type validation, not from min's internal ref check.
# ---------------------------------------------------------------------------
{
	my $schema = { items => { type => 'arrayref', min => 3 } };

	throws_ok {
		validate_strict(schema => $schema, input => { items => 'not_an_array' });
	} qr/must be an arrayref/i, 'type fires first: non-array with min constraint fails type check';

	throws_ok {
		validate_strict(schema => $schema, input => { items => { a => 1 } });
	} qr/must be an arrayref/i, 'type fires first: hashref with arrayref+min constraint fails type check';
}

# ---------------------------------------------------------------------------
# Invariant 2: min boundary on arrayref (element count).
#
# Partition: count < min (fail), count == min (pass), count > min (pass).
# ---------------------------------------------------------------------------
{
	my $schema = { tags => { type => 'arrayref', min => 3 } };

	throws_ok {
		validate_strict(schema => $schema, input => { tags => [1, 2] });
	} qr/must have at least 3 member/i, 'min arrayref: 2 < 3 fails';

	my $r = validate_strict(schema => $schema, input => { tags => [1, 2, 3] });
	ok($r, 'min arrayref: 3 == 3 passes (exact boundary)');

	$r = validate_strict(schema => $schema, input => { tags => [1, 2, 3, 4] });
	ok($r, 'min arrayref: 4 > 3 passes');
}

# ---------------------------------------------------------------------------
# Invariant 3: max boundary on arrayref (element count).
#
# Partition: count > max (fail), count == max (pass), count < max (pass).
# ---------------------------------------------------------------------------
{
	my $schema = { tags => { type => 'arrayref', max => 3 } };

	throws_ok {
		validate_strict(schema => $schema, input => { tags => [1, 2, 3, 4] });
	} qr/must contain no more than 3 item/i, 'max arrayref: 4 > 3 fails';

	my $r = validate_strict(schema => $schema, input => { tags => [1, 2, 3] });
	ok($r, 'max arrayref: 3 == 3 passes (exact boundary)');

	$r = validate_strict(schema => $schema, input => { tags => [1, 2] });
	ok($r, 'max arrayref: 2 < 3 passes');
}

# ---------------------------------------------------------------------------
# Invariant 4: min boundary on hashref (key count).
#
# Partition: key_count < min (fail), key_count == min (pass).
# ---------------------------------------------------------------------------
{
	my $schema = { config => { type => 'hashref', min => 2 } };

	throws_ok {
		validate_strict(schema => $schema, input => { config => { a => 1 } });
	} qr/must contain at least 2 key/i, 'min hashref: 1 key < 2 fails';

	my $r = validate_strict(schema => $schema, input => { config => { a => 1, b => 2 } });
	ok($r, 'min hashref: 2 keys == 2 passes (exact boundary)');
}

# ---------------------------------------------------------------------------
# Invariant 5: max boundary on hashref (key count).
#
# Partition: key_count > max (fail), key_count == max (pass).
# ---------------------------------------------------------------------------
{
	my $schema = { config => { type => 'hashref', max => 2 } };

	throws_ok {
		validate_strict(schema => $schema, input => { config => { a => 1, b => 2, c => 3 } });
	} qr/must contain no more than 2 key/i, 'max hashref: 3 keys > 2 fails';

	my $r = validate_strict(schema => $schema, input => { config => { a => 1, b => 2 } });
	ok($r, 'max hashref: 2 keys == 2 passes (exact boundary)');
}

# ---------------------------------------------------------------------------
# Invariant 6: void type accepts only undef; any defined value is rejected.
#
# Partition: undef (pass), 0 (fail), '' (fail), '0' (fail).
# ---------------------------------------------------------------------------
{
	my $schema = { result => { type => 'void' } };

	my $r = validate_strict(schema => $schema, input => { result => undef });
	ok($r, 'void: undef passes');

	throws_ok {
		validate_strict(schema => $schema, input => { result => 0 });
	} qr/void/i, 'void: 0 fails';

	throws_ok {
		validate_strict(schema => $schema, input => { result => '' });
	} qr/void/i, 'void: empty string fails';
}

# ---------------------------------------------------------------------------
# Invariant 7: semantic unix_timestamp boundary at 0 and 2_147_483_647.
#
# Partition: -1 (fail), 0 (pass), 2_147_483_647 (pass), 2_147_483_648 (fail).
# ---------------------------------------------------------------------------
{
	my $schema = { ts => { type => 'integer', semantic => 'unix_timestamp' } };

	throws_ok {
		validate_strict(schema => $schema, input => { ts => -1 });
	} qr/Unix timestamp/, 'unix_timestamp: -1 fails (negative)';

	my $r = validate_strict(schema => $schema, input => { ts => 0 });
	ok($r, 'unix_timestamp: 0 passes (lower boundary)');

	$r = validate_strict(schema => $schema, input => { ts => 2_147_483_647 });
	ok($r, 'unix_timestamp: 2147483647 passes (upper boundary)');

	throws_ok {
		validate_strict(schema => $schema, input => { ts => 2_147_483_648 });
	} qr/Unix timestamp/, 'unix_timestamp: 2147483648 fails (above upper boundary)';
}

# ---------------------------------------------------------------------------
# Invariant 8: custom type minimum key (typo fix — was 'minumum', now 'minimum').
#
# Premise: a custom type using 'minimum' (not 'min') as its lower bound key
#		  must have that constraint enforced after the fix.
# Partition: value < minimum (fail), value == minimum (pass).
# ---------------------------------------------------------------------------
{
	my $custom_types = {
		positive_integer => {
			type	=> 'integer',
			minimum => 1,
		}
	};
	my $schema = { count => { type => 'positive_integer' } };

	throws_ok {
		validate_strict(
			schema	   => $schema,
			input		=> { count => 0 },
			custom_types => $custom_types,
		);
	} qr/must be at least 1|positive/i, 'custom type minimum key: 0 < 1 fails';

	my $r = validate_strict(
		schema	   => $schema,
		input		=> { count => 1 },
		custom_types => $custom_types,
	);
	ok($r, 'custom type minimum key: 1 == 1 passes (exact boundary)');
}

# ---------------------------------------------------------------------------
# Invariant 9: optional arrayref with min — absent value skips min check.
#
# Premise 1: optional rule makes absence valid.
# Premise 2: min rule must not fire when the parameter is absent.
# Conclusion: omitting an optional arrayref with min constraint is not an error.
# ---------------------------------------------------------------------------
{
	my $schema = { files => { type => 'arrayref', optional => 1, min => 3 } };

	my $r = validate_strict(schema => $schema, input => {});
	ok($r, 'optional arrayref with min: absent value skips min check');

	throws_ok {
		validate_strict(schema => $schema, input => { files => [1, 2] });
	} qr/must have at least 3 member/i, 'optional arrayref with min: present but short fails';
}

done_testing();
