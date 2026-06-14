#!/usr/bin/env perl

# Extended tests — systematically targeting every branch pair and linear code
# sequence not already exercised by the other four test files.
# Organised by code section to maximise LCSAJ / TER3 scores.

use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(blessed);

use Params::Validate::Strict qw(validate_strict);

# ── Test-support classes ──────────────────────────────────────────────────────
{ package Ext::Logger; sub new { bless {e=>[],w=>[]}, shift }
  sub error { push @{$_[0]{e}}, join('',@_[1..$#_]) }
  sub warn  { push @{$_[0]{w}}, join('',@_[1..$#_]) }
  sub errors { $_[0]{e} } sub warns { $_[0]{w} } }
{ package Ext::Base; sub new { bless {}, shift } }
{ package Ext::Child; our @ISA = ('Ext::Base'); sub new { bless {}, shift } }

# ══════════════════════════════════════════════════════════════════════════════
# Type alias coverage  (int / str / num / double / bool)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'type alias: int accepted and coerces like integer' => sub {
	my $r = validate_strict(schema => { n => { type => 'int' } }, input => { n => '7' });
	is($r->{n}, 7, '"int" alias: value coerced to integer');
};

subtest 'type alias: str accepted like string' => sub {
	my $r = validate_strict(schema => { s => { type => 'str' } }, input => { s => 'hi' });
	is($r->{s}, 'hi', '"str" alias: string value returned');
};

subtest 'type alias: num accepted and coerces like number' => sub {
	my $r = validate_strict(schema => { n => { type => 'num' } }, input => { n => '3.14' });
	ok(abs($r->{n} - 3.14) < 1e-9, '"num" alias: coerced to float');
};

subtest 'type alias: double accepted and coerces like number' => sub {
	my $r = validate_strict(schema => { n => { type => 'double' } }, input => { n => '2.718' });
	ok(abs($r->{n} - 2.718) < 1e-9, '"double" alias: coerced to float');
};

subtest 'type alias: bool accepted and coerces like boolean' => sub {
	my $r = validate_strict(schema => { b => { type => 'bool' } }, input => { b => 'yes' });
	ok($r->{b}, '"bool" alias: "yes" coerced to truthy');
};

# ══════════════════════════════════════════════════════════════════════════════
# Unknown type
# ══════════════════════════════════════════════════════════════════════════════

subtest 'unknown type: no custom_types entry → "Unknown type" error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'invented_type_xyz' } },
			input  => { x => 'anything' },
		)
	} qr/Unknown type 'invented_type_xyz'/, 'unrecognised type with no custom_types entry croaks';
};

subtest 'unknown type: custom_types provided but type absent from it → still error' => sub {
	throws_ok {
		validate_strict(
			schema       => { x => { type => 'not_in_custom' } },
			input        => { x => 'anything' },
			custom_types => { something_else => { type => 'string' } },
		)
	} qr/Unknown type 'not_in_custom'/, 'type absent from custom_types also croaks';
};

# ══════════════════════════════════════════════════════════════════════════════
# Optional + absent + nested schema  (the _apply_nested_defaults path)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'optional with schema: absent field gets nested defaults injected' => sub {
	# This hits the elsif($rules->{'schema'}) branch in the optional block,
	# calling _apply_nested_defaults({}, $rules->{'schema'}) when the field is absent.
	my $r = validate_strict(
		schema => {
			cfg => {
				type     => 'hashref',
				optional => 1,
				schema   => {
					timeout => { type => 'integer', optional => 1, default => 30 },
					retries => { type => 'integer', optional => 1, default => 3  },
				},
			},
		},
		input => {},	# cfg absent → default nested values should be applied
	);
	is($r->{cfg}{timeout}, 30, 'nested default timeout applied when parent field absent');
	is($r->{cfg}{retries},  3, 'nested default retries applied when parent field absent');
};

subtest 'optional with schema: no nested defaults → field absent from result' => sub {
	# _apply_nested_defaults({}, schema_with_no_defaults) returns {} (empty).
	# The 'next unless scalar(%{$value})' then skips it → key absent from result.
	my $r = validate_strict(
		schema => {
			cfg => {
				type     => 'hashref',
				optional => 1,
				schema   => {
					name => { type => 'string' },	# required, no default
				},
			},
		},
		input => {},
	);
	ok(!exists $r->{cfg}, 'absent optional hashref with no nested defaults → key absent');
};

subtest 'optional with schema: default AND schema both present — default wins' => sub {
	# exists($rules->{'default'}) is checked first; schema branch is elsif.
	my $r = validate_strict(
		schema => {
			cfg => {
				type     => 'hashref',
				optional => 1,
				default  => { mode => 'preset' },
				schema   => {
					timeout => { type => 'integer', optional => 1, default => 99 },
				},
			},
		},
		input => {},
	);
	is($r->{cfg}{mode}, 'preset', 'default wins over schema when both present');
	ok(!exists $r->{cfg}{timeout}, 'schema defaults not applied when default key wins');
};

# ══════════════════════════════════════════════════════════════════════════════
# min / max  coverage gaps
# ══════════════════════════════════════════════════════════════════════════════

subtest 'number min: value below min → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'number', min => 0.5 } },
			input  => { x => '0.4' },
		)
	} qr/must be at least 0.5/, 'number below float min rejected';
};

subtest 'number max: value above max → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'number', max => 9.9 } },
			input  => { x => '10' },
		)
	} qr/must be no more than 9.9/, 'number above float max rejected';
};

subtest 'number min/max: value within range → accepted' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'number', min => 1.0, max => 2.0 } },
		input  => { x => '1.5' },
	);
	ok(abs($r->{x} - 1.5) < 1e-9, 'number within float range accepted');
};

subtest 'hashref max: too many keys → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { h => { type => 'hashref', max => 2 } },
			input  => { h => { a => 1, b => 2, c => 3 } },
		)
	} qr/must contain no more than 2/, 'hashref with > max keys rejected';
};

subtest 'hashref max: exactly at max → accepted' => sub {
	my $r = validate_strict(
		schema => { h => { type => 'hashref', max => 3 } },
		input  => { h => { a => 1, b => 2, c => 3 } },
	);
	is(scalar keys %{$r->{h}}, 3, 'hashref at exactly max keys accepted');
};

subtest 'minimum alias: works for string length check' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', minimum => 5 } },
			input  => { s => 'hi' },
		)
	} qr/too short/, '"minimum" alias works for string min-length check';
};

subtest 'integer min => 0: zero satisfies the constraint' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', min => 0 } },
		input  => { n => '0' },
	);
	is($r->{n}, 0, 'integer 0 satisfies min => 0');
};

subtest 'integer min with float boundary: 0.5 → 1 passes, 0 fails' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', min => 0.5 } },
		input  => { n => '1' },
	);
	is($r->{n}, 1, 'integer 1 satisfies float min => 0.5');

	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', min => 0.5 } },
			input  => { n => '0' },
		)
	} qr/must be a positive/, 'integer 0 fails float min => 0.5';
};

# ══════════════════════════════════════════════════════════════════════════════
# matches / nomatch  coverage gaps
# ══════════════════════════════════════════════════════════════════════════════

subtest 'matches arrayref: all elements match → accepted' => sub {
	my $r = validate_strict(
		schema => { tags => { type => 'arrayref', matches => qr/^[a-z]+$/ } },
		input  => { tags => ['foo', 'bar', 'baz'] },
	);
	is_deeply($r->{tags}, ['foo','bar','baz'], 'all-matching arrayref accepted');
};

subtest 'matches arrayref: one non-matching element → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { tags => { type => 'arrayref', matches => qr/^[a-z]+$/ } },
			input  => { tags => ['good', 'BAD'] },
		)
	} qr/must match pattern/, 'one non-matching element in arrayref fails';
};

subtest 'nomatch arrayref: no element matches → accepted' => sub {
	my $r = validate_strict(
		schema => { tags => { type => 'arrayref', nomatch => qr/admin/ } },
		input  => { tags => ['user', 'guest', 'viewer'] },
	);
	is_deeply($r->{tags}, ['user','guest','viewer'], 'no-matching-element arrayref passes nomatch');
};

subtest 'nomatch arrayref: one element matches → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { tags => { type => 'arrayref', nomatch => qr/admin/ } },
			input  => { tags => ['user', 'admin', 'guest'] },
		)
	} qr/must match pattern|No member.*must match/, 'one nomatch-matching element in arrayref fails';
};

subtest 'matches + nomatch combined in same rule' => sub {
	# Value must match the positive pattern AND not match the negative pattern
	my $r = validate_strict(
		schema => { s => {
			type    => 'string',
			matches => qr/^\w+$/,
			nomatch => qr/admin/,
		} },
		input => { s => 'alice' },
	);
	is($r->{s}, 'alice', 'value satisfying both matches and nomatch accepted');

	throws_ok {
		validate_strict(
			schema => { s => {
				type    => 'string',
				matches => qr/^\w+$/,
				nomatch => qr/admin/,
			} },
			input => { s => 'admin_user' },
		)
	} qr/must not match pattern/, 'value failing nomatch rejected even though matches passes';
};

subtest 'matches: undef value skipped (next guard fires)' => sub {
	# The matches handler starts with: if(!defined($value)) { next }
	# An absent optional field leaves $value undef → matches not evaluated.
	lives_ok {
		validate_strict(
			schema => { s => {
				type     => 'string',
				optional => 1,
				matches  => qr/^\d+$/,
			} },
			input => {},
		)
	} 'absent optional field: matches check skipped (undef guard fires)';
};

# ══════════════════════════════════════════════════════════════════════════════
# Boolean  numeric values and coercion
# ══════════════════════════════════════════════════════════════════════════════

subtest 'boolean: integer 1 accepted as truthy' => sub {
	my $r = validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 1 });
	ok($r->{b}, 'integer 1 → truthy boolean');
};

subtest 'boolean: integer 0 accepted as falsy' => sub {
	my $r = validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 0 });
	ok(!$r->{b}, 'integer 0 → falsy boolean');
};

subtest 'boolean: coercion actually replaces the original string value' => sub {
	my $r = validate_strict(schema => { b => { type => 'boolean' } }, input => { b => 'yes' });
	# After coercion the stored value is the hash value (1 or 0), not the original string
	ok(defined $r->{b}, 'coerced boolean is defined');
	ok($r->{b} == 1 || $r->{b} == 0, 'coerced to numeric 1 or 0, not original string');
};

# ══════════════════════════════════════════════════════════════════════════════
# element_type  coverage gaps
# ══════════════════════════════════════════════════════════════════════════════

subtest 'element_type: empty array always passes regardless of element_type' => sub {
	lives_ok {
		validate_strict(
			schema => { ids => { type => 'arrayref', element_type => 'integer' } },
			input  => { ids => [] },
		)
	} 'empty array passes element_type check (no elements to fail)';
};

subtest 'element_type number: all numeric elements accepted' => sub {
	my $r = validate_strict(
		schema => { vals => { type => 'arrayref', element_type => 'number' } },
		input  => { vals => ['1.1', '2.2', '3.3'] },
	);
	is(scalar @{$r->{vals}}, 3, 'all numeric elements accepted');
};

subtest 'element_type number: non-numeric element rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { vals => { type => 'arrayref', element_type => 'number' } },
			input  => { vals => ['1.1', 'abc', '3.3'] },
		)
	} qr/can only contain numbers/, 'non-numeric element rejected for element_type number';
};

subtest 'element_type float: synonym for number element' => sub {
	lives_ok {
		validate_strict(
			schema => { vals => { type => 'arrayref', element_type => 'float' } },
			input  => { vals => ['1.5', '2.7'] },
		)
	} '"float" accepted as element_type synonym for number';
};

subtest 'element_type: applied to non-arrayref field → "meaningless element_type" error' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', element_type => 'integer' } },
			input  => { s => 'hello' },
		)
	} qr/meaningless element_type/, 'element_type on non-arrayref croaks';
};

subtest 'element_type: custom type used as element type' => sub {
	# element_type resolves through custom_types and uses the base type
	my $r = validate_strict(
		schema       => { codes => { type => 'arrayref', element_type => 'short_code' } },
		input        => { codes => ['ab', 'cd', 'ef'] },
		custom_types => { short_code => { type => 'string', min => 2, max => 4 } },
	);
	is(scalar @{$r->{codes}}, 3, 'custom element_type: all elements accepted');
};

subtest 'element_type: custom type with transform applied to each element' => sub {
	my $r = validate_strict(
		schema       => { tags => { type => 'arrayref', element_type => 'lc_word' } },
		input        => { tags => ['HELLO', 'WORLD'] },
		custom_types => { lc_word => {
			type      => 'string',
			transform => sub { lc $_[0] },
		} },
	);
	is($r->{tags}[0], 'hello', 'custom element_type transform applied to first element');
	is($r->{tags}[1], 'world', 'custom element_type transform applied to second element');
};

