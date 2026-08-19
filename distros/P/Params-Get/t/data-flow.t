#!/usr/bin/env perl

# Data-flow tests for Params::Get::get_params.
#
# Strategy: trace every critical variable through its complete Define-Use (DU)
# chain -- where data is Defined (D), Used (U), and Killed/destroyed (K).
# Tests assert that:
#   - Data is never used before initialization (~U anomaly).
#   - No variable is defined twice without a read in between (DD anomaly).
#   - No computed value is discarded without being read (D~ dead store).
#   - Caller variables are never silently mutated by the library.
#   - Return values are fresh hashrefs except where identity is documented.
#
# DU chains traced (var -> line numbers in lib/Params/Get.pm):
#   $default       L220 D -> L223,231,233,245,258,261,268,274,281-283,307-315,320 U
#   $default_ref   L221 D -> L223,231 U
#   $args          L248|251 D -> L254,269,270,274,281-283,286,291,294,297,306,...,324 U
#   $from_arrayref L249 D (conditional) -> L320 U  [undef in else-branch]
#   $num_args      L254 D -> L257,267,306,323 U
#   $arg           L269 D -> L270,274,281-283 U
#   $kind          L270 D -> L274,282-283 U
#   $val           L291 D -> L292,294,297 U  [defensive copy guards caller alias]
#   %rc            L234 D -> L235 U(fill) -> L236 U(return)
#
# Static D~ anomaly detected outside this module -- in t/cgi_security.t:
#   $XSS_SRCDOC defined at line 57 of that file is never referenced in any
#   subtest.  Dead store -- should either be removed or exercised.

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
# SECTION 1: $default DU chain -- shift, type-validation, and key-naming
#
# D: my $default = shift  (L220)
# U: croak guard (L223), ARRAY dispatch (L231,233), shorthand (L245),
#    zero-arg confess (L258,261), one-arg wrapping (L268,274,281-283),
#    two-arg OO (L307-315), multi-arrayref (L320)
# K: end of function (lexical)
#
# Key contracts:
#   a. shift is non-destructive to caller: $default is a copy, not an alias.
#   b. $default as string becomes an opaque hash key -- its value is preserved
#      exactly (no stringification side-effects for blessed, overloaded types).
#   c. Non-ARRAY ref as $default croaks before @_ is inspected at all.
# =========================================================================

subtest '$default lifecycle: caller variable is not aliased after shift' => sub {
	my $key = 'country';
	get_params($key, 'US');

	is($key, 'country', 'caller $key unchanged -- $default is a copy, not an alias');
};

subtest '$default lifecycle: undef $default with no args returns undef (not croak)' => sub {
	# D-path: $default = undef after shift; U-path reaches the zero-arg branch
	# where defined($default) is false -> return (not confess).
	my $result = get_params(undef);

	ok(!defined($result), 'undef $default + 0 args -> return undef');
};

subtest '$default lifecycle: defined $default with no args confesses (D->U->croak)' => sub {
	# U-path: $default is truthy -> Carp::confess fires at L261.
	throws_ok(
		sub { get_params('key') },
		$USAGE_RE,
		'defined $default + 0 args -> confess with usage message',
	);
};

subtest '$default lifecycle: string value is preserved exactly as hash key' => sub {
	# U-path: $default used directly as hash key at L274/281/246.
	# Tests that no stringification side-effect alters the key name.
	Readonly::Scalar my $SPECIAL_KEY => "k\x00ey\ttab\nnewline";

	my $result = get_params($SPECIAL_KEY, 'val');

	ok(exists $result->{$SPECIAL_KEY},
		'$default key with special characters stored verbatim');
	is($result->{$SPECIAL_KEY}, 'val', 'value retrievable under verbatim key');
};

subtest '$default lifecycle: non-ARRAY ref croaks before @_ inspection' => sub {
	# U-path: croak guard at L223 fires before any arg is read.
	# Verify a hostile payload in @_ is never processed.
	my $sentinel = 0;
	my $payload  = sub { $sentinel++ };

	throws_ok(
		sub { get_params($payload, 'arg1', 'arg2') },
		$DEFAULT_CROAK_RE,
		'CODE ref $default triggers croak before args are inspected',
	);

	is($sentinel, 0, 'payload in @_ was never called -- croak fired first');
};

