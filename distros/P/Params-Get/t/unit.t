#!/usr/bin/env perl

# Black-box unit tests for Params::Get::get_params.
#
# Strategy: test every calling convention and every error path exactly as
# specified in the public POD.  No knowledge of implementation internals is
# assumed.  Each LIMITATION documented in the POD is given its own named
# subtest so that future changes that accidentally alter documented behavior
# are caught immediately.
#
# Libraries:
#   Test::Most          -- core assertions (is, is_deeply, throws_ok, lives_ok, …)
#   Test::Returns       -- validates return-value shapes against Return::Set schemas
#   Test::Memory::Cycle -- verifies no circular references in returned values
#   Readonly            -- eliminates magic strings/numbers in assertions

use strict;
use warnings;

use Test::Most;
use Test::Needs qw(Test::Returns Test::Memory::Cycle);
use Test::Mockingbird 0.08;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util ();
use Params::Get qw(get_params);

# Named constants -- no magic strings/numbers anywhere in assertions.
Readonly::Scalar my $PKG              => 'Params::Get';
Readonly::Scalar my $USAGE_RE         => qr/Usage:/;
Readonly::Scalar my $DEFAULT_CROAK_RE => qr/Params::Get::get_params: \$default must be a scalar or arrayref/;

# =========================================================================
# SECTION 1: Module contract
#
# POD declares "@EXPORT_OK = qw(get_params)".  The function must be
# importable on demand but must NOT appear in the default export list.
# =========================================================================

subtest 'module contract: get_params importable on demand' => sub {
	ok(Params::Get->can('get_params'),  "$PKG defines get_params");
	ok(defined &get_params,             'get_params imported into this namespace');
};

subtest 'module contract: no default exports -- @EXPORT is empty' => sub {
	is(scalar @Params::Get::EXPORT,    0,            '@EXPORT is empty');
	is(scalar @Params::Get::EXPORT_OK, 1,            '@EXPORT_OK has exactly one symbol');
	is($Params::Get::EXPORT_OK[0],     'get_params', 'that symbol is get_params');
};

# =========================================================================
# SECTION 2: Return type contract
#
# POD: "A hash-ref on success, or undef when $default is undef and no
# arguments are provided."  Every success path must return a hashref;
# the only undef return is the zero-arg + undef-$default case.
# =========================================================================

subtest 'return type: all success paths return a hashref' => sub {
	my $cb  = sub { 1 };
	my $obj = bless {}, 'Unit::Ret';

	my @cases = (
		[ 'single hashref fast path',     get_params({ a => 1 })                        ],
		[ 'named pairs',                  get_params(undef, x => 1, y => 2)             ],
		[ 'scalar + default key',         get_params('k', 'v')                           ],
		[ 'scalarref + default key',      get_params('k', \'v')                         ],
		[ 'arrayref-of-names default',    get_params([qw(a b)], 1, 2)                   ],
		[ 'mandatory + non-empty opts',   get_params('n', 'Alice', { role => 'admin' }) ],
		[ 'coderef wrapped under key',    get_params('fn', $cb)                         ],
		[ 'blessed object under key',     get_params('o', $obj)                         ],
	);

	for my $case (@cases) {
		my ($label, $val) = @{$case};
		is(ref($val), 'HASH', "ref is HASH: $label");
		returns_ok($val, { type => 'hashref' }, "schema: $label");
	}

	diag 'All success-path return types verified' if $ENV{TEST_VERBOSE};
};

subtest 'return type: zero args + undef $default returns undef (not hashref)' => sub {
	my $result = get_params();
	ok(!defined $result, 'get_params() returns undef');
	# The POD schema marks the return as optional, so undef is valid per spec.
	returns_ok(undef, { type => 'hashref', optional => 1 },
		'undef satisfies optional hashref schema');
};

subtest 'return type: undef return is not 0, empty string, or false hashref' => sub {
	my $result = get_params();
	ok(!defined $result,   'return is undef, not defined-false');
	isnt($result, 0,       'not 0');
	isnt($result, '',      'not empty string');
};

# =========================================================================
# SECTION 3: Global state integrity
#
# Calls to get_params must not clobber $@, $!, or $_ in the caller, and
# must not reset a running alarm() countdown.
# =========================================================================