# ══════════════════════════════════════════════════════════════════════════════
# schema rule  structural edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest "schema rule on string type → 'schema' only supports arrayref and hashref" => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', schema => { x => { type => 'integer' } } } },
			input  => { s => 'hello' },
		)
	} qr/only supports arrayref and hashref/, "'schema' on string type croaks with correct message";
};

subtest 'schema rule arrayref: each element validated against element schema' => sub {
	my $r = validate_strict(
		schema => {
			users => {
				type   => 'arrayref',
				schema => {
					name  => { type => 'string' },
					score => { type => 'integer', min => 0, max => 100 },
				},
			},
		},
		input => { users => [
			{ name => 'Alice', score => '85' },
			{ name => 'Bob',   score => '92' },
		] },
	);
	is($r->{users}[0]{name},  'Alice', 'first element name correct');
	is($r->{users}[0]{score},  85,     'first element score coerced');
	is($r->{users}[1]{name},  'Bob',   'second element name correct');
	is($r->{users}[1]{score},  92,     'second element score coerced');
};

subtest 'schema rule arrayref: failing element → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				users => {
					type   => 'arrayref',
					schema => { name => { type => 'string' }, age => { type => 'integer' } },
				},
			},
			input => { users => [{ name => 'Alice', age => 'not_a_number' }] },
		)
	} qr/must be (?:an integer|a number)/, 'invalid element in arrayref schema fails validation';
};

# ══════════════════════════════════════════════════════════════════════════════
# Custom type  with transform path
# ══════════════════════════════════════════════════════════════════════════════

subtest 'custom type: with transform applied before base-type check' => sub {
	my $r = validate_strict(
		schema       => { email => { type => 'normalised_email' } },
		input        => { email => '  USER@EXAMPLE.COM  ' },
		custom_types => { normalised_email => {
			type      => 'string',
			transform => sub { my $s = shift; $s =~ s/^\s+|\s+$//g; lc $s },
			matches   => qr/\@/,
		} },
	);
	is($r->{email}, 'user@example.com', 'custom type transform trims and lowercases');
};

subtest 'custom type: transform non-coderef → "transforms must be a code ref" error' => sub {
	throws_ok {
		validate_strict(
			schema       => { x => { type => 'bad_type' } },
			input        => { x => 'hi' },
			custom_types => { bad_type => { type => 'string', transform => 'not_a_coderef' } },
		)
	} qr/transforms must be a code ref/, 'non-coderef transform in custom type croaks';
};

# ══════════════════════════════════════════════════════════════════════════════
# value_constraint  — all operators
# ══════════════════════════════════════════════════════════════════════════════

for my $op_test (
	[ '<',  5,  4, 6 ],	# $then < $value: 4<5 passes, 6<5 fails
	[ '<=', 5,  5, 6 ],	# $then <= $value: 5<=5 passes, 6<=5 fails
	[ '>',  5,  6, 4 ],	# $then > $value: 6>5 passes, 4>5 fails
	[ '>=', 5,  5, 4 ],	# $then >= $value: 5>=5 passes, 4>=5 fails
) {
	my ($op, $bound, $valid_val, $invalid_val) = @$op_test;
	subtest "value_constraint operator '$op': passing and failing cases" => sub {
		lives_ok {
			validate_strict(
				schema => {
					flag  => { type => 'string',  optional => 1 },
					count => { type => 'integer', optional => 1 },
				},
				input         => { flag => '1', count => $valid_val },
				relationships => [{
					type => 'value_constraint', if => 'flag', then => 'count',
					operator => $op, value => $bound,
				}],
			)
		} "operator '$op': $valid_val $op $bound → passes";

		throws_ok {
			validate_strict(
				schema => {
					flag  => { type => 'string',  optional => 1 },
					count => { type => 'integer', optional => 1 },
				},
				input         => { flag => '1', count => $invalid_val },
				relationships => [{
					type => 'value_constraint', if => 'flag', then => 'count',
					operator => $op, value => $bound,
				}],
			)
		} qr/must be $op $bound/, "operator '$op': $invalid_val $op $bound → fails";
	};
}

subtest 'value_constraint: if-param falsy (0) → constraint not evaluated' => sub {
	# The check is: if(exists && defined && $args->{$if_param}) — 0 is falsy
	lives_ok {
		validate_strict(
			schema => {
				ssl  => { type => 'integer', optional => 1 },
				port => { type => 'integer', optional => 1 },
			},
			input         => { ssl => 0, port => 80 },	# ssl is falsy
			relationships => [{
				type => 'value_constraint', if => 'ssl', then => 'port',
				operator => '==', value => 443,
			}],
		)
	} 'value_constraint: falsy if-param (0) means constraint never evaluated';
};

subtest 'value_constraint: custom description in relationship error' => sub {
	throws_ok {
		validate_strict(
			schema => {
				ssl  => { type => 'string',  optional => 1 },
				port => { type => 'integer', optional => 1 },
			},
			input         => { ssl => '1', port => 80 },
			relationships => [{
				type        => 'value_constraint', if => 'ssl', then => 'port',
				operator    => '==', value => 443,
				description => 'SSL requires port 443',
			}],
		)
	} qr/SSL requires port 443/, 'relationship description used in error message';
};

subtest 'value_constraint: if-param absent → constraint not evaluated' => sub {
	lives_ok {
		validate_strict(
			schema => {
				ssl  => { type => 'string',  optional => 1 },
				port => { type => 'integer', optional => 1 },
			},
			input         => { port => 80 },	# ssl absent
			relationships => [{
				type => 'value_constraint', if => 'ssl', then => 'port',
				operator => '==', value => 443,
			}],
		)
	} 'value_constraint: absent if-param means constraint not evaluated';
};

# ══════════════════════════════════════════════════════════════════════════════
# value_conditional  edge paths
# ══════════════════════════════════════════════════════════════════════════════

subtest 'value_conditional: if-param matches equals, then_required present → passes' => sub {
	lives_ok {
		validate_strict(
			schema => {
				mode => { type => 'string', optional => 1 },
				key  => { type => 'string', optional => 1 },
			},
			input         => { mode => 'secure', key => 'abc123' },
			relationships => [{
				type          => 'value_conditional',
				if            => 'mode',
				equals        => 'secure',
				then_required => 'key',
			}],
		)
	} 'value_conditional: equals + then_required present → ok';
};

subtest 'value_conditional: if-param does not match equals → then_required not enforced' => sub {
	lives_ok {
		validate_strict(
			schema => {
				mode => { type => 'string', optional => 1 },
				key  => { type => 'string', optional => 1 },
			},
			input         => { mode => 'plain' },	# != 'secure', so key not required
			relationships => [{
				type          => 'value_conditional',
				if            => 'mode',
				equals        => 'secure',
				then_required => 'key',
			}],
		)
	} 'value_conditional: if-param != equals, then_required not enforced';
};

subtest 'value_conditional: if-param absent → condition not evaluated' => sub {
	lives_ok {
		validate_strict(
			schema => {
				mode => { type => 'string', optional => 1 },
				key  => { type => 'string', optional => 1 },
			},
			input         => {},	# mode absent entirely
			relationships => [{
				type => 'value_conditional', if => 'mode', equals => 'secure', then_required => 'key',
			}],
		)
	} 'value_conditional: absent if-param → condition not evaluated';
};

# ══════════════════════════════════════════════════════════════════════════════
# Relationship  success paths (both-absent / all-present cases)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'mutually_exclusive: neither present → passes' => sub {
	lives_ok {
		validate_strict(
			schema => {
				file    => { type => 'string', optional => 1 },
				content => { type => 'string', optional => 1 },
			},
			input        => {},
			relationships => [{ type => 'mutually_exclusive', params => ['file','content'] }],
		)
	} 'mutually_exclusive: neither param present → passes';
};

subtest 'required_group: ALL params present → passes' => sub {
	lives_ok {
		validate_strict(
			schema => {
				a => { type => 'string', optional => 1 },
				b => { type => 'string', optional => 1 },
			},
			input        => { a => 'x', b => 'y' },
			relationships => [{ type => 'required_group', params => ['a','b'] }],
		)
	} 'required_group: all params present → passes';
};

subtest 'conditional_requirement: if-param absent → requirement not enforced' => sub {
	lives_ok {
		validate_strict(
			schema => {
				async    => { type => 'string', optional => 1 },
				callback => { type => 'string', optional => 1 },
			},
			input        => {},	# async absent → callback not required
			relationships => [{
				type          => 'conditional_requirement',
				if            => 'async',
				then_required => 'callback',
			}],
		)
	} 'conditional_requirement: absent if-param → then_required not enforced';
};

subtest 'conditional_requirement: if-param falsy (0) → requirement not enforced' => sub {
	lives_ok {
		validate_strict(
			schema => {
				async    => { type => 'integer', optional => 1 },
				callback => { type => 'string',  optional => 1 },
			},
			input        => { async => 0 },	# falsy → condition not triggered
			relationships => [{
				type          => 'conditional_requirement',
				if            => 'async',
				then_required => 'callback',
			}],
		)
	} 'conditional_requirement: falsy if-param (0) → then_required not enforced';
};

subtest 'dependency: required param present → passes' => sub {
	lives_ok {
		validate_strict(
			schema => {
				port => { type => 'integer', optional => 1 },
				host => { type => 'string',  optional => 1 },
			},
			input        => { port => 8080, host => 'localhost' },
			relationships => [{ type => 'dependency', param => 'port', requires => 'host' }],
		)
	} 'dependency: required param is present → passes';
};

subtest 'dependency: neither param present → passes' => sub {
	lives_ok {
		validate_strict(
			schema => {
				port => { type => 'integer', optional => 1 },
				host => { type => 'string',  optional => 1 },
			},
			input        => {},
			relationships => [{ type => 'dependency', param => 'port', requires => 'host' }],
		)
	} 'dependency: neither param present → passes (no trigger)';
};

subtest 'multiple relationships of different types all passing' => sub {
	lives_ok {
		validate_strict(
			schema => {
				mode    => { type => 'string',  optional => 1 },
				key     => { type => 'string',  optional => 1 },
				file    => { type => 'string',  optional => 1 },
				content => { type => 'string',  optional => 1 },
			},
			input        => { mode => 'simple', file => 'x.txt' },
			relationships => [
				{ type => 'mutually_exclusive',     params => ['file','content'] },
				{ type => 'conditional_requirement', if => 'mode', then_required => 'file' },
			],
		)
	} 'multiple relationships all satisfied simultaneously';
};

# ══════════════════════════════════════════════════════════════════════════════
# carp_on_warn + logger
# ══════════════════════════════════════════════════════════════════════════════

subtest 'carp_on_warn + logger: logger->warn called instead of carp' => sub {
	my $logger = Ext::Logger->new;
	my @carp_warnings;
	local $SIG{__WARN__} = sub { push @carp_warnings, @_ };

	validate_strict(
		schema                    => { name => { type => 'string' } },
		input                     => { name => 'Alice', extra => 'x' },
		carp_on_warn              => 1,
		logger                    => $logger,
	);

	is(scalar @carp_warnings, 0, 'no carp emitted when logger present with carp_on_warn');
	ok(scalar @{$logger->warns} > 0, 'logger->warn called instead');
	like($logger->warns->[0], qr/Unknown parameter 'extra'/, 'logger->warn has the right message');
};

subtest 'carp_on_warn: explicit unknown_parameter_handler overrides carp_on_warn' => sub {
	# The code checks explicit handler first; carp_on_warn is only used as fallback.
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok {
		validate_strict(
			schema                    => { name => { type => 'string' } },
			input                     => { name => 'Alice', extra => 'x' },
			carp_on_warn              => 1,
			unknown_parameter_handler => 'ignore',	# explicit → overrides carp_on_warn
		)
	} 'explicit unknown_parameter_handler => ignore overrides carp_on_warn';
	is(scalar @warnings, 0, 'no warning with ignore handler, even with carp_on_warn');
};

# ══════════════════════════════════════════════════════════════════════════════
# Cross-validation  — multiple validators all passing
# ══════════════════════════════════════════════════════════════════════════════

subtest 'cross_validation: multiple validators all returning undef → all run, no error' => sub {
	my @order;
	lives_ok {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => 5 },
			cross_validation => {
				check_a => sub { push @order, 'a'; undef },
				check_b => sub { push @order, 'b'; undef },
			},
		)
	} 'multiple passing validators: no croak';
	is(scalar @order, 2, 'both validators ran');
};

