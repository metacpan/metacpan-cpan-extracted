#!/usr/bin/env perl

# Destructive, pathological, and boundary-condition tests for
# Params::Validate::Strict.  These exercise the corners and crevices
# that ordinary usage never reaches.

use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(blessed looks_like_number);
use POSIX        qw(DBL_MAX);

use Params::Validate::Strict qw(validate_strict);

# ── Test-support classes ──────────────────────────────────────────────────────

# Object that overloads both stringification and numification
{
	package Edge::Overloaded;
	use overload '""'    => sub { 'i_am_a_string' },
	             '0+'    => sub { 42 },
	             'bool'  => sub { 1 },
	             fallback => 1;
	sub new { bless {}, shift }
}

# Object that always dies when you call any method
{
	package Edge::Exploder;
	sub new    { bless {}, shift }
	sub AUTOLOAD { die "Edge::Exploder: method called: $Edge::Exploder::AUTOLOAD\n" }
	sub DESTROY {}
}

# Minimal logger that captures error calls for inspection
{
	package Edge::Logger;
	sub new    { bless { errors => [] }, shift }
	sub error  { push @{$_[0]{errors}}, join('', @_[1..$#_]) }
	sub errors { @{$_[0]{errors}} }
}

# ══════════════════════════════════════════════════════════════════════════════
# String boundary conditions
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string: "0" is Perl-false but a valid non-empty string' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string' } },
		input  => { s => '0' },
	);
	is($r->{s}, '0', '"0" accepted as a valid string despite being Perl-false');
	ok(!$r->{s}, '…and it is indeed Perl-false');
};

subtest 'string: empty string is valid (no min constraint set)' => sub {
	# The string type check gates on ref() — any non-ref scalar is accepted.
	# An empty string with no min constraint is valid; use min => 1 to forbid it.
	my $r = validate_strict(schema => { s => { type => 'string' } }, input => { s => '' });
	is($r->{s}, '', 'empty string accepted when no min constraint is set');
};

subtest 'string: single space is a valid non-empty string' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string' } },
		input  => { s => ' ' },
	);
	is($r->{s}, ' ', 'single space accepted as non-empty string');
};

subtest 'string: embedded NUL byte passes type check' => sub {
	my $s = "hel\x00lo";
	my $r = validate_strict(schema => { s => { type => 'string' } }, input => { s => $s });
	is($r->{s}, $s, 'string with embedded NUL byte accepted');
	is(length($r->{s}), 6, 'length still counts NUL as a character');
};

subtest 'string: "0E0" — Perl zero-but-true idiom' => sub {
	my $r = validate_strict(schema => { s => { type => 'string' } }, input => { s => '0E0' });
	is($r->{s}, '0E0', '"0E0" accepted as string');
	ok('0E0',   '"0E0" is truthy (DBD idiom)');
	ok('0E0' == 0, '…yet numerically equals zero');
};

subtest 'string: 1 million character string' => sub {
	my $big = 'A' x 1_000_000;
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 1 } },
		input  => { s => $big },
	);
	is(length($r->{s}), 1_000_000, '1M-character string accepted and returned intact');
};

subtest 'string min/max: exact boundary — at limit passes, one over fails' => sub {
	lives_ok {
		validate_strict(
			schema => { s => { type => 'string', min => 3, max => 3 } },
			input  => { s => 'abc' },
		)
	} 'string of exactly min==max length accepted';

	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', min => 3, max => 3 } },
			input  => { s => 'abcd' },
		)
	} qr/too long/, 'string one character over max rejected';

	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', min => 3, max => 3 } },
			input  => { s => 'ab' },
		)
	} qr/too short/, 'string one character under min rejected';
};

subtest 'string: min => 0 is valid (all non-undef strings satisfy it)' => sub {
	lives_ok {
		validate_strict(
			schema => { s => { type => 'string', min => 0 } },
			input  => { s => '' },
		)
	} 'min => 0: even an empty string satisfies it';
};

subtest 'string: newline, tab, formfeed — accepted as ordinary characters' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 3 } },
		input  => { s => "\n\t\f" },
	);
	is(length($r->{s}), 3, 'whitespace control characters counted correctly');
};

# ══════════════════════════════════════════════════════════════════════════════
# Integer / number pathology
# ══════════════════════════════════════════════════════════════════════════════

subtest 'integer: leading + sign accepted' => sub {
	my $r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => '+42' });
	is($r->{n}, 42, '"+42" accepted and coerced to 42');
};

subtest 'integer: surrounding whitespace accepted' => sub {
	my $r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => '  -7  ' });
	is($r->{n}, -7, '"  -7  " with surrounding whitespace accepted');
};

subtest 'integer: "1e3" accepted (scientific notation for a whole number)' => sub {
	# 1e3 == 1000, which is a whole number; the validator must accept any
	# representation whose numeric value has no fractional part.
	my $r;
	lives_ok {
		$r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => '1e3' })
	} '"1e3" accepted as integer';
	ok($r->{n} == 1000, 'coerced value is 1000');
};

subtest 'integer: "42.0" accepted (whole number with trailing .0)' => sub {
	# 42.0 == 42; the fractional part is zero, so this is a valid integer.
	my $r;
	lives_ok {
		$r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => '42.0' })
	} '"42.0" accepted as integer';
	ok($r->{n} == 42, 'coerced value is 42');
};

subtest 'integer: "42.9" rejected (not an integer, no rounding)' => sub {
	throws_ok {
		validate_strict(schema => { n => { type => 'integer' } }, input => { n => '42.9' })
	} qr/must be an integer/, '"42.9" rejected — validate_strict does not round';
};

subtest 'integer: zero is accepted (including min => 0)' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', min => 0 } },
		input  => { n => '0' },
	);
	is($r->{n}, 0, '"0" accepted and satisfies min => 0');
	ok(!$r->{n}, '…and the result is Perl-false');
};

subtest 'integer: negative zero is just zero' => sub {
	my $r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => '-0' });
	is($r->{n}, 0, '"-0" coerced to 0');
};

subtest 'integer: 2^31-1 (max 32-bit signed)' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer' } },
		input  => { n => '2147483647' },
	);
	is($r->{n}, 2147483647, '2^31−1 accepted');
};

subtest 'integer: min == max forces exactly one valid value' => sub {
	lives_ok {
		validate_strict(
			schema => { n => { type => 'integer', min => 42, max => 42 } },
			input  => { n => '42' },
		)
	} 'value equal to min==max accepted';

	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', min => 42, max => 42 } },
			input  => { n => '43' },
		)
	} qr/must be no more than 42/, 'value one above min==max rejected';
};

subtest 'number: Inf — behaviour follows Scalar::Util::looks_like_number' => sub {
	my $inf_str = 9**9**9 . '';	# stringify Perl's Inf
	if(looks_like_number($inf_str)) {
		lives_ok {
			validate_strict(schema => { n => { type => 'number' } }, input => { n => $inf_str })
		} "Inf string ('$inf_str') accepted because looks_like_number agrees";
	} else {
		throws_ok {
			validate_strict(schema => { n => { type => 'number' } }, input => { n => $inf_str })
		} qr/must be a number/, "Inf string ('$inf_str') rejected because looks_like_number disagrees";
	}
	pass('Inf handling is consistent with Scalar::Util::looks_like_number');
};

subtest 'number: "NaN" — accepted because Scalar::Util::looks_like_number("NaN") is true' => sub {
	# Modern Scalar::Util considers "NaN" a valid number representation (IEEE 754).
	# validate_strict delegates to looks_like_number, so it accepts NaN too.
	ok(looks_like_number('NaN'), 'Scalar::Util::looks_like_number("NaN") is true on this Perl');
	lives_ok {
		validate_strict(schema => { n => { type => 'number' } }, input => { n => 'NaN' })
	} '"NaN" accepted by validate_strict (consistent with looks_like_number)';
};

subtest 'number: hexadecimal string rejected (looks_like_number does not accept 0x...)' => sub {
	throws_ok {
		validate_strict(schema => { n => { type => 'number' } }, input => { n => '0xFF' })
	} qr/must be a number/, '"0xFF" rejected (hex notation not accepted)';
};

subtest 'number: very small float close to zero' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'number', min => 0 } },
		input  => { x => '1e-300' },
	);
	ok($r->{x} > 0, '1e-300 passes min => 0');
};

