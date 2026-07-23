#!/usr/bin/env perl

# Black-box unit tests for the public API of Params::Validate::Strict.
# Each subtest drives validate_strict through its documented interface only.
# Test::Mockingbird (RAII guards) is used to mock the non-core logger and
# Unicode::GCString dependencies.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock_scoped);

use Params::Validate::Strict qw(validate_strict);

# ── Test support classes ──────────────────────────────────────────────────────

{ package Unit::Searcher; sub new { bless {}, shift } sub search { 1 } sub list { [] } }
{ package Unit::Base;     sub new { bless {}, shift } }
{ package Unit::Child;    our @ISA = ('Unit::Base'); sub new { bless {}, shift } }

# Logger stub — methods must exist so mock_scoped can replace them.
{
	package MockLogger;
	sub new   { bless {}, shift }
	sub error { }		# stub
	sub warn  { }		# stub
}

# Lightweight Unicode::GCString replacement used in the non-ASCII min/max test.
# A plain length() sub avoids the ($) prototype the real module carries.
{
	package Unit::GCString;
	sub new    { bless {}, shift }
	sub length { 3 }	# fixed at 3 grapheme clusters for that one test
}

# ══════════════════════════════════════════════════════════════════════════════
# Return-value contract
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate_strict: valid input returns a hashref' => sub {
	my $r = validate_strict(
		schema => { name => { type => 'string' } },
		input  => { name => 'Alice' },
	);
	is(ref($r), 'HASH', 'return value is a hashref');
};

subtest 'validate_strict: returned hash contains only schema keys' => sub {
	my $r = validate_strict(
		schema => { a => { type => 'string' }, b => { type => 'integer' } },
		input  => { a => 'x', b => '1' },
	);
	ok(exists $r->{a}, 'schema key a present');
	ok(exists $r->{b}, 'schema key b present');
	is(scalar keys %$r, 2, 'no extra keys');
};

subtest 'validate_strict: undef schema passes input through unchanged' => sub {
	my $input = { anything => 'goes' };
	my $r = validate_strict(schema => undef, input => $input);
	is_deeply($r, $input, 'returns input hashref as-is when no schema');
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: string
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type string: valid scalar accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string' } },
		input  => { s => 'hello' },
	);
	is($r->{s}, 'hello', 'string value returned unchanged');
};

subtest 'type string: reference value rejected' => sub {
	throws_ok {
		validate_strict(schema => { s => { type => 'string' } }, input => { s => [] })
	} qr/must be a string/, 'croaks when arrayref passed as string';
};

subtest 'type str: synonym accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'str' } },
		input  => { s => 'ok' },
	);
	is($r->{s}, 'ok', 'str synonym works');
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: integer
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type integer: string coerced to integer' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer' } },
		input  => { n => '42' },
	);
	is($r->{n}, 42, 'value is 42');
	ok($r->{n} == 42, 'numeric equality holds after coercion');
};

subtest 'type integer: negative integer accepted' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer' } },
		input  => { n => '-7' },
	);
	is($r->{n}, -7, 'negative integer coerced correctly');
};

subtest 'type integer: float string rejected' => sub {
	throws_ok {
		validate_strict(schema => { n => { type => 'integer' } }, input => { n => '3.14' })
	} qr/must be an integer/, 'croaks for floating-point string';
};

subtest 'type integer: alphabetic string rejected' => sub {
	throws_ok {
		validate_strict(schema => { n => { type => 'integer' } }, input => { n => 'foo' })
	} qr/must be an integer/, 'croaks for non-numeric string';
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: number / float
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type number: string coerced to number' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'number' } },
		input  => { x => '2.718' },
	);
	ok(abs($r->{x} - 2.718) < 1e-5, 'float coerced correctly');
};

subtest 'type float: synonym for number' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'float' } },
		input  => { x => '1.5' },
	);
	ok($r->{x} == 1.5, 'float synonym accepted and coerced');
};

subtest 'type number: non-numeric string rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'number' } }, input => { x => 'nope' })
	} qr/must be a number/, 'croaks for non-numeric value';
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: boolean
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type boolean: truthy strings accepted' => sub {
	for my $v (qw(1 true yes on)) {
		my $r = validate_strict(
			schema => { b => { type => 'boolean' } },
			input  => { b => $v },
		);
		ok($r->{b}, qq('$v' is truthy));
	}
};

subtest 'type boolean: falsy strings accepted' => sub {
	for my $v (qw(0 false no off)) {
		my $r = validate_strict(
			schema => { b => { type => 'boolean' } },
			input  => { b => $v },
		);
		ok(!$r->{b}, qq('$v' is falsy));
	}
};

subtest 'type boolean: invalid value rejected' => sub {
	throws_ok {
		validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 'maybe' })
	} qr/must be a boolean/, 'croaks for unrecognised boolean string';
};

subtest 'type bool: synonym accepted' => sub {
	my $r = validate_strict(
		schema => { b => { type => 'bool' } },
		input  => { b => 'true' },
	);
	ok($r->{b}, 'bool synonym works');
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: arrayref
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type arrayref: arrayref accepted' => sub {
	my $r = validate_strict(
		schema => { a => { type => 'arrayref' } },
		input  => { a => [1, 2, 3] },
	);
	is_deeply($r->{a}, [1, 2, 3], 'arrayref returned unchanged');
};

subtest 'type arrayref: scalar rejected' => sub {
	throws_ok {
		validate_strict(schema => { a => { type => 'arrayref' } }, input => { a => 'nope' })
	} qr/must be an arrayref/, 'croaks when scalar passed as arrayref';
};

subtest 'type arrayref: hashref rejected' => sub {
	throws_ok {
		validate_strict(schema => { a => { type => 'arrayref' } }, input => { a => {} })
	} qr/must be an arrayref/, 'croaks when hashref passed as arrayref';
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: hashref
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type hashref: hashref accepted' => sub {
	my $r = validate_strict(
		schema => { h => { type => 'hashref' } },
		input  => { h => { k => 'v' } },
	);
	is_deeply($r->{h}, { k => 'v' }, 'hashref returned unchanged');
};

subtest 'type hashref: arrayref rejected' => sub {
	throws_ok {
		validate_strict(schema => { h => { type => 'hashref' } }, input => { h => [] })
	} qr/must be an hashref/, 'croaks when arrayref passed as hashref';
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: scalar
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type scalar: plain string accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar' } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'string returned unchanged');
};

subtest 'type scalar: integer value accepted unchanged' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar' } },
		input  => { x => 42 },
	);
	is($r->{x}, 42, 'integer returned unchanged — scalar type does not coerce');
};

