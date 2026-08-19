#!/usr/bin/env perl

# Domain tests for Params::Get::get_params -- Equivalence Partitioning (EP)
# and Boundary Value Analysis (BVA).
#
# For each input parameter the valid partitions, invalid partitions, and exact
# boundary edges are identified before tests are written.  Each subtest is
# labelled with the partition or boundary it proves.
#
# $default type domain (12 partitions):
#   Valid:
#     EP1  undef             -- no key; named-pairs / hashref mode
#     EP2  non-empty string  -- hash key; truthy; shorthand guard active
#     EP3  empty string ""   -- valid, FALSY; shorthand guard suppressed
#     EP4  "0"               -- valid, FALSY; shorthand guard suppressed
#     EP5  ARRAY ref [...]   -- positional-names mode
#     EP6  empty ARRAY ref   -- positional-names with 0 slots
#   Invalid (croak at guard, L223, before any @args inspection):
#     EP7  CODE ref
#     EP8  HASH ref
#     EP9  SCALAR ref
#     EP10 REF (ref-of-ref)
#     EP11 blessed HASH object  (ref() returns class name, not 'HASH')
#     EP12 blessed ARRAY object (ref() returns class name, not 'ARRAY')
#
# @args count domain (7 partitions):
#   CN0a  0 args, undef $default       -> undef returned
#   CN0b  0 args, defined $default     -> confess
#   CN1   1 HASH ref, no $default      -> fast path; identity return
#   CN2   1 non-HASH, defined $default -> wrap under $default
#   CN3   2 args, 2nd HASH, defined $d -> OO constructor path
#   CN4   even N>=2, no OO match       -> flat key/value pairs
#   CN5   odd N>=3                     -> croak
#
# BVA edges:
#   $default string length:      0 (EP3), 1 (minimum truthy), 65536 (max tested)
#   $default ARRAY key count:    0, 1, N>args (missing->undef), N<args (extras discarded)
#   @args count:                 0, 1, 2, 3 (odd croak), 4, 1000 (large)
#   OO options hash key count:   0 (empty), 1, N (>1)

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::Most;
use Test::Needs;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(blessed);

use Params::Get qw(get_params);
use TestHelper qw($USAGE_RE $DEFAULT_CROAK_RE);

# =========================================================================
# Named partition constants -- no magic values in test bodies
# =========================================================================

# Partition representatives
Readonly::Scalar my $EP2_STRING  => 'country';
Readonly::Scalar my $EP3_EMPTY   => '';
Readonly::Scalar my $EP4_ZERO    => '0';

# BVA edges for $default string length
Readonly::Scalar my $BVA_KEY_LEN_0     => '';
Readonly::Scalar my $BVA_KEY_LEN_1     => 'k';
Readonly::Scalar my $BVA_KEY_LARGE     => 'K' x 65_536;

# BVA edges for @args count
Readonly::Scalar my $BVA_PAIR_LARGE    => 500;     # 500 pairs = 1000 args

# =========================================================================
# SECTION 1: $default type domain -- valid partitions EP1-EP6
# =========================================================================