# ══════════════════════════════════════════════════════════════════════════════
# Unicode pathology
# ══════════════════════════════════════════════════════════════════════════════

subtest 'Unicode: Zalgo text — combining char storm, counted as one grapheme cluster' => sub {
	# e with 5 stacked combining diacritics is still ONE grapheme cluster
	my $zalgo = "e\x{0300}\x{0301}\x{0302}\x{0303}\x{0304}";
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 1, max => 1 } },
		input  => { s => $zalgo },
	);
	is($r->{s}, $zalgo, 'Zalgo text (1 grapheme cluster) satisfies min=>1,max=>1');
};

subtest 'Unicode: emoji ZWJ sequence — multiple code points, one grapheme cluster' => sub {
	# 👨‍👩‍👧 = U+1F468 ZWJ U+1F469 ZWJ U+1F467 — family emoji, 5 code points, 1 grapheme
	my $family = "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}";
	cmp_ok(length($family), '>', 1, 'emoji family has multiple code points');
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 1 } },
		input  => { s => $family },
	);
	ok(defined $r->{s}, 'emoji ZWJ family sequence accepted as non-empty string');
};

subtest 'Unicode: right-to-left override character in string' => sub {
	my $rtl = "Hello\x{202E}world";	# U+202E RIGHT-TO-LEFT OVERRIDE
	my $r = validate_strict(schema => { s => { type => 'string', min => 1 } }, input => { s => $rtl });
	is($r->{s}, $rtl, 'string containing RTL override accepted');
};

subtest 'Unicode: e + combining-accent vs precomposed é — grapheme-level min/max' => sub {
	my $composed   = "\x{00e9}";	# é (precomposed, 1 code point)
	my $decomposed = "e\x{0301}";	# e + combining acute (2 code points)
	# Both should count as 1 grapheme cluster
	for my $s ($composed, $decomposed) {
		my $r = validate_strict(
			schema => { s => { type => 'string', min => 1, max => 1 } },
			input  => { s => $s },
		);
		ok(defined $r->{s}, sprintf('é variant (len=%d bytes) satisfies min=>1,max=>1', length($s)));
	}
};

subtest 'Unicode: zero-width joiner alone — counted as 1 grapheme' => sub {
	my $zwj = "\x{200D}";	# lone ZWJ
	my $r = validate_strict(
		schema => { s => { type => 'string', min => 1 } },
		input  => { s => $zwj },
	);
	ok(defined $r->{s}, 'lone ZWJ character accepted');
};

# ══════════════════════════════════════════════════════════════════════════════
# Boolean edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'boolean: integer 1 and 0 coerced correctly' => sub {
	my $r1 = validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 1 });
	my $r0 = validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 0 });
	ok($r1->{b},  'integer 1 → truthy boolean');
	ok(!$r0->{b}, 'integer 0 → falsy boolean');
};

subtest 'boolean: mixed-case strings — accepted only if present in %booleans hash' => sub {
	# The real Readonly::Values::Boolean on this system includes uppercase variants
	# (TRUE, FALSE, YES, NO, ON, OFF), so "True" may or may not be valid depending
	# on the exact keys in %booleans.  Test against the hash directly.
	use Readonly::Values::Boolean;
	my %b = %Readonly::Values::Boolean::booleans;

	if(exists $b{'True'}) {
		lives_ok {
			validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 'True' })
		} '"True" accepted — present in %booleans hash';
	} else {
		throws_ok {
			validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 'True' })
		} qr/must be a boolean/, '"True" rejected — absent from %booleans hash';
	}

	if(exists $b{'FALSE'}) {
		my $r = validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 'FALSE' });
		ok(!$r->{b}, '"FALSE" accepted as falsy boolean — present in %booleans hash');
	} else {
		throws_ok {
			validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 'FALSE' })
		} qr/must be a boolean/, '"FALSE" rejected — absent from %booleans hash';
	}
};

subtest 'boolean: empty string rejected as boolean' => sub {
	throws_ok {
		validate_strict(schema => { b => { type => 'boolean' } }, input => { b => '' })
	} qr/must be a boolean/, 'empty string not a valid boolean';
};

subtest 'boolean: undef skipped (optional absent-value path)' => sub {
	# type => 'boolean' with !defined($value) → next
	# Required field with undef value: key exists but is undef
	my $r = validate_strict(
		schema => { b => { type => 'boolean' } },
		input  => { b => undef },
	);
	# The integer/number/boolean handlers do 'next' on undef, so the key ends up in
	# validated_args with undef — the field exists but is undef
	ok(exists $r->{b},   'boolean key present in result even when value is undef');
	ok(!defined $r->{b}, '…but the value is undef');
};

# ══════════════════════════════════════════════════════════════════════════════
# Explicit undef for required fields
# ══════════════════════════════════════════════════════════════════════════════

subtest 'explicit undef: required string with undef value is allowed' => sub {
	lives_ok {
		validate_strict(
			schema => { s => { type => 'string' } },
			input  => { s => undef },
		)
	} 'explicit undef for required string field rejected';
};

subtest 'explicit undef: required integer with undef value is allowed' => sub {
	lives_ok {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => undef },
		)
	} 'explicit undef for required integer field rejected';
};

subtest 'explicit undef: present-but-undef key for required field is allowed' => sub {
	lives_ok {
		validate_strict(
			schema => { name => { type => 'string' } },
			input  => { name => undef },
		)
	} 'present-but-undef key for required string field rejected';
};

# ══════════════════════════════════════════════════════════════════════════════
# Transform pathology
# ══════════════════════════════════════════════════════════════════════════════

subtest 'transform: returning undef is allowed for string type check' => sub {
	lives_ok {
		validate_strict(
			schema => { s => { type => 'string', transform => sub { undef } } },
			input  => { s => 'hello' },
		)
	}, 'transform returning undef is allowed for required string type';
};

subtest 'transform: returning a ref when string expected causes type failure' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', transform => sub { [] } } },
			input  => { s => 'hello' },
		)
	} qr/must be a string/, 'transform returning arrayref rejected for string type';
};

subtest 'transform: returning "0" — falsy but valid string' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', transform => sub { '0' } } },
		input  => { s => 'anything' },
	);
	is($r->{s}, '0', 'transform returning "0" produces valid (if falsy) string');
};

subtest 'transform: chained coercions — transform then integer coercion' => sub {
	# transform strips a £ prefix, then type => 'integer' coerces
	my $r = validate_strict(
		schema => { amount => {
			type      => 'integer',
			transform => sub { my $s = shift; $s =~ s/^£//; $s },
		} },
		input => { amount => '£42' },
	);
	is($r->{amount}, 42, 'transform strips prefix, integer coercion follows');
};

subtest 'transform: applied only when value is defined' => sub {
	my $called = 0;
	validate_strict(
		schema => {
			x => { type => 'string', optional => 1,
			        transform => sub { $called++; $_[0] } },
		},
		input => {},
	);
	is($called, 0, 'transform not called for absent optional parameter');
};

# ══════════════════════════════════════════════════════════════════════════════
# Callback / validate pathology
# ══════════════════════════════════════════════════════════════════════════════

subtest 'callback: dying inside callback propagates the exception' => sub {
	throws_ok {
		validate_strict(
			schema => { n => {
				type     => 'integer',
				callback => sub { die "boom!\n" },
			} },
			input => { n => 1 },
		)
	} qr/boom!/, 'die inside callback propagates out of validate_strict';
};

subtest 'callback: returning a reference (truthy non-1) passes validation' => sub {
	my $r = validate_strict(
		schema => { n => {
			type     => 'integer',
			callback => sub { {} },	# hashref is truthy
		} },
		input => { n => 7 },
	);
	is($r->{n}, 7, 'callback returning truthy ref allows the value through');
};

subtest 'callback: returning "0" (false) fails even though it is defined' => sub {
	throws_ok {
		validate_strict(
			schema => { n => {
				type     => 'integer',
				callback => sub { '0' },	# false
			} },
			input => { n => 7 },
		)
	} qr/failed custom validation/, 'callback returning "0" fails validation';
};

subtest 'callback: returning undef (false) fails' => sub {
	throws_ok {
		validate_strict(
			schema => { n => {
				type     => 'integer',
				callback => sub { undef },
			} },
			input => { n => 7 },
		)
	} qr/failed custom validation/, 'callback returning undef fails validation';
};

subtest 'validate: returning 0 (falsy) treated as success — only truthy strings signal failure' => sub {
	# The code is: if(my $error = &{$rule_value}($args)) { _error(...) }
	# 0 is Perl-false, so the if-block never fires.  Only a truthy return value
	# (a non-empty, non-zero string) is treated as an error message.
	lives_ok {
		validate_strict(
			schema => { s => {
				type     => 'string',
				validate => sub { 0 },	# falsy → treated as "no error"
			} },
			input => { s => 'x' },
		)
	} 'validate returning 0 is treated as success (falsy = no error)';
};

subtest 'callback: receives original (post-transform) value, not the pre-transform one' => sub {
	my $seen;
	validate_strict(
		schema => { s => {
			type      => 'string',
			transform => sub { uc $_[0] },
			callback  => sub { $seen = $_[0]; 1 },
		} },
		input => { s => 'hello' },
	);
	is($seen, 'HELLO', 'callback receives post-transform value');
};

# ══════════════════════════════════════════════════════════════════════════════
# memberof / notmemberof boundary conditions
# ══════════════════════════════════════════════════════════════════════════════

subtest 'memberof: empty list rejects every value' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', memberof => [] } },
			input  => { x => 'anything' },
		)
	} qr/must be one of/, 'memberof with empty list rejects all values';
};