subtest 'type scalar: zero accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar' } },
		input  => { x => 0 },
	);
	is($r->{x}, 0, 'zero (falsy scalar) accepted');
};

subtest 'type scalar: empty string accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar' } },
		input  => { x => '' },
	);
	is($r->{x}, '', 'empty string accepted');
};

subtest 'type scalar: arrayref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => [] })
	} qr/must be a scalar/, 'croaks when arrayref passed as scalar';
};

subtest 'type scalar: hashref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => {} })
	} qr/must be a scalar/, 'croaks when hashref passed as scalar';
};

subtest 'type scalar: coderef rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => sub {} })
	} qr/must be a scalar/, 'croaks when coderef passed as scalar';
};

subtest 'type scalar: blessed object rejected' => sub {
	my $obj = Unit::Searcher->new;
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => $obj })
	} qr/must be a scalar/, 'croaks when blessed object passed as scalar';
};

subtest 'type scalar: logger receives error when reference supplied' => sub {
	my $logger = MockLogger->new;
	my @logged;
	my $m = mock_scoped('MockLogger', 'error',
		sub { push @logged, join('', @_[1 .. $#_]) });
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar' } },
			input  => { x => [] },
			logger => $logger,
		)
	} qr/must be a scalar/, 'still croaks with logger present';
	ok(scalar @logged > 0,                 'logger->error called on scalar type failure');
	like($logged[0], qr/must be a scalar/, 'logger receives the error message');
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: scalarref
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type scalarref: reference to scalar accepted' => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => 'scalarref' } },
		input  => { x => \$s },
	);
	is($r->{x}, \$s, 'scalar reference returned unchanged');
};

subtest 'type scalarref: reference to integer accepted' => sub {
	my $n = 42;
	my $r = validate_strict(
		schema => { x => { type => 'scalarref' } },
		input  => { x => \$n },
	);
	is($r->{x}, \$n, 'reference to integer returned unchanged — scalarref does not coerce');
};

subtest 'type scalarref: plain scalar rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => 'hello' })
	} qr/must be a scalar reference/, 'croaks when plain scalar passed as scalarref';
};

subtest 'type scalarref: arrayref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => [] })
	} qr/must be a scalar reference/, 'croaks when arrayref passed as scalarref';
};

subtest 'type scalarref: hashref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => {} })
	} qr/must be a scalar reference/, 'croaks when hashref passed as scalarref';
};

subtest 'type scalarref: coderef rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => sub {} })
	} qr/must be a scalar reference/, 'croaks when coderef passed as scalarref';
};

subtest 'type scalarref: blessed object rejected' => sub {
	my $obj = Unit::Searcher->new;
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => $obj })
	} qr/must be a scalar reference/, 'croaks when blessed object passed as scalarref';
};

subtest 'type scalarref: logger receives error when non-scalarref supplied' => sub {
	my $logger = MockLogger->new;
	my @logged;
	my $m = mock_scoped('MockLogger', 'error',
		sub { push @logged, join('', @_[1 .. $#_]) });
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref' } },
			input  => { x => [] },
			logger => $logger,
		)
	} qr/must be a scalar reference/, 'still croaks with logger present';
	ok(scalar @logged > 0,                          'logger->error called on scalarref type failure');
	like($logged[0], qr/must be a scalar reference/, 'logger receives the error message');
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: stringref
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type stringref: reference to string accepted; returns plain string' => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => 'stringref' } },
		input  => { x => \$s },
	);
	is($r->{x}, 'hello', 'dereferenced string returned');
};

subtest 'type stringref: reference to empty string accepted' => sub {
	my $e = '';
	my $r = validate_strict(
		schema => { x => { type => 'stringref' } },
		input  => { x => \$e },
	);
	is($r->{x}, '', 'empty string returned');
};

subtest 'type stringref: plain scalar rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => 'hello' })
	} qr/must be a string reference/, 'croaks when plain scalar passed as stringref';
};

subtest 'type stringref: plain integer rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => 42 })
	} qr/must be a string reference/, 'croaks when plain integer passed as stringref';
};

subtest 'type stringref: arrayref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => [] })
	} qr/must be a string reference/, 'croaks when arrayref passed as stringref';
};

subtest 'type stringref: hashref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => {} })
	} qr/must be a string reference/, 'croaks when hashref passed as stringref';
};

subtest 'type stringref: coderef rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => sub {} })
	} qr/must be a string reference/, 'croaks when coderef passed as stringref';
};

subtest 'type stringref: blessed object rejected' => sub {
	my $obj = Unit::Searcher->new;
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => $obj })
	} qr/must be a string reference/, 'croaks when blessed object passed as stringref';
};

subtest 'type stringref: ref-of-ref rejected' => sub {
	my $inner = [];	# arrayref; \$inner is type REF, not SCALAR
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \$inner })
	} qr/must be a string reference/, 'croaks when ref-of-ref passed as stringref';
};

subtest 'type stringref: min enforced on referenced string length' => sub {
	my $short = 'hi';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', min => 5 } }, input => { x => \$short })
	} qr/too short/, 'croaks when referenced string is shorter than min';

	my $ok = 'hello';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', min => 5 } }, input => { x => \$ok })
	} 'string at min boundary accepted';
	is($r->{x}, 'hello', 'correct value returned after min check');
};

subtest 'type stringref: max enforced on referenced string length' => sub {
	my $long = 'toolongstring';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', max => 5 } }, input => { x => \$long })
	} qr/too long/, 'croaks when referenced string is longer than max';

	my $ok = 'hello';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', max => 5 } }, input => { x => \$ok })
	} 'string at max boundary accepted';
	is($r->{x}, 'hello', 'correct value returned after max check');
};

subtest 'type stringref: matches applied to referenced string' => sub {
	my $bad = 'hello world';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', matches => qr/^\w+$/ } }, input => { x => \$bad })
	} qr/must match pattern/, 'croaks when referenced string fails pattern';

	my $good = 'hello';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', matches => qr/^\w+$/ } }, input => { x => \$good })
	} 'matching value accepted';
	is($r->{x}, 'hello', 'correct value returned after matches check');
};

subtest 'type stringref: memberof applied to referenced string' => sub {
	my $bad = 'draft';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', memberof => ['yes', 'no'] } }, input => { x => \$bad })
	} qr/must be one of/, 'croaks when referenced string is not a member';

	my $good = 'yes';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', memberof => ['yes', 'no'] } }, input => { x => \$good })
	} 'member value accepted';
	is($r->{x}, 'yes', 'correct value returned after memberof check');
};

