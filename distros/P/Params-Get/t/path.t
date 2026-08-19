#!/usr/bin/env perl

# Path-coverage tests for Params::Get::get_params.
#
# Strategy: one test per uniquely identifiable execution path through the CFG.
# Each subtest is labelled with its path number and the predicate chain that
# forces execution down that specific branch.
#
# CFG predicates (evaluated in the order below after function entry):
#   A  : (@_ == 1) && (ref($_[0]) eq HASH)                [BEFORE shift; fast path]
#   B  : $default_ref && ($default_ref ne ARRAY)           [bad-type guard]
#   C  : $default_ref eq ARRAY                             [positional-names mode]
#   C1 : (@_ == 1) && (ref($_[0]) eq HASH)                [inner fast path in C]
#   D  : (@_ == 1) && (ref($_[0]) eq ARRAY)               [AFTER shift; \@_ detect]
#   E  : $default && (inner==2) && (inner[0] eq $d) && !ref(inner[1]) [shorthand]
#   F  : $num_args == 0
#   G  : defined $default
#   H  : $num_args == 1
#   I  : defined $default  [inside H]
#   J  : $kind eq SCALAR
#   K  : !$kind || ARRAY || CODE || blessed($arg)
#   L  : defined $args->[0]
#   M  : ref($val) eq REF
#   N  : ref($val) eq HASH
#   O  : (ref($val) eq ARRAY) && (@{$val} == 0)
#   P  : ($num_args == 2) && (ref($args->[1]) eq HASH)
#   Q  : defined $default   [inside P]
#   R  : scalar keys %{$args->[1]} > 0
#   S  : $args->[0] eq $default
#   T  : $from_arrayref && defined $default                [L395: multi-arrayref wrap]
#   U  : $num_args % 2 == 0
#
# Dead-code analysis result: NO unreachable lines detected.
#   Every dispatch arm, including the ARRAY arm of the De Morgan disjunction
#   at L357, is reachable -- the ARRAY arm is reached via the D=T (\@_ detect)
#   path when the inner array contains exactly one ARRAY ref element.

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

Readonly::Scalar my $PKG => 'Params::Get';

# =========================================================================
# SECTION 1: P01 -- Fast path (A=T)
#
# Fires BEFORE $default is shifted.  The sole argument IS a plain hashref.
# =========================================================================

subtest 'P01 A=T: sole HASH ref -> fast path; returned by identity' => sub {
	test_needs 'Test::Returns';
	Test::Returns->import;

	my $h      = { a => 1, b => 2 };
	my $result = get_params($h);

	is($result, $h, 'P01: same reference returned (fast path, no copy)');
	returns_ok($result, { type => 'hashref' }, 'P01: return type hashref');
	memory_cycle_ok($result, 'P01: cycle-free');
};

# =========================================================================
# SECTION 2: P02 -- Bad-$default type guard (A=F, B=T)
#
# Any non-ARRAY ref as $default croaks before @args is inspected.
# B=T when $default_ref is truthy AND not 'ARRAY'.
# =========================================================================

subtest 'P02a B=T(CODE): CODE ref $default -> croak before args inspected' => sub {
	my $side_effect = 0;
	throws_ok(
		sub { get_params(sub { $side_effect++ }, 'arg') },
		$DEFAULT_CROAK_RE,
		'P02a: CODE ref $default -> croak',
	);
	is($side_effect, 0, 'args never touched -- croak fired at guard');
};

subtest 'P02b B=T(HASH): HASH ref $default -> croak' => sub {
	throws_ok(
		sub { get_params({}, 'arg') },
		$DEFAULT_CROAK_RE,
		'P02b: HASH ref $default -> croak',
	);
};

subtest 'P02c B=T(SCALAR): SCALAR ref $default -> croak' => sub {
	my $s = 'x';
	throws_ok(
		sub { get_params(\$s, 'arg') },
		$DEFAULT_CROAK_RE,
		'P02c: SCALAR ref $default -> croak',
	);
};

subtest 'P02d B=T(blessed-ARRAY): blessed ARRAY ref -> ref() returns class, not ARRAY -> croak' => sub {
	# Blessing changes what ref() returns, so even an ARRAY referent fails the guard.
	my $obj = bless [], 'FakeArrayClass';
	throws_ok(
		sub { get_params($obj, 'arg') },
		$DEFAULT_CROAK_RE,
		'P02d: blessed ARRAY -> class name ne "ARRAY" -> croak',
	);
};