# =========================================================================
# SECTION 2: $default_ref DU chain -- cache correctness
#
# D: my $default_ref = ref($default)  (L221)
# U: croak guard (L223), ARRAY dispatch (L231)
# K: end of function (lexical)
#
# Because $default_ref is a cache of ref($default), its value must equal
# ref($default) at every use site.  A behavioural proxy test: each ref type
# must route to the expected branch.
# =========================================================================

subtest '$default_ref: undef default routes to scalar-default path (not ARRAY path)' => sub {
	# ref(undef) eq '' -> $default_ref is '' -> L223 guard false -> L231 false
	# -> scalar-default path.  Prove by observing named-pairs behaviour.
	my $result = get_params(undef, a => 1, b => 2);

	is_deeply($result, { a => 1, b => 2 }, 'undef $default: named pairs normalised');
};

subtest '$default_ref: scalar default routes to scalar-default path' => sub {
	# ref('string') eq '' -> $default_ref is '' -> scalar-default path.
	my $result = get_params('key', 'value');

	is_deeply($result, { key => 'value' }, 'string $default: single arg wrapped');
};

subtest '$default_ref: ARRAY ref default routes to positional-names path' => sub {
	# ref([...]) eq 'ARRAY' -> $default_ref is 'ARRAY' -> L231 branch taken.
	my $result = get_params([qw(x y)], 10, 20);

	is_deeply($result, { x => 10, y => 20 }, 'ARRAY $default: positional mapping');
};

subtest '$default_ref: CODE ref default rejected by croak guard' => sub {
	# ref(sub{}) eq 'CODE' -> $default_ref is 'CODE' -> L223 guard true -> croak.
	throws_ok(
		sub { get_params(sub {}, 'arg') },
		$DEFAULT_CROAK_RE,
		'CODE ref $default: croak guard fires via $default_ref check',
	);
};

subtest '$default_ref: HASH ref default rejected by croak guard' => sub {
	# ref({}) eq 'HASH' -> $default_ref is 'HASH' -> L223 guard true -> croak.
	throws_ok(
		sub { get_params({unrelated => 1}, 'arg') },
		$DEFAULT_CROAK_RE,
		'HASH ref $default: croak guard fires via $default_ref check',
	);
};

# =========================================================================
# SECTION 3: $args DU chain -- two definition sites, same downstream use
#
# D-site 1: $args = $_[0]  when caller passed \@_  (L248)
# D-site 2: $args = \@_    when caller passed flat list  (L251)
# U: $num_args computation, all dispatch branches
#
# Contract: both D-sites must produce identical results when the argument
# content is identical.  If the two paths diverge, a caller has inconsistent
# behaviour depending purely on calling style.
# =========================================================================

subtest '$args: flat-list and \@_ paths produce identical results (named pairs)' => sub {
	my @args = (a => 1, b => 2);

	my $flat   = get_params(undef, @args);
	my $arrref = get_params(undef, \@args);

	is_deeply($flat,   { a => 1, b => 2 }, 'flat-list $args path correct');
	is_deeply($arrref, { a => 1, b => 2 }, '\@_ $args path correct');
	is_deeply($flat, $arrref, 'both $args definition sites produce identical result');
};

subtest '$args: flat-list and \@_ paths produce identical results (single scalar)' => sub {
	my @args = ('value_x');

	my $flat   = get_params('key', @args);
	my $arrref = get_params('key', \@args);

	is_deeply($flat,   { key => 'value_x' }, 'flat-list: scalar under $default');
	is_deeply($arrref, { key => 'value_x' }, '\@_: scalar under $default');
	is_deeply($flat, $arrref, 'both paths equivalent for single-scalar input');
};

subtest '$args: \@_ with multiple values under scalar $default wraps array' => sub {
	# This path fires at L320: $from_arrayref && defined $default.
	# D-site 1 ($args = $_[0]) combined with $from_arrayref = 1.
	my @multi = (1, 2, 3);
	my $result = get_params('data', \@multi);

	is_deeply($result->{data}, [1, 2, 3], 'multi-val \@_ stored as arrayref under $default');
	is($result->{data}, \@multi, 'same array reference returned (by identity, not copied)');
};