subtest 'type stringref: optional — absent key is skipped' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'stringref', optional => 1 } },
		input  => {},
	);
	ok(!exists($r->{x}), 'absent optional stringref key not present in result');
};

subtest 'type stringref: default applied when absent' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'stringref', optional => 1, default => 'fallback' } },
		input  => {},
	);
	is($r->{x}, 'fallback', 'default value used when stringref param absent');
};

subtest 'type stringref: custom error_msg used on type failure' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref', error_msg => 'Custom stringref error' } },
			input  => { x => 'not a ref' },
		)
	} qr/Custom stringref error/, 'custom error_msg appears in error';
};

subtest 'type stringref: logger receives error on type failure' => sub {
	my $logger = MockLogger->new;
	my @logged;
	my $m = mock_scoped('MockLogger', 'error',
		sub { push @logged, join('', @_[1 .. $#_]) });
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref' } },
			input  => { x => 'not a ref' },
			logger => $logger,
		)
	} qr/must be a string reference/, 'still croaks with logger present';
	ok(scalar @logged > 0,                           'logger->error called on stringref type failure');
	like($logged[0], qr/must be a string reference/, 'logger receives the error message');
};

# ══════════════════════════════════════════════════════════════════════════════
# Union type: ['string', 'stringref']
# ══════════════════════════════════════════════════════════════════════════════

subtest "union ['string','stringref']: plain string accepted via string branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string', 'stringref'] } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'plain string accepted via string branch of union');
};

subtest "union ['string','stringref']: string reference accepted via stringref branch" => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['string', 'stringref'] } },
		input  => { x => \$s },
	);
	is($r->{x}, 'hello', 'string reference accepted; dereferenced string returned');
};

subtest "union ['string','stringref']: arrayref rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['string', 'stringref'] } },
			input  => { x => [] },
		)
	} qr/must be one of/, 'arrayref rejected by both string and stringref branches';
};

subtest "union ['string','stringref']: hashref rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['string', 'stringref'] } },
			input  => { x => {} },
		)
	} qr/must be one of/, 'hashref rejected by both string and stringref branches';
};

# ══════════════════════════════════════════════════════════════════════════════
# Union type: ['scalar', 'scalarref']
# ══════════════════════════════════════════════════════════════════════════════

subtest "union ['scalar','scalarref']: plain string accepted via scalar branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['scalar', 'scalarref'] } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'plain string accepted via scalar branch of union');
};

subtest "union ['scalar','scalarref']: integer accepted via scalar branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['scalar', 'scalarref'] } },
		input  => { x => 42 },
	);
	is($r->{x}, 42, 'integer accepted via scalar branch of union');
};

subtest "union ['scalar','scalarref']: scalar reference accepted via scalarref branch" => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['scalar', 'scalarref'] } },
		input  => { x => \$s },
	);
	is($r->{x}, \$s, 'scalar reference accepted via scalarref branch of union');
};

subtest "union ['scalar','scalarref']: arrayref rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['scalar', 'scalarref'] } },
			input  => { x => [] },
		)
	} qr/must be one of/, 'arrayref rejected by both scalar and scalarref branches';
};

subtest "union ['scalar','scalarref']: hashref rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['scalar', 'scalarref'] } },
			input  => { x => {} },
		)
	} qr/must be one of/, 'hashref rejected by both scalar and scalarref branches';
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: coderef
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type coderef: coderef accepted' => sub {
	my $cb = sub { 1 };
	my $r = validate_strict(
		schema => { fn => { type => 'coderef' } },
		input  => { fn => $cb },
	);
	is($r->{fn}, $cb, 'coderef returned unchanged');
};

subtest 'type coderef: scalar rejected' => sub {
	throws_ok {
		validate_strict(schema => { fn => { type => 'coderef' } }, input => { fn => 'sub' })
	} qr/must be a coderef/, 'croaks when scalar passed as coderef';
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: object
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type object: blessed reference accepted' => sub {
	my $obj = Unit::Searcher->new;
	my $r = validate_strict(
		schema => { svc => { type => 'object' } },
		input  => { svc => $obj },
	);
	is($r->{svc}, $obj, 'blessed object returned unchanged');
};

subtest 'type object: unblessed reference rejected' => sub {
	throws_ok {
		validate_strict(schema => { svc => { type => 'object' } }, input => { svc => {} })
	} qr/must be an object/, 'croaks when unblessed hashref passed';
};

# ══════════════════════════════════════════════════════════════════════════════
# Union type  (type => ['a', 'b'])
# ══════════════════════════════════════════════════════════════════════════════

subtest 'union type: first candidate matches' => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string', 'arrayref'] } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'string branch of union type accepted');
};

subtest 'union type: second candidate matches' => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string', 'arrayref'] } },
		input  => { x => [1, 2] },
	);
	is_deeply($r->{x}, [1, 2], 'arrayref branch of union type accepted');
};

subtest 'union type: integer coercion propagated from winning branch' => sub {
	my $r = validate_strict(
		schema => { n => { type => ['integer', 'string'] } },
		input  => { n => '99' },
	);
	is($r->{n}, 99, 'integer coercion from winning union branch returned');
};

subtest 'union type: no branch matches → croaks listing types' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['integer', 'arrayref'] } },
			input  => { x => { k => 1 } },
		)
	} qr/must be one of/, 'croaks when no union branch matches';
};

subtest 'union type: optional absent parameter does not croak' => sub {
	lives_ok {
		validate_strict(
			schema => { x => { type => ['string', 'integer'], optional => 1 } },
			input  => {},
		)
	} 'absent optional union-type parameter accepted';
};

# ══════════════════════════════════════════════════════════════════════════════
# min / max
# ══════════════════════════════════════════════════════════════════════════════

subtest 'min: string shorter than minimum → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', min => 5 } },
			input  => { s => 'hi' },
		)
	} qr/too short/, 'croaks when string is shorter than min';
};

subtest 'min: string meeting minimum → ok' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 3 } },
		input  => { s => 'hey' },
	);
	is($r->{s}, 'hey', 'string at min length accepted');
};

subtest 'max: string longer than maximum → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', max => 3 } },
			input  => { s => 'toolong' },
		)
	} qr/too long/, 'croaks when string exceeds max';
};