# =========================================================================
# SECTION 3: P03/P04 -- ARRAY $default paths (A=F, B=F, C=T)
#
# P03: C=T, C1=T -- inner sole hashref bypasses %rc assembly; identity return.
# P04: C=T, C1=F -- %rc assembled from positional args; fresh ref returned.
# =========================================================================

subtest 'P03 C=T, C1=T: ARRAY $default + sole HASH arg -> inner fast path' => sub {
	my $h      = { existing => 'hash' };
	my $result = get_params([qw(x y)], $h);

	is($result, $h, 'P03: inner fast path returns original hashref by identity');
};

subtest 'P04 C=T, C1=F: ARRAY $default + flat args -> positional %rc assembly' => sub {
	my $result = get_params([qw(name age city)], 'Bob', 25, 'Berlin');

	is_deeply($result, { name => 'Bob', age => 25, city => 'Berlin' },
		'P04: positional mapping via %rc');
	memory_cycle_ok($result, 'P04: cycle-free');
};

# =========================================================================
# SECTION 4: P05 -- Shorthand fires (A=F, B=F, C=F, D=T, E=T)
#
# E requires ALL four sub-conditions:
#   E1: $default is truthy
#   E2: inner array has exactly 2 elements
#   E3: inner[0] eq $default
#   E4: inner[1] is NOT a ref
# =========================================================================

subtest 'P05 E=T: all four shorthand conditions true -> {$d => inner[1]}' => sub {
	my @inner  = ('key', 'value');
	my $result = get_params('key', \@inner);

	is_deeply($result, { key => 'value' },
		'P05: shorthand fires; returns {$default => inner[1]}');
};

subtest 'P05-E1 E=F(falsy $default): "" suppresses shorthand -> different path' => sub {
	# E1 false: $default="" is falsy; $default && ... short-circuits.
	# Inner array ['', 'v'] has 2 elements but shorthand guard fails.
	# $from_arrayref=1, $num_args=2 -> T: $from_arrayref && defined("") -> L395.
	my @inner  = ('', 'v');
	my $result = get_params('', \@inner);

	is($result->{''},  \@inner,
		'P05-E1: falsy $default suppresses shorthand; array wrapped under "" key (L395 T-path)');
};

subtest 'P05-E2 E=F(not 2 elements): 1-element inner -> shorthand skipped -> one-arg path' => sub {
	# E2 false: inner has 1 element -> @{...}==2 is false.
	# $num_args=1, I=T, $arg='v', !$kind -> wrap.
	my @inner  = ('v');
	my $result = get_params('key', \@inner);

	is_deeply($result, { key => 'v' },
		'P05-E2: 1-element inner skips shorthand; wrapped via one-arg path');
};

subtest 'P05-E3 E=F(inner[0] != $default): key mismatch -> shorthand skipped' => sub {
	# E3 false: inner[0]='other' ne $default='key'.
	# $num_args=2, even -> P=F (inner[1]='v' not HASH) -> T=T ($from_arrayref, defined 'key') -> L395.
	my @inner  = ('other', 'v');
	my $result = get_params('key', \@inner);

	is($result->{key}, \@inner,
		'P05-E3: key mismatch suppresses shorthand; whole array wrapped via L395');
};

subtest 'P05-E4 E=F(inner[1] is ref): ref value suppresses shorthand -> L395' => sub {
	# E4 false: inner[1]=[1,2] is a ref; !ref([1,2]) is false.
	my $aref   = [1, 2];
	my @inner  = ('key', $aref);
	my $result = get_params('key', \@inner);

	is($result->{key}, \@inner,
		'P05-E4: ref second element suppresses shorthand; array wrapped via L395');
};

# =========================================================================
# SECTION 5: P06/P07 -- Arrayref path, zero inner args (D=T, E=F, F=T)
#
# P06: F=T, G=T -- defined $default, 0 inner args -> confess.
# P07: F=T, G=F -- undef $default, 0 inner args -> return undef.
#
# This is the documented LIMITATION: an empty array ref is indistinguishable
# from \@_ of an empty list.
# =========================================================================

subtest 'P06 F=T,G=T: D=T, empty inner, defined $default -> confess (LIMITATION)' => sub {
	throws_ok(
		sub { get_params('required', []) },
		$USAGE_RE,
		'P06: empty \@_ passthrough with defined $default -> confess',
	);
};

subtest 'P07 F=T,G=F: D=T, empty inner, undef $default -> return undef (LIMITATION)' => sub {
	my $result = get_params(undef, []);

	ok(!defined($result),
		'P07: empty \@_ passthrough with undef $default -> undef (LIMITATION)');
};