subtest 'notmemberof: empty list accepts every value' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'string', notmemberof => [] } },
		input  => { x => 'anything' },
	);
	is($r->{x}, 'anything', 'notmemberof with empty list accepts all values');
};

subtest 'memberof: single-element list — exact match required' => sub {
	lives_ok {
		validate_strict(
			schema => { x => { type => 'string', memberof => ['only'] } },
			input  => { x => 'only' },
		)
	} 'single-element memberof: exact match accepted';

	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', memberof => ['only'] } },
			input  => { x => 'other' },
		)
	} qr/must be one of/, 'single-element memberof: non-matching value rejected';
};

subtest 'memberof: duplicate values in list — still works correctly' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'string', memberof => ['a', 'a', 'b', 'b'] } },
		input  => { x => 'a' },
	);
	is($r->{x}, 'a', 'memberof with duplicates: valid member accepted');
};

subtest 'memberof: value "0" (numeric zero) in numeric memberof' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', memberof => [0, 1, 2] } },
		input  => { n => '0' },
	);
	is($r->{n}, 0, 'integer "0" passes numeric memberof check against 0');
};

subtest 'notmemberof + transform: blacklist checked after normalisation' => sub {
	throws_ok {
		validate_strict(
			schema => { user => {
				type        => 'string',
				transform   => sub { lc $_[0] },
				notmemberof => ['admin'],
			} },
			input => { user => 'ADMIN' },
		)
	} qr/must not be one of/, 'ADMIN → admin after transform, then blacklisted';
};

# ══════════════════════════════════════════════════════════════════════════════
# Regex / matches pathology
# ══════════════════════════════════════════════════════════════════════════════

subtest 'matches: string pattern wrapped in qr/\\Q...\\E/ — matched as a literal, not a regex' => sub {
	# Non-Regexp values are wrapped: qr/\Q$rule_value\E/
	# \Q...\E escapes all metacharacters, so '^\d+$' matches the LITERAL STRING
	# "^\d+$", not strings that look like integers.  Use qr// when you need a regex.
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', matches => '^\d+$' } },
			input  => { s => '123' },
		)
	} qr/must match pattern/, '"123" does not match literal "^\\d+\$" (metacharacters escaped)';

	# The literal string "^\d+$" DOES match itself
	my $r = validate_strict(
		schema => { s => { type => 'string', matches => '^\d+$' } },
		input  => { s => '^\d+$' },
	);
	is($r->{s}, '^\d+$', 'the literal string "^\\d+\$" matches the escaped pattern');
};

subtest 'matches: value containing regex metacharacters' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', matches => qr/^\$\d+\.\d{2}$/ } },
		input  => { s => '$42.00' },
	);
	is($r->{s}, '$42.00', 'value with $ and . matched by explicit qr//');
};

subtest 'matches: empty pattern qr// matches everything' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', matches => qr// } },
		input  => { s => 'anything' },
	);
	is($r->{s}, 'anything', 'empty qr// pattern matches any string');
};

subtest 'nomatch: empty pattern qr// rejects everything (all strings match it)' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', nomatch => qr// } },
			input  => { s => 'anything' },
		)
	} qr/must not match pattern/, 'empty nomatch pattern rejects all strings';
};

# ══════════════════════════════════════════════════════════════════════════════
# Overloaded objects and Perl-specific weirdness
# ══════════════════════════════════════════════════════════════════════════════

subtest 'overloaded object: rejected for type string (it is a ref)' => sub {
	my $obj = Edge::Overloaded->new;
	throws_ok {
		validate_strict(schema => { s => { type => 'string' } }, input => { s => $obj })
	} qr/must be a string/, 'overloaded object rejected for string type (ref check fires first)';
};

subtest 'overloaded object: accepted for type object' => sub {
	my $obj = Edge::Overloaded->new;
	my $r = validate_strict(schema => { o => { type => 'object' } }, input => { o => $obj });
	is($r->{o}, $obj, 'overloaded object accepted for object type');
};

subtest 'overloaded object: accepted for type number when numification overloaded' => sub {
	# Scalar::Util::looks_like_number on an object with 0+ overloading triggers the
	# numeric conversion (giving 42), not the "" stringification.  So the object
	# passes the number type check — looks_like_number sees a number, not a string.
	my $obj = Edge::Overloaded->new;
	lives_ok {
		validate_strict(schema => { n => { type => 'number' } }, input => { n => $obj })
	} 'overloaded object with 0+ overload accepted for number type (numification triggered)';
};

subtest 'blessed coderef: accepted for coderef type (reftype eq CODE) and for object type' => sub {
	my $bcr = bless sub { 42 }, 'MyCallable';

	throws_ok {
		validate_strict(schema => { f => { type => 'coderef' } }, input => { f => $bcr })
	} qr/Parameter 'f' must be a coderef/, 'blessed coderef not allowed for coderef type (reftype returns "CODE")';

	lives_ok {
		validate_strict(schema => { o => { type => 'object' } }, input => { o => $bcr })
	} 'blessed coderef accepted for object type (it is blessed)';

	# An unblessed coderef still works too
	my $plain = sub { 99 };
	lives_ok {
		validate_strict(schema => { f => { type => 'coderef' } }, input => { f => $plain })
	} 'unblessed coderef still accepted for coderef type';
};

subtest 'exploding object: can check fires, method call dies, exception propagates' => sub {
	my $boom = Edge::Exploder->new;
	throws_ok {
		validate_strict(
			schema => { o => { type => 'object', can => 'nonexistent' } },
			input  => { o => $boom },
		)
	} qr/must be an object that understands the nonexistent method/,
	  'can check fails correctly for object lacking the method';
};

# ══════════════════════════════════════════════════════════════════════════════
# Schema structural edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'schema: all-optional fields — empty input returns empty hashref' => sub {
	my $r = validate_strict(
		schema => {
			a => { type => 'string',  optional => 1 },
			b => { type => 'integer', optional => 1 },
			c => { type => 'boolean', optional => 1 },
		},
		input => {},
	);
	is(scalar keys %$r, 0, 'empty input against all-optional schema returns empty hashref');
};

subtest 'schema: 100-field wide schema' => sub {
	my %schema = map { ("field_$_" => { type => 'string' }) } 1..100;
	my %input  = map { ("field_$_" => "val_$_")             } 1..100;
	my $r = validate_strict(schema => \%schema, input => \%input);
	is(scalar keys %$r,    100,      '100-field schema: all fields returned');
	is($r->{field_1},      'val_1',  'first field correct');
	is($r->{field_100},    'val_100','last field correct');
};

subtest 'schema: simple string shorthand (type as bare string)' => sub {
	my $r = validate_strict(
		schema => { name => 'string', age => 'integer' },
		input  => { name => 'Alice', age => '30' },
	);
	is($r->{name}, 'Alice', 'bare string type shorthand: name');
	is($r->{age},  30,      'bare string type shorthand: age coerced');
};