subtest 'min/max: non-ASCII string length counted in characters not bytes' => sub {
	# Mock Unicode::GCString::new so the returned object reports 3 grapheme
	# clusters — verifying that the module delegates length to GCString rather
	# than using byte-count length().
	my $m = mock_scoped('Unicode::GCString', 'new', sub { Unit::GCString->new });
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', min => 4 } },
			input  => { s => "\x{00e9}l\x{00e8}" },	# 3-char Unicode string
		)
	} qr/too short/, 'character count (not byte count) used for non-ASCII min';
};

subtest 'min: integer below minimum → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', min => 10 } },
			input  => { n => 5 },
		)
	} qr/must be at least 10/, 'croaks when integer is below min';
};

subtest 'max: integer above maximum → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', max => 100 } },
			input  => { n => 200 },
		)
	} qr/must be no more than 100/, 'croaks when integer exceeds max';
};

subtest 'min: arrayref shorter than minimum → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { a => { type => 'arrayref', min => 3 } },
			input  => { a => [1] },
		)
	} qr/must have at least /, 'croaks when array has fewer than min elements';
};

subtest 'max: arrayref longer than maximum → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { a => { type => 'arrayref', max => 2 } },
			input  => { a => [1, 2, 3] },
		)
	} qr/must contain no more than/, 'croaks when array exceeds max elements';
};

subtest 'min: hashref with fewer than minimum keys → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { h => { type => 'hashref', min => 3 } },
			input  => { h => { a => 1 } },
		)
	} qr/must contain at least/, 'croaks when hashref has too few keys';
};

subtest 'schema: min > max rejected as invalid schema' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', min => 10, max => 5 } },
			input  => { n => 7 },
		)
	} qr/min must be <= max/, 'croaks when schema specifies min > max';
};

# ══════════════════════════════════════════════════════════════════════════════
# matches / nomatch
# ══════════════════════════════════════════════════════════════════════════════

subtest 'matches: value satisfies pattern → ok' => sub {
	my $r = validate_strict(
		schema => { code => { type => 'string', matches => qr/^\d{4}$/ } },
		input  => { code => '1234' },
	);
	is($r->{code}, '1234', 'value matching pattern accepted');
};

subtest 'matches: value fails pattern → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { code => { type => 'string', matches => qr/^\d{4}$/ } },
			input  => { code => 'abcd' },
		)
	} qr/must match pattern/, 'croaks when value does not match pattern';
};

subtest 'regex: synonym for matches' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', regex => qr/^[a-z]+$/ } },
		input  => { s => 'abc' },
	);
	is($r->{s}, 'abc', 'regex synonym accepted');
};

subtest 'matches: all arrayref members must match' => sub {
	throws_ok {
		validate_strict(
			schema => { tags => { type => 'arrayref', matches => qr/^[a-z]+$/ } },
			input  => { tags => ['good', 'BAD'] },
		)
	} qr/must match pattern/, 'croaks when any arrayref member fails pattern';
};

subtest 'nomatch: value matching forbidden pattern → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { user => { type => 'string', nomatch => qr/admin/ } },
			input  => { user => 'admin_user' },
		)
	} qr/must not match pattern/, 'croaks when value matches nomatch pattern';
};

subtest 'nomatch: value not matching forbidden pattern → ok' => sub {
	my $r = validate_strict(
		schema => { user => { type => 'string', nomatch => qr/admin/ } },
		input  => { user => 'alice' },
	);
	is($r->{user}, 'alice', 'value not matching nomatch pattern accepted');
};

# ══════════════════════════════════════════════════════════════════════════════
# memberof / enum / notmemberof / case_sensitive
# ══════════════════════════════════════════════════════════════════════════════

subtest 'memberof: valid member accepted' => sub {
	my $r = validate_strict(
		schema => { status => { type => 'string', memberof => [qw(draft published)] } },
		input  => { status => 'draft' },
	);
	is($r->{status}, 'draft', 'memberof: valid member returned');
};

subtest 'memberof: non-member rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { status => { type => 'string', memberof => [qw(draft published)] } },
			input  => { status => 'deleted' },
		)
	} qr/must be one of/, 'croaks when value not in memberof list';
};

subtest 'enum: synonym for memberof' => sub {
	my $r = validate_strict(
		schema => { role => { type => 'string', enum => [qw(admin user guest)] } },
		input  => { role => 'user' },
	);
	is($r->{role}, 'user', 'enum synonym works');
};

subtest 'memberof: case_sensitive => 0 allows any case, preserves original' => sub {
	my $r = validate_strict(
		schema => { code => {
			type           => 'string',
			memberof       => ['ABC', 'DEF'],
			case_sensitive => 0,
		} },
		input => { code => 'abc' },
	);
	is($r->{code}, 'abc', 'case-insensitive match; original casing preserved');
};

subtest 'memberof: case_sensitive => 1 (default) rejects wrong case' => sub {
	throws_ok {
		validate_strict(
			schema => { code => { type => 'string', memberof => ['ABC'] } },
			input  => { code => 'abc' },
		)
	} qr/must be one of/, 'case-sensitive comparison by default';
};

subtest 'memberof: numeric types use == comparison' => sub {
	my $r = validate_strict(
		schema => { level => { type => 'integer', memberof => [1, 2, 3] } },
		input  => { level => '2' },
	);
	is($r->{level}, 2, 'integer memberof uses numeric equality after coercion');
};

subtest 'memberof: cannot be combined with min → croaks on schema error' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', memberof => [1,2,3], min => 1 } },
			input  => { n => 2 },
		)
	} qr/makes no sense with memberof/, 'croaks for memberof+min combination';
};

subtest 'notmemberof: blacklisted value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { user => { type => 'string', notmemberof => [qw(admin root)] } },
			input  => { user => 'admin' },
		)
	} qr/must not be one of/, 'croaks when value is on the blacklist';
};

subtest 'notmemberof: non-blacklisted value accepted' => sub {
	my $r = validate_strict(
		schema => { user => { type => 'string', notmemberof => [qw(admin root)] } },
		input  => { user => 'alice' },
	);
	is($r->{user}, 'alice', 'value not on blacklist accepted');
};

subtest 'notmemberof: case_sensitive => 0 blocks any case variant' => sub {
	throws_ok {
		validate_strict(
			schema => { user => {
				type           => 'string',
				notmemberof    => ['Admin'],
				case_sensitive => 0,
			} },
			input => { user => 'ADMIN' },
		)
	} qr/must not be one of/, 'case-insensitive notmemberof rejects variant case';
};

# ══════════════════════════════════════════════════════════════════════════════
# can / isa
# ══════════════════════════════════════════════════════════════════════════════