subtest 'global state: $@ not clobbered on successful call' => sub {
	local $@ = 'sentinel_at';
	get_params(undef, foo => 'bar');
	is($@, 'sentinel_at', '$@ unchanged after get_params');
};

subtest 'global state: $! not modified on successful call' => sub {
	require POSIX;
	$! = POSIX::ENOENT();
	my $before = int($!);
	get_params(undef, x => 1);
	is(int($!), $before, '$! (errno) unchanged after get_params');
};

subtest 'global state: $_ (topic variable) not clobbered' => sub {
	local $_ = 'sentinel_topic';
	get_params(undef, a => 1);
	is($_, 'sentinel_topic', '$_ unchanged after get_params');
};

subtest 'global state: alarm countdown not reset or cleared by get_params' => sub {
	plan skip_all => 'alarm() not supported on Windows' if $^O eq 'MSWin32';
	# Set a 300-second countdown, call get_params (takes microseconds),
	# then immediately restore the original alarm via alarm($prev).
	# The returned remaining time must be indistinguishably close to 300.
	my $prev      = alarm(300);
	get_params(undef, foo => 'bar');
	my $remaining = alarm($prev);    # restore; capture remaining
	cmp_ok($remaining, '>=', 298, 'alarm not cleared or materially shortened');
	cmp_ok($remaining, '<=', 300, 'alarm remaining is plausible (upper bound)');
};

# =========================================================================
# SECTION 4: Fast path
#
# POD Pseudocode step 1: "Fast-path: if the sole argument is a plain HASH
# ref, return it immediately (fires before $default is inspected)."
# =========================================================================

subtest 'fast path: single hashref returned by identity (no copy)' => sub {
	my $h      = { foo => 'bar', num => 42 };
	my $result = get_params($h);

	is_deeply($result, { foo => 'bar', num => 42 }, 'content intact');
	is($result,         $h,                          'same reference -- no copy made');
	memory_cycle_ok($result, 'fast-path result is cycle-free');

	diag explain $result if $ENV{TEST_VERBOSE};
};

subtest 'fast path: empty hashref returned by identity' => sub {
	my $h      = {};
	my $result = get_params($h);
	is_deeply($result, {}, 'empty hashref returned');
	is($result,         $h, 'same reference');
};

subtest 'fast path fires before $default is inspected (documented LIMITATION)' => sub {
	# LIMITATION: get_params('config', { a => 1 }) returns { a => 1 },
	# not { config => { a => 1 } }.  The fast path sees 1 hashref arg and
	# returns immediately -- $default is never reached.
	my $h      = { a => 1 };
	my $result = get_params('config', $h);

	is_deeply($result,  $h,  'hashref returned directly');
	is($result,          $h,  'same reference');
	ok(!exists $result->{config}, '"config" key absent -- fast path overrode $default');

	diag 'LIMITATION: single hashref always bypasses $default key naming' if $ENV{TEST_VERBOSE};
};

# =========================================================================
# SECTION 5: $default validation
#
# POD: "Croaks from the caller's frame ... non-ARRAY ref passed as $default."
# Exact croak message: "Params::Get::get_params: $default must be a scalar or
# arrayref".
# =========================================================================

subtest '$default HASH ref: croaks with exact message before touching args' => sub {
	throws_ok(
		sub { get_params({}, 'irrelevant_arg') },
		$DEFAULT_CROAK_RE,
		'HASH ref as $default: exact croak message',
	);
};

subtest '$default SCALAR ref: croaks immediately' => sub {
	throws_ok(
		sub { get_params(\'text', 'arg') },
		$DEFAULT_CROAK_RE,
		'SCALAR ref as $default: exact croak message',
	);
};

subtest '$default CODE ref: croaks immediately' => sub {
	throws_ok(
		sub { get_params(sub { }, 'arg') },
		$DEFAULT_CROAK_RE,
		'CODE ref as $default: exact croak message',
	);
};

subtest '$default REF-of-REF: croaks immediately' => sub {
	my $inner = {};
	my $rref  = \$inner;
	throws_ok(
		sub { get_params($rref, 'arg') },
		$DEFAULT_CROAK_RE,
		'REF-of-REF as $default: exact croak message',
	);
};

subtest '$default undef: accepted without error' => sub {
	lives_ok(sub { get_params(undef, foo => 1) }, 'undef $default is valid');
};

subtest '$default plain string: accepted without error' => sub {
	lives_ok(sub { get_params('key', 'val') }, 'string $default is valid');
};