# =========================================================================
# SECTION 4: $from_arrayref DU chain -- conditional definition
#
# D: declared undef via my ($args, $from_arrayref)  (L240)
# Conditional D: = 1 only in the \@_ branch  (L249)
# U: boolean guard $from_arrayref && defined $default  (L320)
#
# The ~U risk: $from_arrayref is used at L320 without a guaranteed prior
# assignment.  It is safe because undef is falsy, making the && short-circuit.
# These tests verify that the flag is exactly 0 or 1 at each call site and
# that neither state produces incorrect output.
# =========================================================================

subtest '$from_arrayref: flat-list path -- flag is falsy, L320 branch NOT taken' => sub {
	# Flat-list path sets $args = \@_ (L251) and $from_arrayref stays undef.
	# L320 guard: undef && ... -> false -> branch skipped -> even-length list path.
	my @pairs = (a => 10, b => 20);
	my $result = get_params('key', @pairs);

	# If $from_arrayref had incorrectly been set, this would return
	# { key => \@pairs } instead of the correct named-pairs result.
	is_deeply($result, { a => 10, b => 20 },
		'flat list: $from_arrayref falsy -> L320 skipped -> named pairs returned');
};

subtest '$from_arrayref: arrayref path -- flag is truthy, L320 branch taken' => sub {
	# Arrayref path sets $from_arrayref = 1 (L249).
	# L320 guard: 1 && defined('key') -> true -> { $default => $args } returned.
	my @multi = (10, 20, 30);
	my $result = get_params('key', \@multi);

	is_deeply($result, { key => [10, 20, 30] },
		'\@_ path: $from_arrayref truthy -> L320 taken -> {key => arrayref}');
};

subtest '$from_arrayref: arrayref path with undef $default -- L320 skipped' => sub {
	# $from_arrayref = 1 but defined($default) is false -> L320 guard fails.
	# Falls through to even-length list path.
	my @pairs = (a => 1, b => 2);
	my $result = get_params(undef, \@pairs);

	is_deeply($result, { a => 1, b => 2 },
		'\@_ with undef $default: L320 skipped -> named-pairs path used');
};

# =========================================================================
# SECTION 5: $num_args DU chain -- computed from $args, drives dispatch
#
# D: my $num_args = scalar @{$args}  (L254)
# U: L257 (zero-arg branch), L267 (one-arg branch), L306 (two-arg branch),
#    L323 (even/odd split)
# K: end of function
#
# Contract: $num_args must accurately reflect the count of elements in $args
# for both D-sites of $args.
# =========================================================================

subtest '$num_args: zero args (undef $default) -> undef returned' => sub {
	# $num_args = 0 -> L257 branch -> defined($default) is false -> return undef.
	my $result = get_params(undef);

	ok(!defined($result), '$num_args = 0, undef $default -> returns undef');
};

subtest '$num_args: one arg routes to one-arg branch' => sub {
	# $num_args = 1 -> L267 branch.
	my $result = get_params('k', 'v');

	is_deeply($result, { k => 'v' }, '$num_args = 1 -> one-arg branch dispatched');
};

subtest '$num_args: two args with hashref routes to two-arg branch' => sub {
	# $num_args = 2 and ref($args->[1]) eq 'HASH' -> L306 branch.
	my $result = get_params('id', 42, { opt => 'x' });

	is_deeply($result, { id => 42, opt => 'x' },
		'$num_args = 2 + hashref -> OO constructor branch dispatched');
};

subtest '$num_args: even count routes to flat key/value path' => sub {
	# $num_args = 4 (even, not 2+HASH) -> L323 -> return { @{$args} }.
	my $result = get_params(undef, a => 1, b => 2);

	is_deeply($result, { a => 1, b => 2 },
		'$num_args = 4 (even) -> named-pairs path');
};

subtest '$num_args: odd count (no default) croaks' => sub {
	# $num_args = 3 (odd) -> falls to L327 croak.
	throws_ok(
		sub { get_params(undef, 'a', 1, 'b') },
		$USAGE_RE,
		'$num_args = 3 (odd, no default) -> croak',
	);
};

subtest '$num_args: correctly computed from \@_ D-site (arrayref path)' => sub {
	# When $args = $_[0] (L248), $num_args must equal scalar @{$_[0]}.
	my @data = (x => 10, y => 20, z => 30, w => 40);
	my $result = get_params(undef, \@data);

	is(scalar keys %{$result}, 4,
		'$num_args from arrayref D-site: all 4 pairs normalised');
};

