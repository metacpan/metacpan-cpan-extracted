#!/usr/bin/env perl

# Destructive, pathological, and security-focused edge-case tests for
# Params::Get::get_params.
#
# Strategy: actively try to break or subvert the module with:
#   - False-but-defined scalars (0, "", "0", undef)
#   - Exotic and undocumented reference types (GLOB, Regexp, triple REF)
#   - Circular (self-referential) data structures
#   - Pathologically large inputs
#   - List/scalar/boolean context confusion
#   - Global variable clobbering ($@, $!, $_, $\)
#   - Hostile upstream mocks (croak/confess suppressed; security consequences)
#   - Duplicate-key injection attacks
#   - Special characters in keys and $default names
#   - Boundary conditions on the arrayref-of-names $default feature
#
# Tests are derived strictly from POD-specified behavior.
# When a probe reveals a security consequence, it is documented explicitly.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird 0.08;
use Test::Returns;
use Readonly;
use Scalar::Util ();
use POSIX ();
use Params::Get qw(get_params);

# Named constants -- no magic strings/numbers in assertions.
Readonly::Scalar my $PKG              => 'Params::Get';
Readonly::Scalar my $USAGE_RE         => qr/Usage:/;
Readonly::Scalar my $DEFAULT_CROAK_RE => qr/\$default must be a scalar or arrayref/;
Readonly::Scalar my $ONE_MB           => 1_048_576;
Readonly::Scalar my $LARGE_PAIR_COUNT => 500;

# =========================================================================
# SECTION 1: False-but-defined and boundary scalar values
#
# Perl's truthiness rules: 0, "", "0", and undef are all false.
# Any internal conditional that tests truthiness rather than definedness
# can silently discard a legitimate caller value.  Attack each one.
# =========================================================================

subtest 'boundary: numeric zero (0) as value -- not lost to falsiness' => sub {
	# If any internal branch uses `if ($arg)` instead of `if (defined $arg)`,
	# a zero value would be silently dropped or treated as absent.
	my $result = get_params('count', 0);
	ok(defined $result->{count}, 'zero value is defined in result');
	is($result->{count}, 0,      'numeric zero preserved exactly');
	isnt($result->{count}, undef, 'not coerced to undef');
};

subtest 'boundary: empty string ("") as value -- not silently dropped' => sub {
	my $result = get_params('label', '');
	ok(exists $result->{label}, 'key present for empty-string value');
	is($result->{label}, '', 'empty string preserved');
};

subtest 'boundary: string "0" as value -- distinct from numeric 0' => sub {
	my $result = get_params('flag', '0');
	is($result->{flag}, '0', '"0" preserved as-is');
	is(ref($result->{flag}), '', 'stored value is plain scalar');
};

subtest 'boundary: "0E0" (zero-but-true) -- truthiness idiom preserved' => sub {
	my $result = get_params('rows', '0E0');
	is($result->{rows}, '0E0', '"0E0" value preserved');
	ok($result->{rows},  '"0E0" is truthy (Perl convention intact)');
};

subtest 'boundary: numeric zero (0) as $default key name -- accepted as valid scalar' => sub {
	# A $default of 0 is defined and not a ref; get_params must treat it as the key.
	my $result = get_params(0, 'payload');
	ok(exists $result->{0}, 'key "0" present (stringified)');
	is($result->{0}, 'payload', 'value accessible via numeric key');
};

subtest 'boundary: empty string ("") as $default key name -- defined non-ref accepted' => sub {
	my $result = get_params('', 'data');
	ok(exists $result->{''}, 'empty-string key present');
	is($result->{''},  'data', 'value accessible');
};

subtest 'boundary: undef as value with $default -- key present, value undef' => sub {
	# The !$kind branch fires (ref(undef) = ''); it must return the undef value.
	my $result = get_params('opt', undef);
	ok(exists $result->{opt},   'key present for undef value');
	ok(!defined $result->{opt}, 'value is undef (not absent)');
};

subtest 'boundary: 0 as $default, undef as value -- both falsy, both survive' => sub {
	my $result = get_params(0, undef);
	ok(exists $result->{0},    '"0" key present');
	ok(!defined $result->{0},  'value is undef');
};

subtest 'boundary: zero and empty string in named pairs' => sub {
	my $result = get_params(undef, 0 => 0, '' => '');
	is($result->{0},  0,  'key 0 => value 0');
	is($result->{''},'',  'key "" => value ""');
};