# =========================================================================
# SECTION 6: P08-P13 -- Arrayref path, one inner arg (D=T, E=F, H=T)
#
# $args->[0] is the single element of the inner array.  Dispatch depends on
# its type and whether $default is defined (I=T or I=F).
# =========================================================================

subtest 'P08 J=T via D=T: SCALAR ref inner element, defined $default -> deref+wrap' => sub {
	my $s      = 'London';
	my $result = get_params('city', [\$s]);

	is($result->{city}, 'London', 'P08: SCALAR ref inner element dereffed and wrapped');
};

subtest 'P09a K=T(!kind) via D=T: plain scalar inner, defined $default -> wrap' => sub {
	# K=T via !$kind (plain scalar, ref()=='').
	my $result = get_params('val', ['Oslo']);

	is_deeply($result, { val => 'Oslo' },
		'P09a: plain scalar inner wrapped under $default');
};

subtest 'P09b K=T(ARRAY) via D=T: ARRAY ref inner element, defined $default -> wrap as-is' => sub {
	# K=T via $kind eq ARRAY.  This arm is ONLY reachable via the D=T path
	# (in the flat-list path, an ARRAY ref arg would have triggered D=T).
	my $aref   = [1, 2, 3];
	my $result = get_params('list', [$aref]);

	is($result->{list}, $aref, 'P09b: ARRAY ref inner element wrapped as-is (same ref)');
};

subtest 'P09c K=T(CODE) via D=T: CODE ref inner, defined $default -> wrap as-is' => sub {
	# K=T via $kind eq CODE.
	my $code   = sub { 99 };
	my $result = get_params('cb', [$code]);

	is($result->{cb}, $code,      'P09c: CODE ref stored under $default');
	is($result->{cb}->(), 99,     'P09c: stored CODE ref is callable');
};

subtest 'P09d K=T(blessed) via D=T: blessed inner, defined $default -> wrap as-is' => sub {
	# K=T via Scalar::Util::blessed($arg).
	my $obj    = bless { x => 1 }, 'MyDTClass';
	my $result = get_params('obj', [$obj]);

	is($result->{obj},       $obj,        'P09d: blessed inner stored by reference');
	is(ref($result->{obj}),  'MyDTClass', 'P09d: blessing preserved');
};

subtest 'P10 J=F,K=F,N=T via D=T: HASH ref inner, defined $default -> LIMITATION' => sub {
	# HASH ref: !$kind=F, ARRAY=F, CODE=F, blessed=F -> K=F -> falls through.
	# L=T, M=F, N=T -> return HASH by identity, bypassing $default.
	my $h      = { a => 1 };
	my $result = get_params('outer', [$h]);

	is($result, $h,
		'P10: HASH ref inner falls through to L369; returned by identity (LIMITATION)');
	ok(!exists $result->{outer},
		'P10: $default key "outer" absent -- hashref not wrapped');
};

subtest 'P11 I=F,L=F via D=T: undef inner element, undef $default -> return undef' => sub {
	# I=F (undef $default), L=F (inner[0] is undef), return undef.
	my $result = get_params(undef, [undef]);

	ok(!defined($result),
		'P11: undef inner element with undef $default -> return undef (L=F branch)');
};

subtest 'P12 O=T via D=T: empty ARRAY ref as inner element, undef $default -> return []' => sub {
	# I=F, L=T, M=F, N=F, O=T -- empty ARRAY via inner element.
	my $empty  = [];
	my $result = get_params(undef, [$empty]);

	is($result, $empty,
		'P12: empty ARRAY ref inner element returned by identity (O=T branch)');
};

subtest 'P13 O=F via D=T: non-empty ARRAY ref as inner element, undef $default -> croak' => sub {
	# I=F, L=T, M=F, N=F, O=F (ARRAY is non-empty) -> croak.
	throws_ok(
		sub { get_params(undef, [[1, 2]]) },
		$USAGE_RE,
		'P13: non-empty ARRAY inner element with undef $default -> croak (O=F)',
	);
};

# =========================================================================
# SECTION 7: P14-P16 -- Arrayref path, multi-arg inner (D=T, E=F, num_args>1)
#
# P14: T=T (from_arrayref && defined $default) -> wrap whole array under key.
# P15: T=F (undef $default), U=T (even) -> named pairs from inner array.
# P16: T=F (undef $default), U=F (odd)  -> croak.
# =========================================================================