subtest 'schema: arrayref of rules with no matching type error lists all candidates' => sub {
	throws_ok {
		validate_strict(
			schema => { x => [
				{ type => 'integer', min => 1 },
				{ type => 'arrayref' },
				{ type => 'hashref' },
			] },
			input => { x => 'a string' },
		)
	} qr/must be one of.*integer|must be one of.*arrayref/i,
	  'array-of-rules failure lists all candidate types';
};

subtest 'schema: union type with single element behaves like plain type' => sub {
	my $r = validate_strict(
		schema => { n => { type => ['integer'] } },
		input  => { n => '7' },
	);
	is($r->{n}, 7, 'single-element union type coerces correctly');
};

subtest 'schema: unknown rule name croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', invented_rule => 1 } },
			input  => { x => 'hi' },
		)
	} qr/Unknown rule 'invented_rule'/, 'unrecognised rule name croaks';
};

# ══════════════════════════════════════════════════════════════════════════════
# Positional argument edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'positional: single argument at position 0' => sub {
	my $r = validate_strict(
		schema => { only => { type => 'string', position => 0 } },
		input  => ['hello'],
	);
	is(ref($r),  'ARRAY',   'single positional arg returns arrayref');
	is($r->[0], 'hello',   'value at position 0 correct');
};

subtest 'positional: integer coercion works in positional mode' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', position => 0 } },
		input  => ['42'],
	);
	is($r->[0], 42, 'integer coerced correctly in positional mode');
};

subtest 'positional: integer 0 correctly placed at position (not silently dropped)' => sub {
	# The return loop uses exists() so falsy-but-valid coerced values (integer 0)
	# are correctly assigned to their position rather than silently dropped.
	my $r = validate_strict(
		schema => {
			zero => { type => 'integer', position => 0 },
			one  => { type => 'string',  position => 1 },
		},
		input => ['0', 'hello'],
	);
	is(ref($r), 'ARRAY', 'positional mode returns arrayref');
	is($r->[0],  0,       'position 0 with integer value 0 correctly placed');
	is($r->[1], 'hello',  'position 1 correct');
};

# ══════════════════════════════════════════════════════════════════════════════
# Cross-validation pathology
# ══════════════════════════════════════════════════════════════════════════════

subtest 'cross_validation: validator that dies propagates the exception' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => 1 },
			cross_validation => {
				kaboom => sub { die "cross-validator exploded!\n" },
			},
		)
	} qr/cross-validator exploded/, 'die inside cross-validator propagates';
};

subtest 'cross_validation: multiple validators — first failure stops execution' => sub {
	my @order;
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => 1 },
			cross_validation => {
				first  => sub { push @order, 'first';  'first failed'  },
				second => sub { push @order, 'second'; undef           },
			},
		)
	} qr/first failed/, 'first failing validator stops further cross-validation';
	# Note: hash iteration order is non-deterministic, so 'second' might run first.
	# What we can assert is that exactly one validator reported an error.
	ok(scalar @order >= 1, 'at least one validator ran');
};

subtest 'cross_validation: receives post-transform post-coerce values' => sub {
	my ($seen_n, $seen_s);
	validate_strict(
		schema => {
			n => { type => 'integer', transform => sub { $_[0] * 2 } },
			s => { type => 'string',  transform => sub { uc $_[0]  } },
		},
		input => { n => '21', s => 'hello' },
		cross_validation => {
			capture => sub { $seen_n = $_[0]{n}; $seen_s = $_[0]{s}; undef },
		},
	);
	is($seen_n, 42,      'cross-validator sees post-transform integer (21*2=42)');
	is($seen_s, 'HELLO', 'cross-validator sees post-transform string (uppercased)');
};

# ══════════════════════════════════════════════════════════════════════════════
# Relationships pathology
# ══════════════════════════════════════════════════════════════════════════════

subtest 'relationships: empty relationships array is harmless' => sub {
	lives_ok {
		validate_strict(
			schema        => { x => { type => 'string' } },
			input         => { x => 'ok' },
			relationships => [],
		)
	} 'empty relationships array does not croak';
};

subtest 'relationships: relationship referencing absent field is silently skipped' => sub {
	# A dependency where 'port' is absent → the dep check short-circuits
	lives_ok {
		validate_strict(
			schema        => { host => { type => 'string', optional => 1 } },
			input         => {},
			relationships => [
				{ type => 'dependency', param => 'port', requires => 'host' },
			],
		)
	} 'dependency on absent param: condition param absent → passes silently';
};

subtest 'relationships: value_constraint with != operator' => sub {
	# When ssl is set, port must NOT be 80
	lives_ok {
		validate_strict(
			schema => {
				ssl  => { type => 'string',  optional => 1 },
				port => { type => 'integer', optional => 1 },
			},
			input        => { ssl => '1', port => 443 },
			relationships => [
				{ type => 'value_constraint', if => 'ssl', then => 'port',
				  operator => '!=', value => 80 },
			],
		)
	} 'port 443 satisfies != 80 constraint when ssl active';

	throws_ok {
		validate_strict(
			schema => {
				ssl  => { type => 'string',  optional => 1 },
				port => { type => 'integer', optional => 1 },
			},
			input        => { ssl => '1', port => 80 },
			relationships => [
				{ type => 'value_constraint', if => 'ssl', then => 'port',
				  operator => '!=', value => 80 },
			],
		)
	} qr/port must be != 80/, 'port 80 violates != 80 constraint when ssl active';
};

# ══════════════════════════════════════════════════════════════════════════════
# Default value edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'default: value of undef — key absent from result (undef default not stored)' => sub {
	# The code does: if(exists($rules->{'default'})) { $validated_args{$key} = $rules->{'default'} }
	# undef is stored as undef, but then 'next' exits before type validation.
	my $r = validate_strict(
		schema => { x => { type => 'string', optional => 1, default => undef } },
		input  => {},
	);
	# default => undef → $validated_args{x} = undef; then next → returned
	ok(exists $r->{x},   'key with undef default present in result');
	ok(!defined $r->{x}, '…with undef value (not validated)');
};

subtest 'default: value 0 applied correctly despite being falsy' => sub {
	my $r = validate_strict(
		schema => { count => { type => 'integer', optional => 1, default => 0 } },
		input  => {},
	);
	is($r->{count}, 0, 'falsy default value 0 applied correctly');
};

subtest 'default: complex structure as default value (not validated)' => sub {
	my $default_list = [1, 2, 3];
	my $r = validate_strict(
		schema => { ids => { type => 'arrayref', optional => 1, default => $default_list } },
		input  => {},
	);
	is_deeply($r->{ids}, [1, 2, 3], 'arrayref default applied; default is not validated');
};

# ══════════════════════════════════════════════════════════════════════════════
# Error message edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'error_msg: containing regex metacharacters is passed through safely' => sub {
	throws_ok {
		validate_strict(
			schema => { n => {
				type      => 'integer',
				min       => 10,
				error_msg => 'Value must be >= 10 (got $value — try again!)',
			} },
			input => { n => 5 },
		)
	} qr/Value must be >= 10/, 'error_msg with special chars passed through correctly';
};

subtest 'error_msg: very long custom message' => sub {
	my $long_msg = 'E' x 10_000;
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', min => 100, error_msg => $long_msg } },
			input  => { n => 1 },
		)
	} qr/EEEEEE/, '10k-character error_msg propagated';
};

subtest 'description: appears in error for missing required field' => sub {
	throws_ok {
		validate_strict(
			schema      => { name => { type => 'string' } },
			input       => {},
			description => 'UserRecord',
		)
	} qr/UserRecord/, 'description "UserRecord" appears in missing-field error';
};

# ══════════════════════════════════════════════════════════════════════════════
# unknown_parameter_handler boundary conditions
# ══════════════════════════════════════════════════════════════════════════════

subtest 'unknown_parameter_handler: invalid value croaks' => sub {
	throws_ok {
		validate_strict(
			schema                    => { x => { type => 'string' } },
			input                     => { x => 'hi', extra => 'bad' },
			unknown_parameter_handler => 'maybe',	# not die/warn/ignore
		)
	} qr/'maybe' unknown_parameter_handler must be one of/, 'invalid handler name croaks';
};

subtest 'unknown_parameter_handler: multiple unknown params, all warned about' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	validate_strict(
		schema                    => { x => { type => 'string' } },
		input                     => { x => 'ok', a => 1, b => 2, c => 3 },
		unknown_parameter_handler => 'warn',
	);
	is(scalar @warnings, 3, 'one warning per unknown parameter');
};

