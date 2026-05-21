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
	} qr/must be at least/, 'integer 0 fails float min => 0.5';
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

subtest 'integer: "3.0" rejected (decimal point present)' => sub {
	throws_ok {
		validate_strict(schema => { n => { type => 'integer' } }, input => { n => '3.0' })
	} qr/must be an integer/, '"3.0" rejected as non-integer';
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

done_testing;