# ══════════════════════════════════════════════════════════════════════════════
# Positional args  — non-contiguous positions and optional positional
# ══════════════════════════════════════════════════════════════════════════════

subtest 'positional: non-contiguous positions produce gaps (undef) in returned arrayref' => sub {
	my $r = validate_strict(
		schema => {
			first => { type => 'string', position => 0 },
			third => { type => 'string', position => 2 },	# gap at index 1
		},
		input => ['hello', 'skipped', 'world'],
	);
	is(ref($r), 'ARRAY', 'returns arrayref');
	is($r->[0], 'hello', 'position 0 correct');
	is($r->[2], 'world', 'position 2 correct');
};

subtest 'positional: optional arg absent at position → gap in array' => sub {
	my $r = validate_strict(
		schema => {
			name  => { type => 'string',  position => 0 },
			score => { type => 'integer', position => 1, optional => 1 },
		},
		input => ['Alice'],	# score absent
	);
	is(ref($r), 'ARRAY',   'returns arrayref');
	is($r->[0], 'Alice',   'position 0 correct');
};

# ══════════════════════════════════════════════════════════════════════════════
# Schema structural edge cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'schema: empty schema with empty input → empty hashref result' => sub {
	my $r = validate_strict(schema => {}, input => {});
	is(ref($r), 'HASH',        'returns hashref');
	is(scalar keys %$r, 0, 'result is empty');
};

subtest 'schema: empty schema with unknown params uses unknown_parameter_handler' => sub {
	throws_ok {
		validate_strict(schema => {}, input => { x => 1 })
	} qr/Unknown parameter 'x'/, 'unknown param against empty schema croaks by default';
};

subtest 'schema: bare string type shorthand with constraint' => sub {
	my $r = validate_strict(
		schema => { name => 'string', age => 'integer' },
		input  => { name => 'Alice', age => '30' },
	);
	is($r->{name}, 'Alice', 'bare string shorthand works');
	is($r->{age},  30,      'bare integer shorthand coerces');
};

subtest 'schema: undef schema with arrayref input → arrayref returned unchanged' => sub {
	my $input = [1, 2, 3];
	my $r = validate_strict(schema => undef, input => $input);
	is_deeply($r, $input, 'undef schema with arrayref input returns arrayref unchanged');
};

subtest 'schema: ref($rules) is a non-HASH, non-ARRAY ref → handled gracefully' => sub {
	# If a schema value is not a hashref, arrayref, or string, what happens?
	# A scalar ref: ref(\1) eq 'SCALAR' — falls through to the else branch which
	# may croak or handle it. Test that it doesn't silently corrupt output.
	throws_ok {
		validate_strict(
			schema => { x => \42 },	# scalar ref — not a valid schema entry form
			input  => { x => 'test' },
		)
	} qr/./, 'scalar-ref schema entry triggers an error of some kind';
};

# ══════════════════════════════════════════════════════════════════════════════
# Error message  — per-rule error_msg at multiple levels
# ══════════════════════════════════════════════════════════════════════════════

subtest 'error_msg: per-rule overrides default for min violation' => sub {
	throws_ok {
		validate_strict(
			schema => { age => {
				type      => 'integer',
				min       => 18,
				error_msg => 'Must be an adult',
			} },
			input => { age => 16 },
		)
	} qr/Must be an adult/, 'per-rule error_msg used for min violation';
};

subtest 'error_msg: per-rule overrides default for type violation' => sub {
	throws_ok {
		validate_strict(
			schema => { n => {
				type      => 'integer',
				error_msg => 'Custom type error',
			} },
			input => { n => 'bad' },
		)
	} qr/Custom type error/, 'per-rule error_msg used for type violation';
};

subtest 'error_msg: per-rule overrides for matches violation' => sub {
	throws_ok {
		validate_strict(
			schema => { code => {
				type      => 'string',
				matches   => qr/^\d{4}$/,
				error_msg => 'Must be exactly 4 digits',
			} },
			input => { code => 'abcd' },
		)
	} qr/Must be exactly 4 digits/, 'per-rule error_msg for matches violation';
};

subtest 'error_msg: per-rule for nomatch violation' => sub {
	throws_ok {
		validate_strict(
			schema => { user => {
				type      => 'string',
				nomatch   => qr/admin/,
				error_msg => 'Admin username not allowed',
			} },
			input => { user => 'admin' },
		)
	} qr/Admin username not allowed/, 'per-rule error_msg for nomatch violation';
};

# ══════════════════════════════════════════════════════════════════════════════
# Logger  — error path with logger records the message
# ══════════════════════════════════════════════════════════════════════════════

subtest 'logger: error recorded AND croak raised for type failure' => sub {
	my $logger = Ext::Logger->new;
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer' } },
			input  => { n => 'bad' },
			logger => $logger,
		)
	} qr/must be (?:an integer|a number)/, 'croak raised';
	ok(scalar @{$logger->errors} > 0, 'logger->error also called');
	like($logger->errors->[0], qr/must be (?:an integer|a number)/, 'logger message matches croak message');
};

subtest 'logger: unknown_parameter_handler warn → logger->warn called, no croak' => sub {
	my $logger = Ext::Logger->new;
	my @carp_out;
	local $SIG{__WARN__} = sub { push @carp_out, @_ };
	lives_ok {
		validate_strict(
			schema                    => { x => { type => 'string' } },
			input                     => { x => 'hi', extra => 'bad' },
			unknown_parameter_handler => 'warn',
			logger                    => $logger,
		)
	} 'no croak with warn handler + logger';
	is(scalar @carp_out, 0, 'no carp — logger intercepted it');
	ok(scalar @{$logger->warns} > 0, 'logger->warn called');
};

# ══════════════════════════════════════════════════════════════════════════════
# isa / can  — success paths and description in errors
# ══════════════════════════════════════════════════════════════════════════════

subtest 'isa: exact class match (not via inheritance) → ok' => sub {
	my $obj = Ext::Base->new;
	lives_ok {
		validate_strict(
			schema => { o => { type => 'object', isa => 'Ext::Base' } },
			input  => { o => $obj },
		)
	} 'exact class match satisfies isa check';
};

subtest 'isa: subclass satisfies parent isa check' => sub {
	my $child = Ext::Child->new;
	lives_ok {
		validate_strict(
			schema => { o => { type => 'object', isa => 'Ext::Base' } },
			input  => { o => $child },
		)
	} 'Ext::Child ISA Ext::Base → isa check passes';
};

subtest 'can: object has method → ok' => sub {
	my $obj = bless {}, 'Ext::Can::Test';
	{ no strict 'refs'; *{'Ext::Can::Test::frob'} = sub { 1 } }
	lives_ok {
		validate_strict(
			schema => { o => { type => 'object', can => 'frob' } },
			input  => { o => $obj },
		)
	} 'can check passes when method exists';
};

# ══════════════════════════════════════════════════════════════════════════════
# transform  — not called for absent optional, called for present
# ══════════════════════════════════════════════════════════════════════════════

subtest 'transform: coderef on optional absent field — not invoked' => sub {
	my $calls = 0;
	validate_strict(
		schema => { x => {
			type      => 'string',
			optional  => 1,
			transform => sub { $calls++; $_[0] },
		} },
		input => {},
	);
	is($calls, 0, 'transform not called for absent optional parameter');
};

subtest 'transform: coderef on present field — invoked once' => sub {
	my $calls = 0;
	validate_strict(
		schema => { x => {
			type      => 'string',
			transform => sub { $calls++; uc $_[0] },
		} },
		input => { x => 'hello' },
	);
	is($calls, 1, 'transform called exactly once for present parameter');
};

subtest 'transform: non-coderef transform → "transforms must be a code ref" error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', transform => 'not_a_sub' } },
			input  => { x => 'hello' },
		)
	} qr/transforms must be a code ref/, 'non-coderef transform croaks';
};

# ══════════════════════════════════════════════════════════════════════════════
# Calling conventions  — Data::Processor compatibility
# ══════════════════════════════════════════════════════════════════════════════

subtest 'schema wrapping: description from wrapper used in error messages' => sub {
	throws_ok {
		validate_strict(
			schema => {
				description => 'WidgetConfig',
				members     => { count => { type => 'integer', min => 1 } },
			},
			input => {},	# count missing
		)
	} qr/WidgetConfig|Required parameter 'count'/, 'wrapper description or missing-param error shown';
};

subtest 'args alias and members alias used together' => sub {
	my $r = validate_strict(
		members => { x => { type => 'string' } },
		args    => { x => 'hello' },
	);
	is($r->{x}, 'hello', '"members" + "args" aliases both honoured simultaneously');
};

# ══════════════════════════════════════════════════════════════════════════════
# Integer type  sign / whitespace edge cases for branch coverage
# ══════════════════════════════════════════════════════════════════════════════

subtest 'integer: +7 (explicit positive sign) coerces correctly' => sub {
	my $r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => '+7' });
	is($r->{n}, 7, '"+7" accepted and coerced to 7');
};

subtest 'integer: " -3 " (spaces + sign) coerces correctly' => sub {
	my $r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => ' -3 ' });
	is($r->{n}, -3, '" -3 " accepted and coerced to -3');
};

subtest 'integer: "3.0" accepted (whole number with trailing .0)' => sub {
	# 3.0 has no fractional part; the validator accepts any numeric representation
	# whose value is a whole number, regardless of how it is written.
	my $r;
	lives_ok {
		$r = validate_strict(schema => { n => { type => 'integer' } }, input => { n => '3.0' })
	} '"3.0" accepted as integer';
	ok($r->{n} == 3, 'coerced value is 3');
};

# ══════════════════════════════════════════════════════════════════════════════
# Statefulness  — validate_strict return values and input immutability
# ══════════════════════════════════════════════════════════════════════════════

subtest 'return value: always a hashref for named mode (never undef on success)' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'string', optional => 1 } },
		input  => {},
	);
	is(ref($r), 'HASH', 'successful validation always returns a hashref');
};

subtest 'input immutability: nested hashref not modified during schema validation' => sub {
	my $inner = { name => 'Alice', age => '30' };
	my $input = { user => $inner };
	validate_strict(
		schema => {
			user => {
				type   => 'hashref',
				schema => {
					name => { type => 'string'  },
					age  => { type => 'integer' },
				},
			},
		},
		input => $input,
	);
	is($inner->{age}, '30', 'original nested hashref age still a string after validation');
};

# ══════════════════════════════════════════════════════════════════════════════
# Arrayref schema  edge cases  (new in 0.32)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'arrayref schema: non-hashref element → croaks' => sub {
	throws_ok {
		validate_strict(schema => ['not_a_hashref'], input => {})
	} qr/must be a hashref/, 'non-hashref element in arrayref schema croaks';
};

subtest 'arrayref schema: element missing "name" key → croaks' => sub {
	throws_ok {
		validate_strict(schema => [ { type => 'string' } ], input => {})
	} qr/must have a 'name' key/, 'arrayref schema element without name key croaks';
};

subtest 'arrayref schema: duplicate name → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => [
				{ name => 'x', type => 'string'  },
				{ name => 'x', type => 'integer' },	# duplicate
			],
			input => { x => 'hello' },
		)
	} qr/duplicate parameter 'x'/, 'duplicate name in arrayref schema croaks';
};

subtest 'arrayref schema: empty arrayref → valid, returns empty hashref' => sub {
	my $r = validate_strict(schema => [], input => {});
	is(ref($r), 'HASH', 'empty arrayref schema returns hashref');
	is(scalar keys %$r, 0, 'result is empty');
};

subtest 'arrayref schema: "name" key not propagated as a validation rule' => sub {
	# After normalisation the 'name' key must be absent from the rule hash,
	# otherwise it would be seen as an unknown rule and croak.
	lives_ok {
		validate_strict(
			schema => [ { name => 'x', type => 'string' } ],
			input  => { x => 'hello' },
		)
	} '"name" key consumed during normalisation, not passed to rule dispatch';
};

subtest 'arrayref schema: transform, matches, and optional all work' => sub {
	my $r = validate_strict(
		schema => [
			{ name => 'tag',  type => 'string', transform => sub { lc $_[0] },
			                                    matches   => qr/^[a-z]+$/ },
			{ name => 'note', type => 'string', optional  => 1, default => 'none' },
		],
		input => { tag => 'HELLO' },
	);
	is($r->{tag},  'hello', 'transform applied and pattern passed');
	is($r->{note}, 'none',  'default for absent optional applied');
};