subtest 'can: object with required method → ok' => sub {
	my $obj = Unit::Searcher->new;
	lives_ok {
		validate_strict(
			schema => { svc => { type => 'object', can => 'search' } },
			input  => { svc => $obj },
		)
	} 'no error when object responds to required method';
};

subtest 'can: object missing required method → croaks' => sub {
	my $obj = Unit::Searcher->new;	# has no 'delete' method
	throws_ok {
		validate_strict(
			schema => { svc => { type => 'object', can => 'delete' } },
			input  => { svc => $obj },
		)
	} qr/must be an object that understands the delete method/,
	  'croaks when required method is absent';
};

subtest 'can: arrayref of methods — all present → ok' => sub {
	my $obj = Unit::Searcher->new;	# has both search and list
	lives_ok {
		validate_strict(
			schema => { svc => { type => 'object', can => ['search', 'list'] } },
			input  => { svc => $obj },
		)
	} 'no error when object responds to all listed methods';
};

subtest 'can: arrayref of methods — one absent → croaks' => sub {
	my $obj = Unit::Searcher->new;
	throws_ok {
		validate_strict(
			schema => { svc => { type => 'object', can => ['search', 'vanish'] } },
			input  => { svc => $obj },
		)
	} qr/must be an object that understands the vanish method/,
	  'croaks naming the absent method';
};

subtest 'isa: object of correct class (including inheritance) → ok' => sub {
	my $obj = Unit::Child->new;
	lives_ok {
		validate_strict(
			schema => { obj => { type => 'object', isa => 'Unit::Base' } },
			input  => { obj => $obj },
		)
	} 'subclass satisfies isa check';
};

subtest 'isa: wrong class → croaks' => sub {
	my $obj = Unit::Searcher->new;
	throws_ok {
		validate_strict(
			schema => { obj => { type => 'object', isa => 'Unit::Base' } },
			input  => { obj => $obj },
		)
	} qr/must be a 'Unit::Base' object/, 'croaks when object fails isa check';
};

# ══════════════════════════════════════════════════════════════════════════════
# element_type
# ══════════════════════════════════════════════════════════════════════════════

subtest 'element_type integer: all-integer array accepted' => sub {
	my $r = validate_strict(
		schema => { ids => { type => 'arrayref', element_type => 'integer' } },
		input  => { ids => [1, 2, 3] },
	);
	is_deeply($r->{ids}, [1, 2, 3], 'all-integer array returned unchanged');
};

subtest 'element_type integer: non-integer element → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { ids => { type => 'arrayref', element_type => 'integer' } },
			input  => { ids => [1, 'two', 3] },
		)
	} qr/can only contain integers/, 'croaks when an element is not an integer';
};

subtest 'element_type string: ref element → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { tags => { type => 'arrayref', element_type => 'string' } },
			input  => { tags => ['ok', []] },
		)
	} qr/can only contain strings/, 'croaks when an element is a reference';
};

# ══════════════════════════════════════════════════════════════════════════════
# optional / default / nullable
# ══════════════════════════════════════════════════════════════════════════════

subtest 'optional: absent parameter not present in result' => sub {
	my $r = validate_strict(
		schema => {
			name => { type => 'string' },
			nick => { type => 'string', optional => 1 },
		},
		input => { name => 'Alice' },
	);
	ok(!exists $r->{nick}, 'absent optional parameter absent from result');
};

subtest 'optional: present parameter validated and returned' => sub {
	my $r = validate_strict(
		schema => { role => { type => 'string', optional => 1 } },
		input  => { role => 'admin' },
	);
	is($r->{role}, 'admin', 'present optional parameter returned normally');
};

subtest 'default: applied when optional parameter absent' => sub {
	my $r = validate_strict(
		schema => { role => { type => 'string', optional => 1, default => 'guest' } },
		input  => {},
	);
	is($r->{role}, 'guest', 'default value applied for absent optional');
};

subtest 'default: not applied when parameter is present' => sub {
	my $r = validate_strict(
		schema => { role => { type => 'string', optional => 1, default => 'guest' } },
		input  => { role => 'admin' },
	);
	is($r->{role}, 'admin', 'supplied value wins over default');
};

subtest 'optional as coderef: evaluated with value and all params' => sub {
	# When coderef returns 1 the parameter becomes optional
	my $r = validate_strict(
		schema => {
			flag    => { type => 'string' },
			payload => {
				type     => 'string',
				optional => sub {
					my ($val, $all) = @_;
					return $all->{flag} eq 'skip' ? 1 : 0;
				},
			},
		},
		input => { flag => 'skip' },	# no payload — coderef makes it optional
	);
	ok(!exists $r->{payload}, 'coderef optional: parameter treated as optional');
};

subtest 'nullable: flag-only optional, no coderef' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', nullable => 1 } },
		input  => {},
	);
	ok(!exists $r->{n}, 'nullable parameter absent from result when not supplied');
};

subtest 'required parameter missing → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { name => { type => 'string' } },
			input  => {},
		)
	} qr/Required parameter 'name' is missing/, 'croaks for missing required parameter';
};

# ══════════════════════════════════════════════════════════════════════════════
# Nested schemas
# ══════════════════════════════════════════════════════════════════════════════

subtest 'nested hashref schema: inner fields validated' => sub {
	my $r = validate_strict(
		schema => {
			user => {
				type   => 'hashref',
				schema => {
					name => { type => 'string' },
					age  => { type => 'integer', min => 0 },
				},
			},
		},
		input => { user => { name => 'Bob', age => '30' } },
	);
	is($r->{user}{name}, 'Bob', 'nested string field returned');
	is($r->{user}{age},  30,    'nested integer field coerced');
};

subtest 'nested hashref schema: inner field invalid → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				user => {
					type   => 'hashref',
					schema => { age => { type => 'integer' } },
				},
			},
			input => { user => { age => 'not_a_number' } },
		)
	} qr/must be an integer/, 'croaks when nested field fails validation';
};

subtest 'nested arrayref schema: each element validated' => sub {
	lives_ok {
		validate_strict(
			schema => {
				tags => {
					type   => 'arrayref',
					schema => { type => 'string', matches => qr/^[a-z]+$/ },
				},
			},
			input => { tags => ['foo', 'bar'] },
		)
	} 'all arrayref elements passing schema accepted';
};

subtest 'nested arrayref schema: failing element → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				tags => {
					type   => 'arrayref',
					schema => { type => 'string', matches => qr/^[a-z]+$/ },
				},
			},
			input => { tags => ['good', 'BAD'] },
		)
	} qr/must match pattern/, 'croaks when an array element fails nested schema';
};

