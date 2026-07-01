#!/usr/bin/env perl

# White-box function tests for Params::Get::get_params.
#
# Strategy: systematically exercise every dispatch branch in the implementation,
# verifying both return values and Carp call arguments via Test::Mockingbird spies.
# Test::Returns validates the shape of every return value.
# Test::Memory::Cycle confirms that constructed hashrefs are GC-collectable.

use strict;
use warnings;

use Test::Most;

use Test::Mockingbird 0.08;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util ();

use Params::Get qw(get_params);

# Named constants so no magic strings appear in assertions.
Readonly::Scalar my $PKG            => 'Params::Get';
Readonly::Scalar my $USAGE_RE       => qr/Usage/;
Readonly::Scalar my $DEFAULT_ERR_RE => qr/\$default must be a scalar or arrayref/;

# =========================================================================
# SECTION 1: Fast path
#
# When exactly one argument is received and it is a plain hashref,
# get_params returns it immediately BEFORE shifting $default.  This means
# the sole hashref is also the $default value -- intentional performance
# trade-off documented in LIMITATIONS.
# =========================================================================

subtest 'fast path: sole hashref returned by identity, no copy made' => sub {
	my $h      = { foo => 'bar', baz => 42 };
	my $result = get_params($h);

	is_deeply($result, $h,  'hashref contents intact');
	is($result,        $h,  'same reference object returned (no clone)');

	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'cycle-free');

	diag explain $result if $ENV{TEST_VERBOSE};
};

subtest 'fast path: empty hashref returned by identity' => sub {
	my $h      = {};
	my $result = get_params($h);

	is_deeply($result, {}, 'empty hashref returned');
	is($result,        $h, 'same reference returned');
};

# =========================================================================
# SECTION 2: $default validation
#
# Immediately after shifting $default, any ref type that is NOT an ARRAY ref
# triggers an unconditional Carp::croak.
# =========================================================================