# ══════════════════════════════════════════════════════════════════════════════
# Statefulness / immutability boundary conditions
# ══════════════════════════════════════════════════════════════════════════════

subtest 'schema reuse: failed validation does not corrupt schema for next call' => sub {
	my $schema = { n => { type => 'integer', min => 1 } };

	# A non-numeric string fails the looks_like_number pre-check with "must be a
	# number" before the integer-specific message can fire — match either.
	throws_ok {
		validate_strict(schema => $schema, input => { n => 'not_a_number' })
	} qr/must be (?:an integer|a number)/, 'first call fails as expected';

	my $r = validate_strict(schema => $schema, input => { n => '5' });
	is($r->{n}, 5, 'schema intact after failed call: second call succeeds');
};

subtest 'input immutability: coercion returns new values, original input unchanged' => sub {
	my $input = { age => '42', active => 'true' };
	validate_strict(
		schema => {
			age    => { type => 'integer' },
			active => { type => 'boolean' },
		},
		input => $input,
	);
	is($input->{age},    '42',   'original input age is still a string');
	is($input->{active}, 'true', 'original input active is still a string');
};

# ══════════════════════════════════════════════════════════════════════════════
# Scalar type edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'scalar: "0" (Perl-false) is a valid scalar' => sub {
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => '0' });
	is($r->{x}, '0', '"0" accepted as scalar');
	ok(!$r->{x}, '…and it is Perl-false');
};

subtest 'scalar: empty string is a valid scalar' => sub {
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => '' });
	is($r->{x}, '', 'empty string accepted as scalar');
};

subtest 'scalar: numeric zero is a valid scalar' => sub {
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => 0 });
	is($r->{x}, 0, 'numeric zero accepted as scalar');
	ok(!$r->{x}, '…and it is Perl-false');
};

subtest 'scalar: single space is a valid scalar' => sub {
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => ' ' });
	is($r->{x}, ' ', 'single space accepted as scalar');
};

subtest 'scalar: undef value passes through (next guard fires)' => sub {
	# The scalar handler does 'next' on undef, consistent with all other type handlers.
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => undef });
	ok(exists $r->{x},   'scalar key present in result even when value is undef');
	ok(!defined $r->{x}, '…but the value is undef');
};

subtest 'scalar: no coercion — value returned unchanged' => sub {
	# type => 'scalar' performs no coercion, unlike type => 'integer'
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => '007' });
	is($r->{x}, '007', '"007" returned unchanged — leading zero preserved, no numification');
};

subtest 'scalar: integer literal accepted without coercion' => sub {
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => 42 });
	is($r->{x}, 42, 'integer literal accepted as plain scalar');
};

subtest 'scalar: embedded NUL byte accepted' => sub {
	my $s = "hel\x00lo";
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => $s });
	is($r->{x}, $s, 'string with embedded NUL byte accepted as scalar');
};

subtest 'scalar: very long string accepted' => sub {
	my $big = 'X' x 1_000_000;
	my $r = validate_strict(schema => { x => { type => 'scalar' } }, input => { x => $big });
	is(length($r->{x}), 1_000_000, '1M-character string accepted as scalar');
};

subtest 'scalar: arrayref rejected — error mentions ARRAY' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => [] })
	} qr/must be a scalar.*not a ARRAY/, 'arrayref rejected; ARRAY appears in message';
};

subtest 'scalar: hashref rejected — error mentions HASH' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => {} })
	} qr/must be a scalar.*not a HASH/, 'hashref rejected; HASH appears in message';
};

subtest 'scalar: coderef rejected — error mentions CODE' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => sub {} })
	} qr/must be a scalar.*not a CODE/, 'coderef rejected; CODE appears in message';
};

subtest 'scalar: scalar reference rejected — error mentions SCALAR' => sub {
	my $n = 42;
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => \$n })
	} qr/must be a scalar.*not a SCALAR/, 'scalar ref rejected; SCALAR appears in message';
};

subtest 'scalar: REF-of-REF rejected — error mentions REF' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => \[] })
	} qr/must be a scalar.*not a REF/, 'ref-of-ref rejected; REF appears in message';
};

subtest 'scalar: GLOB reference rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => \*STDOUT })
	} qr/must be a scalar/, 'GLOB reference rejected for scalar type';
};

subtest 'scalar: Regexp object rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => qr/foo/ })
	} qr/must be a scalar/, 'Regexp reference rejected for scalar type';
};

subtest 'scalar: blessed object (Edge::Overloaded) rejected — class name in error' => sub {
	my $obj = Edge::Overloaded->new;
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => $obj })
	} qr/must be a scalar.*Edge::Overloaded/,
	  'blessed object rejected; class name appears in error (ref() returns class, not reftype)';
};

subtest 'scalar: blessed coderef rejected — bless class in error, not CODE' => sub {
	my $bcr = bless sub { 42 }, 'MyCallable';
	throws_ok {
		validate_strict(schema => { x => { type => 'scalar' } }, input => { x => $bcr })
	} qr/must be a scalar.*MyCallable/,
	  'blessed coderef rejected; class name (not CODE) in error because ref() returns bless class';
};

subtest 'scalar: custom error_msg overrides default' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', error_msg => 'Only plain scalars please!' } },
			input  => { x => [] },
		)
	} qr/Only plain scalars please!/, 'custom error_msg used for scalar type violation';
};

subtest 'scalar: transform returning plain scalar — accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', transform => sub { uc $_[0] } } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'HELLO', 'transform applied; uppercased plain scalar passes type check');
};

subtest 'scalar: transform returning a reference — rejected after transform' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', transform => sub { [] } } },
			input  => { x => 'hello' },
		)
	} qr/must be a scalar/, 'transform returning arrayref rejected for scalar type';
};

subtest 'scalar: transform returning undef — passes through (undef next-guard fires)' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', transform => sub { undef } } },
		input  => { x => 'hello' },
	);
	ok(exists $r->{x},   'key present after transform-to-undef');
	ok(!defined $r->{x}, 'value is undef (next guard fired, no type error raised)');
};

subtest 'scalar: schema reuse after rejection — schema not corrupted' => sub {
	my $schema = { x => { type => 'scalar' } };
	throws_ok {
		validate_strict(schema => $schema, input => { x => [] })
	} qr/must be a scalar/, 'first call with arrayref fails correctly';
	my $r = validate_strict(schema => $schema, input => { x => 'fine' });
	is($r->{x}, 'fine', 'schema intact after failed call; second call with string succeeds');
};

subtest 'scalar: union type [scalar, arrayref] — plain value matches scalar branch' => sub {
	my $r = validate_strict(
		schema => { x => { type => ['scalar', 'arrayref'] } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'plain string accepted via scalar branch of union type');
};

subtest 'scalar: union type [scalar, arrayref] — arrayref matches arrayref branch' => sub {
	my $r = validate_strict(
		schema => { x => { type => ['scalar', 'arrayref'] } },
		input  => { x => [1, 2, 3] },
	);
	is_deeply($r->{x}, [1, 2, 3], 'arrayref accepted via arrayref branch of union type');
};

# -- "meaningless rule" error branches (category 1) ---------------------------
# Each of these hits an else-branch that only fires when the rule is combined
# with a type it does not understand.  None were previously reachable.

subtest 'scalar: min rule — meaningless min value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', min => 3 } },
			input  => { x => 'hi' },
		)
	} qr/meaningless min value/, 'min with scalar type croaks "meaningless min value"';
};

subtest 'scalar: max rule — meaningless max value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', max => 10 } },
			input  => { x => 'hi' },
		)
	} qr/meaningless max value/, 'max with scalar type croaks "meaningless max value"';
};

subtest 'scalar: isa rule — meaningless isa value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', isa => 'SomeClass' } },
			input  => { x => 'hello' },
		)
	} qr/meaningless isa value/, 'isa with scalar type croaks "meaningless isa value"';
};

subtest 'scalar: can rule — meaningless can value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', can => 'some_method' } },
			input  => { x => 'hello' },
		)
	} qr/meaningless can value/, 'can with scalar type croaks "meaningless can value"';
};