# ══════════════════════════════════════════════════════════════════════════════
# transform
# ══════════════════════════════════════════════════════════════════════════════

subtest 'transform: applied before type validation' => sub {
	my $r = validate_strict(
		schema => { name => {
			type      => 'string',
			transform => sub { lc $_[0] },
		} },
		input => { name => 'ALICE' },
	);
	is($r->{name}, 'alice', 'transform applied; lowercased value returned');
};

subtest 'transform: transformed value subject to constraints' => sub {
	# transform lowercases, then notmemberof checks the lowercased value
	throws_ok {
		validate_strict(
			schema => { user => {
				type        => 'string',
				transform   => sub { lc $_[0] },
				notmemberof => ['admin'],
			} },
			input => { user => 'ADMIN' },
		)
	} qr/must not be one of/, 'constraint applied to transformed value';
};

# ══════════════════════════════════════════════════════════════════════════════
# callback
# ══════════════════════════════════════════════════════════════════════════════

subtest 'callback: returning true allows parameter' => sub {
	my $r = validate_strict(
		schema => { n => {
			type     => 'integer',
			callback => sub { $_[0] % 2 == 0 },	# must be even
		} },
		input => { n => 4 },
	);
	is($r->{n}, 4, 'value passing callback accepted');
};

subtest 'callback: returning false rejects parameter' => sub {
	throws_ok {
		validate_strict(
			schema => { n => {
				type     => 'integer',
				callback => sub { $_[0] % 2 == 0 },
			} },
			input => { n => 3 },
		)
	} qr/failed custom validation/, 'croaks when callback returns false';
};

subtest 'callback: receives value, all-args hashref, and schema' => sub {
	my @recv;
	validate_strict(
		schema => { x => {
			type     => 'integer',
			callback => sub { @recv = @_; 1 },
		} },
		input => { x => 7 },
	);
	is($recv[0], 7,           'callback arg[0] is the parameter value');
	is(ref $recv[1], 'HASH',  'callback arg[1] is the input hashref');
	is(ref $recv[2], 'HASH',  'callback arg[2] is the schema hashref');
};

# ══════════════════════════════════════════════════════════════════════════════
# validate / validator
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate: coderef returning undef passes' => sub {
	lives_ok {
		validate_strict(
			schema => { pw => {
				type     => 'string',
				validate => sub { undef },
			} },
			input => { pw => 'anything' },
		)
	} 'no error when validate coderef returns undef';
};

subtest 'validate: coderef returning error string → croaks with that string' => sub {
	throws_ok {
		validate_strict(
			schema => { pw => {
				type     => 'string',
				validate => sub { 'Password too weak' },
			} },
			input => { pw => '123' },
		)
	} qr/Password too weak/, 'croaks with message from validate coderef';
};

subtest 'validator: synonym for validate' => sub {
	lives_ok {
		validate_strict(
			schema => { x => {
				type      => 'string',
				validator => sub { undef },
			} },
			input => { x => 'ok' },
		)
	} '"validator" accepted as synonym of "validate"';
};

# ══════════════════════════════════════════════════════════════════════════════
# custom_types
# ══════════════════════════════════════════════════════════════════════════════

subtest 'custom_types: value matching custom type accepted' => sub {
	my $r = validate_strict(
		schema       => { email => { type => 'email_addr' } },
		input        => { email => 'user@example.com' },
		custom_types => { email_addr => {
			type    => 'string',
			matches => qr/\@/,
		} },
	);
	is($r->{email}, 'user@example.com', 'valid custom-type value accepted');
};

subtest 'custom_types: value failing custom type rejected' => sub {
	throws_ok {
		validate_strict(
			schema       => { email => { type => 'email_addr' } },
			input        => { email => 'not-an-email' },
			custom_types => { email_addr => {
				type    => 'string',
				matches => qr/\@/,
			} },
		)
	} qr/must match pattern/, 'croaks when value fails custom type constraint';
};

subtest 'custom_types: schema can add constraints the custom type does not define' => sub {
	# Custom type only enforces the base string type; the schema adds a
	# matches pattern.  The additional constraint is applied correctly.
	throws_ok {
		validate_strict(
			schema       => { code => { type => 'shortcode', matches => qr/^\d+$/ } },
			input        => { code => 'abc' },
			custom_types => { shortcode => { type => 'string' } },
		)
	} qr/must match pattern/, 'schema-level matches applied on top of custom type';
};

# ══════════════════════════════════════════════════════════════════════════════
# cross_validation
# ══════════════════════════════════════════════════════════════════════════════

subtest 'cross_validation: all pass → ok' => sub {
	lives_ok {
		validate_strict(
			schema => {
				password => { type => 'string' },
				confirm  => { type => 'string' },
			},
			input => { password => 'abc', confirm => 'abc' },
			cross_validation => {
				match => sub { $_[0]{password} eq $_[0]{confirm} ? undef : "No match" },
			},
		)
	} 'no error when cross_validation returns undef';
};

subtest 'cross_validation: failure → croaks with returned message' => sub {
	throws_ok {
		validate_strict(
			schema => {
				password => { type => 'string' },
				confirm  => { type => 'string' },
			},
			input => { password => 'abc', confirm => 'xyz' },
			cross_validation => {
				match => sub { $_[0]{password} eq $_[0]{confirm}
					? undef : "Passwords do not match" },
			},
		)
	} qr/Passwords do not match/, 'croaks with cross_validation error message';
};

subtest 'cross_validation: receives post-transform values' => sub {
	my $seen;
	validate_strict(
		schema => { email => {
			type      => 'string',
			transform => sub { lc $_[0] },
		} },
		input => { email => 'ALICE@EXAMPLE.COM' },
		cross_validation => {
			capture => sub { $seen = $_[0]{email}; undef },
		},
	);
	is($seen, 'alice@example.com', 'cross_validation sees transformed value');
};

# ══════════════════════════════════════════════════════════════════════════════
# relationships
# ══════════════════════════════════════════════════════════════════════════════

subtest 'relationship mutually_exclusive: one present → ok' => sub {
	lives_ok {
		validate_strict(
			schema => {
				file    => { type => 'string', optional => 1 },
				content => { type => 'string', optional => 1 },
			},
			input        => { file => 'x.txt' },
			relationships => [ { type => 'mutually_exclusive', params => ['file', 'content'] } ],
		)
	} 'one of a mutually-exclusive pair is fine';
};

subtest 'relationship mutually_exclusive: both present → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				file    => { type => 'string', optional => 1 },
				content => { type => 'string', optional => 1 },
			},
			input        => { file => 'x.txt', content => 'raw' },
			relationships => [ { type => 'mutually_exclusive', params => ['file', 'content'] } ],
		)
	} qr/Cannot specify both/, 'croaks when both mutually-exclusive params present';
};