subtest 'EP1 ($default undef): enables named-pairs mode' => sub {
	my $result = get_params(undef, city => 'Oslo', pop => 700_000);

	is_deeply($result, { city => 'Oslo', pop => 700_000 },
		'EP1: undef $default -- named pairs normalised correctly');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'EP2 ($default non-empty string): becomes hash key' => sub {
	my $result = get_params($EP2_STRING, 'US');

	is_deeply($result, { country => 'US' },
		'EP2: non-empty string $default -- single arg wrapped under key');
};

subtest 'EP3 ($default empty string ""): valid, FALSY -- args treated as named pairs' => sub {
	# Empty string is falsy; the shorthand guard ($default && ...) is suppressed.
	# A \@_ arrayref with 2 elements where $_[0]->[0] eq '' is NOT unwrapped.
	# Instead it falls to the even-length check and named pairs are returned.
	my $result = get_params($EP3_EMPTY, a => 1, b => 2);

	is_deeply($result, { a => 1, b => 2 },
		'EP3: empty string $default -- named pairs path used (shorthand suppressed)');
};

subtest 'EP4 ($default "0"): valid, FALSY -- shorthand suppressed' => sub {
	my $result = get_params($EP4_ZERO, x => 10);

	is_deeply($result, { x => 10 },
		'EP4: "0" $default -- named pairs path used (shorthand suppressed)');
};

subtest 'EP5 ($default non-empty ARRAY ref): positional-names mode' => sub {
	my $result = get_params([qw(name age city)], 'Alice', 30, 'London');

	is_deeply($result, { name => 'Alice', age => 30, city => 'London' },
		'EP5: ARRAY ref $default -- positional mapping');
	memory_cycle_ok($result, 'cycle-free');
};

subtest 'EP6 ($default empty ARRAY ref []): 0 slots -- all args silently discarded' => sub {
	# key count = 0; slice @rc{()} = @_[0 .. -1] is a no-op.
	my $result = get_params([], 'a', 'b', 'c');

	is_deeply($result, {}, 'EP6: empty ARRAY ref $default -- empty hashref returned');
};

# =========================================================================
# SECTION 2: $default type domain -- invalid partitions EP7-EP12
# (Each must croak before any @arg is read)
# =========================================================================

subtest 'EP7 ($default CODE ref): croak before args are inspected' => sub {
	my $calls = 0;

	throws_ok(
		sub { get_params(sub { $calls++ }, 'arg1', 'arg2') },
		$DEFAULT_CROAK_RE,
		'EP7: CODE ref $default -> immediate croak',
	);

	is($calls, 0, 'CODE ref was never invoked -- croak fired first');
};

subtest 'EP8 ($default HASH ref): croak before args are inspected' => sub {
	throws_ok(
		sub { get_params({}, 'arg') },
		$DEFAULT_CROAK_RE,
		'EP8: HASH ref $default -> immediate croak',
	);
};

subtest 'EP9 ($default SCALAR ref): croak before args are inspected' => sub {
	my $s = 'text';
	throws_ok(
		sub { get_params(\$s, 'arg') },
		$DEFAULT_CROAK_RE,
		'EP9: SCALAR ref $default -> immediate croak',
	);
};

subtest 'EP10 ($default REF-of-ref): croak before args are inspected' => sub {
	my $s = 'text';
	my $r = \$s;
	throws_ok(
		sub { get_params(\$r, 'arg') },
		$DEFAULT_CROAK_RE,
		'EP10: REF (ref-of-ref) as $default -> immediate croak',
	);
};

subtest 'EP11 ($default blessed HASH): ref() returns class name, not HASH -> croak' => sub {
	my $obj = bless {}, 'FakeClass';
	throws_ok(
		sub { get_params($obj, 'arg') },
		$DEFAULT_CROAK_RE,
		'EP11: blessed HASH object as $default -> croak (class name ne ARRAY)',
	);
};

subtest 'EP12 ($default blessed ARRAY): ref() returns class name, not ARRAY -> croak' => sub {
	# Blessing an ARRAY ref changes ref() to return the class name, not 'ARRAY'.
	# The guard ($default_ref ne $T_ARRAY) fires even though the referent is an array.
	my $obj = bless [], 'FakeArrayClass';
	throws_ok(
		sub { get_params($obj, 'arg') },
		$DEFAULT_CROAK_RE,
		'EP12: blessed ARRAY object as $default -> croak (ref() != "ARRAY")',
	);
};

# =========================================================================
# SECTION 3: $default string length -- BVA boundaries
# =========================================================================

subtest 'BVA $default length=0 (EP3 boundary): empty string is a valid hash key' => sub {
	# Length-0 string is falsy but legal; the returned hashref has '' as a key.
	my $result = get_params($BVA_KEY_LEN_0, 'v', undef);

	# Empty string default with named pairs (shorthand suppressed)
	my $r2 = get_params($BVA_KEY_LEN_0, q{} => 'val');
	is($r2->{q{}}, 'val', 'BVA length=0: empty string key is valid in returned hashref');
};

subtest 'BVA $default length=1 (minimum truthy): shorthand guard is active' => sub {
	# Length-1 non-zero string is the minimum truthy $default.
	# The two-element shorthand fires when conditions are met.
	my @inner = ($BVA_KEY_LEN_1, 'v');
	my $result = get_params($BVA_KEY_LEN_1, \@inner);

	is_deeply($result, { $BVA_KEY_LEN_1 => 'v' },
		'BVA length=1: minimum truthy $default activates shorthand');
};

subtest 'BVA $default length=65536 (large key): handled without error' => sub {
	my $result = get_params($BVA_KEY_LARGE, 'val');

	is(length((keys %{$result})[0]), length($BVA_KEY_LARGE),
		'BVA length=65536: large $default stored as key at full length');
	is($result->{$BVA_KEY_LARGE}, 'val', 'value retrievable under large key');
};

# =========================================================================
# SECTION 4: $default ARRAY ref key-count -- BVA
# =========================================================================

subtest 'BVA ARRAY $default keys=0: all args discarded, empty hashref returned' => sub {
	my $result = get_params([], 'a', 'b', 'c', 'd');

	is_deeply($result, {}, 'key count=0: all positional args discarded');
	is(scalar keys %{$result}, 0, 'hashref has zero keys');
};

subtest 'BVA ARRAY $default keys=1: maps only first arg' => sub {
	my $result = get_params([qw(x)], 10, 99, 88);

	is_deeply($result, { x => 10 }, 'key count=1: only first arg mapped; rest discarded');
};

subtest 'BVA ARRAY $default keys>@args: missing args produce undef slots' => sub {
	# 3 keys but only 1 arg: slots for y and z get undef via slice.
	my @captured_warnings;
	{
		local $SIG{__WARN__} = sub { push @captured_warnings, @_ };
		my $result = get_params([qw(x y z)], 10);
		is_deeply($result, { x => 10, y => undef, z => undef },
			'keys > args: missing slots are undef');
		ok(exists $result->{y}, 'undef slot key y exists');
		ok(exists $result->{z}, 'undef slot key z exists');
	}
	is(scalar @captured_warnings, 0, 'no uninitialized-value warning for missing positional args');
};

subtest 'BVA ARRAY $default keys<@args: extra args silently discarded' => sub {
	my $result = get_params([qw(a b)], 1, 2, 3, 4, 5);

	is_deeply($result, { a => 1, b => 2 }, 'keys < args: extra args discarded');
	is(scalar keys %{$result}, 2, 'exactly 2 keys; no extras leaked');
};

# =========================================================================
# SECTION 5: @args count domain -- valid partitions CN0a, CN1, CN2, CN4
# =========================================================================

subtest 'CN0a (@args=0, undef $default): returns undef' => sub {
	my $result = get_params(undef);

	ok(!defined($result), 'CN0a: 0 args, undef $default -> undef returned');
};

subtest 'CN1 (@args=1 HASH ref, no $default): fast path -- identity return' => sub {
	# Fast path at L218: sole arg is a HASH ref; returned unchanged, before
	# $default is even inspected.
	my $h = { latitude => 51.5, longitude => -0.1 };

	my $result = get_params($h);

	is($result, $h, 'CN1: sole HASH ref -> fast path; same reference returned');
};

subtest 'CN1 boundary: @_==2 (with $default) bypasses fast path' => sub {
	# Fast path requires @_==1 (counting $default as part of @_).
	# When $default is provided alongside the hashref, @_ is 2 -> no fast path.
	# The LIMITATION applies: the hashref bypasses $default key-naming anyway.
	my $h      = { a => 1 };
	my $result = get_params('key', $h);

	# LIMITATION: sole HASH ref returned by identity even when $default given.
	is($result, $h, 'CN1 boundary: hashref with $default still returned by identity (LIMITATION)');
};

subtest 'CN2 (@args=1 scalar, defined $default): wrapped under $default' => sub {
	my $result = get_params('temperature', 36.6);

	is_deeply($result, { temperature => 36.6 },
		'CN2: 1 scalar arg, defined $default -> wrapped');
};

subtest 'CN4 (@args=4, even, undef $default): flat key/value pairs' => sub {
	my $result = get_params(undef, a => 1, b => 2);

	is_deeply($result, { a => 1, b => 2 }, 'CN4: even 4 args -> named pairs');
};

subtest 'CN4 BVA @args=1000 (large even count): all pairs normalised' => sub {
	my @pairs = map { ("k$_" => "v$_") } 1 .. $BVA_PAIR_LARGE;

	my $result;
	lives_ok(
		sub { $result = get_params(undef, @pairs) },
		"CN4 BVA: $BVA_PAIR_LARGE pairs (1000 args) accepted",
	);

	is(scalar keys %{$result}, $BVA_PAIR_LARGE, "all $BVA_PAIR_LARGE keys present");
	is($result->{k1},                       'v1',              'first pair correct');
	is($result->{"k$BVA_PAIR_LARGE"}, "v$BVA_PAIR_LARGE", 'last pair correct');
};

# =========================================================================
# SECTION 6: @args count domain -- invalid partitions CN0b, CN5
# =========================================================================

subtest 'CN0b (@args=0, defined $default): confess with usage message' => sub {
	throws_ok(
		sub { get_params('required_key') },
		$USAGE_RE,
		'CN0b: 0 args, defined $default -> confess (not croak)',
	);

	# Distinguish confess (full stack trace) from croak (one line):
	# both set $@, but confess includes a "Params::Get->get_params" line.
	eval { get_params('k') };
	like($@, qr/get_params/, 'confess message includes function name');
};

subtest 'CN5 BVA @args=3 (minimum odd): croak' => sub {
	throws_ok(
		sub { get_params(undef, 'a', 1, 'b') },
		$USAGE_RE,
		'CN5 BVA min: 3 args (minimum odd) -> croak',
	);
};

subtest 'CN5 BVA @args=5 (next odd): croak' => sub {
	throws_ok(
		sub { get_params(undef, 'a', 1, 'b', 2, 'c') },
		$USAGE_RE,
		'CN5 BVA: 5 args (odd, >min) -> croak',
	);
};

# =========================================================================
# SECTION 7: Single-arg type domain -- with defined $default
# (BVA: each distinct ref() value drives a different dispatch arm)
# =========================================================================

subtest 'single-arg undef, defined $default: wrapped as undef value' => sub {
	my $result = get_params('flag', undef);

	ok(exists $result->{flag},   'key exists in result');
	ok(!defined($result->{flag}), 'value is undef');
};

subtest 'single-arg empty string "", defined $default: wrapped as empty string' => sub {
	my $result = get_params('val', '');

	is($result->{val}, '', 'EP3 boundary: empty string value wrapped under $default');
};

subtest 'single-arg "0", defined $default: falsy scalar wrapped correctly' => sub {
	my $result = get_params('flag', '0');

	is($result->{flag}, '0', 'EP4 boundary: "0" value wrapped; not confused with undef');
};

subtest 'single-arg SCALAR ref, defined $default: dereferenced then wrapped' => sub {
	my $inner  = 'London';
	my $result = get_params('city', \$inner);

	is($result->{city}, 'London', 'SCALAR ref arg: deref -> wrap; original preserved');
};

subtest 'single-arg ARRAY ref, defined $default: wrapped as-is (not dereffed)' => sub {
	my $aref   = [1, 2, 3];
	my $result = get_params('list', $aref);

	is($result->{list}, $aref,  'ARRAY ref arg: same reference stored under $default');
};

subtest 'single-arg CODE ref, defined $default: wrapped as-is' => sub {
	my $code   = sub { 'result' };
	my $result = get_params('handler', $code);

	is($result->{handler}, $code,         'CODE ref arg: stored under $default');
	is($result->{handler}->(), 'result',  'stored CODE ref is callable');
};

subtest 'single-arg blessed object, defined $default: wrapped as-is' => sub {
	my $obj    = bless { x => 99 }, 'MyClass';
	my $result = get_params('obj', $obj);

	is($result->{obj},        $obj,      'blessed object stored by reference');
	is(ref($result->{obj}),   'MyClass', 'blessing preserved');
};

subtest 'single-arg HASH ref, defined $default: LIMITATION -- bypasses $default key' => sub {
	# Documented LIMITATION: a sole hash ref always bypasses $default key-naming.
	# The one-arg path falls through to L294 and returns the hashref directly.
	my $h      = { inner => 'val' };
	my $result = get_params('outer', $h);

	is($result, $h,
		'LIMITATION: HASH ref with defined $default returned by identity, not wrapped');
	ok(!exists $result->{outer},
		'LIMITATION: $default key "outer" absent -- hashref not wrapped');
};

# =========================================================================
# SECTION 8: Single-arg type domain -- with undef $default
# =========================================================================

subtest 'single-arg undef, undef $default: returns undef' => sub {
	my $result = get_params(undef, undef);

	ok(!defined($result), 'undef arg, undef $default -> undef returned');
};

subtest 'single-arg HASH ref, undef $default: returns hashref by identity (L294)' => sub {
	my $h = { k => 'v' };

	my $result = get_params(undef, $h);

	is($result, $h, 'HASH ref, undef $default -> returned by identity via L294');
};

subtest 'single-arg REF-of-HASH-ref, undef $default: unwrapped to HASH then returned' => sub {
	# ref(\$href) eq 'REF' -> $val = ${$val} -> HASH ref -> L294 return.
	my %h   = (a => 1);
	my $ref = \(\%h);        # ref-of-HASH-ref: ref($ref) eq 'REF'

	my $result = get_params(undef, $ref);

	is_deeply($result, { a => 1 }, 'REF-of-HASH-ref: unwrapped to HASH, returned');
};

subtest 'single-arg plain string, undef $default: croak' => sub {
	throws_ok(
		sub { get_params(undef, 'unrecognised') },
		$USAGE_RE,
		'plain string, undef $default -> croak (no valid convention matched)',
	);
};

subtest 'single-arg empty ARRAY ref, undef $default: LIMITATION -- returns undef' => sub {
	# []: ref eq ARRAY -> \@_ detection path fires, $args=[], $num_args=0.
	# Zero-arg branch: defined($default)=false -> return undef.
	# The empty arrayref is indistinguishable from \@_ of an empty @_.
	my $result = get_params(undef, []);

	ok(!defined($result),
		'LIMITATION: empty ARRAY ref with undef $default returns undef (not the ref)');
};

# =========================================================================
# SECTION 9: Two-arg OO constructor -- options hash key-count BVA
# (L306: ($num_args == 2) && (ref($args->[1]) eq $T_HASH) && defined $default)
# =========================================================================

subtest 'OO BVA keys=0 (empty options hash): hashref stored as value' => sub {
	# L315: empty opts -> return { $default => $args->[1] }.
	my $opts   = {};
	my $result = get_params('id', 42, $opts);

	is_deeply($result, { id => {} },
		'OO BVA keys=0: empty options hashref stored as value under $default');
	is($result->{id}, $opts, 'stored opts is same reference as passed');
};

subtest 'OO BVA keys=1 (non-empty, first arg != $default): merged' => sub {
	# L312: $args->[0] ne $default -> merge mandatory + options.
	my $result = get_params('id', 42, { opt => 'x' });

	is_deeply($result, { id => 42, opt => 'x' },
		'OO BVA keys=1: mandatory value + single option merged');
};

subtest 'OO BVA keys=1 (non-empty, first arg IS $default): hashref wrapped' => sub {
	# L310: $args->[0] eq $default -> { $default => opts_hashref }.
	my $opts   = { opt => 'x' };
	my $result = get_params('id', 'id', $opts);

	is_deeply($result, { id => { opt => 'x' } },
		'OO BVA: first arg == $default -> options hashref wrapped under key');
};

subtest 'OO BVA keys=N (multiple options): all merged' => sub {
	my $result = get_params('name', 'Alice', { role => 'admin', active => 1, dept => 'eng' });

	is_deeply($result, { name => 'Alice', role => 'admin', active => 1, dept => 'eng' },
		'OO BVA keys=N: multiple options merged with mandatory value');
};

# =========================================================================
# SECTION 10: Falsy $default shorthand boundary
# (L245: if($default && (@{$_[0]} == 2) && ($_[0]->[0] eq $default) && !ref($_[0]->[1])))
# =========================================================================

subtest 'shorthand BVA: truthy $default + 2-element \@_ -> shorthand fires' => sub {
	# All 4 conditions true: $default truthy, 2 elements, first eq $default,
	# second not a ref.
	my @inner  = ('key', 'value');
	my $result = get_params('key', \@inner);

	is_deeply($result, { key => 'value' },
		'shorthand BVA truthy: 2-element \@_ where [0] eq $default -> shorthand');
};

subtest 'shorthand BVA: EP3 ("") $default suppresses shorthand' => sub {
	# $default = "" -> $default && ... is false -> shorthand skipped.
	# Inner array is treated as flat key/value pairs instead.
	my @inner  = ('', 'value');
	my $result = get_params('', \@inner);

	# Shorthand suppressed: falls to $from_arrayref path.
	# $from_arrayref=1, $default='', defined('')=true -> L320 fires:
	# return { '' => \@inner } (multi-value arrayref under empty-string key).
	is($result->{''}, \@inner,
		'shorthand BVA EP3 (""): shorthand suppressed; array wrapped under "" key');
};

subtest 'shorthand BVA: EP4 ("0") $default suppresses shorthand' => sub {
	my @inner  = ('0', 'value');
	my $result = get_params('0', \@inner);

	# Same: "0" is falsy, shorthand suppressed, L320 fires.
	is($result->{'0'}, \@inner,
		'shorthand BVA EP4 ("0"): shorthand suppressed; array wrapped under "0" key');
};

subtest 'shorthand BVA: 2-element \@_ where second IS a ref -- shorthand suppressed' => sub {
	# Fourth condition: !ref($_[0]->[1]) is false -> shorthand skipped.
	# Inner is ['key', [1,2,3]] -- second element is an ARRAY ref.
	my $aref   = [1, 2, 3];
	my @inner  = ('key', $aref);
	my $result = get_params('key', \@inner);

	# Shorthand suppressed (second is a ref); falls to L320:
	# $from_arrayref && defined('key') -> { 'key' => \@inner }.
	is($result->{key}, \@inner,
		'shorthand BVA: ref as second element suppresses shorthand; array wrapped');
};

# =========================================================================
# SECTION 11: Combinatorial boundary interactions
# =========================================================================

subtest 'combinatorial: max $default key length + max arg value size' => sub {
	my $large_val = 'V' x 1_048_576;    # 1 MiB value

	my $result;
	lives_ok(
		sub { $result = get_params($BVA_KEY_LARGE, $large_val) },
		'max key ($BVA_KEY_LARGE chars) + max value (1 MiB) accepted without error',
	);

	is(length((keys %{$result})[0]), length($BVA_KEY_LARGE), 'key length preserved');
	is(length($result->{$BVA_KEY_LARGE}), length($large_val),  'value length preserved');
};

subtest 'combinatorial: ARRAY $default with 0 keys + 1000 positional args' => sub {
	my @args = 1 .. 1000;

	my $result = get_params([], @args);

	is_deeply($result, {}, '0-key ARRAY $default: all 1000 args discarded silently');
};

subtest 'combinatorial: large ARRAY $default with 0 positional args -- all undef' => sub {
	my @keys   = map { "key$_" } 1 .. 10;
	my $result;
	{
		local $SIG{__WARN__} = sub {};    # Suppress uninitialized; confirmed by SECTION 4
		$result = get_params(\@keys);     # 0 args after shift
	}

	is(scalar keys %{$result}, 10, '10-key ARRAY $default + 0 args: 10 undef slots');
	ok(!defined($result->{key1}), 'all slots are undef');
};

subtest 'combinatorial: EP3 ("") $default + 0 args -- confess' => sub {
	# "" is falsy but DEFINED; zero-arg path: defined("") is true -> confess.
	throws_ok(
		sub { get_params('') },
		$USAGE_RE,
		'EP3 ("") $default + 0 args: defined("") is true -> confess, not silent undef',
	);
};

done_testing();