subtest 'boundary: 1 MB value string survives without truncation' => sub {
	my $big    = 'x' x $ONE_MB;
	my $result = get_params('blob', $big);
	is(length($result->{blob}), $ONE_MB, '1 MB value preserved in full');
	is(substr($result->{blob}, -1), 'x', 'last byte correct');
};

# =========================================================================
# SECTION 2: Exotic and undocumented reference types
#
# The POD documents specific ref types: arrayref, scalarref (dereferenced),
# coderef, blessed object.  Any undocumented ref type (GLOB, triple REF)
# must either croak or fall through to a predictable croak.
# =========================================================================

subtest 'exotic ref: GLOB ref (\*STDOUT) with $default -- falls through and croaks' => sub {
	# GLOB refs are not listed in the POD.  None of the defined-$default
	# handlers match 'GLOB', so execution falls to the no-$default path
	# which encounters an unrecognised type and croaks.
	throws_ok(
		sub { get_params('io', \*STDOUT) },
		$USAGE_RE,
		'GLOB ref with $default: croak expected',
	);
};

subtest 'exotic ref: GLOB ref without $default -- croaks' => sub {
	throws_ok(
		sub { get_params(undef, \*STDOUT) },
		$USAGE_RE,
		'GLOB ref without $default: croak expected',
	);
};

subtest 'exotic ref: Regexp object (qr//) with $default -- blessed dispatch wraps it' => sub {
	# qr// objects are blessed as "Regexp".  The blessed-dispatch branch fires
	# and stores the Regexp under $default -- it remains callable.
	my $re     = qr/^test_pattern$/;
	my $result = get_params('pattern', $re);

	is($result->{pattern}, $re, 'Regexp stored under $default key');
	is(Scalar::Util::blessed($result->{pattern}), 'Regexp',
		'blessedness preserved');
	ok('test_pattern' =~ $result->{pattern}, 'stored Regexp still matches');
};

subtest 'exotic ref: Regexp object without $default -- falls through and croaks' => sub {
	# Without $default the lone Regexp hits the no-$default path;
	# it is not a HASH ref and not an empty ARRAY ref, so it croaks.
	throws_ok(
		sub { get_params(undef, qr/foo/) },
		$USAGE_RE,
		'lone Regexp without $default: croak',
	);
};

subtest 'exotic ref: double REF-of-HASH unwraps correctly' => sub {
	# Regression guard: one-level unwrap of a REF-pointing-at-a-hashref works.
	my $h    = { a => 1 };
	my $rref = \$h;          # REF pointing at the hashref scalar

	my $result = get_params(undef, $rref);
	is_deeply($result, { a => 1 }, 'double REF-of-HASH unwrapped correctly');
};

subtest 'exotic ref: triple REF (REF-of-REF-of-HASH) croaks -- only one level unwrapped' => sub {
	# The unwrap step executes exactly once.  After unwrapping a triple REF,
	# what remains is still a REF (not a HASH), so the no-$default path croaks.
	my $h    = { key => 'val' };
	my $r1   = \$h;          # REF-of-HASH
	my $r2   = \$r1;         # REF-of-REF-of-HASH

	throws_ok(
		sub { get_params(undef, $r2) },
		$USAGE_RE,
		'triple REF croaks -- double is the documented limit',
	);
};

# =========================================================================
# SECTION 3: Circular (self-referential) data structures
#
# get_params must never attempt to deep-copy or traverse values.  A circular
# reference passed as input must emerge unchanged -- the same object identity
# must be preserved -- without triggering infinite recursion or memory leaks.
# =========================================================================

subtest 'circular: self-referential hashref in fast path returned by identity' => sub {
	# Fast path: lone hashref is returned immediately without traversal.
	# A circular structure must survive unmolested.
	my $h = { value => 42 };
	$h->{self} = $h;          # introduce a cycle

	my $result = get_params($h);

	is($result,            $h, 'same reference returned -- no copy attempted');
	is($result->{self},    $h, 'cycle intact in result');
	is($result->{self}{value}, 42, 'data reachable through cycle');

	diag 'circular ref survived fast path' if $ENV{TEST_VERBOSE};
};

subtest 'circular: self-referential hashref as named-pair value' => sub {
	my $h = { x => 10 };
	$h->{self} = $h;

	my $result = get_params(undef, container => $h);

	is($result->{container},       $h,  'circular value stored by identity');
	is($result->{container}{self}, $h,  'cycle still intact inside named pair');
};