subtest 'P14 T=T: D=T, multi-inner, defined $default -> {$d => arrayref}' => sub {
	# $from_arrayref=1, $num_args=3, defined $default -> L395: T=T.
	my @data   = (10, 20, 30);
	my $result = get_params('data', \@data);

	is($result->{data}, \@data,
		'P14: multi-element \@_ stored as arrayref under $default (L395 T-path)');
};

subtest 'P15 T=F,U=T: D=T, even inner, undef $default -> named pairs' => sub {
	# $from_arrayref=1, undef $default -> T=F -> U: 4%2==0 -> return {pairs}.
	my @pairs  = (a => 1, b => 2);
	my $result = get_params(undef, \@pairs);

	is_deeply($result, { a => 1, b => 2 },
		'P15: even inner array with undef $default -> named pairs (U=T)');
};

subtest 'P16 T=F,U=F: D=T, odd inner, undef $default -> croak' => sub {
	# $from_arrayref=1, undef $default -> T=F -> U: 3%2==1 -> croak.
	my @odd = ('a', 1, 'b');
	throws_ok(
		sub { get_params(undef, \@odd) },
		$USAGE_RE,
		'P16: odd inner array with undef $default -> croak (U=F)',
	);
};

# =========================================================================
# SECTION 8: P17/P18 -- Flat-list path, zero args (D=F, F=T)
#
# P17: F=T, G=T -- defined $default, 0 flat args -> confess.
# P18: F=T, G=F -- undef $default, 0 flat args -> return undef.
# =========================================================================

subtest 'P17 F=T,G=T(flat): defined $default, 0 args -> confess' => sub {
	throws_ok(
		sub { get_params('key') },
		$USAGE_RE,
		'P17: flat path, 0 args, defined $default -> confess',
	);
};

subtest 'P18 F=T,G=F(flat): undef $default, 0 args -> return undef' => sub {
	my $result = get_params(undef);

	ok(!defined($result), 'P18: flat path, 0 args, undef $default -> undef');
};

# =========================================================================
# SECTION 9: P19-P25 -- Flat-list path, one arg (D=F, H=T)
#
# D=F is guaranteed here because the single arg's ref is NOT 'ARRAY'.
# (Any ARRAY ref arg would have triggered D=T.)
# =========================================================================

subtest 'P19 J=T(flat): SCALAR ref, defined $default -> deref+wrap' => sub {
	my $inner  = 'Paris';
	my $result = get_params('city', \$inner);

	is($result->{city}, 'Paris', 'P19: SCALAR ref dereffed and wrapped under $default');
};

subtest 'P20a K=T(!kind,flat): plain scalar, defined $default -> wrap' => sub {
	# !$kind (plain scalar, ref()=='').
	my $result = get_params('country', 'FR');

	is_deeply($result, { country => 'FR' }, 'P20a: plain scalar wrapped');
};

subtest 'P20b K=T(CODE,flat): CODE ref, defined $default -> wrap as-is' => sub {
	# $kind eq CODE from flat-list path (CODE ref does NOT trigger D=T since
	# ref(sub{}) eq 'CODE', not 'ARRAY').
	my $code   = sub { 'x' };
	my $result = get_params('fn', $code);

	is($result->{fn}, $code, 'P20b: CODE ref wrapped as-is from flat-list path');
};

subtest 'P20c K=T(blessed,flat): blessed obj, defined $default -> wrap' => sub {
	my $obj    = bless { y => 2 }, 'FlatClass';
	my $result = get_params('obj', $obj);

	is($result->{obj},       $obj,       'P20c: blessed object stored by reference');
	is(ref($result->{obj}),  'FlatClass','P20c: blessing preserved');
};

subtest 'P21 J=F,K=F,N=T(flat,def): HASH ref, defined $default -> LIMITATION' => sub {
	# HASH ref with defined $default: falls through I=T block (K=F for HASH),
	# reaches L=T, N=T -> returns HASH by identity, not wrapped.
	my $h      = { z => 99 };
	my $result = get_params('outer', $h);

	is($result, $h, 'P21: HASH ref with $default returned by identity (LIMITATION)');
	ok(!exists $result->{outer}, 'P21: $default key absent -- HASH not wrapped');
};

subtest 'P22 I=F,L=F(flat): undef arg, undef $default -> return undef' => sub {
	my $result = get_params(undef, undef);

	ok(!defined($result), 'P22: undef arg with undef $default -> return undef (L=F)');
};