subtest '$default arrayref of strings: accepted without error' => sub {
	lives_ok(sub { get_params([qw(a b)], 1, 2) }, 'arrayref $default is valid');
};

# =========================================================================
# SECTION 6: Arrayref-of-names $default
#
# POD Pseudocode step 3: "If $default is an ARRAY ref, map remaining @_
# positionally to those key names and return."
# Formal spec: get_params([n1..nk], v*) == {ni -> vi}  i in 1..k
# =========================================================================

subtest 'arrayref default: two args mapped to named keys' => sub {
	my $result = get_params([qw(name age)], 'Alice', 30);
	is_deeply($result, { name => 'Alice', age => 30 }, 'two positional args mapped');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'arrayref default: missing arg produces undef for that key (key still present)' => sub {
	my $result = get_params([qw(name age)], 'Bob');
	ok(exists $result->{age},     'age key present even though not supplied');
	ok(!defined $result->{age},   'missing arg maps to undef');
	is($result->{name}, 'Bob',    'supplied arg mapped correctly');
};

subtest 'arrayref default: extra args silently discarded (documented LIMITATION)' => sub {
	my $result = get_params([qw(a b)], 1, 2, 3);
	is_deeply($result, { a => 1, b => 2 }, 'extra arg discarded');
	ok(!exists $result->{3}, 'no phantom key from discarded extra arg');
	is(scalar keys %{$result}, 2, 'result has exactly two keys');

	diag 'LIMITATION: positional-names $default silently discards extra args' if $ENV{TEST_VERBOSE};
};

subtest 'arrayref default: empty names list returns empty hashref' => sub {
	my $result = get_params([], 'ignored', 'also_ignored');
	is_deeply($result, {}, 'empty key list yields empty hashref');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest 'arrayref default: single hashref passthrough preserved (consistent with fast path)' => sub {
	my $h      = { x => 1 };
	my $result = get_params([qw(x y)], $h);
	is_deeply($result, $h, 'hashref passed through unchanged');
	is($result,          $h, 'same reference returned');
};

subtest 'arrayref default: single undef arg maps to first key as undef' => sub {
	my $result = get_params([qw(name)], undef);
	ok(exists $result->{name},   'key present');
	ok(!defined $result->{name}, 'value is undef');
};

# =========================================================================
# SECTION 7: \@_ detection and two-element shorthand
#
# POD Pseudocode step 4: detect \@_ calling convention.  Two-element
# shorthand fires when element[0] eq $default AND !ref(element[1]).
# =========================================================================

subtest '\@_ two-element shorthand: matching default + plain scalar' => sub {
	# Simulates: caller does routine(country => 'US') and callee uses \@_.
	my $result = get_params('country', ['country', 'US']);
	is_deeply($result, { country => 'US' }, 'shorthand unwrapped correctly');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest '\@_ shorthand suppressed: value is a reference' => sub {
	# !ref(element[1]) guard: if value is a ref the shorthand does NOT fire.
	# The whole arrayref is stored as the value under $default instead.
	my $result = get_params('list', ['list', [1, 2, 3]]);
	is_deeply($result, { list => ['list', [1, 2, 3]] },
		'ref value suppresses shorthand; whole \@_ stored under default');
};

subtest '\@_ shorthand suppressed: element[0] does not match $default' => sub {
	my $result = get_params('dest', ['source', 'US']);
	is_deeply($result, { dest => ['source', 'US'] },
		'key mismatch suppresses shorthand; whole \@_ stored under default');
};

subtest '\@_ multi-value: all elements stored as arrayref under scalar default' => sub {
	my $result = get_params('items', ['a', 'b', 'c']);
	is_deeply($result, { items => ['a', 'b', 'c'] },
		'multi-element \@_ stored as arrayref under default key');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest '\@_ mandatory-positional + options hashref' => sub {
	# Simulates Obj->new('Alice', { role => 'admin' }) when callee uses \@_.
	my $result = get_params('name', ['Alice', { role => 'admin' }]);
	is_deeply(
		$result,
		{ name => 'Alice', role => 'admin' },
		'\@_ mandatory + non-empty options merged correctly',
	);
};

# =========================================================================
# SECTION 8: Zero-argument dispatch
#
# POD: confess (full stack trace) when $default is defined but zero args.
# Error contains "Usage:" and the $default key name.
# Return undef when $default is undef.
# =========================================================================

subtest 'zero args + defined $default: confess thrown containing "Usage:"' => sub {
	throws_ok(
		sub { get_params('required') },
		$USAGE_RE,
		'confess message contains "Usage:"',
	);
};

subtest 'zero args + defined $default: error message contains the key name' => sub {
	throws_ok(
		sub { get_params('my_secret_key') },
		qr/my_secret_key/,
		'confess message includes the $default key name',
	);
};

subtest 'zero args + undef $default: returns undef gracefully' => sub {
	my $result = get_params();
	ok(!defined $result, 'get_params() returns undef');
};

subtest 'zero args + explicit undef $default: returns undef' => sub {
	# get_params(undef): single arg (undef) -- not a hashref, so fast path
	# skips.  $default=undef shifted; zero remaining args; !defined($default)
	# -> return undef.
	my $result = get_params(undef);
	ok(!defined $result, 'get_params(undef) returns undef');
};

# =========================================================================
# SECTION 9: One-argument dispatch
#
# POD: with $default defined, wrap the single arg under that key.
# Types handled: plain scalar, arrayref, scalarref (auto-dereferenced),
# coderef, blessed object.
# Without $default: hashref passes through; REF-of-REF unwrapped;
# empty arrayref returned as-is; anything else croaks.
# =========================================================================

subtest 'one arg + $default: plain scalar wrapped under key' => sub {
	my $result = get_params('country', 'US');
	is_deeply($result, { country => 'US' }, 'scalar wrapped');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'one arg + $default: numeric scalar wrapped under key' => sub {
	my $result = get_params('count', 42);
	is_deeply($result, { count => 42 }, 'numeric scalar wrapped');
};

subtest 'one arg + $default: undef arg wrapped under key' => sub {
	# Single undef arg: $arg = undef, ref('') -> !$kind -> return { $default => undef }.
	my $result = get_params('flag', undef);
	ok(exists  $result->{flag},   'key present for undef arg');
	ok(!defined $result->{flag},  'value is undef');
};

subtest 'one arg + $default: arrayref stored under key (not dereferenced)' => sub {
	my @list   = (1, 2, 3);
	my $result = get_params('items', \@list);
	is_deeply($result, { items => [1, 2, 3] }, 'arrayref stored under key');
	is($result->{items}, \@list, 'same arrayref reference -- not copied');
};

subtest 'one arg + $default: scalarref is dereferenced before wrapping' => sub {
	# POD: "Scalar-ref: foo(\'text') -- dereferenced automatically"
	my $str    = 'hello';
	my $result = get_params('msg', \$str);
	is_deeply($result, { msg => 'hello' }, 'scalarref dereferenced; scalar stored');
	is(ref($result->{msg}), '', 'stored value is a plain scalar, not a ref');
};

subtest 'one arg + $default: coderef stored under key, still callable' => sub {
	my $cb     = sub { 42 };
	my $result = get_params('handler', $cb);
	is($result->{handler},     $cb, 'same coderef stored by identity');
	is($result->{handler}->(), 42,  'stored coderef remains callable');
};

subtest 'one arg + $default: blessed object wrapped under key' => sub {
	my $obj    = bless { value => 99 }, 'Unit::Blessed';
	my $result = get_params('widget', $obj);
	is_deeply($result, { widget => $obj }, 'blessed object wrapped');
	is(Scalar::Util::blessed($result->{widget}), 'Unit::Blessed',
		'blessedness and class preserved in stored reference');
};

subtest 'one arg + undef $default: plain hashref passed through unchanged' => sub {
	my $h      = { k => 'v', num => 7 };
	my $result = get_params(undef, $h);
	is($result, $h, 'hashref returned by identity');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
};

subtest 'one arg + undef $default: undef arg returns undef' => sub {
	my $result = get_params(undef, undef);
	ok(!defined $result, 'undef arg with undef $default returns undef');
};

subtest 'one arg + undef $default: REF-of-REF unwrapped to inner hashref' => sub {
	my $inner  = { x => 'y' };
	my $rref   = \$inner;    # ref-to-ref-to-hashref
	my $result = get_params(undef, $rref);
	is_deeply($result, $inner, 'inner hashref extracted from REF-of-REF');
	is(ref($result),   'HASH', 'result is a HASH ref');
};

subtest 'one arg + undef $default: lone scalar croaks with "Usage:"' => sub {
	throws_ok(
		sub { get_params(undef, 'bare_scalar') },
		$USAGE_RE,
		'lone scalar without $default croaks',
	);
};

subtest 'one arg + undef $default: unblessed hashref is the value -- no $default wrapping' => sub {
	# Documented LIMITATION: single hashref always goes through the fast path or
	# the no-$default path; it is never wrapped under $default.
	my $h      = { a => 1 };
	my $result = get_params('key', $h);

	is_deeply($result, $h,  'hashref returned directly, not wrapped under "key"');
	ok(!exists $result->{key}, '"key" key absent');
};

# =========================================================================
# SECTION 10: Two-arg with hashref -- mandatory-positional + options pattern
#
# POD: "Mandatory positional argument plus an options hash-ref:
#        Obj->new($val, { opt => 1 })"
# Formal spec:
#   get_params(d, v, {k->w..}) == {d->v, k->w..}  non-empty opts
#   get_params(d, d, {k->w..}) == {d -> {k->w..}}  first arg IS key name
# =========================================================================

subtest 'mandatory + non-empty options: mandatory value merged with options' => sub {
	my $result = get_params('name', 'Alice', { role => 'admin', active => 1 });
	is_deeply(
		$result,
		{ name => 'Alice', role => 'admin', active => 1 },
		'mandatory value and option keys merged',
	);
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'mandatory + options: first arg IS the default key -- options become the value' => sub {
	# Formal spec: get_params(d, d, {k->w..}) == {d -> {k->w..}}
	my $result = get_params('config', 'config', { a => 1, b => 2 });
	is_deeply(
		$result,
		{ config => { a => 1, b => 2 } },
		'options hashref stored as value when first arg matches $default',
	);
};

subtest 'mandatory + empty options hashref: ref stored as value under default' => sub {
	my $result = get_params('name', 'Bob', {});
	is_deeply($result, { name => {} }, 'empty options hashref stored as value');
};

subtest 'mandatory + options: no $default -- treated as even-length key-value pair' => sub {
	# Without $default the two-arg hashref branch is skipped; the two args
	# become a single key-value pair.
	my $result = get_params(undef, 'opts', { a => 1 });
	is_deeply($result, { opts => { a => 1 } }, 'two args become one named pair');
};

# =========================================================================
# SECTION 11: Even-length named pairs
#
# POD: "Named key/value pairs: foo(a => 1, b => 2)"
# Formal spec: get_params(undef, k1,v1..) == {ki -> vi}  when |A| is even
# =========================================================================

subtest 'named pairs: two pairs normalised into hashref' => sub {
	my $result = get_params(undef, foo => 'bar', baz => 42);
	is_deeply($result, { foo => 'bar', baz => 42 }, 'two named pairs normalised');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'named pairs: four pairs' => sub {
	my $result = get_params(undef, a => 1, b => 2, c => 3, d => 4);
	is_deeply($result, { a => 1, b => 2, c => 3, d => 4 }, 'four named pairs');
};

subtest 'named pairs: values may be refs, blessed objects, and undef' => sub {
	my $cb   = sub { };
	my $obj  = bless {}, 'Unit::T';
	my $result = get_params(undef,
		code  => $cb,
		obj   => $obj,
		empty => undef,
		num   => 3.14,
	);
	is($result->{code},       $cb,    'coderef value preserved');
	is($result->{obj},        $obj,   'blessed object value preserved');
	ok(!defined $result->{empty},     'undef value preserved');
	is($result->{num},        3.14,   'numeric value preserved');
};

subtest 'named pairs: duplicate keys -- last value wins (documented LIMITATION)' => sub {
	# LIMITATION: "Duplicate keys in a flat list silently overwrite; last value wins."
	my $result = get_params(undef, x => 'first', x => 'second');
	is($result->{x}, 'second', 'last occurrence of duplicate key wins');

	diag 'LIMITATION: duplicate keys silently overwrite; last value wins' if $ENV{TEST_VERBOSE};
};

subtest 'named pairs: defined $default does not affect even-length processing' => sub {
	# When arg count is even and > 2, the even-length path fires regardless of $default.
	my $result = get_params('unused', k1 => 'v1', k2 => 'v2');
	is_deeply($result, { k1 => 'v1', k2 => 'v2' }, 'even list processed as named pairs');
	ok(!exists $result->{unused}, '$default key absent from result');
};

# =========================================================================
# SECTION 12: Odd-length error path
#
# POD: "odd N -- croak."  Error message: "Usage: Pkg->method()"
# =========================================================================

subtest 'odd args (3) + undef $default: croaks with "Usage:"' => sub {
	throws_ok(
		sub { get_params(undef, 'a', 'b', 'c') },
		$USAGE_RE,
		'three-arg list (odd) croaks',
	);
};

subtest 'odd args (5) + undef $default: croaks' => sub {
	throws_ok(
		sub { get_params(undef, a => 1, b => 2, 'orphan') },
		$USAGE_RE,
		'five-arg odd list croaks',
	);
};

subtest 'odd args (3) + defined $default: still croaks' => sub {
	throws_ok(
		sub { get_params('key', 'a', 'b', 'c') },
		$USAGE_RE,
		'odd arg list with defined $default still croaks',
	);
};

# =========================================================================
# SECTION 13: Documented LIMITATIONS as explicit acceptance tests
#
# Each LIMITATION named in the POD is verified here as an intentional,
# specified behavior.  Tests document *intended* behavior, not bugs.
# =========================================================================

subtest 'LIMITATION: single empty arrayref indistinguishable from \@_ of empty list' => sub {
	# POD LIMITATION: "When the caller does foo([]) and the callee uses
	# get_params('key', @_), the lone arrayref is treated as a \@_
	# passthrough, unwraps to an empty list, and then croaks because
	# $default is defined but zero arguments remain."
	throws_ok(
		sub { get_params('key', []) },
		$USAGE_RE,
		'foo([]) with scalar $default throws (documented LIMITATION)',
	);

	diag 'LIMITATION: empty arrayref indistinguishable from \@_ of empty list' if $ENV{TEST_VERBOSE};
};

subtest 'LIMITATION: single hashref always bypasses $default key naming' => sub {
	# POD: "get_params('config', { a => 1 }) returns { a => 1 }, not
	# { config => { a => 1 } }.  The fast path fires before $default is
	# inspected."
	my $h      = { a => 1 };
	my $result = get_params('config', $h);
	is_deeply($result, $h,  'returned directly, not wrapped under "config"');
	ok(!exists $result->{config}, '"config" key absent -- fast path fired');
};

subtest 'LIMITATION: no graceful zero-arg path when $default is a string' => sub {
	# POD: "When $default is a string and zero arguments are received,
	# the function always confesses.  There is no way to express 'accept
	# zero args and return undef gracefully'."
	throws_ok(
		sub { get_params('required_key') },
		$USAGE_RE,
		'zero args + string $default always confesses (no opt-out)',
	);
};

subtest 'LIMITATION: duplicate key -- later key silently overwrites earlier one' => sub {
	# Security implication documented in POD: an attacker-controlled
	# trailing key can silently override an earlier sanitised value.
	my $result = get_params(undef, safe => 'sanitised', safe => 'attacker_value');
	is($result->{safe}, 'attacker_value', 'later key wins silently');
};

subtest 'LIMITATION: positional-names $default silently discards extra arguments' => sub {
	my $result = get_params([qw(a b)], 10, 20, 30, 40);
	is_deeply($result, { a => 10, b => 20 }, 'third and fourth args discarded');
	is(scalar keys %{$result}, 2, 'result has exactly two keys -- extras gone');
};

# =========================================================================
# SECTION 14: Memory cycle safety across all construction paths
#
# get_params builds hash refs from caller data.  No path should produce a
# self-referential (circular) structure that would prevent garbage collection.
# =========================================================================

subtest 'no memory cycles in any construction path' => sub {
	memory_cycle_ok(get_params({ a => 1 }),                'fast path');
	memory_cycle_ok(get_params(undef, foo => 'bar'),       'named pairs');
	memory_cycle_ok(get_params('k', 'v'),                  'scalar default');
	memory_cycle_ok(get_params('k', \'v'),                 'scalarref default');
	memory_cycle_ok(get_params([qw(x y)], 10, 20),        'positional-names default');
	memory_cycle_ok(get_params('n', 'val', { opt => 1 }), 'mandatory + options');
	memory_cycle_ok(get_params('o', bless {}, 'T'),        'blessed object');
};

done_testing();