subtest '$default CODE ref: croaks before inspecting args' => sub {
	my $spy = spy 'Carp::croak';

	throws_ok(
		sub { get_params(sub { }, 'any_arg') },
		$DEFAULT_ERR_RE,
		'CODE ref as $default throws',
	);

	my @calls = $spy->();
	ok(@calls >= 1, 'Carp::croak was called');
	like(
		join('', grep { defined } @{$calls[0]}[1 .. $#{$calls[0]}]),
		$DEFAULT_ERR_RE,
		'croak message references $default',
	);

	diag diagnose_mocks_pretty() if $ENV{TEST_VERBOSE};
	restore_all();
};

subtest '$default SCALAR ref: croaks immediately' => sub {
	throws_ok(
		sub { get_params(\'text', 'arg') },
		$DEFAULT_ERR_RE,
		'SCALAR ref as $default throws',
	);
};

subtest '$default HASH ref: croaks immediately' => sub {
	# A non-ARRAY hashref as $default is an API misuse.
	throws_ok(
		sub { get_params({}, 'arg') },
		$DEFAULT_ERR_RE,
		'HASH ref as $default throws',
	);
};

# =========================================================================
# SECTION 3: Arrayref-of-names $default
#
# When $default is an ARRAY ref it is treated as a list of positional key
# names.  The n-th remaining argument is mapped to the n-th key name.
# =========================================================================

subtest 'arrayref default: two args mapped to named keys' => sub {
	my $result = get_params([qw(name age)], 'Alice', 30);

	is_deeply($result, { name => 'Alice', age => 30 }, 'positional args mapped correctly');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'cycle-free');

	diag explain $result if $ENV{TEST_VERBOSE};
};

subtest 'arrayref default: missing trailing arg produces undef for that key' => sub {
	my $result = get_params([qw(name age)], 'Bob');
	is_deeply($result, { name => 'Bob', age => undef }, 'missing arg key present with undef value');
};

subtest 'arrayref default: extra args beyond key count are silently discarded' => sub {
	my $result = get_params([qw(a b)], 1, 2, 99);
	is_deeply($result, { a => 1, b => 2 }, 'third arg discarded');
	ok(!exists $result->{99}, 'no phantom key from discarded arg');
};

subtest 'arrayref default: empty names list returns empty hashref' => sub {
	my $result = get_params([], 'ignored', 'also_ignored');
	is_deeply($result, {}, 'empty key list yields empty hashref');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest 'arrayref default: sole hashref passthrough consistent with scalar-default fast path' => sub {
	# Even with an arrayref $default, a single plain hashref is returned as-is.
	my $h      = { x => 1, y => 2 };
	my $result = get_params([qw(x y)], $h);

	is_deeply($result, $h, 'hashref returned unchanged');
	is($result,        $h, 'same reference object');
};

# =========================================================================
# SECTION 4: \@_ detection and two-element shorthand
#
# When the sole remaining arg is an ARRAY ref, get_params treats it as
# a \@_ passthrough.  The two-element shorthand fires only when:
#   element[0] eq $default  AND  !ref(element[1])
# =========================================================================

subtest '\@_ two-element shorthand: matching default + plain scalar value' => sub {
	# Simulates: caller does routine(country => 'US') and callee uses \@_.
	my $result = get_params('country', ['country', 'US']);
	is_deeply($result, { country => 'US' }, 'shorthand unwrapped correctly');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest '\@_ two-element shorthand: suppressed when value is a reference' => sub {
	# The !ref(element[1]) guard prevents the shorthand from misinterpreting
	# an arrayref value.  The whole \@_ becomes the wrapped value instead.
	my $result = get_params('list', ['list', [1, 2, 3]]);
	is_deeply($result, { list => ['list', [1, 2, 3]] },
		'ref value suppresses shorthand; whole \@_ wrapped under default');
};

subtest '\@_ shorthand suppressed when element[0] does not match $default' => sub {
	# The element[0] eq $default condition is strict: a mismatch disables shorthand.
	my $result = get_params('dest', ['source', 'US']);
	# from_arrayref=1, num_args=2, arg[1] not a HASH, then from_arrayref + $default fires.
	is_deeply($result, { dest => ['source', 'US'] },
		'non-matching key suppresses shorthand; whole \@_ wrapped under default');
};

subtest '\@_ multi-value list wrapped under scalar default' => sub {
	# Simulates caller doing routine('a', 'b', 'c') and callee using get_params('items', \@_).
	my $result = get_params('items', ['a', 'b', 'c']);
	is_deeply($result, { items => ['a', 'b', 'c'] },
		'multi-element \@_ stored as arrayref under default key');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest '\@_ mandatory-positional + options via arrayref' => sub {
	# Simulates: Obj->new('Alice', { role => 'admin' }) with callee using \@_.
	# from_arrayref=1, num_args=2, arg[1] is HASH (non-empty), arg[0] ne $default.
	my $result = get_params('name', ['Alice', { role => 'admin' }]);
	is_deeply(
		$result,
		{ name => 'Alice', role => 'admin' },
		'\@_ mandatory + options hashref merged correctly',
	);
};

# =========================================================================
# SECTION 5: Zero-argument dispatch
# =========================================================================

subtest 'zero args + defined $default: Carp::confess with "Usage" message' => sub {
	# confess (not croak) is used here to include a full stack trace, since
	# missing a required argument is almost always a programming error.
	my $spy = spy 'Carp::confess';

	throws_ok(
		sub { get_params('required_key') },
		$USAGE_RE,
		'confess thrown when $default defined and no args provided',
	);

	my @calls = $spy->();
	ok(@calls >= 1, 'Carp::confess called');

	my $msg = join '', grep { defined } @{$calls[0]}[1 .. $#{$calls[0]}];
	like($msg, $USAGE_RE,           'confess message contains "Usage"');
	like($msg, qr/required_key/,    'confess message contains the $default key name');

	diag "confess args: $msg" if $ENV{TEST_VERBOSE};
	restore_all();
};

subtest 'zero args + undef $default: returns undef gracefully' => sub {
	my $result = get_params();
	ok(!defined $result, 'undef returned for zero args with undef $default');
	# undef satisfies an optional hashref spec
	returns_ok(undef, { type => 'hashref', optional => 1 }, 'undef ok for optional hashref spec');
};

# =========================================================================
# SECTION 6: One-argument dispatch
#
# With $default defined, the single argument is wrapped under that key.
# Without $default, the sole arg must be a hashref (or an empty arrayref).
# =========================================================================

subtest 'one arg + defined $default: plain scalar wrapped under key' => sub {
	my $result = get_params('country', 'DE');
	is_deeply($result, { country => 'DE' }, 'scalar wrapped under default key');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'one arg + defined $default: arrayref stored by reference (no copy)' => sub {
	my @list   = (1, 2, 3);
	my $result = get_params('items', \@list);

	is_deeply($result, { items => [1, 2, 3] }, 'arrayref stored under key');
	is($result->{items}, \@list, 'same arrayref reference, not a copy');
};

subtest 'one arg + defined $default: scalarref value is dereferenced before wrapping' => sub {
	my $val    = 'hello';
	my $result = get_params('msg', \$val);
	is_deeply($result, { msg => 'hello' }, 'scalarref dereferenced; scalar value stored');
};

subtest 'one arg + defined $default: coderef stored callable' => sub {
	my $cb     = sub { 42 };
	my $result = get_params('handler', $cb);

	is($result->{handler},     $cb, 'coderef stored by identity');
	is($result->{handler}->(), 42,  'stored coderef is still callable');
};

subtest 'one arg + defined $default: blessed object wrapped under default key' => sub {
	# Scalar::Util::blessed is an XS alias and cannot be reliably mocked via
	# symbol table replacement.  Test the dispatch path with a real blessed object.
	my $obj    = bless { value => 42 }, 'Test::DummyClass';
	my $result = get_params('thing', $obj);

	is_deeply($result, { thing => $obj }, 'blessed object wrapped under default key');
	is($result->{thing}, $obj, 'same blessed reference stored (not copied)');
	is(Scalar::Util::blessed($result->{thing}), 'Test::DummyClass',
		'returned value is still blessed as the correct class');
};

subtest 'one arg + defined $default: unblessed hashref falls through to no-$default path (LIMITATION)' => sub {
	# None of the defined-$default handlers matches an unblessed hashref,
	# so execution falls through to the no-$default path, which returns it directly.
	# This is a documented LIMITATION (single hashref always bypasses $default key naming).
	my $h      = { a => 1 };
	my $result = get_params('key', $h);

	is_deeply($result, $h, 'hashref returned directly, not wrapped under key');
	is($result,        $h, 'same reference object returned');
};

subtest 'one arg + undef $default: undef arg returns undef' => sub {
	my $result = get_params(undef, undef);
	ok(!defined $result, 'undef arg with undef $default returns undef');
};

subtest 'one arg + undef $default: hashref passed through unchanged' => sub {
	my $h      = { k => 'v' };
	my $result = get_params(undef, $h);

	is($result, $h, 'hashref returned by identity');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest 'one arg + undef $default: REF-of-REF unwrapped; inner hashref returned' => sub {
	my $inner  = { x => 1 };
	my $rref   = \$inner;    # ref-to-ref-to-hashref
	my $result = get_params(undef, $rref);

	is_deeply($result, $inner, 'inner hashref extracted from REF-of-REF');
};

subtest 'one arg + undef $default: empty arrayref inside \@_ returned as-is' => sub {
	# get_params(undef, $aref) where $aref=[] treats the lone arrayref as
	# \@_ of an empty list and returns undef -- that is the documented LIMITATION.
	#
	# The "return empty arrayref directly" branch is only reachable when the
	# caller passes \@_ and @_ contains exactly one empty arrayref as its sole
	# element, i.e. get_params(undef, [$aref]).
	my $aref   = [];
	my $result = get_params(undef, [$aref]);    # \@_ wrapper around the lone []

	is(ref($result),      'ARRAY', 'empty arrayref returned as ARRAY ref');
	is(scalar @{$result}, 0,       'returned array is empty');
	is($result,           $aref,   'same reference object returned (not a copy)');
};

subtest 'one arg + undef $default: unrecognised scalar croaks with "Usage"' => sub {
	my $spy = spy 'Carp::croak';

	throws_ok(
		sub { get_params(undef, 'lone_scalar') },
		$USAGE_RE,
		'lone scalar without $default throws',
	);

	my @calls = $spy->();
	ok(@calls >= 1, 'Carp::croak was called');
	like(
		join('', grep { defined } @{$calls[0]}[1 .. $#{$calls[0]}]),
		$USAGE_RE,
		'croak message says "Usage"',
	);

	restore_all();
};

# =========================================================================
# SECTION 7: Two-argument dispatch where arg[1] is a hashref
#
# Covers the Obj->new($mandatory, \%options) calling convention.
# =========================================================================

subtest 'two args, non-empty options: mandatory value merged with options' => sub {
	my $result = get_params('name', 'Alice', { role => 'admin', active => 1 });
	is_deeply(
		$result,
		{ name => 'Alice', role => 'admin', active => 1 },
		'mandatory value and option keys merged',
	);
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'two args, first arg IS the default key name: options hashref becomes the value' => sub {
	# When arg[0] eq $default, the second hashref is the value, not options to merge.
	my $result = get_params('config', 'config', { a => 1, b => 2 });
	is_deeply(
		$result,
		{ config => { a => 1, b => 2 } },
		'arg[0] matching $default wraps the options hashref as the value',
	);
};

subtest 'two args, empty options hashref: ref stored as value under default' => sub {
	my $result = get_params('name', 'Bob', {});
	is_deeply($result, { name => {} }, 'empty options hashref stored as value');
};

subtest 'two args with hashref but no $default: treated as even-length key-value pair' => sub {
	# Without $default the 2-arg hashref branch is skipped entirely.
	my $result = get_params(undef, 'opts', { a => 1 });
	is_deeply($result, { opts => { a => 1 } }, 'no $default: two args become a key-value pair');
};

# =========================================================================
# SECTION 8: Even-length named-pairs dispatch
# =========================================================================

subtest 'named pairs: two pairs returned as hashref' => sub {
	my $result = get_params(undef, foo => 'bar', baz => 42);

	is_deeply($result, { foo => 'bar', baz => 42 }, 'two named pairs normalised');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'named pairs: four pairs' => sub {
	my $result = get_params(undef, a => 1, b => 2, c => 3, d => 4);
	is_deeply($result, { a => 1, b => 2, c => 3, d => 4 }, 'four named pairs');
};

subtest 'named pairs: duplicate keys -- last value wins (documented behavior)' => sub {
	# Perl hash construction silently overwrites duplicate keys.
	# This is documented in LIMITATIONS; get_params makes no attempt to detect it.
	my $result = get_params(undef, x => 'first', x => 'second');
	is($result->{x}, 'second', 'second occurrence of duplicate key wins');
};

subtest 'named pairs with defined $default: pairs still processed as flat list' => sub {
	my $result = get_params('unused', k1 => 'v1', k2 => 'v2');
	is_deeply($result, { k1 => 'v1', k2 => 'v2' }, 'even-length list processed regardless of $default');
};

# =========================================================================
# SECTION 9: Odd-length error path
# =========================================================================

subtest 'three args (odd) with undef $default: croaks' => sub {
	my $spy = spy 'Carp::croak';

	throws_ok(
		sub { get_params(undef, 'a', 'b', 'c') },
		$USAGE_RE,
		'odd arg count throws',
	);

	my @calls = $spy->();
	ok(@calls >= 1, 'Carp::croak called for odd arg count');
	like(
		join('', grep { defined } @{$calls[0]}[1 .. $#{$calls[0]}]),
		$USAGE_RE,
		'croak message says "Usage"',
	);

	restore_all();
};

subtest 'five args (odd): croaks' => sub {
	throws_ok(
		sub { get_params(undef, a => 1, b => 2, 'orphan') },
		$USAGE_RE,
		'five-arg odd list throws',
	);
};

# =========================================================================
# SECTION 10: Caller variable mutation prevention
#
# The REF-of-REF unwrap path now copies to a local $val before doing the
# ref check.  Previously it assigned through the @_ alias and mutated the
# caller's variable in place.  These tests are a permanent regression guard
# for that security fix.
# =========================================================================

subtest 'REF-of-REF unwrap: caller variable not mutated (regression guard)' => sub {
	my $inner = { key => 'value' };
	my $rref  = \$inner;      # ref-to-ref-to-hashref

	my $result = get_params(undef, $rref);

	# The returned value must be the inner hashref.
	is_deeply($result, $inner, 'correct hashref extracted');

	# The critical assertion: $rref must still be a REF pointing to $inner.
	is(ref($rref),  'REF',   '$rref is still a REF (not unwrapped in place)');
	is($$rref,      $inner,  '$rref still dereferences to $inner');

	diag sprintf('rref is: %s', ref(\$rref)) if $ENV{TEST_VERBOSE};
};

subtest 'REF-of-SCALAR-ref: caller var unchanged even when call croaks' => sub {
	my $str  = 'hello';
	my $sref = \$str;        # ref-to-scalar
	my $rref = \$sref;       # ref-to-ref-to-scalar (unwraps to scalarref, not hashref -> croak)

	throws_ok(
		sub { get_params(undef, $rref) },
		$USAGE_RE,
		'REF-of-SCALAR-ref croaks (no hashref inside)',
	);

	# Despite the croak, $rref and $sref must be unchanged.
	is(ref($rref),   'REF',    '$rref still a REF after failed call');
	is($$rref,       $sref,    '$rref still dereferences to $sref');
	is(ref($$rref),  'SCALAR', 'inner $sref still a SCALAR ref');
};

# =========================================================================
# SECTION 11: Systematic return-type validation via Test::Returns
# =========================================================================

subtest 'Test::Returns: all success paths return hashref' => sub {
	my @cases = (
		[ 'single hashref (fast path)',     get_params({ a => 1 })                         ],
		[ 'named pairs',                    get_params(undef, x => 1, y => 2)              ],
		[ 'scalar default',                 get_params('k', 'v')                            ],
		[ 'scalarref default',              get_params('k', \'v')                           ],
		[ 'arrayref-of-names default',      get_params([qw(a b)], 1, 2)                    ],
		[ 'mandatory + non-empty options',  get_params('n', 'Alice', { role => 'admin' })  ],
	);

	for my $case (@cases) {
		my ($label, $result) = @{$case};
		returns_ok($result, { type => 'hashref' }, "hashref: $label");
	}
};

subtest 'Test::Returns: undef return satisfies optional-hashref spec' => sub {
	returns_ok(undef, { type => 'hashref', optional => 1 },
		'get_params() with no args: undef ok for optional hashref');
};

# =========================================================================
# SECTION 12: Memory cycle checks
#
# No path in get_params introduces a self-referential structure.
# Verify this for every construction route.
# =========================================================================

subtest 'no memory cycles in any construction path' => sub {
	memory_cycle_ok(get_params({ a => 1 }),                 'single hashref (fast path)');
	memory_cycle_ok(get_params(undef, foo => 'bar'),        'named pairs');
	memory_cycle_ok(get_params('k', 'v'),                   'scalar default');
	memory_cycle_ok(get_params([qw(x y)], 10, 20),         'arrayref-of-names default');
	memory_cycle_ok(get_params('n', 'val', { opt => 1 }),  'mandatory + options');
};

done_testing();