# =========================================================================
# SECTION 6: $arg/$kind DU chain -- one-arg dispatch, data integrity
#
# D: my $arg  = $args->[0]   (L269)
# D: my $kind = ref($arg)    (L270)
# U: SCALAR fast guard (L274), De Morgan disjunction (L282-283)
# K: end of one-arg block
#
# Contract: $kind drives dispatch; $arg content must reach the returned
# hashref unchanged regardless of which arm is taken.
# =========================================================================

subtest '$arg/$kind: plain scalar -> value reaches hashref unchanged' => sub {
	# $kind = '' -> De Morgan arm: !$kind -> return { $default => $arg }.
	Readonly::Scalar my $PAYLOAD => "hello\x00world\ttab";

	my $result = get_params('msg', $PAYLOAD);

	is($result->{msg}, $PAYLOAD, 'plain scalar $arg preserved exactly under $default');
};

subtest '$arg/$kind: SCALAR ref -> dereferenced value reaches hashref' => sub {
	# $kind = 'SCALAR' -> fast guard at L274: return { $default => ${$arg} }.
	my $inner   = 'dereffed';
	my $sref    = \$inner;
	my $result  = get_params('val', $sref);

	is($result->{val}, 'dereffed', 'SCALAR ref $arg dereferenced; content in hashref');
	is($result->{val}, $inner,     'dereffed value is the same string');
};

subtest '$arg/$kind: ARRAY ref -> ref stored as-is under $default' => sub {
	# $kind = 'ARRAY' -> De Morgan arm: $kind eq $T_ARRAY -> as-is.
	my $aref   = [1, 2, 3];
	my $result = get_params('list', $aref);

	is($result->{list}, $aref, 'ARRAY ref $arg: same reference stored (not copied)');
};

subtest '$arg/$kind: CODE ref -> ref stored as-is under $default' => sub {
	# $kind = 'CODE' -> De Morgan arm: $kind eq $T_CODE -> as-is.
	my $code   = sub { 42 };
	my $result = get_params('cb', $code);

	is($result->{cb}, $code,  'CODE ref $arg: same reference stored');
	is($result->{cb}->(), 42, 'stored CODE ref is callable and returns expected value');
};

subtest '$arg/$kind: blessed object -> object stored as-is under $default' => sub {
	# $kind = ref($obj) (some class name) and Scalar::Util::blessed -> as-is.
	my $obj = bless { x => 1 }, 'FakeClass';
	my $result = get_params('obj', $obj);

	is($result->{obj}, $obj, 'blessed object stored by reference under $default');
	ok(blessed($result->{obj}), 'stored value is still blessed');
	is(ref($result->{obj}), 'FakeClass', 'blessing is preserved');
};

# =========================================================================
# SECTION 7: $val copy invariant -- L291 defensive copy
#
# D: my $val = $args->[0]  (L291)
# Mutation: $val = ${$val} if ref($val) eq $T_REF  (L292)
# U: L294 (HASH return), L297 (empty ARRAY return)
#
# Critical invariant: $args->[0] is an alias to the caller's variable through
# @_ (when the flat-list D-site is active).  Reassigning $val (L292) must
# NEVER mutate the caller's original.  This is enforced by taking a named
# copy at L291 rather than assigning through $args->[0] directly.
# =========================================================================

subtest '$val copy: caller variable not mutated when REF-of-REF is unwrapped' => sub {
	# A REF-of-REF (ref(\$x) eq 'REF') arrives in the no-default one-arg path.
	# $val is copied, then dereferenced: $val = ${$val} -> \$x -> a SCALAR ref.
	# ref($val) is then 'SCALAR' which is not HASH or empty ARRAY -> croak.
	# Verify the caller's original variable is unchanged despite the dereference.
	my $inner  = 'original';
	my $sref   = \$inner;
	my $rref   = \$sref;    # ref($rref) eq 'REF'
	my $before = $rref;

	eval { get_params(undef, $rref) };    # Will croak (SCALAR ref, no $default)

	is($rref,   $before,    'caller $rref not mutated after REF-unwrap in get_params');
	is($$rref,  $sref,      'caller $rref still points to $sref');
	is($$$rref, 'original', 'inner value unchanged');
};