subtest 'arrayref schema: cross_validation receives normalised result' => sub {
	my $seen;
	validate_strict(
		schema => [
			{ name => 'a', type => 'integer' },
			{ name => 'b', type => 'integer' },
		],
		input => { a => '3', b => '7' },
		cross_validation => {
			capture => sub { $seen = $_[0]; undef },
		},
	);
	is($seen->{a}, 3, 'cross_validation sees coerced integer a');
	is($seen->{b}, 7, 'cross_validation sees coerced integer b');
};

# ══════════════════════════════════════════════════════════════════════════════
# Mutant-survivor tests  (from ATG mutation report)
# ══════════════════════════════════════════════════════════════════════════════

# COND_INV_1317: if(ref($custom_type->{'transform'}) eq 'CODE') in element_type
# handler.  If inverted to 'unless', a non-coderef transform would be called as
# code and the error branch would never fire for an invalid transform.
subtest 'element_type: custom type with non-coderef transform → croaks' => sub {
	throws_ok {
		validate_strict(
			schema       => { tags => { type => 'arrayref', element_type => 'bad_xform' } },
			input        => { tags => ['hello', 'world'] },
			custom_types => { bad_xform => { type => 'string', transform => 'not_a_coderef' } },
		)
	} qr/transforms must be a code ref/,
	  'element_type custom type with non-coderef transform croaks at the right point';
};

# COND_INV_1418: if(exists($custom_types->{$type}->{'max'})) in the max handler.
# If inverted to 'unless', the custom type's max override would be skipped when
# the custom type DOES have a max, so the schema's (larger) max would be used
# and a too-long value would slip through.
subtest 'max: custom type max overrides schema max (COND_INV_1418)' => sub {
	# custom type caps at 3; schema says 10 — custom type must win
	throws_ok {
		validate_strict(
			schema       => { s => { type => 'short_str', max => 10 } },
			input        => { s => 'hello' },	# length 5 > custom max 3
			custom_types => { short_str => { type => 'string', max => 3 } },
		)
	} qr/too long/, 'custom type max (3) overrides schema max (10) — string of length 5 rejected';

	# Sanity: a string within the custom type's max still passes
	lives_ok {
		validate_strict(
			schema       => { s => { type => 'short_str', max => 10 } },
			input        => { s => 'hi' },	# length 2 <= custom max 3
			custom_types => { short_str => { type => 'string', max => 3 } },
		)
	} 'string within custom type max accepted';
};

# COND_INV_1459: if($rules->{'error_msg'}) in the string max error branch.
# If inverted to 'unless', the custom message would be used when error_msg is
# ABSENT and the default message would appear when it IS set — exactly backwards.
subtest 'max: custom error_msg used when string exceeds max (COND_INV_1459)' => sub {
	throws_ok {
		validate_strict(
			schema => { s => {
				type      => 'string',
				max       => 3,
				error_msg => 'Custom: string too long',
			} },
			input  => { s => 'toolong' },
		)
	} qr/Custom: string too long/,
	  'custom error_msg (not default) used for string max violation';

	# Also verify the DEFAULT message fires when no error_msg is set,
	# confirming the branch is reached and not silently short-circuited.
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', max => 3 } },
			input  => { s => 'toolong' },
		)
	} qr/too long/, 'default error message fires when no error_msg set';
};

# ══════════════════════════════════════════════════════════════════════════════
# A. Systematic type × min  — every type that supports min, pass and fail
# ══════════════════════════════════════════════════════════════════════════════

for my $c (
	{ type => 'string',  min => 3, pass => 'hello', fail => 'hi',  pass_re => undef, fail_re => qr/too short/ },
	{ type => 'integer', min => 5, pass => '10',    fail => '3',   pass_re => undef, fail_re => qr/must be at least 5/ },
	{ type => 'number',  min => 2, pass => '3.5',   fail => '1.0', pass_re => undef, fail_re => qr/must be at least 2/ },
	{ type => 'float',   min => 2, pass => '3.5',   fail => '1.0', pass_re => undef, fail_re => qr/must be at least 2/ },
	{ type => 'arrayref',min => 2, pass => [1,2,3], fail => [1],   pass_re => undef, fail_re => qr/must be at least length 2/ },
	{ type => 'hashref', min => 2, pass => {a=>1,b=>2}, fail => {a=>1}, pass_re => undef, fail_re => qr/must contain at least 2/ },
) {
	my ($type, $min) = @{$c}{'type','min'};
	subtest "type $type + min=$min: value above min accepted" => sub {
		my $r = validate_strict(
			schema => { x => { type => $type, min => $min } },
			input  => { x => $c->{pass} },
		);
		ok(defined $r->{x}, "type $type: value >= min returned");
	};
	subtest "type $type + min=$min: value below min rejected" => sub {
		throws_ok {
			validate_strict(
				schema => { x => { type => $type, min => $min } },
				input  => { x => $c->{fail} },
			)
		} $c->{fail_re}, "type $type: value < min rejected";
	};
}

# ══════════════════════════════════════════════════════════════════════════════
# B. Systematic type × max  — every type that supports max, pass and fail
# ══════════════════════════════════════════════════════════════════════════════

for my $c (
	{ type => 'string',  max => 5, pass => 'hi',    fail => 'toolongvalue', fail_re => qr/too long/ },
	{ type => 'integer', max => 10, pass => '7',    fail => '15',           fail_re => qr/must be no more than 10/ },
	{ type => 'number',  max => 5,  pass => '3.5',  fail => '6.0',          fail_re => qr/must be no more than 5/ },
	{ type => 'float',   max => 5,  pass => '3.5',  fail => '6.0',          fail_re => qr/must be no more than 5/ },
	{ type => 'arrayref',max => 3,  pass => [1,2],  fail => [1,2,3,4],      fail_re => qr/must contain no more than 3/ },
	{ type => 'hashref', max => 2,  pass => {a=>1}, fail => {a=>1,b=>2,c=>3}, fail_re => qr/must contain no more than 2/ },
) {
	my ($type, $max) = @{$c}{'type','max'};
	subtest "type $type + max=$max: value within max accepted" => sub {
		my $r = validate_strict(
			schema => { x => { type => $type, max => $max } },
			input  => { x => $c->{pass} },
		);
		ok(defined $r->{x}, "type $type: value <= max returned");
	};
	subtest "type $type + max=$max: value exceeding max rejected" => sub {
		throws_ok {
			validate_strict(
				schema => { x => { type => $type, max => $max } },
				input  => { x => $c->{fail} },
			)
		} $c->{fail_re}, "type $type: value > max rejected";
	};
}

# ══════════════════════════════════════════════════════════════════════════════
# C. Systematic type × min × max  — in-range, below-min, above-max
# ══════════════════════════════════════════════════════════════════════════════

for my $c (
	{ type => 'string',  min=>3, max=>8,
	  ok=>'hello', low=>'hi', high=>'toolongstr',
	  lo_re=>qr/too short/, hi_re=>qr/too long/ },
	{ type => 'integer', min=>5, max=>15,
	  ok=>'10', low=>'3', high=>'20',
	  lo_re=>qr/must be at least 5/, hi_re=>qr/must be no more than 15/ },
	{ type => 'number',  min=>1, max=>5,
	  ok=>'3.0', low=>'0.5', high=>'6.0',
	  lo_re=>qr/must be at least 1/, hi_re=>qr/must be no more than 5/ },
	{ type => 'float',   min=>1, max=>5,
	  ok=>'3.0', low=>'0.5', high=>'6.0',
	  lo_re=>qr/must be at least 1/, hi_re=>qr/must be no more than 5/ },
	{ type => 'arrayref',min=>2, max=>4,
	  ok=>[1,2,3], low=>[1], high=>[1,2,3,4,5],
	  lo_re=>qr/must be at least length 2/, hi_re=>qr/must contain no more than 4/ },
	{ type => 'hashref', min=>2, max=>3,
	  ok=>{a=>1,b=>2}, low=>{a=>1}, high=>{a=>1,b=>2,c=>3,d=>4},
	  lo_re=>qr/must contain at least 2/, hi_re=>qr/must contain no more than 3/ },
) {
	my ($type, $min, $max) = @{$c}{'type','min','max'};
	subtest "type $type + min=$min + max=$max: in-range value accepted" => sub {
		my $r = validate_strict(
			schema => { x => { type => $type, min => $min, max => $max } },
			input  => { x => $c->{ok} },
		);
		ok(defined $r->{x}, "type $type in-range accepted");
	};
	subtest "type $type + min=$min + max=$max: below-min rejected" => sub {
		throws_ok {
			validate_strict(
				schema => { x => { type => $type, min => $min, max => $max } },
				input  => { x => $c->{low} },
			)
		} $c->{lo_re}, "type $type: below min rejected";
	};
	subtest "type $type + min=$min + max=$max: above-max rejected" => sub {
		throws_ok {
			validate_strict(
				schema => { x => { type => $type, min => $min, max => $max } },
				input  => { x => $c->{high} },
			)
		} $c->{hi_re}, "type $type: above max rejected";
	};
}

# ══════════════════════════════════════════════════════════════════════════════
# D. type × matches  — string, integer, number
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string + matches: matching value accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', matches => qr/^\d{3}$/ } },
		input  => { s => '123' },
	);
	is($r->{s}, '123', 'three-digit string matches pattern');
};

subtest 'string + matches: non-matching value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', matches => qr/^\d{3}$/ } },
			input  => { s => 'abc' },
		)
	} qr/must match pattern/, 'non-matching string rejected';
};

subtest 'string + matches as plain string (literal match): substring present → accepted' => sub {
	# Plain string matches are compiled with quotemeta, so special chars become literal.
	# Use a simple word without anchors or regex metacharacters.
	my $r = validate_strict(
		schema => { s => { type => 'string', matches => 'hello' } },
		input  => { s => 'say hello there' },
	);
	is($r->{s}, 'say hello there', 'plain string matches: literal substring found → accepted');
};

subtest 'integer + matches: integer stringifies and matches pattern' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', matches => qr/^1/ } },
		input  => { n => '12' },
	);
	is($r->{n}, 12, 'integer starting with 1 matches pattern');
};

subtest 'integer + matches: integer not matching pattern rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', matches => qr/^1/ } },
			input  => { n => '25' },
		)
	} qr/must match pattern/, 'integer not matching pattern rejected';
};

subtest 'number + matches: number matching pattern accepted' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'number', matches => qr/^3/ } },
		input  => { n => '3.14' },
	);
	ok(abs($r->{n} - 3.14) < 1e-9, 'number matching pattern accepted');
};

# ══════════════════════════════════════════════════════════════════════════════
# E. type × nomatch
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string + nomatch: non-matching value accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', nomatch => qr/admin/ } },
		input  => { s => 'alice' },
	);
	is($r->{s}, 'alice', 'value not matching nomatch pattern accepted');
};

subtest 'string + nomatch: matching value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', nomatch => qr/admin/ } },
			input  => { s => 'admin' },
		)
	} qr/must not match pattern/, 'value matching nomatch pattern rejected';
};

subtest 'integer + nomatch: integer not matching pattern accepted' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', nomatch => qr/^0/ } },
		input  => { n => '42' },
	);
	is($r->{n}, 42, 'integer not matching nomatch pattern accepted');
};

subtest 'integer + nomatch: integer matching pattern rejected' => sub {
	# '99' coerces to 99; 99 stringifies as '99' which matches /^9/
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', nomatch => qr/^9/ } },
			input  => { n => '99' },
		)
	} qr/must not match pattern/, 'integer matching nomatch pattern rejected';
};

# ══════════════════════════════════════════════════════════════════════════════
# F. type × memberof  — string case-sensitive, case-insensitive, numeric types
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string + memberof: exact-case match accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', memberof => ['alpha','beta','gamma'] } },
		input  => { s => 'beta' },
	);
	is($r->{s}, 'beta', 'exact string match in memberof accepted');
};

subtest 'string + memberof: value not in list rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', memberof => ['alpha','beta','gamma'] } },
			input  => { s => 'delta' },
		)
	} qr/must be one of/, 'string not in memberof list rejected';
};

subtest 'string + memberof: wrong case rejected when case_sensitive=1 (default)' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', memberof => ['Alpha','Beta'], case_sensitive => 1 } },
			input  => { s => 'alpha' },
		)
	} qr/must be one of/, 'wrong-case string rejected (case-sensitive default)';
};

subtest 'string + memberof + case_sensitive=0: wrong case accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', memberof => ['Alpha','Beta'], case_sensitive => 0 } },
		input  => { s => 'ALPHA' },
	);
	is($r->{s}, 'ALPHA', 'wrong-case string accepted with case_sensitive=0; original case preserved');
};