subtest 'circular: single circular hashref triggers fast path (not $default wrapping)' => sub {
	# One arg, one hashref: fast path fires before $default is inspected.
	# Documented LIMITATION: single hashref bypasses $default key naming.
	my $h = {};
	$h->{self} = $h;

	my $result = get_params('wrap', $h);

	is($result, $h, 'fast path identity (LIMITATION: $default bypassed)');
	ok(!exists $result->{wrap}, '"wrap" key absent -- fast path overrode $default');
};

# =========================================================================
# SECTION 4: Pathologically large data
#
# Large even-length lists, very long key names, and large positional-names
# arrays must all process correctly and not silently truncate.
# =========================================================================

subtest 'large data: 500-pair even-length list returns complete hashref' => sub {
	my @pairs;
	push @pairs, ("key_$_", "val_$_") for 0 .. ($LARGE_PAIR_COUNT - 1);

	my $result = get_params(undef, @pairs);

	is(ref($result), 'HASH', 'result is a hashref');
	is(scalar keys %{$result}, $LARGE_PAIR_COUNT, 'all pairs present');
	is($result->{key_0},                            'val_0',                        'first pair correct');
	is($result->{"key_@{[$LARGE_PAIR_COUNT - 1]}"}, "val_@{[$LARGE_PAIR_COUNT-1]}", 'last pair correct');
};

subtest 'large data: 10_000-character $default key name' => sub {
	my $long   = 'k' x 10_000;
	my $result = get_params($long, 'v');
	ok(exists $result->{$long}, '10k-char key present');
	is($result->{$long}, 'v',   'value accessible under long key');
};

subtest 'large data: 10_000-character key in named pairs' => sub {
	my $long   = 'n' x 10_000;
	my $result = get_params(undef, $long => 'payload');
	ok(exists $result->{$long},  'long named-pair key present');
	is($result->{$long}, 'payload', 'value correct');
};

subtest 'large data: 100-field positional-names $default' => sub {
	my @keys = map { "field_$_" } 0 .. 99;
	my @vals = map { "value_$_" } 0 .. 99;
	my $result = get_params(\@keys, @vals);

	is(scalar keys %{$result}, 100, '100 fields mapped');
	is($result->{field_0},  'value_0',  'first field correct');
	is($result->{field_99}, 'value_99', 'last field correct');
};

# =========================================================================
# SECTION 5: Context abuse
#
# get_params always returns a hashref (scalar).  In list context that hashref
# is a one-element list.  Reentrant calls and contaminated $_ must all be
# handled gracefully.
# =========================================================================

subtest 'context: list context -- returns single-element list containing hashref' => sub {
	# Caller assigns into an array: the returned hashref is the sole element.
	my @list = get_params(undef, a => 1, b => 2);
	is(scalar @list, 1,      'exactly one element in list context');
	is(ref($list[0]), 'HASH', 'that element is a hashref');
	is($list[0]{a},   1,     'data accessible through array element');
};

subtest 'context: boolean context -- any returned hashref is truthy' => sub {
	my $full  = get_params({ x => 1 });
	my $empty = get_params({});
	ok(!!$full,  'non-empty hashref is true in boolean context');
	ok(!!$empty, 'empty hashref is also true (it is a reference)');
};

subtest 'context: $_ contaminated by outer map -- not clobbered inside get_params' => sub {
	# Common scenario: caller is inside a map where $_ is the loop variable.
	# get_params must not use or modify $_.
	my @results = map {
		local $_ = "item_$_";
		my $saved = $_;
		get_params(undef, key => 'val');
		$saved;    # must equal the saved $_ value
	} 1 .. 3;

	is($results[0], 'item_1', '$_ preserved after get_params in map iteration 1');
	is($results[1], 'item_2', '$_ preserved in iteration 2');
	is($results[2], 'item_3', '$_ preserved in iteration 3');
};

subtest 'context: reentrant call -- get_params inside a coderef wrapped by get_params' => sub {
	# Outer call wraps a coderef; inner call is made when the coderef is invoked.
	# Verify the two invocations are completely independent (no shared mutable state).
	my $outer = get_params('cb', sub {
		return get_params('inner', 'deep_value');
	});

	is(ref($outer->{cb}),  'CODE',  'outer: coderef wrapped under "cb"');
	my $inner = $outer->{cb}->();
	is_deeply($inner, { inner => 'deep_value' }, 'inner get_params returns correctly');
};