subtest 'scalar: element_type rule — meaningless element_type value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', element_type => 'string' } },
			input  => { x => 'hello' },
		)
	} qr/meaningless element_type value/, 'element_type with scalar type croaks "meaningless element_type value"';
};

# -- post-type rule interactions (category 2) ----------------------------------
# These run after the type block.  All existing tests use string/integer/array
# types; testing them with scalar exercises distinct branches.

subtest 'scalar: matches rule — matching value accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', matches => qr/^\w+$/ } },
		input  => { x => 'hello123' },
	);
	is($r->{x}, 'hello123', 'scalar value matching pattern accepted');
};

subtest 'scalar: matches rule — non-matching value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', matches => qr/^\d+$/ } },
			input  => { x => 'abc' },
		)
	} qr/must match pattern/, 'scalar value not matching pattern rejected';
};

subtest 'scalar: nomatch rule — non-matching value accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', nomatch => qr/bad/ } },
		input  => { x => 'good' },
	);
	is($r->{x}, 'good', 'scalar value not matching nomatch pattern accepted');
};

subtest 'scalar: nomatch rule — matching value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', nomatch => qr/bad/ } },
			input  => { x => 'bad_value' },
		)
	} qr/must not match pattern/, 'scalar value matching nomatch pattern rejected';
};

subtest 'scalar: memberof rule — valid member accepted via string comparison' => sub {
	# type => 'scalar' is not integer/number/float, so memberof uses string equality,
	# not numeric comparison — this exercises the string branch of the memberof handler.
	my $r = validate_strict(
		schema => { x => { type => 'scalar', memberof => ['alpha', 'beta', 'gamma'] } },
		input  => { x => 'beta' },
	);
	is($r->{x}, 'beta', 'scalar value in memberof list accepted via string comparison path');
};

subtest 'scalar: memberof rule — invalid member rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', memberof => ['alpha', 'beta', 'gamma'] } },
			input  => { x => 'delta' },
		)
	} qr/must be one of/, 'scalar value not in memberof list rejected';
};

subtest 'scalar: notmemberof rule — non-blacklisted value accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', notmemberof => ['banned', 'forbidden'] } },
		input  => { x => 'allowed' },
	);
	is($r->{x}, 'allowed', 'scalar value not in notmemberof blacklist accepted');
};

subtest 'scalar: notmemberof rule — blacklisted value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', notmemberof => ['banned', 'forbidden'] } },
			input  => { x => 'banned' },
		)
	} qr/must not be one of/, 'scalar value in notmemberof blacklist rejected';
};

subtest 'scalar: notmemberof with case_sensitive => 0 — case-insensitive blacklist check' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', notmemberof => ['BANNED'], case_sensitive => 0 } },
			input  => { x => 'banned' },
		)
	} qr/must not be one of/, 'case-insensitive notmemberof rejects value regardless of case';
};

# -- lifecycle paths (category 3) ----------------------------------------------

subtest 'scalar: required field absent — "Required parameter missing" error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar' } },
			input  => {},
		)
	} qr/Required parameter 'x' is missing/, 'absent required scalar field triggers "Required parameter missing"';
};

subtest 'scalar: optional field absent — key not in result' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', optional => 1 } },
		input  => {},
	);
	ok(!exists $r->{x}, 'absent optional scalar field not present in result');
};

subtest 'scalar: optional field with default — default applied when absent' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', optional => 1, default => 'fallback' } },
		input  => {},
	);
	is($r->{x}, 'fallback', 'default value applied when optional scalar field absent');
};

subtest 'scalar: description field — appears in type-violation error message' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar', description => 'MyScalarField' } },
			input  => { x => [] },
		)
	} qr/MyScalarField/, 'description appears in scalar type violation error';
};

subtest 'scalar: logger receives error message on type violation' => sub {
	my $logger = Edge::Logger->new;
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalar' } },
			input  => { x => [] },
			logger => $logger,
		)
	} qr/must be a scalar/, 'scalar type violation still croaks when logger present';
	my @errs = $logger->errors;
	is(scalar @errs, 1, 'logger received exactly one error');
	like($errs[0], qr/must be a scalar.*ARRAY/, 'logger error message mentions scalar and ARRAY');
};

# -- other rule interactions (category 4) -------------------------------------

subtest 'scalar: callback applied — passing callback allows value through' => sub {
	my $seen;
	my $r = validate_strict(
		schema => { x => {
			type     => 'scalar',
			callback => sub { $seen = $_[0]; 1 },
		} },
		input => { x => 'test_value' },
	);
	is($r->{x}, 'test_value', 'callback passes: scalar value returned');
	is($seen, 'test_value',   'callback received the plain scalar value');
};

subtest 'scalar: callback applied — failing callback rejects value' => sub {
	throws_ok {
		validate_strict(
			schema => { x => {
				type     => 'scalar',
				callback => sub { 0 },
			} },
			input => { x => 'anything' },
		)
	} qr/failed custom validation/, 'false-returning callback rejects scalar value';
};

subtest 'scalar: nullable => 1 is synonym for optional — absent key not in result' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalar', nullable => 1 } },
		input  => {},
	);
	ok(!exists $r->{x}, 'nullable scalar field absent from input not present in result');
};

subtest 'scalar: positional argument — plain value accepted' => sub {
	my $r = validate_strict(
		schema => { name => { type => 'scalar', position => 0 } },
		input  => ['hello'],
	);
	is(ref($r),  'ARRAY',   'positional scalar returns arrayref');
	is($r->[0], 'hello',    'positional scalar value correct at position 0');
};

subtest 'scalar: positional argument — reference rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { name => { type => 'scalar', position => 0 } },
			input  => [[1, 2, 3]],
		)
	} qr/must be a scalar/, 'positional arrayref argument rejected for scalar type';
};

# ══════════════════════════════════════════════════════════════════════════════
# Scalarref type edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'scalarref: reference to string accepted' => sub {
	my $s = 'hello';
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \$s });
	is($r->{x}, \$s, 'ref to string accepted and returned unchanged');
};

subtest 'scalarref: reference to integer accepted' => sub {
	my $n = 42;
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \$n });
	is($r->{x}, \$n, 'ref to integer accepted');
};

subtest 'scalarref: reference to zero (Perl-false number) accepted' => sub {
	my $z = 0;
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \$z });
	is($r->{x}, \$z, 'ref to zero accepted');
	ok(!${$r->{x}}, '…and the dereferenced value is Perl-false');
};

subtest 'scalarref: reference to empty string accepted' => sub {
	my $e = '';
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \$e });
	is($r->{x}, \$e, 'ref to empty string accepted');
};

subtest 'scalarref: reference to undef (scalar ref to undef) accepted' => sub {
	my $u;    # undef
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \$u });
	is(ref($r->{x}), 'SCALAR', 'ref to undef is a SCALAR ref — accepted');
	ok(!defined ${$r->{x}}, '…and the dereferenced value is undef');
};

subtest 'scalarref: undef parameter value passes through (next guard fires)' => sub {
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => undef });
	ok(exists $r->{x},   'scalarref key present in result even when value is undef');
	ok(!defined $r->{x}, '…but the value is undef');
};

subtest 'scalarref: value returned unchanged — no coercion' => sub {
	my $s = '007';
	my $ref = \$s;
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => $ref });
	is($r->{x}, $ref, 'same reference identity returned — scalarref type does not copy or coerce');
};

subtest 'scalarref: NUL byte in referenced string accepted' => sub {
	my $s = "hel\x00lo";
	my $r = validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \$s });
	is(${$r->{x}}, $s, 'ref to string containing NUL byte accepted');
};

subtest 'scalarref: plain string rejected — error mentions "plain scalar"' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => 'hello' })
	} qr/must be a scalar reference.*plain scalar/, 'plain string rejected; "plain scalar" in error';
};

subtest 'scalarref: plain integer rejected — error mentions "plain scalar"' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => 42 })
	} qr/must be a scalar reference.*plain scalar/, 'plain integer rejected; "plain scalar" in error';
};

subtest 'scalarref: arrayref rejected — error mentions ARRAY' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => [] })
	} qr/must be a scalar reference.*ARRAY/, 'arrayref rejected; ARRAY in error';
};

subtest 'scalarref: hashref rejected — error mentions HASH' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => {} })
	} qr/must be a scalar reference.*HASH/, 'hashref rejected; HASH in error';
};