subtest 'string + memberof + case_sensitive=0: value not in list still rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', memberof => ['Alpha','Beta'], case_sensitive => 0 } },
			input  => { s => 'gamma' },
		)
	} qr/must be one of/, 'value absent from list rejected even with case_sensitive=0';
};

subtest 'integer + memberof: numeric match accepted' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', memberof => [1,2,3,4,5] } },
		input  => { n => '3' },
	);
	is($r->{n}, 3, 'integer memberof: numeric match accepted');
};

subtest 'integer + memberof: value not in list rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', memberof => [1,2,3,4,5] } },
			input  => { n => '6' },
		)
	} qr/must be one of/, 'integer not in memberof list rejected';
};

subtest 'number + memberof: floating-point numeric match accepted' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'number', memberof => [0.5, 1.0, 1.5, 2.0] } },
		input  => { n => '1.5' },
	);
	ok(abs($r->{n} - 1.5) < 1e-9, 'number memberof: 1.5 accepted');
};

subtest 'number + memberof: value not in list rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'number', memberof => [0.5, 1.0, 1.5] } },
			input  => { n => '2.5' },
		)
	} qr/must be one of/, 'number not in memberof list rejected';
};

subtest 'float + memberof: numeric match accepted (float synonym for number)' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'float', memberof => [1.0, 2.0, 3.0] } },
		input  => { n => '2.0' },
	);
	ok(abs($r->{n} - 2.0) < 1e-9, 'float memberof: 2.0 accepted');
};

# ══════════════════════════════════════════════════════════════════════════════
# G. type × notmemberof
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string + notmemberof: value not in blacklist accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', notmemberof => ['admin','root','system'] } },
		input  => { s => 'alice' },
	);
	is($r->{s}, 'alice', 'string not in notmemberof blacklist accepted');
};

subtest 'string + notmemberof: value in blacklist rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', notmemberof => ['admin','root','system'] } },
			input  => { s => 'root' },
		)
	} qr/must not be one of/, 'blacklisted string rejected';
};

subtest 'string + notmemberof + case_sensitive=1: different case NOT blacklisted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', notmemberof => ['Admin'], case_sensitive => 1 } },
		input  => { s => 'admin' },
	);
	is($r->{s}, 'admin', 'different-case value passes notmemberof when case_sensitive=1');
};

subtest 'string + notmemberof + case_sensitive=0: any case blacklisted' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', notmemberof => ['admin'], case_sensitive => 0 } },
			input  => { s => 'ADMIN' },
		)
	} qr/must not be one of/, 'case-insensitive notmemberof rejects any-case match';
};

subtest 'integer + notmemberof: value not in blacklist accepted' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', notmemberof => [22,80,443] } },
		input  => { n => '8080' },
	);
	is($r->{n}, 8080, 'integer not in blacklist accepted');
};

subtest 'integer + notmemberof: value in blacklist rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', notmemberof => [22,80,443] } },
			input  => { n => '80' },
		)
	} qr/must not be one of/, 'blacklisted integer rejected';
};

# ══════════════════════════════════════════════════════════════════════════════
# H. memberof cannot be combined with min or max
# ══════════════════════════════════════════════════════════════════════════════

subtest 'memberof + min → "makes no sense" error' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', memberof => [1,2,3], min => 1 } },
			input  => { n => '2' },
		)
	} qr/makes no sense with memberof/, 'memberof + min combination rejected';
};

subtest 'memberof + max → "makes no sense" error' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', memberof => [1,2,3], max => 3 } },
			input  => { n => '2' },
		)
	} qr/makes no sense with memberof/, 'memberof + max combination rejected';
};

subtest 'enum + min → "makes no sense" error (enum is a synonym for memberof)' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', enum => [1,2,3], min => 1 } },
			input  => { n => '2' },
		)
	} qr/makes no sense with memberof/, 'enum + min combination rejected';
};

subtest 'values + max → "makes no sense" error (values is a synonym for memberof)' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', values => [1,2,3], max => 3 } },
			input  => { n => '2' },
		)
	} qr/makes no sense with memberof/, 'values + max combination rejected';
};

# ══════════════════════════════════════════════════════════════════════════════
# I. optional × default  — multiple types
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string + optional: absent field not in result' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', optional => 1 } },
		input  => {},
	);
	ok(!exists $r->{s}, 'absent optional string field not in result');
};

subtest 'string + optional + default: absent field gets default' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', optional => 1, default => 'guest' } },
		input  => {},
	);
	is($r->{s}, 'guest', 'default string applied when field absent');
};

subtest 'string + optional + default: present value wins over default' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', optional => 1, default => 'guest' } },
		input  => { s => 'alice' },
	);
	is($r->{s}, 'alice', 'supplied value wins over default');
};

subtest 'integer + optional: absent field not in result' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', optional => 1 } },
		input  => {},
	);
	ok(!exists $r->{n}, 'absent optional integer field not in result');
};

subtest 'integer + optional + default=0: absent field gets default 0' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', optional => 1, default => 0 } },
		input  => {},
	);
	is($r->{n}, 0, 'default 0 applied for absent optional integer');
};

subtest 'boolean + optional + default: absent field gets default (default is not validated)' => sub {
	# Defaults are not validated/coerced, so use a raw 0/1 rather than a boolean string.
	my $r = validate_strict(
		schema => { flag => { type => 'boolean', optional => 1, default => 0 } },
		input  => {},
	);
	is($r->{flag}, 0, 'default 0 applied for absent optional boolean field');
};

subtest 'arrayref + optional: absent field not in result' => sub {
	my $r = validate_strict(
		schema => { items => { type => 'arrayref', optional => 1 } },
		input  => {},
	);
	ok(!exists $r->{items}, 'absent optional arrayref field not in result');
};

subtest 'arrayref + optional + default: absent field gets default arrayref' => sub {
	my $r = validate_strict(
		schema => { items => { type => 'arrayref', optional => 1, default => [] } },
		input  => {},
	);
	is_deeply($r->{items}, [], 'default empty arrayref applied for absent field');
};

subtest 'hashref + optional + default: absent field gets default hashref' => sub {
	my $r = validate_strict(
		schema => { meta => { type => 'hashref', optional => 1, default => {} } },
		input  => {},
	);
	is_deeply($r->{meta}, {}, 'default empty hashref applied for absent field');
};

subtest 'nullable as synonym for optional: absent field not in result' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', nullable => 1 } },
		input  => {},
	);
	ok(!exists $r->{s}, 'nullable=1 behaves like optional: absent field not in result');
};

subtest 'optional as coderef: returns 1 (optional) → absent field not in result' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', optional => sub { 1 } } },
		input  => {},
	);
	ok(!exists $r->{s}, 'optional coderef returning 1: absent field not in result');
};

subtest 'optional as coderef: returns 0 (required) → absent field causes error' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', optional => sub { 0 } } },
			input  => {},
		)
	} qr/Required parameter 's'/, 'optional coderef returning 0: absent required field croaks';
};

# ══════════════════════════════════════════════════════════════════════════════
# J. transform × other rules  — transform happens before all other checks
# ══════════════════════════════════════════════════════════════════════════════

subtest 'transform + type=string: value transformed then type-checked' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', transform => sub { uc $_[0] } } },
		input  => { s => 'hello' },
	);
	is($r->{s}, 'HELLO', 'transform applied; uppercased value passes string type check');
};

subtest 'transform + type=integer: transform rounds to integer first, then type check passes' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', transform => sub { int($_[0] + 0.5) } } },
		input  => { n => '3.7' },
	);
	is($r->{n}, 4, 'transform rounds 3.7 → 4; integer type check passes');
};

subtest 'transform + min: transform reduces value below min → min fails' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', transform => sub { $_[0] - 10 }, min => 5 } },
			input  => { n => '8' },
		)
	} qr/must be at least 5/, 'transform (8-10=-2) reduces value below min=5 → rejected';
};

subtest 'transform + min: transform raises value above min → passes' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'integer', transform => sub { $_[0] + 10 }, min => 5 } },
		input  => { n => '1' },
	);
	is($r->{n}, 11, 'transform raises 1+10=11 above min=5 → accepted');
};

subtest 'transform + max: transform raises value above max → rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { n => { type => 'integer', transform => sub { $_[0] * 3 }, max => 10 } },
			input  => { n => '5' },
		)
	} qr/must be no more than 10/, 'transform (5*3=15) raises value above max=10 → rejected';
};

subtest 'transform + matches: transform normalises, then pattern check' => sub {
	my $r = validate_strict(
		schema => { s => {
			type      => 'string',
			transform => sub { lc $_[0] },
			matches   => qr/^[a-z]+$/,
		} },
		input => { s => 'HELLO' },
	);
	is($r->{s}, 'hello', 'transform lowercases value; lowercased form matches pattern');
};

subtest 'transform + memberof: transform normalises, then memberof check' => sub {
	my $r = validate_strict(
		schema => { s => {
			type      => 'string',
			transform => sub { lc $_[0] },
			memberof  => ['draft','published','archived'],
		} },
		input => { s => 'DRAFT' },
	);
	is($r->{s}, 'draft', 'transform lowercases; lowercased form found in memberof list');
};

subtest 'transform + notmemberof: transform normalises, then notmemberof check' => sub {
	throws_ok {
		validate_strict(
			schema => { s => {
				type        => 'string',
				transform   => sub { lc $_[0] },
				notmemberof => ['admin','root'],
			} },
			input => { s => 'ADMIN' },
		)
	} qr/must not be one of/, 'transform lowercases ADMIN → admin; notmemberof rejects it';
};

subtest 'transform returning wrong type: type check then fails' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', transform => sub { [] } } },
			input  => { s => 'hello' },
		)
	} qr/must be a string/, 'transform returning arrayref fails string type check';
};

# ══════════════════════════════════════════════════════════════════════════════
# K. callback combinations
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string + callback: passing callback returns value' => sub {
	my $seen;
	my $r = validate_strict(
		schema => { s => { type => 'string', callback => sub { $seen = $_[0]; 1 } } },
		input  => { s => 'hello' },
	);
	is($r->{s}, 'hello', 'string value returned when callback passes');
	is($seen, 'hello', 'callback received the string value');
};

subtest 'string + callback: failing callback rejects value' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', callback => sub { 0 } } },
			input  => { s => 'hello' },
		)
	} qr/failed custom validation/, 'false-returning callback rejects string value';
};

subtest 'integer + callback: callback receives coerced integer value' => sub {
	my $seen;
	my $r = validate_strict(
		schema => { n => { type => 'integer', callback => sub { $seen = $_[0]; 1 } } },
		input  => { n => '42' },
	);
	is($r->{n}, 42, 'integer value returned');
	is($seen, 42, 'callback receives coerced integer, not original string');
};

subtest 'integer + callback: callback has access to full input via second arg' => sub {
	my $received_args;
	validate_strict(
		schema => {
			a => { type => 'integer' },
			b => { type => 'integer', callback => sub { $received_args = $_[1]; 1 } },
		},
		input => { a => '1', b => '2' },
	);
	ok(ref($received_args) eq 'HASH', 'callback second arg is a hashref');
	ok(exists $received_args->{a}, 'callback can see other validated fields');
};

subtest 'integer + min + callback: all rules pass together' => sub {
	my $r = validate_strict(
		schema => { n => {
			type     => 'integer',
			min      => 1,
			callback => sub { $_[0] % 2 == 0 },
		} },
		input => { n => '4' },
	);
	is($r->{n}, 4, 'integer 4 passes min=1 and even-number callback');
};

subtest 'arrayref + callback: callback receives reference to the array' => sub {
	my $seen;
	my $r = validate_strict(
		schema => { items => {
			type     => 'arrayref',
			callback => sub { $seen = $_[0]; 1 },
		} },
		input => { items => [1,2,3] },
	);
	is_deeply($seen, [1,2,3], 'callback receives the arrayref value');
};

# ══════════════════════════════════════════════════════════════════════════════
# L. validate / validator  (per-field full-input validation)
# ══════════════════════════════════════════════════════════════════════════════

subtest 'validate: returning undef → passes' => sub {
	my $r = validate_strict(
		schema => {
			password => { type => 'string' },
			user     => { type => 'string',
				validate => sub { my $p = shift; $p->{password} eq 'secret' ? undef : 'wrong password' }
			},
		},
		input => { password => 'secret', user => 'alice' },
	);
	is($r->{user}, 'alice', 'validate returning undef passes');
};

subtest 'validate: returning error string → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				password => { type => 'string' },
				user     => { type => 'string',
					validate => sub { my $p = shift; $p->{password} eq 'secret' ? undef : 'wrong password' }
				},
			},
			input => { password => 'wrong', user => 'alice' },
		)
	} qr/wrong password/, 'validate returning error string causes croak';
};