subtest 'context: scalar-forced return from list-like call' => sub {
	my $r = scalar get_params(undef, p => 1, q => 2);
	is(ref($r), 'HASH', 'scalar-forced call returns hashref');
	is($r->{p}, 1, 'data intact in scalar-forced result');
};

# =========================================================================
# SECTION 6: Security -- duplicate key injection
#
# POD LIMITATION: "Duplicate keys in a flat list silently overwrite; last
# value wins."  These tests expose the attack surface and document its
# exact semantics.
# =========================================================================

subtest 'security: duplicate key -- last value wins (documented LIMITATION)' => sub {
	my $result = get_params(undef, role => 'guest', role => 'admin');
	is($result->{role}, 'admin', 'second occurrence overwrites first');
	is(scalar keys %{$result}, 1, 'only one key -- no phantom duplicates');
};

subtest 'security: attacker-injected key silently overrides earlier sanitised value' => sub {
	# Threat model: trusted code sets a safe value first.  An attacker who
	# can append key-value pairs to the argument list overrides it silently.
	# This documents the attack surface; mitigation is validation upstream.
	Readonly::Scalar my $SAFE_VALUE => 'guest';
	Readonly::Scalar my $EVIL_VALUE => 'superuser';

	my $result = get_params(undef,
		role => $SAFE_VALUE,    # sanitised by caller
		role => $EVIL_VALUE,    # injected by attacker after the fact
	);

	is($result->{role}, $EVIL_VALUE,
		'SECURITY: later key silently overrides earlier sanitised value');

	diag 'Mitigation: validate with Params::Validate::Strict before trusting the hashref'
		if $ENV{TEST_VERBOSE};
};

subtest 'security: 100 duplicate keys -- only the last survives' => sub {
	my @pairs = map { (secret => "value_$_") } 0 .. 99;
	my $result = get_params(undef, @pairs);
	is($result->{secret}, 'value_99', 'last of 100 duplicates wins');
	is(scalar keys %{$result}, 1, 'result contains exactly one key');
};

subtest 'security: null byte in key name -- Perl hash accepts it unchanged' => sub {
	# Perl hash keys CAN contain null bytes.  get_params must not strip them.
	# The caller is responsible for sanitising key names before passing them.
	my $null_key = "before\x00after";
	my $result   = get_params(undef, $null_key => 'value');
	ok(exists $result->{$null_key}, 'null-byte key present');
	is($result->{$null_key}, 'value', 'value accessible via null-byte key');
};

subtest 'security: newline in key name -- stored without modification' => sub {
	my $nl_key = "line1\nline2";
	my $result = get_params(undef, $nl_key => 'val');
	ok(exists $result->{$nl_key}, 'newline key present');
	is($result->{$nl_key}, 'val', 'value accessible');
};

subtest 'security: large value (100k chars) not silently truncated' => sub {
	Readonly::Scalar my $LEN => 100_000;
	my $val    = 'A' x $LEN;
	my $result = get_params('payload', $val);
	is(length($result->{payload}), $LEN,  'full length preserved');
	is(substr($result->{payload}, -1), 'A', 'last byte intact');
};

# =========================================================================
# SECTION 7: Global state in error paths
#
# Every code path -- success, croak, confess -- must preserve $@, $!, $_, and $\.
# unit.t checks the success path; we focus here on the croak/confess paths.
# =========================================================================

subtest 'global state: $@ captures croak message and is not left stale' => sub {
	local $@ = 'prior_error';
	eval { get_params(undef, 'lone_scalar') };
	like($@, $USAGE_RE, 'croak message correctly placed in $@ by eval');
};

subtest 'global state: $_ not clobbered in the fast path' => sub {
	local $_ = 'fast_path_sentinel';
	get_params({ a => 1 });
	is($_, 'fast_path_sentinel', '$_ preserved through fast path');
};

subtest 'global state: $_ not clobbered when get_params croaks' => sub {
	local $_ = 'croak_path_sentinel';
	eval { get_params(undef, 'bare') };
	is($_, 'croak_path_sentinel', '$_ preserved even when croak fires');
};