subtest 'relationship required_group: at least one present → ok' => sub {
	lives_ok {
		validate_strict(
			schema => {
				id   => { type => 'integer', optional => 1 },
				name => { type => 'string',  optional => 1 },
			},
			input        => { id => 1 },
			relationships => [ { type => 'required_group', params => ['id', 'name'] } ],
		)
	} 'one member of required_group is sufficient';
};

subtest 'relationship required_group: none present → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				id   => { type => 'integer', optional => 1 },
				name => { type => 'string',  optional => 1 },
			},
			input        => {},
			relationships => [ { type => 'required_group', params => ['id', 'name'] } ],
		)
	} qr/Must specify at least one of/, 'croaks when no member of required_group present';
};

subtest 'relationship conditional_requirement: if truthy and then absent → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				async    => { type => 'string', optional => 1 },
				callback => { type => 'string', optional => 1 },
			},
			input        => { async => '1' },
			relationships => [ {
				type          => 'conditional_requirement',
				if            => 'async',
				then_required => 'callback',
			} ],
		)
	} qr/callback is required/, 'croaks when conditional requirement unmet';
};

subtest 'relationship dependency: param present without required → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				port => { type => 'integer', optional => 1 },
				host => { type => 'string',  optional => 1 },
			},
			input        => { port => 8080 },
			relationships => [ { type => 'dependency', param => 'port', requires => 'host' } ],
		)
	} qr/port requires host/, 'croaks when dependency not satisfied';
};

subtest 'relationship value_constraint: violated → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				ssl  => { type => 'string',  optional => 1 },
				port => { type => 'integer', optional => 1 },
			},
			input        => { ssl => '1', port => 80 },
			relationships => [ {
				type     => 'value_constraint',
				if       => 'ssl',
				then     => 'port',
				operator => '==',
				value    => 443,
			} ],
		)
	} qr/port must be == 443/, 'croaks when value_constraint violated';
};

subtest 'relationship value_conditional: value matches, required absent → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				mode => { type => 'string', optional => 1 },
				key  => { type => 'string', optional => 1 },
			},
			input        => { mode => 'secure' },
			relationships => [ {
				type          => 'value_conditional',
				if            => 'mode',
				equals        => 'secure',
				then_required => 'key',
			} ],
		)
	} qr/key is required/, 'croaks when value_conditional requirement unmet';
};

# ══════════════════════════════════════════════════════════════════════════════
# unknown_parameter_handler
# ══════════════════════════════════════════════════════════════════════════════

subtest 'unknown_parameter_handler: die (default) → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { name => { type => 'string' } },
			input  => { name => 'Alice', extra => 'surprise' },
		)
	} qr/Unknown parameter 'extra'/, 'unknown parameter causes croak by default';
};

subtest 'unknown_parameter_handler: warn → no croak, emits warning' => sub {
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	lives_ok {
		validate_strict(
			schema                    => { name => { type => 'string' } },
			input                     => { name => 'Alice', extra => 'ok' },
			unknown_parameter_handler => 'warn',
		)
	} 'no croak for unknown parameter with warn handler';
	ok(scalar @w > 0,             'warning emitted for unknown parameter');
	like($w[0], qr/Unknown parameter 'extra'/, 'warning names the parameter');
};

subtest 'unknown_parameter_handler: ignore → silent' => sub {
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	lives_ok {
		validate_strict(
			schema                    => { name => { type => 'string' } },
			input                     => { name => 'Alice', extra => 'ignored' },
			unknown_parameter_handler => 'ignore',
		)
	} 'no croak for unknown parameter with ignore handler';
	is(scalar @w, 0, 'no warning emitted with ignore handler');
};

subtest 'carp_on_warn: sets default unknown_parameter_handler to warn' => sub {
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	lives_ok {
		validate_strict(
			schema       => { name => { type => 'string' } },
			input        => { name => 'Alice', extra => 'ok' },
			carp_on_warn => 1,
		)
	} 'carp_on_warn: unknown parameter warns rather than dies';
	ok(scalar @w > 0, 'warning emitted when carp_on_warn set');
};

# ══════════════════════════════════════════════════════════════════════════════
# logger integration  (mock_scoped used for logger methods)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'logger: error method called when validation fails, still croaks' => sub {
	my $logger = MockLogger->new;
	my @logged;
	my $m = mock_scoped('MockLogger', 'error',
		sub { push @logged, join('', @_[1 .. $#_]) });
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => 'not_an_integer' },
			logger => $logger,
		)
	} qr/must be an integer/, 'validate_strict still croaks with logger present';
	ok(scalar @logged > 0,          'logger->error called on validation failure');
	like($logged[0], qr/must be an integer/, 'logger receives the error message');
};