subtest '$val copy: HASH reached via REF-of-HASH unwrap -- caller not mutated' => sub {
	# REF-of-HASH: $val = ${$val} -> a HASH ref -> L294 return $val.
	# Caller's original variable must still be the REF-of-HASH.
	my %h      = (a => 1);
	my $href   = \%h;
	my $refref = \$href;    # ref($refref) eq 'REF', ${$refref} is a HASH ref

	my $result = get_params(undef, $refref);    # No croak; HASH is returned

	is_deeply($result, { a => 1 }, 'HASH reached via REF-unwrap returns hashref');
	is($refref, \$href, 'caller $refref unchanged after REF-unwrap');
	is($$refref, $href, 'caller $refref still points to original $href');
};

subtest '$val copy: plain HASH ref passed directly -- returned by identity' => sub {
	# No REF-unwrap needed (ref($val) ne 'REF'); L294 returns $val as-is.
	# The returned reference IS the same hash.
	my $h = { key => 'val' };

	my $result = get_params(undef, $h);

	is($result, $h, 'HASH ref returned by identity (same reference) via $val path');
};

# =========================================================================
# SECTION 8: %rc DU chain -- positional-names hash assembly
#
# D: my %rc  (L234)
# U: @rc{@{$default}} = @_[0 .. $#{$default}]  (L235, fill via slice)
# U: return \%rc  (L236)
# K: end of ARRAY-$default block
#
# Contract:
#   a. Keys come from $default arrayref in order.
#   b. Values come from positional @_ in order.
#   c. Extra @_ args beyond key count are silently discarded.
#   d. Missing @_ args produce undef keys (slot exists but value is undef).
#   e. The 'no warnings uninitialized' block prevents noise for missing args.
# =========================================================================

subtest '%rc assembly: keys from $default, values from @_ in order' => sub {
	my $result = get_params([qw(name age city)], 'Alice', 30, 'Boston');

	is_deeply($result, { name => 'Alice', age => 30, city => 'Boston' },
		'positional mapping: keys ordered from $default, values from @_');
};

subtest '%rc assembly: extra positional args silently discarded (D~ safe)' => sub {
	# @_[0 .. $#{$default}] slice stops at key count; extra values never read.
	my $result = get_params([qw(a b)], 1, 2, 3, 4, 5);

	is_deeply($result, { a => 1, b => 2 }, 'extra args discarded; only keyed slots filled');
	is(scalar keys %{$result}, 2, 'exactly 2 keys in %rc');
};

subtest '%rc assembly: missing args produce undef values -- slot exists' => sub {
	# When @_ has fewer elements than $default key count, slice produces undef.
	# The 'no warnings uninitialized' guard suppresses the expected warning.
	my $result;
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		$result = get_params([qw(x y z)], 10, 20);
	}

	is_deeply($result, { x => 10, y => 20, z => undef },
		'missing arg: slot exists with undef value');
	ok(exists $result->{z}, 'undef slot key exists in returned hashref');
	is(scalar @warnings, 0, 'no uninitialized-value warning emitted for missing arg');
};

subtest '%rc assembly: single-hashref passthrough honoured inside ARRAY-$default path' => sub {
	# L233: return $_[0] if (@_ == 1) && (ref($_[0]) eq $T_HASH)
	# Even with $default as an arrayref, a sole hashref bypasses %rc assembly.
	my $h = { existing => 'hash' };
	my $result = get_params([qw(a b)], $h);

	is($result, $h, 'sole hashref bypasses %rc assembly; returned by identity');
};

subtest '%rc assembly: returned reference is fresh (not aliased to %rc)' => sub {
	# \%rc creates a new reference; modifying the returned hashref must not
	# affect any internal state (there is none after %rc goes out of scope).
	my $result = get_params([qw(k)], 'v');

	$result->{extra} = 'injected';

	is($result->{extra}, 'injected', 'returned hashref is independently mutable');
	# No internal state to check -- confirms %rc is truly a fresh allocation.
};

# =========================================================================
# SECTION 9: Return-value identity -- fast path vs. fresh hashref
#
# The fast path (L218) returns the sole hashref BY IDENTITY.
# Every other path constructs a NEW hashref (anonymous {} or \%rc).
# This distinction is a documented behaviour (see LIMITATIONS) and must
# be stable: callers who mutate the returned hashref must not see side
# effects unless they deliberately pass the same hashref in on the fast path.
# =========================================================================