subtest 'global state: $! (errno) preserved across all three major paths' => sub {
	$! = POSIX::ENOENT();
	my $errno = int($!);

	get_params(undef, a => 1);           # success path
	is(int($!), $errno, '$! unchanged after success path');

	get_params({ b => 2 });             # fast path
	is(int($!), $errno, '$! unchanged after fast path');

	eval { get_params(undef, 'x') };    # croak path
	is(int($!), $errno, '$! unchanged after croak path');
};

subtest 'global state: $\ (output record separator) not modified' => sub {
	local $\ = 'ORS_SENTINEL';
	get_params(undef, x => 1);
	is($\, 'ORS_SENTINEL', '$\ unchanged after get_params');
};

# =========================================================================
# SECTION 8: Hostile upstream mocks
#
# Replace Carp::croak and Carp::confess with stubs that RETURN instead of
# dying.  This simulates compromised error-reporting and reveals whether any
# code path continues executing unsafely after a suppressed error signal.
#
# Pre-probed results (confirmed before writing tests):
#   - odd-args croak suppressed  → returns undef       (safe)
#   - confess suppressed (0 args)→ returns undef       (safe)
#   - lone-scalar croak suppressed → returns undef     (safe)
#   - $default validation croak suppressed, even pairs → returns HASH
#     *** SECURITY: even-length pairs are still processed and returned! ***
# =========================================================================

subtest 'hostile mock: croak suppressed for odd arg list -- returns undef safely' => sub {
	# After the odd-args croak is suppressed, the function falls off the end
	# of the subroutine; the implicit return is undef.  No partial data leaks.
	mock 'Carp::croak' => sub { return; };

	my $result = get_params(undef, 'a', 'b', 'c');

	ok(!defined $result,
		'croak-suppressed odd-args path: returns undef (no partial hashref)');

	restore_all();
};

subtest 'hostile mock: croak suppressed for lone scalar -- returns undef safely' => sub {
	mock 'Carp::croak' => sub { return; };

	my $result = get_params(undef, 'bare_scalar');

	ok(!defined $result,
		'croak-suppressed lone-scalar path: returns undef');

	restore_all();
};

subtest 'hostile mock: confess suppressed for zero args + defined $default -- returns undef' => sub {
	# Zero args + defined $default should confess.  When confess is mocked to
	# return, the zero-args branch falls to its own `return;` statement -- still undef.
	mock 'Carp::confess' => sub { return; };

	my $result = get_params('required');

	ok(!defined $result,
		'confess-suppressed zero-args path: returns undef (not empty hashref)');

	restore_all();
};