subtest 'logger: warn method called for unknown parameter with warn handler' => sub {
	my $logger = MockLogger->new;
	my @warned;
	my $m = mock_scoped('MockLogger', 'warn',
		sub { push @warned, join('', @_[1 .. $#_]) });
	lives_ok {
		validate_strict(
			schema                    => { name => { type => 'string' } },
			input                     => { name => 'Alice', extra => 'ok' },
			unknown_parameter_handler => 'warn',
			logger                    => $logger,
		)
	} 'no croak when warn handler active and logger present';
	ok(scalar @warned > 0,                 'logger->warn called for unknown parameter');
	like($warned[0], qr/Unknown parameter/, 'logger->warn receives the warning');
};

# ══════════════════════════════════════════════════════════════════════════════
# error_msg and description
# ══════════════════════════════════════════════════════════════════════════════

subtest 'error_msg per rule: custom message replaces default' => sub {
	throws_ok {
		validate_strict(
			schema => { age => {
				type      => 'integer',
				min       => 18,
				error_msg => 'You must be at least 18',
			} },
			input => { age => 15 },
		)
	} qr/You must be at least 18/, 'per-rule error_msg used in croak';
};

subtest 'description: appears in default error messages' => sub {
	throws_ok {
		validate_strict(
			schema      => { name => { type => 'string' } },
			input       => {},
			description => 'UserRecord',
		)
	} qr/UserRecord/, 'description appears in the error message';
};

# ══════════════════════════════════════════════════════════════════════════════
# Positional arguments
# ══════════════════════════════════════════════════════════════════════════════

subtest 'positional args: returns arrayref in position order' => sub {
	my $r = validate_strict(
		schema => {
			first  => { type => 'string',  position => 0 },
			second => { type => 'integer', position => 1 },
		},
		input => ['hello', '7'],
	);
	is(ref($r),  'ARRAY',   'positional mode returns an arrayref');
	is($r->[0], 'hello',   'first positional arg in position 0');
	is($r->[1],  7,         'second positional arg coerced and in position 1');
};

# ══════════════════════════════════════════════════════════════════════════════
# Data::Processor schema-wrapping compatibility
# ══════════════════════════════════════════════════════════════════════════════

subtest 'schema wrapping: members key unwrapped transparently' => sub {
	my $r = validate_strict(
		schema => {
			description => 'User record',
			members     => { name => { type => 'string' } },
		},
		input => { name => 'Carol' },
	);
	is($r->{name}, 'Carol', 'members-wrapped schema processed correctly');
};

subtest 'schema wrapping: error_msg from schema used in failures' => sub {
	throws_ok {
		validate_strict(
			schema => {
				description => 'Widget',
				error_msg   => 'Widget validation failed',
				members     => { count => { type => 'integer' } },
			},
			input => {},
		)
	} qr/Widget validation failed|Required parameter/, 'schema-level error_msg or default used';
};

# ══════════════════════════════════════════════════════════════════════════════
# args / members / schema aliases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'args alias: accepted alongside schema' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'string' } },
		args   => { x => 'hello' },
	);
	is($r->{x}, 'hello', '"args" accepted as alias for "input"');
};

subtest 'members alias: accepted alongside input' => sub {
	my $r = validate_strict(
		members => { x => { type => 'string' } },
		input   => { x => 'world' },
	);
	is($r->{x}, 'world', '"members" accepted as alias for "schema"');
};

# ══════════════════════════════════════════════════════════════════════════════
# Arrayref schema format  (new in 0.32)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'arrayref schema: normalised to hashref — basic types and coercion work' => sub {
	my $r = validate_strict(
		schema => [
			{ name => 'username', type => 'string',  min => 3, max => 20 },
			{ name => 'age',      type => 'integer', min => 0, max => 150 },
		],
		input => { username => 'Alice', age => '30' },
	);
	is($r->{username}, 'Alice', 'string field returned unchanged');
	is($r->{age},       30,     'integer field coerced from string');
};

subtest 'arrayref schema: optional + default applied correctly' => sub {
	my $r = validate_strict(
		schema => [
			{ name => 'name', type => 'string' },
			{ name => 'role', type => 'string', optional => 1, default => 'user' },
		],
		input => { name => 'Bob' },
	);
	is($r->{name}, 'Bob',  'required field returned');
	is($r->{role}, 'user', 'default applied for absent optional field');
};

subtest 'arrayref schema: constraint enforced (max violated)' => sub {
	throws_ok {
		validate_strict(
			schema => [ { name => 'score', type => 'integer', min => 0, max => 100 } ],
			input  => { score => 150 },
		)
	} qr/must be no more than 100/, 'max constraint enforced via arrayref schema';
};

subtest 'arrayref schema: equivalent result to hashref schema' => sub {
	my $hash_schema = { n => { type => 'integer', min => 1 }, s => { type => 'string' } };
	my $arr_schema  = [
		{ name => 'n', type => 'integer', min => 1 },
		{ name => 's', type => 'string'  },
	];
	my $input = { n => '5', s => 'hello' };
	my $r1 = validate_strict(schema => $hash_schema, input => $input);
	my $r2 = validate_strict(schema => $arr_schema,  input => $input);
	is_deeply($r1, $r2, 'arrayref and hashref schemas produce identical results');
};

subtest 'arrayref schema: members wrapper also accepts arrayref form' => sub {
	my $r = validate_strict(
		schema => {
			description => 'Wrapped arrayref members',
			members     => [
				{ name => 'x', type => 'integer' },
			],
		},
		input => { x => '7' },
	);
	is($r->{x}, 7, 'arrayref inside members wrapper normalised correctly');
};

subtest 'arrayref schema: missing required field still croaks' => sub {
	throws_ok {
		validate_strict(
			schema => [ { name => 'required_field', type => 'string' } ],
			input  => {},
		)
	} qr/Required parameter 'required_field' is missing/, 'missing required field croaks with arrayref schema';
};

subtest 'arrayref schema: unknown_parameter_handler honoured' => sub {
	throws_ok {
		validate_strict(
			schema => [ { name => 'x', type => 'string' } ],
			input  => { x => 'hi', extra => 'unexpected' },
		)
	} qr/Unknown parameter 'extra'/, 'unknown parameter still croaks with arrayref schema';
};

# ══════════════════════════════════════════════════════════════════════════════
# enum synonym  (complete as of 0.32: min/max incompatibility now also enforced)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'enum: synonym for memberof — valid member accepted' => sub {
	my $r = validate_strict(
		schema => { status => { type => 'string', enum => [qw(draft published archived)] } },
		input  => { status => 'draft' },
	);
	is($r->{status}, 'draft', 'enum: valid member accepted');
};

subtest 'enum: synonym for memberof — non-member rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { status => { type => 'string', enum => [qw(draft published)] } },
			input  => { status => 'deleted' },
		)
	} qr/must be one of/, 'enum: non-member rejected';
};

subtest 'enum + min → "makes no sense" error' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', enum => [1, 2, 3], min => 1 } },
			input  => { n => 2 },
		)
	} qr/makes no sense with memberof/, 'enum combined with min croaks';
};

subtest 'enum + max → "makes no sense" error' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', enum => [1, 2, 3], max => 3 } },
			input  => { n => 2 },
		)
	} qr/makes no sense with memberof/, 'enum combined with max croaks';
};

subtest 'values: synonym for memberof — valid member accepted' => sub {
	my $r = validate_strict(
		schema => { colour => { type => 'string', values => [qw(red green blue)] } },
		input  => { colour => 'green' },
	);
	is($r->{colour}, 'green', 'values: valid member accepted');
};

subtest 'values: synonym for memberof — non-member rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { colour => { type => 'string', values => [qw(red green blue)] } },
			input  => { colour => 'purple' },
		)
	} qr/must be one of/, 'values: non-member rejected';
};

subtest 'values + min → "makes no sense" error' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', values => [1, 2, 3], min => 1 } },
			input  => { n => 2 },
		)
	} qr/makes no sense with memberof/, 'values combined with min croaks';
};

subtest 'values + max → "makes no sense" error' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', values => [1, 2, 3], max => 3 } },
			input  => { n => 2 },
		)
	} qr/makes no sense with memberof/, 'values combined with max croaks';
};

done_testing;
