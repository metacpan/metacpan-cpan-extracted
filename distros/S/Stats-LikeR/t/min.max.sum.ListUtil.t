#!/usr/bin/env perl
# min(), max() and sum() against List::Util's own tests for the same names.
#
# Provenance: Scalar-List-Utils 1.70, the copy bundled with perl 5.44.0
# (cpan/Scalar-List-Utils/t/min.t, t/max.t and t/sum.t). Every case below is
# one of those, in the same order, under the same test name, with the import
# changed from List::Util to Stats::LikeR; the one addition is a no-argument
# croak check for min() and max() beside sum()'s. Upstream defines Foo once per
# file, overloading only the comparison that file needs; the single Foo here
# overloads both, which changes nothing either test calls. There are no reference numbers to
# freeze: each upstream expectation is either a literal in its own file or is
# computed there from the inputs (a sort, a BigInt sum), and that is kept.
#
# Where the port departs from upstream, and why:
#
#  * sum() with no arguments. List::Util returns undef; Stats::LikeR croaks
#    "sum needs >= 1 element", as it does for an empty min() and max(). That is
#    documented behaviour, so the croak is what is tested here.
#
#  * Math::BigInt. min(), max() and sum() here are NV reductions -- the XSUBs
#    return an NV -- so a BigInt argument goes through its 0+ overload and the
#    answer is the NV nearest the exact one, not a BigInt. Upstream's `is()`
#    against the exact 2**65-ish integer is therefore replaced by `==` against
#    the same arithmetic done on the NVs, which is what the XSUB is meant to
#    compute. The expected NV is built by perl's own numification of the
#    BigInt's decimal string, so it tracks the NV width: on a double build
#    2**65 - 2 rounds to 2**65, on a long-double build it is exact.
#
#  * sum()'s "uses IV where it can" and "min + max" cases are dropped.
#    List::Util sums in IV while every value fits and so gets
#    sum(1<<60, 1) > 1<<60 and sum(-(1<<63), IV_MAX) == -1; an NV sum gives
#    1<<60 and 0 on a double build (R's double sum() gives the same), and the
#    exact answers on long double and quadmath. Neither is a defect.
#
#  * The `example` class -- a blessed *array* ref overloading 0+ -- is flattened
#    as an array of data, as every array ref is here, blessed or not and
#    overloaded or not: the maintainer chose that over List::Util's reading on
#    2026-09-27, so that an array-based object passed to a reduction keeps
#    being read as the values it holds. Its second element is the tag "test",
#    so upstream's three sums croak "non-numeric value at array ref index 1",
#    and that croak is what is tested. A blessed arrayref whose elements are
#    all numbers is summed as its elements, which is tested beside them.
#
# The GETMAGIC block is upstream's regression test for arguments whose value
# exists only once their get magic has run: `$#list` has no value flags until
# then. Up to 0.321 all three functions croaked "undefined value at argument
# index 1" on it; t/get.magic.args.t covers the rest of the family.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(min max sum);
use Math::BigInt;

# rand() as upstream, but seeded so that a failure reproduces
srand(20260927);

{
	package Foo;
	# min.t's, max.t's and sum.t's Foo, with both comparisons overloaded
	use overload
	  '""' => sub { ${ $_[0] } },
	  '0+' => sub { ${ $_[0] } },
	  '<'  => sub { ${ $_[0] } < ${ $_[1] } },
	  '>'  => sub { ${ $_[0] } > ${ $_[1] } },
	  fallback => 1;
	sub new {
		my ($class, $value) = @_;
		bless \$value, $class;
	}
}
{
	package example;
	# sum.t's: numifies to its first element, stringifies with a tag
	use overload
	  '0+' => sub { $_[0][0] },
	  '""' => sub { my $r = "$_[0][0]"; $r = "+$r" unless $r =~ m/^\-/; $r .= " [$_[0][1]]"; $r },
	  fallback => 1;
	sub new {
		my $class = shift;
		return bless [@_], $class;
	}
}

my $one = Foo->new(1);
my $two = Foo->new(2);
my $thr = Foo->new(3);

my $v1 = Math::BigInt->new(2) ** Math::BigInt->new(65);
my $v2 = $v1 - 1;
my $v3 = $v2 - 1;
sub nv { 0 + "$_[0]" }	# the NV a BigInt's 0+ overload yields