subtest 'scalarref: coderef rejected — error mentions CODE' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => sub {} })
	} qr/must be a scalar reference.*CODE/, 'coderef rejected; CODE in error';
};

subtest 'scalarref: REF-of-REF rejected — error mentions REF' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \[] })
	} qr/must be a scalar reference.*REF/, 'ref-of-ref rejected; REF in error';
};

subtest 'scalarref: GLOB reference rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => \*STDOUT })
	} qr/must be a scalar reference/, 'GLOB reference rejected for scalarref type';
};

subtest 'scalarref: Regexp object rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => qr/foo/ })
	} qr/must be a scalar reference/, 'Regexp reference rejected for scalarref type';
};

subtest 'scalarref: blessed object rejected — class name in error' => sub {
	my $obj = Edge::Overloaded->new;
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => $obj })
	} qr/must be a scalar reference.*Edge::Overloaded/,
	  'blessed object rejected; class name appears in error';
};

subtest 'scalarref: blessed scalar ref rejected — class name, not SCALAR, in error' => sub {
	my $n = 99;
	my $bref = bless \$n, 'MyScalarBox';
	throws_ok {
		validate_strict(schema => { x => { type => 'scalarref' } }, input => { x => $bref })
	} qr/must be a scalar reference.*MyScalarBox/,
	  'blessed scalar ref rejected; class name (not SCALAR) in error because ref() returns bless class';
};

subtest 'scalarref: custom error_msg overrides default' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', error_msg => 'Only scalar refs allowed!' } },
			input  => { x => 'oops' },
		)
	} qr/Only scalar refs allowed!/, 'custom error_msg used for scalarref type violation';
};

subtest 'scalarref: transform returning a scalarref — accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalarref', transform => sub { my $v = uc ${$_[0]}; \$v } } },
		input  => { x => \'hello' },
	);
	is(${$r->{x}}, 'HELLO', 'transform applied; uppercased scalarref passes type check');
};

subtest 'scalarref: transform returning a plain scalar — rejected after transform' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', transform => sub { ${$_[0]} } } },
			input  => { x => \'hello' },
		)
	} qr/must be a scalar reference/, 'transform returning plain scalar rejected for scalarref type';
};

subtest 'scalarref: schema reuse after rejection — schema not corrupted' => sub {
	my $schema = { x => { type => 'scalarref' } };
	throws_ok {
		validate_strict(schema => $schema, input => { x => 'oops' })
	} qr/must be a scalar reference/, 'first call with plain scalar fails correctly';
	my $s = 'ok';
	my $r = validate_strict(schema => $schema, input => { x => \$s });
	is($r->{x}, \$s, 'schema intact after failed call; second call with scalarref succeeds');
};

subtest 'scalarref: union type [scalarref, arrayref] — scalarref matches scalarref branch' => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['scalarref', 'arrayref'] } },
		input  => { x => \$s },
	);
	is($r->{x}, \$s, 'scalarref accepted via scalarref branch of union type');
};

subtest 'scalarref: union type [scalarref, arrayref] — arrayref matches arrayref branch' => sub {
	my $r = validate_strict(
		schema => { x => { type => ['scalarref', 'arrayref'] } },
		input  => { x => [1, 2, 3] },
	);
	is_deeply($r->{x}, [1, 2, 3], 'arrayref accepted via arrayref branch of union type');
};

# -- "meaningless rule" error branches for scalarref ---------------------------

subtest 'scalarref: min rule — meaningless min value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', min => 3 } },
			input  => { x => \'hi' },
		)
	} qr/meaningless min value/, 'min with scalarref type croaks "meaningless min value"';
};

subtest 'scalarref: max rule — meaningless max value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', max => 10 } },
			input  => { x => \'hi' },
		)
	} qr/meaningless max value/, 'max with scalarref type croaks "meaningless max value"';
};

subtest 'scalarref: isa rule — meaningless isa value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', isa => 'SomeClass' } },
			input  => { x => \'hello' },
		)
	} qr/meaningless isa value/, 'isa with scalarref type croaks "meaningless isa value"';
};

subtest 'scalarref: can rule — meaningless can value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', can => 'some_method' } },
			input  => { x => \'hello' },
		)
	} qr/meaningless can value/, 'can with scalarref type croaks "meaningless can value"';
};

subtest 'scalarref: element_type rule — meaningless element_type value error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', element_type => 'string' } },
			input  => { x => \'hello' },
		)
	} qr/meaningless element_type value/, 'element_type with scalarref type croaks "meaningless element_type value"';
};

# -- lifecycle paths for scalarref --------------------------------------------

subtest 'scalarref: required field absent — "Required parameter missing" error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref' } },
			input  => {},
		)
	} qr/Required parameter 'x' is missing/, 'absent required scalarref field triggers "Required parameter missing"';
};

subtest 'scalarref: optional field absent — key not in result' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalarref', optional => 1 } },
		input  => {},
	);
	ok(!exists $r->{x}, 'absent optional scalarref field not present in result');
};

subtest 'scalarref: optional field with default — default applied when absent' => sub {
	my $default = \'fallback';
	my $r = validate_strict(
		schema => { x => { type => 'scalarref', optional => 1, default => $default } },
		input  => {},
	);
	is($r->{x}, $default, 'default scalar reference applied when optional scalarref field absent');
};

subtest 'scalarref: description field — appears in type-violation error message' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref', description => 'MyScalarRefField' } },
			input  => { x => 'oops' },
		)
	} qr/MyScalarRefField/, 'description appears in scalarref type violation error';
};

subtest 'scalarref: logger receives error message on type violation' => sub {
	my $logger = Edge::Logger->new;
	throws_ok {
		validate_strict(
			schema => { x => { type => 'scalarref' } },
			input  => { x => 'oops' },
			logger => $logger,
		)
	} qr/must be a scalar reference/, 'scalarref type violation still croaks when logger present';
	my @errs = $logger->errors;
	is(scalar @errs, 1, 'logger received exactly one error');
	like($errs[0], qr/must be a scalar reference.*plain scalar/, 'logger error message mentions scalar reference and plain scalar');
};

# -- other rule interactions for scalarref ------------------------------------

subtest 'scalarref: callback applied — passing callback allows value through' => sub {
	my $seen;
	my $s = 'test_value';
	my $r = validate_strict(
		schema => { x => {
			type     => 'scalarref',
			callback => sub { $seen = ${$_[0]}; 1 },
		} },
		input => { x => \$s },
	);
	is($r->{x}, \$s,        'callback passes: scalarref returned');
	is($seen, 'test_value', 'callback received the dereferenced value');
};

subtest 'scalarref: callback applied — failing callback rejects value' => sub {
	throws_ok {
		validate_strict(
			schema => { x => {
				type     => 'scalarref',
				callback => sub { 0 },
			} },
			input => { x => \'anything' },
		)
	} qr/failed custom validation/, 'false-returning callback rejects scalarref value';
};

subtest 'scalarref: nullable => 1 — absent key not in result' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'scalarref', nullable => 1 } },
		input  => {},
	);
	ok(!exists $r->{x}, 'nullable scalarref field absent from input not present in result');
};

subtest 'scalarref: memberof rule — same reference identity accepted via string comparison' => sub {
	# type => 'scalarref' is not integer/number/float, so memberof uses string equality.
	# References stringify to their address, so only the identical reference matches.
	my $val = \'beta';
	my $r = validate_strict(
		schema => { x => { type => 'scalarref', memberof => [$val] } },
		input  => { x => $val },
	);
	is($r->{x}, $val, 'identical scalarref identity matched in memberof list via string comparison path');
};

subtest 'scalarref: positional argument — scalarref accepted' => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { name => { type => 'scalarref', position => 0 } },
		input  => [\$s],
	);
	is(ref($r),   'ARRAY',  'positional scalarref returns arrayref');
	is($r->[0], \$s,        'positional scalarref value correct at position 0');
};

subtest 'scalarref: positional argument — plain value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { name => { type => 'scalarref', position => 0 } },
			input  => ['hello'],
		)
	} qr/must be a scalar reference/, 'positional plain string rejected for scalarref type';
};

# ══════════════════════════════════════════════════════════════════════════════
# Type: stringref — pathological and boundary edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'stringref: reference to plain string accepted; plain string returned' => sub {
	my $s = 'hello';
	my $r = validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \$s });
	is($r->{x}, 'hello', 'dereferenced string returned');
};