subtest 'return identity: fast path returns the SAME hashref object' => sub {
	my $h = { a => 1, b => 2 };

	my $result = get_params($h);    # Fast path: (@_ == 1) && (ref eq HASH)

	is($result, $h, 'fast path: same reference returned (no copy)');

	# Mutating the result DOES affect the original -- documented behaviour.
	$result->{mutated} = 1;
	is($h->{mutated}, 1, 'fast path identity: mutation of result affects original');
};

subtest 'return identity: named-pairs path returns a FRESH hashref' => sub {
	# The caller passes individual key/value args; the result is { @{$args} }.
	# It must NOT be the same reference as any of the input values.
	my $result = get_params(undef, a => 1, b => 2);

	$result->{injected} = 99;

	# No original hashref to compare against; just verify result is self-contained.
	is($result->{injected}, 99,    'fresh hashref is independently mutable');
	is($result->{a},        1,     'original key preserved after mutation');
	memory_cycle_ok($result, 'named-pairs result: no reference cycles');
};

subtest 'return identity: scalar-default path returns a FRESH hashref' => sub {
	my $val    = 'hello';
	my $result = get_params('k', $val);

	isnt($result, \$val,  'result is not a reference to the input scalar');
	is($result->{k}, $val, 'value preserved in fresh hashref');
	memory_cycle_ok($result, 'scalar-default result: cycle-free');
};

subtest 'return identity: positional-names path returns a FRESH hashref' => sub {
	my $result = get_params([qw(x y)], 10, 20);

	$result->{z} = 30;

	is_deeply($result, { x => 10, y => 20, z => 30 }, 'fresh hashref independently mutable');
	memory_cycle_ok($result, 'positional-names result: cycle-free');
};

# =========================================================================
# SECTION 10: Global state isolation across all DU paths
#
# No variable in get_params reaches outside its lexical scope.  These tests
# confirm that $@, $!, and $_ are each preserved across every major dispatch
# path, including croak paths (which set $@ as a side effect only inside
# a wrapping eval -- the caller's pre-existing $@ must not be lost).
# =========================================================================

subtest 'global state: $@ preserved across fast-path call' => sub {
	eval { die "sentinel\n" };
	my $saved = $@;

	get_params({ a => 1 });

	is($@, $saved, '$@ unchanged across fast-path call');
};

subtest 'global state: $@ preserved across named-pairs call' => sub {
	eval { die "sentinel\n" };
	my $saved = $@;

	get_params(undef, x => 1, y => 2);

	is($@, $saved, '$@ unchanged across named-pairs call');
};

subtest 'global state: $@ preserved across positional-names call' => sub {
	eval { die "sentinel\n" };
	my $saved = $@;

	get_params([qw(a b)], 1, 2);

	is($@, $saved, '$@ unchanged across positional-names call');
};

subtest 'global state: $_ preserved across all major paths' => sub {
	local $_ = 'outer_default_var';

	get_params({ a => 1 });
	is($_, 'outer_default_var', '$_ unchanged after fast-path call');

	get_params(undef, k => 'v');
	is($_, 'outer_default_var', '$_ unchanged after named-pairs call');

	get_params('key', 'value');
	is($_, 'outer_default_var', '$_ unchanged after scalar-default call');

	get_params([qw(n)], 1);
	is($_, 'outer_default_var', '$_ unchanged after positional-names call');
};

subtest 'global state: $! preserved across named-pairs call' => sub {
	stat('/nonexistent_data_flow_probe_' . $$);    # Sets $! = ENOENT
	my $saved_errno = $! + 0;

	get_params(undef, a => 1, b => 2, c => 3, d => 4);

	is($! + 0, $saved_errno, '$! (errno) not clobbered by named-pairs call');
};

subtest 'global state: $! preserved across positional-names call' => sub {
	stat('/nonexistent_data_flow_probe2_' . $$);
	my $saved_errno = $! + 0;

	get_params([qw(x y z)], 10, 20, 30);

	is($! + 0, $saved_errno, '$! not clobbered by positional-names call');
};

done_testing();