subtest 'validator synonym: same as validate, returning undef → passes' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'string', validator => sub { undef } } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'validator synonym: undef return passes validation');
};

subtest 'validator synonym: returning error string → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', validator => sub { 'not allowed' } } },
			input  => { x => 'hello' },
		)
	} qr/not allowed/, 'validator synonym: error string return causes croak';
};

# ══════════════════════════════════════════════════════════════════════════════
# M. description  — appears in error messages for different rule failures
# ══════════════════════════════════════════════════════════════════════════════

subtest 'description + type failure: description in error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'integer', description => 'UserAge' } },
			input  => { x => 'bad' },
		)
	} qr/UserAge/, 'description appears in type-failure error';
};

subtest 'description + min failure: description in error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'integer', min => 18, description => 'UserAge' } },
			input  => { x => '10' },
		)
	} qr/UserAge/, 'description appears in min-failure error';
};

subtest 'description + max failure: description in error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', max => 5, description => 'Slug' } },
			input  => { x => 'toolongvalue' },
		)
	} qr/Slug/, 'description appears in max-failure error';
};

subtest 'description + matches failure: description in error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', matches => qr/^\d+$/, description => 'PostCode' } },
			input  => { x => 'abc' },
		)
	} qr/PostCode/, 'description appears in matches-failure error';
};

subtest 'description + memberof failure: description in error' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'string', memberof => ['a','b'], description => 'Choice' } },
			input  => { x => 'c' },
		)
	} qr/Choice/, 'description appears in memberof-failure error';
};

# ══════════════════════════════════════════════════════════════════════════════
# N. Union types  — type => [t1, t2]
# ══════════════════════════════════════════════════════════════════════════════

subtest "union [string, integer]: string value accepted via string branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string','integer'] } },
		input  => { x => 'hello' },
	);
	is($r->{x}, 'hello', 'string matches string branch of union');
};

subtest "union [string, integer]: integer-string coerced via integer branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string','integer'] } },
		input  => { x => '42' },
	);
	# '42' matches string (string wins left-to-right), so returned as string
	ok(defined $r->{x}, "'42' accepted by union [string, integer]");
};

subtest "union [integer, string]: integer wins left-to-right over string" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['integer','string'] } },
		input  => { x => '10' },
	);
	is($r->{x}, 10, 'integer branch wins; value coerced to integer');
};

subtest "union [arrayref, hashref]: arrayref matched via arrayref branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['arrayref','hashref'] } },
		input  => { x => [1,2,3] },
	);
	is_deeply($r->{x}, [1,2,3], 'arrayref accepted via arrayref branch of union');
};

subtest "union [arrayref, hashref]: hashref matched via hashref branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['arrayref','hashref'] } },
		input  => { x => {a=>1} },
	);
	is_deeply($r->{x}, {a=>1}, 'hashref accepted via hashref branch of union');
};

subtest "union [arrayref, hashref]: string rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['arrayref','hashref'] } },
			input  => { x => 'nope' },
		)
	} qr/must be one of/, 'string rejected by both arrayref and hashref branches';
};

subtest "union [scalar, scalarref]: plain string accepted via scalar branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['scalar','scalarref'] } },
		input  => { x => 'plain' },
	);
	is($r->{x}, 'plain', 'plain string accepted via scalar branch of union');
};

subtest "union [scalar, scalarref]: scalarref accepted via scalarref branch" => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['scalar','scalarref'] } },
		input  => { x => \$s },
	);
	is($r->{x}, \$s, 'scalarref accepted via scalarref branch of union');
};

subtest "union [scalar, scalarref]: arrayref rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['scalar','scalarref'] } },
			input  => { x => [] },
		)
	} qr/must be one of/, 'arrayref rejected by both scalar and scalarref branches';
};

# ══════════════════════════════════════════════════════════════════════════════
# N2. stringref — type check, min×max, matches, nomatch, memberof, notmemberof,
#     optional×default, transform, union types
# ══════════════════════════════════════════════════════════════════════════════

subtest 'stringref: plain string accepted; dereferenced string returned' => sub {
	my $s = 'hello';
	my $r = validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \$s });
	is($r->{x}, 'hello', 'dereferenced string returned');
};

subtest 'stringref: empty string ref accepted' => sub {
	my $e = '';
	my $r = validate_strict(schema => { x => { type => 'stringref' } }, input => { x => \$e });
	is($r->{x}, '', 'empty string accepted');
};

subtest 'stringref: plain scalar rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => 'plain' })
	} qr/must be a string reference/, 'plain scalar rejected';
};

subtest 'stringref: arrayref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => [] })
	} qr/must be a string reference/, 'arrayref rejected';
};

subtest 'stringref: hashref rejected' => sub {
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref' } }, input => { x => {} })
	} qr/must be a string reference/, 'hashref rejected';
};

subtest 'stringref × min: string below min rejected' => sub {
	my $s = 'hi';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', min => 5 } }, input => { x => \$s })
	} qr/too short/, 'string shorter than min rejected';
};

subtest 'stringref × min: string at exact min accepted' => sub {
	my $s = 'hello';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', min => 5 } }, input => { x => \$s })
	} 'string at min boundary accepted';
	is($r->{x}, 'hello', 'correct value returned');
};

subtest 'stringref × max: string above max rejected' => sub {
	my $s = 'toolong';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', max => 5 } }, input => { x => \$s })
	} qr/too long/, 'string longer than max rejected';
};

subtest 'stringref × max: string at exact max accepted' => sub {
	my $s = 'hello';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', max => 5 } }, input => { x => \$s })
	} 'string at max boundary accepted';
	is($r->{x}, 'hello', 'correct value returned');
};

subtest 'stringref × min × max: within range accepted' => sub {
	my $s = 'hello';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', min => 3, max => 8 } }, input => { x => \$s })
	} 'string within min..max range accepted';
	is($r->{x}, 'hello', 'correct value returned');
};

subtest 'stringref × min × max: below range rejected' => sub {
	my $s = 'hi';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', min => 3, max => 8 } }, input => { x => \$s })
	} qr/too short/, 'string below range rejected';
};

subtest 'stringref × min × max: above range rejected' => sub {
	my $s = 'toolongvalue';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', min => 3, max => 8 } }, input => { x => \$s })
	} qr/too long/, 'string above range rejected';
};

subtest 'stringref × matches: matching value accepted' => sub {
	my $s = 'hello123';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', matches => qr/^\w+$/ } }, input => { x => \$s })
	} 'string matching pattern accepted';
	is($r->{x}, 'hello123', 'correct value returned');
};

subtest 'stringref × matches: non-matching value rejected' => sub {
	my $s = 'hello world';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', matches => qr/^\w+$/ } }, input => { x => \$s })
	} qr/must match pattern/, 'string not matching pattern rejected';
};

subtest 'stringref × nomatch: non-matching value accepted' => sub {
	my $s = 'hello';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', nomatch => qr/\d/ } }, input => { x => \$s })
	} 'string not matching nomatch pattern accepted';
	is($r->{x}, 'hello', 'correct value returned');
};

subtest 'stringref × nomatch: matching value rejected' => sub {
	my $s = 'hello123';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', nomatch => qr/\d/ } }, input => { x => \$s })
	} qr/must not match/, 'string matching nomatch pattern rejected';
};

subtest 'stringref × memberof: member value accepted' => sub {
	my $s = 'yes';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', memberof => ['yes', 'no'] } }, input => { x => \$s })
	} 'member value accepted';
	is($r->{x}, 'yes', 'correct value returned');
};

subtest 'stringref × memberof: non-member value rejected' => sub {
	my $s = 'maybe';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', memberof => ['yes', 'no'] } }, input => { x => \$s })
	} qr/must be one of/, 'non-member value rejected';
};

subtest 'stringref × notmemberof: non-blacklisted value accepted' => sub {
	my $s = 'alice';
	my $r;
	lives_ok {
		$r = validate_strict(schema => { x => { type => 'stringref', notmemberof => ['admin', 'root'] } }, input => { x => \$s })
	} 'non-blacklisted value accepted';
	is($r->{x}, 'alice', 'correct value returned');
};

subtest 'stringref × notmemberof: blacklisted value rejected' => sub {
	my $s = 'admin';
	throws_ok {
		validate_strict(schema => { x => { type => 'stringref', notmemberof => ['admin', 'root'] } }, input => { x => \$s })
	} qr/must not be one of/, 'blacklisted value rejected';
};

subtest 'stringref × optional: absent parameter skipped' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'stringref', optional => 1 } },
		input  => {},
	);
	ok(!exists($r->{x}), 'absent optional stringref not in result');
};

subtest 'stringref × default: default used when absent' => sub {
	my $r = validate_strict(
		schema => { x => { type => 'stringref', optional => 1, default => 'fallback' } },
		input  => {},
	);
	is($r->{x}, 'fallback', 'default value used');
};

subtest 'stringref × transform: transform receives dereferenced string' => sub {
	# Module dereferences before calling transform; transform sees the plain string
	my $s = '  HELLO  ';
	my $r;
	lives_ok {
		$r = validate_strict(
			schema => { x => { type => 'stringref', transform => sub { lc($_[0]) } } },
			input  => { x => \$s },
		)
	} 'transform applied to dereferenced stringref value';
	is($r->{x}, '  hello  ', 'lowercase transform applied');
};

subtest 'stringref × transform + matches: transform then match' => sub {
	my $s = 'HELLO';
	my $r;
	lives_ok {
		$r = validate_strict(
			schema => { x => { type => 'stringref', transform => sub { lc($_[0]) }, matches => qr/^[a-z]+$/ } },
			input  => { x => \$s },
		)
	} 'transform applied before matches check';
	is($r->{x}, 'hello', 'transformed value returned');
};

subtest 'stringref × min + matches: both applied' => sub {
	my $s = 'hi';
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref', min => 3, matches => qr/^\w+$/ } },
			input  => { x => \$s },
		)
	} qr/too short/, 'min failure reported even when matches would pass';
};

subtest 'stringref × error_msg: custom message on type failure' => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref', error_msg => 'Need a string ref here' } },
			input  => { x => 'plain' },
		)
	} qr/Need a string ref here/, 'custom error_msg used on type failure';
};

subtest 'stringref × error_msg: custom message on min failure' => sub {
	my $s = 'hi';
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref', min => 5, error_msg => 'Too short!' } },
			input  => { x => \$s },
		)
	} qr/Too short!/, 'custom error_msg used on min failure';
};

subtest 'stringref × error_msg: custom message on max failure' => sub {
	my $s = 'toolongvalue';
	throws_ok {
		validate_strict(
			schema => { x => { type => 'stringref', max => 5, error_msg => 'Too long!' } },
			input  => { x => \$s },
		)
	} qr/Too long!/, 'custom error_msg used on max failure';
};

# Union types with stringref

subtest "union [string, stringref]: plain string accepted via string branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string', 'stringref'] } },
		input  => { x => 'plain' },
	);
	is($r->{x}, 'plain', 'plain string accepted via string branch');
};

subtest "union [string, stringref]: stringref accepted via stringref branch" => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['string', 'stringref'] } },
		input  => { x => \$s },
	);
	is($r->{x}, 'hello', 'string reference accepted; dereferenced string returned');
};

subtest "union [string, stringref]: arrayref rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['string', 'stringref'] } },
			input  => { x => [] },
		)
	} qr/must be one of/, 'arrayref rejected by both string and stringref branches';
};

subtest "union [scalar, stringref]: plain scalar accepted via scalar branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['scalar', 'stringref'] } },
		input  => { x => 42 },
	);
	is($r->{x}, 42, 'plain scalar accepted via scalar branch');
};

subtest "union [scalar, stringref]: stringref accepted via stringref branch" => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['scalar', 'stringref'] } },
		input  => { x => \$s },
	);
	is($r->{x}, 'hello', 'string reference accepted via stringref branch');
};

subtest "union [scalar, stringref]: arrayref rejected by both branches" => sub {
	throws_ok {
		validate_strict(
			schema => { x => { type => ['scalar', 'stringref'] } },
			input  => { x => [] },
		)
	} qr/must be one of/, 'arrayref rejected by both scalar and stringref branches';
};

subtest "union [string, stringref] × min: min applied; short string rejected" => sub {
	my $s = 'hi';
	throws_ok {
		validate_strict(
			schema => { x => { type => ['string', 'stringref'], min => 5 } },
			input  => { x => \$s },
		)
	} qr/too short|must be one of/, 'short string ref rejected by union with min';
};

subtest "union [string, stringref] × min: long enough plain string accepted" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string', 'stringref'], min => 5 } },
		input  => { x => 'hello world' },
	);
	is($r->{x}, 'hello world', 'long enough plain string accepted via string branch');
};