subtest 'min.t' => sub {
	ok(defined &min, 'defined');
	is(min(9), 9, 'single arg');
	is(min(1, 2), 1, '2-arg ordered');
	is(min(2, 1), 1, '2-arg reverse ordered');
	my @a = map { rand() } 1 .. 20;
	my @b = sort { $a <=> $b } @a;
	is(min(@a), $b[0], '20-arg random order');
	is(min($one, $two, $thr), 1, 'overload');
	is(min($thr, $two, $one), 1, 'overload');
	cmp_ok(min($v1, $v2, $v1, $v3, $v1), '==', nv($v3), 'bigint');
	is(min($v1, 1, 2, 3), 1, 'bigint and normal int');
	is(min(1, 2, $v1, 3), 1, 'bigint and normal int');
	like(eval { min(); 1 } ? '' : $@, qr/^min needs >= 1 numeric element/, 'no args croaks');
};

subtest 'max.t' => sub {
	ok(defined &max, 'defined');
	is(max(1), 1, 'single arg');
	is(max(1, 2), 2, '2-arg ordered');
	is(max(2, 1), 2, '2-arg reverse ordered');
	my @a = map { rand() } 1 .. 20;
	my @b = sort { $a <=> $b } @a;
	is(max(@a), $b[-1], '20-arg random order');
	is(max($one, $two, $thr), 3, 'overload');
	is(max($thr, $two, $one), 3, 'overload');
	cmp_ok(max($v1, $v2, $v1, $v3, $v1), '==', nv($v1), 'bigint');
	cmp_ok(max($v1, 1, 2, 3), '==', nv($v1), 'bigint and normal int');
	cmp_ok(max(1, 2, $v1, 3), '==', nv($v1), 'bigint and normal int');
	like(eval { max(); 1 } ? '' : $@, qr/^max needs >= 1 numeric element/, 'no args croaks');
};

subtest 'sum.t' => sub {
	like(eval { sum(); 1 } ? '' : $@, qr/^sum needs >= 1 element/, 'no args croaks');
	is(sum(9), 9, 'one arg');
	is(sum(1, 2, 3, 4), 10, '4 args');
	is(sum(-1), -1, 'one -1');
	my $x = -3;
	is(sum($x, 3), 0, 'variable arg');
	is(sum(-3.5, 3), -0.5, 'real numbers');
	is(sum(3, -3.5), -0.5, 'initial integer, then real');
	is(sum($one, $two, $thr), 6, 'overload');
	cmp_ok(sum($v1, $v2), '==', nv($v1) + nv($v2), 'bigint');
	cmp_ok(sum(42, $v1), '==', 42 + nv($v1), 'bigint + builtin int');
	cmp_ok(sum(42, $v1, 2), '==', 42 + nv($v1) + 2, 'bigint + builtin int');
	# upstream expects 21, 23 and 25: see the header for why these croak
	my $e1 = example->new(7, 'test');
	like(eval { sum($e1, 7, 7); 1 } ? '' : $@,
	     qr/^sum: non-numeric value at array ref index 1 \(argument 0\)/, 'overload returning non-overload');
	like(eval { sum(8, $e1, 8); 1 } ? '' : $@,
	     qr/^sum: non-numeric value at array ref index 1 \(argument 1\)/, 'overload returning non-overload');
	like(eval { sum(9, 9, $e1); 1 } ? '' : $@,
	     qr/^sum: non-numeric value at array ref index 1 \(argument 2\)/, 'overload returning non-overload');
	is(sum(example->new(7, 5), 7), 19, 'an overloaded blessed arrayref is summed as its elements');
};

subtest 'GETMAGIC' => sub {
	# min.t's closing block: $#list is magical, and has no value until it runs
	my @list;
	for my $size (10, 20, 10, 30) {
		@list = (1) x $size;
		my $sum = sum(0, $#list);
		ok($sum == $size - 1, "sum(\$#list, 0) == $size-1");
		my $min = min(15, $#list);
		ok($min <= 15, "min(15,$size)");
		my $max = max(0, $#list);
		ok($max == $size - 1, "max(\$#list, 0) == $size-1");
	}
};

done_testing();