subtest 'P23 I=F,L=T,M=T,N=T(flat): REF-of-HASH, undef $default -> deref -> return HASH' => sub {
	# ref(arg)='REF' -> not ARRAY -> D=F. M=T -> deref -> HASH -> N=T -> return.
	my %h      = (k => 'v');
	my $href   = \%h;
	my $rref   = \$href;       # ref($rref) eq 'REF'

	my $result = get_params(undef, $rref);

	is_deeply($result, { k => 'v' }, 'P23: REF-of-HASH dereffed (M=T); HASH returned (N=T)');
};

subtest 'P24 I=F,L=T,M=F,N=T(flat): HASH ref direct, undef $default -> returned by identity' => sub {
	# HASH ref: D=F (not ARRAY), H=T, I=F. L=T, M=F (ref=HASH not REF), N=T.
	my $h      = { a => 1 };
	my $result = get_params(undef, $h);

	is($result, $h, 'P24: plain HASH ref, undef $default -> returned by identity (N=T)');
};

subtest 'P25 croak(flat): unrecognised single arg, undef $default -> croak' => sub {
	# String: !$kind is true in I=T context, but I=F here. L=T, M=F, N=F, O=F -> croak.
	throws_ok(
		sub { get_params(undef, 'unrecognised_string') },
		$USAGE_RE,
		'P25: string, undef $default -> croak (no valid convention matched)',
	);
};

# =========================================================================
# SECTION 10: P26-P29 -- Two-arg OO constructor paths (P=T)
#
# P=T: $num_args==2 AND ref($args->[1]) eq HASH
# Q=T: defined $default  -> enter OO sub-dispatch
# Q=F: undef $default    -> fall through to even-pairs return
# R=T: non-empty opts    -> check if first arg IS $default key (S)
# R=F: empty opts        -> return { $default => empty hashref }
# S=T: first arg IS key  -> wrap opts hashref under key
# S=F: first arg NOT key -> merge mandatory + opts
# =========================================================================

subtest 'P26 P=T,Q=T,R=T,S=T: first arg IS $default key -> wrap opts hashref' => sub {
	# $args->[0] eq $default -> return { $default => opts }.
	my $opts   = { role => 'admin' };
	my $result = get_params('id', 'id', $opts);

	is_deeply($result, { id => { role => 'admin' } },
		'P26: first arg == $default -> opts hashref stored under key');
	is($result->{id}, $opts, 'P26: same opts reference stored');
};

subtest 'P27 P=T,Q=T,R=T,S=F: first arg != $default key -> mandatory + merge' => sub {
	# $args->[0]='Alice' ne $default='name' -> merge.
	my $result = get_params('name', 'Alice', { role => 'user', active => 1 });

	is_deeply($result, { name => 'Alice', role => 'user', active => 1 },
		'P27: mandatory value + non-empty opts merged (S=F)');
};

subtest 'P28 P=T,Q=T,R=F: empty options hash -> stored as value' => sub {
	# scalar keys %{}  == 0 -> R=F -> return { $default => empty hashref }.
	my $empty  = {};
	my $result = get_params('id', 42, $empty);

	is_deeply($result, { id => {} },
		'P28: empty opts stored as value under $default (R=F)');
	is($result->{id}, $empty, 'P28: same empty hashref reference stored');
};

subtest 'P29 P=T,Q=F: undef $default + 2-arg HASH -> falls to even-pairs path' => sub {
	# P=T but Q=F (undef $default) -> OO block produces no return -> T=F -> U=T.
	my $h      = { role => 'guest' };
	my $result = get_params(undef, 'key', $h);

	is_deeply($result, { key => { role => 'guest' } },
		'P29: undef $default with 2-arg HASH -> treated as flat pair (Q=F fallthrough)');
};

# =========================================================================
# SECTION 11: P30/P31 -- Flat-list even/odd paths (D=F, num_args>2 or no OO match)
# =========================================================================

subtest 'P30 U=T(flat): even flat-list args -> named pairs' => sub {
	my $result = get_params(undef, x => 10, y => 20, z => 30);

	is_deeply($result, { x => 10, y => 20, z => 30 },
		'P30: 6 flat args (even, U=T) -> named pairs');
	memory_cycle_ok($result, 'P30: cycle-free');
};

subtest 'P31 U=F(flat): odd flat-list args -> croak' => sub {
	throws_ok(
		sub { get_params(undef, 'a', 1, 'b') },
		$USAGE_RE,
		'P31: 3 flat args (odd, U=F) -> croak',
	);
};

done_testing();