subtest "union [string, stringref] × matches: matched string ref accepted" => sub {
	my $s = 'hello';
	my $r = validate_strict(
		schema => { x => { type => ['string', 'stringref'], matches => qr/^[a-z]+$/ } },
		input  => { x => \$s },
	);
	is($r->{x}, 'hello', 'matching stringref accepted via union');
};

subtest "union [string, stringref] × matches: non-matching value rejected by both" => sub {
	my $s = 'HELLO';
	throws_ok {
		validate_strict(
			schema => { x => { type => ['string', 'stringref'], matches => qr/^[a-z]+$/ } },
			input  => { x => \$s },
		)
	} qr/must match pattern|must be one of/, 'non-matching stringref rejected by both branches';
};

subtest "union [string, object]: string accepted via string branch" => sub {
	my $r = validate_strict(
		schema => { x => { type => ['string','object'] } },
		input  => { x => 'just a string' },
	);
	is($r->{x}, 'just a string', 'string accepted via string branch of [string,object] union');
};

subtest "union [string, object]: blessed object accepted via object branch" => sub {
	my $obj = Ext::Base->new;
	my $r = validate_strict(
		schema => { x => { type => ['string','object'] } },
		input  => { x => $obj },
	);
	is($r->{x}, $obj, 'blessed object accepted via object branch of [string,object] union');
};

# ══════════════════════════════════════════════════════════════════════════════
# O. isa and can  — fail cases, multi-method, combined
# ══════════════════════════════════════════════════════════════════════════════

{ package Ext::Dog; our @ISA = ('Ext::Base'); sub new { bless {}, shift } sub speak { 'woof' } sub fetch { 1 } }
{ package Ext::Cat; our @ISA = ('Ext::Base'); sub new { bless {}, shift } sub speak { 'meow' } }
{ package Ext::Robot; sub new { bless {}, shift } sub speak { 'beep' } sub compute { 1 } }

subtest 'isa: object of wrong class rejected' => sub {
	my $obj = Ext::Robot->new;
	throws_ok {
		validate_strict(
			schema => { o => { type => 'object', isa => 'Ext::Base' } },
			input  => { o => $obj },
		)
	} qr/must be a 'Ext::Base'/, 'object of wrong class rejected by isa check';
};

subtest 'isa: subclass satisfies isa check for parent' => sub {
	my $dog = Ext::Dog->new;
	lives_ok {
		validate_strict(
			schema => { o => { type => 'object', isa => 'Ext::Base' } },
			input  => { o => $dog },
		)
	} 'Ext::Dog ISA Ext::Base → isa for Ext::Base passes';
};

subtest 'can: single method present → passes' => sub {
	my $dog = Ext::Dog->new;
	lives_ok {
		validate_strict(
			schema => { o => { type => 'object', can => 'speak' } },
			input  => { o => $dog },
		)
	} 'object with "speak" method passes can=speak check';
};

subtest 'can: single method absent → fails' => sub {
	my $cat = Ext::Cat->new;
	throws_ok {
		validate_strict(
			schema => { o => { type => 'object', can => 'fetch' } },
			input  => { o => $cat },
		)
	} qr/understands/, 'object missing "fetch" method rejected by can=fetch check';
};

subtest 'can as arrayref: all methods present → passes' => sub {
	my $dog = Ext::Dog->new;
	lives_ok {
		validate_strict(
			schema => { o => { type => 'object', can => ['speak','fetch'] } },
			input  => { o => $dog },
		)
	} 'object with all listed methods passes can=[speak,fetch]';
};

subtest 'can as arrayref: one method absent → fails' => sub {
	my $cat = Ext::Cat->new;
	throws_ok {
		validate_strict(
			schema => { o => { type => 'object', can => ['speak','fetch'] } },
			input  => { o => $cat },
		)
	} qr/understands/, 'cat missing "fetch" fails can=[speak,fetch]';
};

subtest 'isa + can: both satisfied → passes' => sub {
	my $dog = Ext::Dog->new;
	lives_ok {
		validate_strict(
			schema => { o => { type => 'object', isa => 'Ext::Base', can => 'speak' } },
			input  => { o => $dog },
		)
	} 'Ext::Dog passes both isa=Ext::Base and can=speak';
};

subtest 'isa + can: isa satisfied but can fails → rejects' => sub {
	my $base = Ext::Base->new;	# is Ext::Base but has no speak method
	throws_ok {
		validate_strict(
			schema => { o => { type => 'object', isa => 'Ext::Base', can => 'speak' } },
			input  => { o => $base },
		)
	} qr/understands/, 'Ext::Base passes isa but fails can=speak';
};

subtest 'isa + can: isa fails (wrong class) → rejects' => sub {
	my $robot = Ext::Robot->new;	# not an Ext::Base
	throws_ok {
		validate_strict(
			schema => { o => { type => 'object', isa => 'Ext::Base', can => 'speak' } },
			input  => { o => $robot },
		)
	} qr/must be a 'Ext::Base'/, 'Ext::Robot fails isa=Ext::Base check';
};

# ══════════════════════════════════════════════════════════════════════════════
# P. element_type × min × max
# ══════════════════════════════════════════════════════════════════════════════

subtest 'arrayref + element_type=string + min: all-string array above min passes' => sub {
	my $r = validate_strict(
		schema => { tags => { type => 'arrayref', element_type => 'string', min => 2 } },
		input  => { tags => ['alpha','beta','gamma'] },
	);
	is(scalar @{$r->{tags}}, 3, 'string element_type + min: 3-element array accepted');
};

subtest 'arrayref + element_type=string + min: below-min array rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { tags => { type => 'arrayref', element_type => 'string', min => 3 } },
			input  => { tags => ['only_one'] },
		)
	} qr/must be at least length 3/, 'element_type + min: short array rejected';
};

subtest 'arrayref + element_type=string + max: all-string array within max passes' => sub {
	my $r = validate_strict(
		schema => { tags => { type => 'arrayref', element_type => 'string', max => 3 } },
		input  => { tags => ['a','b'] },
	);
	is(scalar @{$r->{tags}}, 2, 'element_type + max: 2-element array within max=3 accepted');
};

subtest 'arrayref + element_type=string + max: over-max array rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { tags => { type => 'arrayref', element_type => 'string', max => 2 } },
			input  => { tags => ['a','b','c'] },
		)
	} qr/must contain no more than 2/, 'element_type + max: over-max array rejected';
};

subtest 'arrayref + element_type=integer: non-integer element rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { ids => { type => 'arrayref', element_type => 'integer' } },
			input  => { ids => [1, 2, 'oops', 4] },
		)
	} qr/can only contain integers/, 'non-integer element in integer element_type array rejected';
};

subtest 'arrayref + element_type=integer + min + max: all rules satisfied' => sub {
	my $r = validate_strict(
		schema => { ids => { type => 'arrayref', element_type => 'integer', min => 2, max => 4 } },
		input  => { ids => ['1','2','3'] },
	);
	is(scalar @{$r->{ids}}, 3, 'integer element_type + min=2 + max=4: 3-element array accepted');
};

# ══════════════════════════════════════════════════════════════════════════════
# Q. Nested schema  — fail cases and deeper nesting
# ══════════════════════════════════════════════════════════════════════════════

subtest 'hashref + schema: required inner field missing → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				user => {
					type   => 'hashref',
					schema => { name => { type => 'string' }, age => { type => 'integer' } },
				},
			},
			input => { user => { name => 'Alice' } },	# age missing
		)
	} qr/Required parameter 'age'/, 'missing required inner field croaks';
};

subtest 'hashref + schema: inner field type mismatch → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => {
				user => {
					type   => 'hashref',
					schema => { name => { type => 'string' }, age => { type => 'integer' } },
				},
			},
			input => { user => { name => 'Alice', age => 'not_a_number' } },
		)
	} qr/must be (?:an integer|a number)/, 'inner field type mismatch croaks';
};

subtest 'hashref + schema: all inner fields valid → coercion applied' => sub {
	my $r = validate_strict(
		schema => {
			user => {
				type   => 'hashref',
				schema => { name => { type => 'string' }, age => { type => 'integer' } },
			},
		},
		input => { user => { name => 'Alice', age => '30' } },
	);
	is($r->{user}{name}, 'Alice', 'inner name correct');
	is($r->{user}{age},  30,      'inner age coerced to integer');
};

subtest 'deeply nested: hashref containing hashref → all levels validated' => sub {
	my $r = validate_strict(
		schema => {
			config => {
				type   => 'hashref',
				schema => {
					db => {
						type   => 'hashref',
						schema => {
							host => { type => 'string' },
							port => { type => 'integer', min => 1, max => 65535 },
						},
					},
				},
			},
		},
		input => { config => { db => { host => 'localhost', port => '5432' } } },
	);
	is($r->{config}{db}{host}, 'localhost', 'deeply nested host correct');
	is($r->{config}{db}{port}, 5432,        'deeply nested port coerced');
};

subtest 'hashref + min + schema: min key count and inner schema both applied' => sub {
	throws_ok {
		validate_strict(
			schema => {
				meta => {
					type   => 'hashref',
					min    => 3,
					schema => { a => { type => 'string', optional => 1 }, b => { type => 'string', optional => 1 } },
				},
			},
			input => { meta => { a => 'x' } },	# only 1 key, min is 3
		)
	} qr/must contain at least 3/, 'hashref min key count enforced alongside inner schema';
};

# ══════════════════════════════════════════════════════════════════════════════
# R. Cross-validation  — fail cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'cross_validation: failing validator → croaks with returned message' => sub {
	throws_ok {
		validate_strict(
			schema => {
				password         => { type => 'string' },
				password_confirm => { type => 'string' },
			},
			input => { password => 'secret', password_confirm => 'different' },
			cross_validation => {
				passwords_match => sub {
					my $p = shift;
					$p->{password} eq $p->{password_confirm} ? undef : "Passwords don't match";
				},
			},
		)
	} qr/Passwords don't match/, 'cross_validation failure croaks with returned message';
};

subtest 'cross_validation: multiple validators, one fails → croaks' => sub {
	throws_ok {
		validate_strict(
			schema => { a => { type => 'integer' }, b => { type => 'integer' } },
			input  => { a => '10', b => '5' },
			cross_validation => {
				a_lt_b => sub { my $p = shift; $p->{a} < $p->{b} ? undef : 'a must be less than b' },
				b_gt_0 => sub { my $p = shift; $p->{b} > 0 ? undef : 'b must be positive' },
			},
		)
	} qr/a must be less than b/, 'cross_validation: first failing validator stops processing';
};

subtest 'cross_validation: receives coerced (post-transform) values' => sub {
	my $seen_a;
	validate_strict(
		schema => { a => { type => 'integer' } },
		input  => { a => '99' },
		cross_validation => {
			capture => sub { $seen_a = shift->{a}; undef },
		},
	);
	is($seen_a, 99, 'cross_validation receives coerced integer, not original string');
};

# ══════════════════════════════════════════════════════════════════════════════
# S. Relationships  — fail cases
# ══════════════════════════════════════════════════════════════════════════════

subtest 'required_group: none of the group present → fails' => sub {
	throws_ok {
		validate_strict(
			schema => {
				email => { type => 'string', optional => 1 },
				phone => { type => 'string', optional => 1 },
			},
			input        => {},
			relationships => [{ type => 'required_group', params => ['email','phone'] }],
		)
	} qr/at least one of|required_group/i, 'required_group fails when no member present';
};

subtest 'required_group: one present → passes' => sub {
	lives_ok {
		validate_strict(
			schema => {
				email => { type => 'string', optional => 1 },
				phone => { type => 'string', optional => 1 },
			},
			input        => { email => 'a@b.com' },
			relationships => [{ type => 'required_group', params => ['email','phone'] }],
		)
	} 'required_group: one member present → passes';
};

subtest 'conditional_requirement: if-param present, then_required absent → fails' => sub {
	throws_ok {
		validate_strict(
			schema => {
				async    => { type => 'string',  optional => 1 },
				callback => { type => 'string',  optional => 1 },
			},
			input        => { async => 'yes' },
			relationships => [{
				type          => 'conditional_requirement',
				if            => 'async',
				then_required => 'callback',
			}],
		)
	} qr/callback/, 'conditional_requirement: trigger present but required absent → fails';
};

subtest 'conditional_requirement: if-param + then_required both present → passes' => sub {
	lives_ok {
		validate_strict(
			schema => {
				async    => { type => 'string', optional => 1 },
				callback => { type => 'string', optional => 1 },
			},
			input        => { async => 'yes', callback => 'my_cb' },
			relationships => [{
				type          => 'conditional_requirement',
				if            => 'async',
				then_required => 'callback',
			}],
		)
	} 'conditional_requirement: both trigger and required present → passes';
};