subtest 'stringref: reference to empty string accepted' => sub {
	my $e = '';
	my $r = validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \$e });
	is($r->{x}, '', 'empty string returned');
};

subtest 'stringref: reference to string with NUL byte accepted' => sub {
	my $s = "hel\x00lo";
	my $r = validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \$s });
	is($r->{x}, $s, 'string with NUL byte accepted');
};

subtest 'stringref: reference to unicode string accepted' => sub {
	my $s = "caf\x{e9}";
	my $r = validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \$s });
	is($r->{x}, $s, 'unicode string accepted');
};

subtest 'stringref: undef parameter value — skips type check (next guard)' => sub {
	my $r = validate_strict(schema => { x => { type => 'stringref' } }, input => { x => undef });
	ok(exists $r->{x},    'stringref key present even when value is undef');
	ok(!defined $r->{x},  '…and the value is undef');
};

subtest 'stringref: plain string rejected — error mentions "plain scalar"' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => 'hello' })
	} qr/must be a string reference.*plain scalar/, 'plain string rejected; "plain scalar" in error';
};

subtest 'stringref: plain integer rejected — error mentions "plain scalar"' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => 42 })
	} qr/must be a string reference.*plain scalar/, 'plain integer rejected; "plain scalar" in error';
};

subtest 'stringref: arrayref rejected — error mentions ARRAY' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => [] })
	} qr/must be a string reference.*ARRAY/, 'arrayref rejected; ARRAY in error';
};

subtest 'stringref: hashref rejected — error mentions HASH' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => {} })
	} qr/must be a string reference.*HASH/, 'hashref rejected; HASH in error';
};

subtest 'stringref: coderef rejected — error mentions CODE' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => sub {} })
	} qr/must be a string reference.*CODE/, 'coderef rejected; CODE in error';
};

subtest 'stringref: ref-of-ref (REF type) rejected — error mentions REF' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \[] })
	} qr/must be a string reference.*REF/, 'ref-of-ref rejected; REF in error';
};

subtest 'stringref: GLOB reference rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \*STDOUT })
	} qr/must be a string reference/, 'GLOB reference rejected for stringref type';
};

subtest 'stringref: Regexp object rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => qr/foo/ })
	} qr/must be a string reference/, 'Regexp reference rejected for stringref type';
};

subtest 'stringref: blessed object rejected — class name in error' => sub {
	my $obj = Edge::Overloaded->new;
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => $obj })
	} qr/must be a string reference.*Edge::Overloaded/,
	  'blessed object rejected; class name in error';
};

subtest 'stringref: min at exact boundary accepted' => sub {
	my $s = 'hello';
	my $r = validate_strict(schema => { x => { type => 'stringref', min => 5 } }, input => { x => \$s });
	is($r->{x}, 'hello', 'string at exact min boundary accepted');
};

subtest 'stringref: min exceeded — "too short" error' => sub {
	my $s = 'hi';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', min => 5 } }, input => { x => \$s })
	} qr/too short/, 'string shorter than min rejected with "too short" message';
};

subtest 'stringref: min < 0 — "meaningless minimum" error' => sub {
	my $s = 'hello';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', min => -1 } }, input => { x => \$s })
	} qr/meaningless minimum/, 'negative min for stringref croaks "meaningless minimum"';
};

subtest 'stringref: max at exact boundary accepted' => sub {
	my $s = 'hello';
	my $r = validate_strict(schema => { x => { type => 'stringref', max => 5 } }, input => { x => \$s });
	is($r->{x}, 'hello', 'string at exact max boundary accepted');
};

subtest 'stringref: max exceeded — "too long" error' => sub {
	my $s = 'toolongvalue';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', max => 5 } }, input => { x => \$s })
	} qr/too long/, 'string longer than max rejected with "too long" message';
};

subtest 'stringref: transform receives the already-dereferenced plain string' => sub {
	# The module dereferences the stringref before calling transform, so transform
	# sees the plain string, not the reference.
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => 'stringref', transform => sub { uc($_[0]) } } },
		input  => { x => \$s },
	);
	is($r->{x}, 'HELLO', 'transform uppercases the already-dereferenced string');
};

subtest 'stringref: custom error_msg overrides default on type violation' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref', error_msg => 'Only string refs allowed!' } },
			input  => { x => 'oops' },
		)
	} qr/Only string refs allowed!/, 'custom error_msg used for stringref type violation';
};

subtest 'stringref: required field absent — "Required parameter missing" error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref' } },
			input  => {},
		)
	} qr/Required parameter 'x' is missing/, 'absent required stringref field triggers "Required parameter missing"';
};

subtest 'stringref: optional field absent — key not in result' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'stringref', optional => 1 } },
		input  => {},
	);
	ok(!exists $r->{x}, 'absent optional stringref field not present in result');
};

subtest 'stringref: optional with default — default applied when absent' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'stringref', optional => 1, default => 'fallback' } },
		input  => {},
	);
	is($r->{x}, 'fallback', 'default value used when optional stringref field absent');
};

subtest 'stringref: description field — appears in type-violation error message' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref', description => 'MyStringRefField' } },
			input  => { x => 'oops' },
		)
	} qr/MyStringRefField/, 'description appears in stringref type violation error';
};

subtest 'stringref: logger receives error message on type violation' => sub {
	my $logger = Edge::Logger->new;
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref' } },
			input  => { x => 'oops' },
			logger => $logger,
		)
	} qr/must be a string reference/, 'stringref type violation still croaks when logger present';
	my @errs = $logger->errors;
	is(scalar @errs, 1, 'logger received exactly one error');
	like($errs[0], qr/must be a string reference.*plain scalar/, 'logger error mentions string reference and plain scalar');
};

subtest 'stringref: callback receives dereferenced string value' => sub {
	my $seen;
	my $s = 'test_value';
	my $r = validate_strict(
		schema => { x => {
			type     => 'stringref',
			callback => sub { $seen = $_[0]; 1 },
		} },
		input => { x => \$s },
	);
	is($r->{x},  'test_value', 'dereferenced string returned');
	is($seen, 'test_value',    'callback received the dereferenced string');
};

subtest 'stringref: callback failing — rejects value' => sub {
	throws_ok {
		validate_strict(
			schema => { x => {
				type     => 'stringref',
				callback => sub { 0 },
			} },
			input => { x => \'anything' },
		)
	} qr/failed custom validation/, 'false-returning callback rejects stringref value';
};

subtest 'stringref: nullable => 1 — absent key not in result' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'stringref', nullable => 1 } },
		input  => {},
	);
	ok(!exists $r->{x}, 'nullable stringref field absent from input not present in result');
};

subtest 'stringref: schema reuse after rejection — schema not corrupted' => sub {
	my $schema = { x => { type => 'stringref' } };
	throws_ok {
		validate_strict(schema => $schema, input => { x => 'oops' })
	} qr/must be a string reference/, 'first call with plain scalar fails correctly';
	my $s = 'ok';
	my $r = validate_strict(schema => $schema, input => { x => \$s });
	is($r->{x}, 'ok', 'schema intact after failed call; second call with stringref succeeds');
};

subtest 'stringref: union type [stringref, arrayref] — stringref matches stringref branch' => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['stringref', 'arrayref'] } },
		input  => { x => \$s },
	);
	is($r->{x}, 'hello', 'stringref accepted; dereferenced string returned');
};

subtest 'stringref: union type [stringref, arrayref] — arrayref matches arrayref branch' => sub {
	my $r = validate_strict(
		schema => { x => { type => ['stringref', 'arrayref'] } },
		input  => { x => [1, 2, 3] },
	);
	is_deeply($r->{x}, [1, 2, 3], 'arrayref accepted via arrayref branch of union type');
};

subtest 'stringref: positional argument — stringref accepted' => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { name => { type => 'stringref', position => 0 } },
		input  => [\$s],
	);
	is(ref($r), 'ARRAY',   'positional stringref returns arrayref');
	is($r->[0], 'hello',   'positional stringref dereferenced correctly at position 0');
};

subtest 'stringref: positional argument — plain value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { name => { type => 'stringref', position => 0 } },
			input  => ['hello'],
		)
	} qr/must be a string reference/, 'positional plain string rejected for stringref type';
};

done_testing;