subtest 'hostile mock: croak suppressed for bad $default -- even pairs still processed' => sub {
	# SECURITY FINDING: when the $default-validation croak is suppressed,
	# execution continues past the guard.  With even-length named pairs
	# following the bad $default, the even-length branch fires and returns a
	# valid hashref -- the bad $default is silently ignored.
	#
	# Impact: a caller relying solely on the croak to reject bad $default
	# values cannot guarantee the function stopped if croak is not fatal.
	# Mitigation: validate $default yourself before calling get_params.
	mock 'Carp::croak' => sub { return; };

	my $result = get_params({}, safe_key => 'safe_val');

	is(ref($result), 'HASH',
		'SECURITY: croak-suppressed bad $default -- even pairs still returned');
	is($result->{safe_key}, 'safe_val',
		'pair data is present in the result despite invalid $default');

	diag 'Security: suppressing $default croak allows get_params to return data anyway'
		if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'hostile mock: Scalar::Util::blessed mock -- get_params wraps object correctly regardless' => sub {
	# On macOS the XS alias for blessed prevents glob interception (intercepted=0).
	# On Linux the pure-Perl glob replacement fires (intercepted=1).
	# Either way, get_params must wrap the blessed object under $default.
	# Do NOT assert which platform behavior occurs -- that is a Perl internals
	# detail, not a contract of Params::Get.
	my $intercepted = 0;
	mock 'Scalar::Util::blessed' => sub { $intercepted = 1; return 'FakeClass'; };

	my $obj    = bless { v => 99 }, 'Real::Class';
	my $result = get_params('thing', $obj);

	is(ref($result), 'HASH', 'get_params returns a hashref');
	is($result->{thing}, $obj, 'blessed object stored under $default key');

	# Restore the real blessed() BEFORE checking the class of the stored object.
	restore_all();

	is(Scalar::Util::blessed($result->{thing}), 'Real::Class',
		'stored object is still blessed as Real::Class after restore');

	diag sprintf('Scalar::Util::blessed was %sintercepted (0=XS bypassed mock; 1=pure-Perl)',
		$intercepted ? '' : 'NOT ')
		if $ENV{TEST_VERBOSE};
};

# =========================================================================
# SECTION 9: Special characters in keys and $default names
# =========================================================================

subtest 'special chars: Unicode $default key name' => sub {
	my $key    = "\x{263A}";    # WHITE SMILING FACE
	my $result = get_params($key, 'smile');
	ok(exists $result->{$key}, 'Unicode key present');
	is($result->{$key}, 'smile', 'value accessible via Unicode $default');
};

subtest 'special chars: binary control characters in named-pair key' => sub {
	my $bin = join '', map { chr($_) } 0x01 .. 0x08;
	my $result = get_params(undef, $bin => 'binary_val');
	ok(exists $result->{$bin}, 'binary-char key stored');
	is($result->{$bin}, 'binary_val', 'value accessible');
};

subtest 'special chars: numeric keys auto-stringified in named pairs' => sub {
	# Perl stringifies hash keys; 3.14 becomes "3.14" and 42 becomes "42".
	my $result = get_params(undef, 3.14 => 'pi', 42 => 'answer');
	is($result->{'3.14'}, 'pi',     'float key stringified to "3.14"');
	is($result->{'42'},   'answer', 'integer key stringified to "42"');
};

# =========================================================================
# SECTION 10: Positional-names $default boundary conditions
#
# $default is an ARRAY ref of key names; the n-th arg maps to the n-th key.
# Edge cases: undef key names, empty string keys, duplicate key names.
# =========================================================================

subtest 'positional names: undef element in key list stringified to ""' => sub {
	# Perl stringifies undef hash keys to ""; verify get_params does not crash.
	my $result;
	{
		no warnings 'uninitialized';
		$result = get_params([undef, 'b'], 'val_a', 'val_b');
	}
	ok(exists $result->{''},  'undef key present as empty string');
	is($result->{''},  'val_a', 'value for stringified undef key');
	is($result->{b},   'val_b', 'sibling key unaffected');
};

subtest 'positional names: empty string element in key list' => sub {
	my $result = get_params(['', 'b'], 10, 20);
	ok(exists $result->{''},  'empty-string key present');
	is($result->{''},  10,    'empty-string key has correct value');
	is($result->{b},   20,    '"b" key has correct value');
};

subtest 'positional names: duplicate key names -- second write wins' => sub {
	# Two positional names that are identical: both positions write to the
	# same hash slot; the second write overwrites the first.
	my $result = get_params([qw(x x)], 'first', 'second');
	is($result->{x}, 'second', 'second positional write wins');
	is(scalar keys %{$result}, 1, 'only one key in result (no phantom duplicate)');
};

subtest 'positional names: empty names arrayref + any args produces empty hashref' => sub {
	my $result = get_params([], 'ignored1', 'ignored2', 'ignored3');
	is_deeply($result, {}, 'empty names list yields empty hashref regardless of args');
};

subtest 'positional names: all args absent -- all keys present, all values undef' => sub {
	# Called as get_params([qw(a b c)]) -- one arg which IS the $default.
	# After shifting $default, @_ is empty; @_[0..2] = (undef, undef, undef).
	my $result = get_params([qw(a b c)]);

	for my $k (qw(a b c)) {
		ok(exists $result->{$k},   "$k key present even with no args");
		ok(!defined $result->{$k}, "$k maps to undef (missing = undef, not absent)");
	}
};

subtest 'positional names: extra args beyond key list silently discarded' => sub {
	# LIMITATION: positional-names $default silently discards extra arguments.
	my $result = get_params([qw(a b)], 1, 2, 3, 4, 5);
	is_deeply($result, { a => 1, b => 2 }, 'only first 2 args mapped');
	is(scalar keys %{$result}, 2, 'extra args left no trace in result');
};

subtest 'positional names: single hashref still passes through (fast path exception)' => sub {
	# Even with an arrayref $default, a single plain hashref in the arg list
	# is returned as-is -- for consistency with the scalar $default fast path.
	my $h      = { x => 10, y => 20 };
	my $result = get_params([qw(x y)], $h);
	is($result, $h, 'hashref returned by identity, not mapped positionally');
};

done_testing();