subtest 'value_conditional: if-param matches equals, then_required absent → fails' => sub {
	throws_ok {
		validate_strict(
			schema => {
				mode => { type => 'string', optional => 1 },
				key  => { type => 'string', optional => 1 },
			},
			input        => { mode => 'secure' },	# key absent but required when mode=secure
			relationships => [{
				type          => 'value_conditional',
				if            => 'mode',
				equals        => 'secure',
				then_required => 'key',
			}],
		)
	} qr/key/, 'value_conditional: condition met but required field absent → fails';
};

# ══════════════════════════════════════════════════════════════════════════════
# T. Positional arguments
# ══════════════════════════════════════════════════════════════════════════════

subtest 'positional: single arg at position 0 → result is arrayref' => sub {
	my $r = validate_strict(
		schema => { name => { type => 'string', position => 0 } },
		input  => ['Alice'],
	);
	is(ref($r),  'ARRAY',  'single positional arg: result is arrayref');
	is($r->[0], 'Alice',   'value at position 0 correct');
};

subtest 'positional: single arg wrong type → fails' => sub {
	throws_ok {
		validate_strict(
			schema => { name => { type => 'string', position => 0 } },
			input  => [[]],
		)
	} qr/must be a string/, 'positional arg with wrong type rejected';
};

subtest 'positional: two args, both pass with coercion' => sub {
	my $r = validate_strict(
		schema => {
			name  => { type => 'string',  position => 0 },
			score => { type => 'integer', position => 1 },
		},
		input => ['Alice', '95'],
	);
	is($r->[0], 'Alice', 'positional name correct');
	is($r->[1], 95,      'positional score coerced to integer');
};

subtest 'positional: integer coercion at position 0' => sub {
	my $r = validate_strict(
		schema => { count => { type => 'integer', position => 0 } },
		input  => ['42'],
	);
	is($r->[0], 42, 'positional integer string coerced to 42');
};

subtest 'positional: three args, middle one optional and absent → gap in array' => sub {
	my $r = validate_strict(
		schema => {
			a => { type => 'string',  position => 0 },
			b => { type => 'string',  position => 1, optional => 1 },
			c => { type => 'string',  position => 2 },
		},
		input => ['first', undef, 'third'],
	);
	is($r->[0], 'first', 'position 0 correct');
	is($r->[2], 'third', 'position 2 correct');
};

# ══════════════════════════════════════════════════════════════════════════════
# U. Synonym rules
# ══════════════════════════════════════════════════════════════════════════════

subtest 'regex synonym for matches: matching value accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', regex => qr/^\d+$/ } },
		input  => { s => '123' },
	);
	is($r->{s}, '123', 'regex synonym: matching value accepted');
};

subtest 'regex synonym for matches: non-matching value rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', regex => qr/^\d+$/ } },
			input  => { s => 'abc' },
		)
	} qr/must match pattern/, 'regex synonym: non-matching value rejected';
};

subtest 'enum synonym for memberof: accepted value passes' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', enum => ['red','green','blue'] } },
		input  => { s => 'green' },
	);
	is($r->{s}, 'green', 'enum synonym: value in list accepted');
};

subtest 'enum synonym for memberof: rejected value fails' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', enum => ['red','green','blue'] } },
			input  => { s => 'yellow' },
		)
	} qr/must be one of/, 'enum synonym: value not in list rejected';
};

subtest 'values synonym for memberof: accepted value passes' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'string', values => ['x','y','z'] } },
		input  => { s => 'y' },
	);
	is($r->{s}, 'y', 'values synonym: value in list accepted');
};

subtest 'values synonym for memberof: rejected value fails' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', values => ['x','y','z'] } },
			input  => { s => 'w' },
		)
	} qr/must be one of/, 'values synonym: value not in list rejected';
};

subtest 'str synonym for string: valid string accepted' => sub {
	my $r = validate_strict(
		schema => { s => { type => 'str', min => 2 } },
		input  => { s => 'hi' },
	);
	is($r->{s}, 'hi', 'str synonym accepted with min constraint');
};

subtest 'bool synonym for boolean: "yes" accepted and coerced' => sub {
	my $r = validate_strict(
		schema => { b => { type => 'bool' } },
		input  => { b => 'yes' },
	);
	ok($r->{b}, 'bool synonym: "yes" coerced to truthy');
};

subtest 'float synonym for number: float value passes min/max range' => sub {
	my $r = validate_strict(
		schema => { n => { type => 'float', min => 1.0, max => 10.0 } },
		input  => { n => '3.14' },
	);
	ok(abs($r->{n} - 3.14) < 1e-9, 'float synonym: value in range accepted and coerced');
};

subtest 'minimum synonym for min: string below minimum rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { s => { type => 'string', minimum => 5 } },
			input  => { s => 'hi' },
		)
	} qr/too short/, 'minimum synonym rejects short string';
};

# ══════════════════════════════════════════════════════════════════════════════
# V. min as coderef  — dynamic minimum based on other parameters
# ══════════════════════════════════════════════════════════════════════════════

subtest 'min as coderef: dynamic minimum satisfied → passes' => sub {
	my $r = validate_strict(
		schema => {
			country => { type => 'string' },
			age     => {
				type => 'integer',
				min  => sub {
					my ($value, $all_params) = @_;
					$all_params->{country} eq 'US' ? 21 : 18;
				},
			},
		},
		input => { country => 'US', age => '21' },
	);
	is($r->{age}, 21, 'dynamic min (US → 21): age 21 passes');
};

subtest 'min as coderef: dynamic minimum not satisfied → fails' => sub {
	throws_ok {
		validate_strict(
			schema => {
				country => { type => 'string' },
				age     => {
					type => 'integer',
					min  => sub {
						my ($value, $all_params) = @_;
						$all_params->{country} eq 'US' ? 21 : 18;
					},
				},
			},
			input => { country => 'US', age => '18' },
		)
	} qr/must be at least 21/, 'dynamic min (US → 21): age 18 fails';
};

subtest 'min as coderef: different country gives lower dynamic minimum' => sub {
	my $r = validate_strict(
		schema => {
			country => { type => 'string' },
			age     => {
				type => 'integer',
				min  => sub {
					my ($value, $all_params) = @_;
					$all_params->{country} eq 'US' ? 21 : 18;
				},
			},
		},
		input => { country => 'UK', age => '18' },
	);
	is($r->{age}, 18, 'dynamic min (UK → 18): age 18 passes');
};

# ══════════════════════════════════════════════════════════════════════════════
# W. Complex multi-rule combinations
# ══════════════════════════════════════════════════════════════════════════════

subtest 'string + min + max + matches: all rules satisfied' => sub {
	my $r = validate_strict(
		schema => { code => {
			type    => 'string',
			min     => 3,
			max     => 8,
			matches => qr/^[a-z0-9]+$/,
		} },
		input => { code => 'abc123' },
	);
	is($r->{code}, 'abc123', 'string + min + max + matches: all pass');
};

subtest 'string + min + max + matches: below min rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { code => { type => 'string', min => 3, max => 8, matches => qr/^[a-z]+$/ } },
			input  => { code => 'ab' },
		)
	} qr/too short/, 'string + min + max + matches: below-min rejected';
};

subtest 'string + min + max + matches: above max rejected' => sub {
	throws_ok {
		validate_strict(
			schema => { code => { type => 'string', min => 3, max => 8, matches => qr/^[a-z]+$/ } },
			input  => { code => 'toolongstring' },
		)
	} qr/too long/, 'string + min + max + matches: above-max rejected';
};

subtest 'string + min + max + matches: pattern fails' => sub {
	throws_ok {
		validate_strict(
			schema => { code => { type => 'string', min => 3, max => 8, matches => qr/^[a-z]+$/ } },
			input  => { code => 'abc123' },
		)
	} qr/must match pattern/, 'string + min + max + matches: pattern mismatch rejected';
};

subtest 'string + min + max + matches + nomatch: all rules satisfied' => sub {
	my $r = validate_strict(
		schema => { user => {
			type    => 'string',
			min     => 3,
			max     => 20,
			matches => qr/^[a-z0-9_]+$/,
			nomatch => qr/admin/,
		} },
		input => { user => 'alice_99' },
	);
	is($r->{user}, 'alice_99', 'string + min + max + matches + nomatch: all pass');
};

subtest 'integer + min + max + callback: all rules satisfied' => sub {
	my $r = validate_strict(
		schema => { n => {
			type     => 'integer',
			min      => 2,
			max      => 100,
			callback => sub { $_[0] % 2 == 0 },
		} },
		input => { n => '8' },
	);
	is($r->{n}, 8, 'integer + min + max + callback: all pass');
};

subtest 'string + transform + min + matches: transform applied, then min and matches checked' => sub {
	my $r = validate_strict(
		schema => { tag => {
			type      => 'string',
			transform => sub { lc $_[0] },
			min       => 3,
			matches   => qr/^[a-z]+$/,
		} },
		input => { tag => 'HELLO' },
	);
	is($r->{tag}, 'hello', 'transform + min + matches: all pass after lowercase transform');
};

subtest 'arrayref + min + max + element_type: all rules satisfied' => sub {
	my $r = validate_strict(
		schema => { ids => {
			type         => 'arrayref',
			min          => 2,
			max          => 5,
			element_type => 'integer',
		} },
		input => { ids => ['1','2','3'] },
	);
	is(scalar @{$r->{ids}}, 3, 'arrayref + min + max + element_type: 3-element array accepted');
};

subtest 'arrayref + min + max + element_type: element type fails' => sub {
	throws_ok {
		validate_strict(
			schema => { ids => { type => 'arrayref', min => 1, max => 5, element_type => 'integer' } },
			input  => { ids => [1, 'bad', 3] },
		)
	} qr/can only contain integers/, 'arrayref element_type failure inside min+max combo';
};

subtest 'hashref + min + max + schema: all constraints satisfied' => sub {
	my $r = validate_strict(
		schema => { cfg => {
			type   => 'hashref',
			min    => 2,
			max    => 4,
			schema => {
				host => { type => 'string' },
				port => { type => 'integer', min => 1 },
			},
		} },
		input => { cfg => { host => 'localhost', port => '3306' } },
	);
	is($r->{cfg}{host}, 'localhost', 'hashref + min + max + schema: host correct');
	is($r->{cfg}{port}, 3306,        'hashref + min + max + schema: port coerced');
};

subtest 'string + notmemberof + min + max + matches: all pass' => sub {
	my $r = validate_strict(
		schema => { username => {
			type        => 'string',
			min         => 3,
			max         => 20,
			matches     => qr/^[a-z0-9_]+$/,
			notmemberof => ['admin','root','system'],
		} },
		input => { username => 'alice_42' },
	);
	is($r->{username}, 'alice_42', 'string + notmemberof + min + max + matches: all pass');
};

subtest 'string + memberof + description + error_msg: error_msg overrides default' => sub {
	throws_ok {
		validate_strict(
			schema => { status => {
				type        => 'string',
				memberof    => ['draft','published'],
				description => 'ArticleStatus',
				error_msg   => 'Invalid status value',
			} },
			input => { status => 'deleted' },
		)
	} qr/Invalid status value/, 'error_msg overrides default memberof failure message';
};

subtest 'integer + min + max + matches + notmemberof: all pass together' => sub {
	my $r = validate_strict(
		schema => { port => {
			type        => 'integer',
			min         => 1024,
			max         => 65535,
			matches     => qr/^\d+$/,
			notmemberof => [22, 80, 443],
		} },
		input => { port => '8080' },
	);
	is($r->{port}, 8080, 'integer + min + max + matches + notmemberof: port 8080 passes all');
};

subtest 'two-field schema with cross-dependencies via callback' => sub {
	my $r = validate_strict(
		schema => {
			start => { type => 'integer' },
			end   => {
				type     => 'integer',
				callback => sub {
					my ($val, $all) = @_;
					$val > $all->{start};
				},
			},
		},
		input => { start => '5', end => '10' },
	);
	is($r->{start}, 5,  'start coerced');
	is($r->{end},   10, 'end accepted: > start');
};

subtest 'two-field schema: callback rejects when end <= start' => sub {
	throws_ok {
		validate_strict(
			schema => {
				start => { type => 'integer' },
				end   => {
					type     => 'integer',
					callback => sub { my ($val, $all) = @_; $val > $all->{start} },
				},
			},
			input => { start => '10', end => '5' },
		)
	} qr/failed custom validation/, 'end <= start fails callback';
};

done_testing;
