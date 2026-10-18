#!/usr/bin/env perl
#
# Cross-validation of get_union(), intersection(), Lonly(), Ronly() and
# is_equivalent() against List::Compare, using List::Compare's own test suite
# rather than cases invented here.  t/set_ops.t, t/intersection.t and
# t/is_equivalent.t already cover numeric keys, the UTF-8 flag, argument
# validation and leak checking; this file does not repeat those.
#
# Provenance of every expected value below: List::Compare 0.55 (CPAN, JKEENAN),
# the distribution's t/ directory.
#
#   * The fixture lists @a0, @a1, @a2, @a3, @a4 and @a8 are copied verbatim from
#     t/Test/ListCompareSpecial.pm, as are the membership tables
#     $test_member_which_dual, $test_member_which_mult, $test_members_which,
#     $test_members_which_mult, $test_member_any_dual, $test_member_any_mult,
#     $test_members_any and $test_members_any_mult.
#   * The two-list expectations are the @pred values of
#     t/33_func_lists_dual_sorted.t, and the five- and six-list ones those of
#     t/35_func_lists_mult_sorted.t.  The OO files t/01 to t/16 and the other
#     functional list files t/34 and t/36 to t/40 pin the same values for the
#     same fixture, through the OO interface, the unsorted and accelerated
#     modes, and the { lists => [...] } call form.
#   * The subset fixture and verdicts are those of t/50_lcf_subset.t, which
#     t/49_lc_subset.t repeats through the OO interface.
#   * The constructor errors are those at the end of
#     t/01_oo_lists_dual_reg_sorted.t.
#
# List::Compare's methods map onto Stats::LikeR as follows.  The first five are
# direct equivalents; the rest are compositions of them, which put
# List::Compare's pinned answers on the functions from more directions.
#
#   get_union                  get_union(@lists)
#   get_intersection           intersection(@lists)
#   get_unique, get_Lonly      Lonly(@lists)            (list 0 only)
#   get_unique(.., [k])        Lonly(list k, the others), Ronly(the others, list k)
#   get_complement (2 lists),  Ronly(L, R)
#     get_Ronly
#   is_LequivalentR([i, j])    is_equivalent(list i, list j)
#   get_complement(.., [k])    Lonly([get_union(the others)], list k)
#   get_symmetric_difference   get_union(map { [Lonly(list k, the others)] } k)
#   get_nonintersection        Lonly([get_union(@lists)], [intersection(@lists)])
#   get_shared                 Lonly([get_union(@lists)], [symmetric difference])
#   is_LsubsetR([i, j])        scalar Lonly(list i, list j) == 0
#   is_RsubsetL([i, j])        scalar Ronly(list i, list j) == 0
#   is_LdisjointR([i, j])      scalar intersection(list i, list j) == 0
#   is_member_which(.., [v])   the k for which scalar intersection([v], list k) == 1
#   is_member_any(.., [v])     scalar intersection([v], [get_union(@lists)])
#
# Left out, because Stats::LikeR has no counterpart: get_bag (a multiset union,
# where Stats::LikeR's functions all deduplicate), the seen-hash input files t/17
# to t/32 and t/41 to t/48 (Stats::LikeR takes array references only; those
# hashes' keys are the same sets as the arrays here), print_subset_chart,
# print_equivalence_chart, get_version, and the errors in t/90 and t/91, which
# are about List::Compare's own argument forms and seen-hash values.
#
# List::Compare returns its results sorted; these functions return them in
# first-appearance order.  Every fixture list is in alphabetical order, and the
# lists introduce new values in alphabetical order too, so here the two orders
# coincide and every comparison below is exact, order included.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception; # throws_ok
use Stats::LikeR qw(get_union intersection Lonly Ronly is_equivalent);

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);
my @a2 = qw(fargo golfer hilton icon icon jerky);
my @a3 = qw(fargo golfer hilton icon icon);
my @a4 = qw(fargo fargo golfer hilton icon);
my @a8 = qw(kappa lambda mu);

# The values the membership tables are indexed by, from t/33 and t/35.
my @args = qw(abel baker camera delta edward fargo golfer hilton icon jerky zebra);

# List::Compare's is_member_which() for one value: the indices of the lists
# that contain it, in index order.
sub member_which {
	my ($lists, $v) = @_;
	return [ grep { scalar(intersection([$v], $lists->[$_])) == 1 } 0..$#$lists ];
}

# The lists other than index $k, in their original order.
sub others {
	my ($lists, $k) = @_;
	return map { $lists->[$_] } grep { $_ != $k } 0..$#$lists;
}

# Every way of asking for "only in list $k" that Lonly() and Ronly() offer: $k
# moved to the front for Lonly() and to the back for Ronly().  The order of the
# other lists does not affect the answer, so both are also asked with the
# others reversed.
sub only_in {
	my ($lists, $k, $pred, $what) = @_;
	my @rest = others($lists, $k);
	is_deeply([Lonly($lists->[$k], @rest)],         $pred, "$what: Lonly, list $k first");
	is_deeply([Lonly($lists->[$k], reverse @rest)], $pred, "$what: Lonly, list $k first, others reversed");
	is_deeply([Ronly(@rest, $lists->[$k])],         $pred, "$what: Ronly, list $k last");
	is_deeply([Ronly(reverse(@rest), $lists->[$k])], $pred, "$what: Ronly, list $k last, others reversed");
	is(scalar(Lonly($lists->[$k], @rest)), scalar(@$pred), "$what: Lonly count, list $k first");
	is(scalar(Ronly(@rest, $lists->[$k])), scalar(@$pred), "$what: Ronly count, list $k last");
}

# Values in exactly one list (List::Compare's get_symmetric_difference).
sub symdiff {
	my @lists = @_;
	return get_union(map { [Lonly($lists[$_], others(\@lists, $_))] } 0..$#lists);
}

# ---------------------------------------------------------------------------
# Two lists, t/33_func_lists_dual_sorted.t
# ---------------------------------------------------------------------------
{
	my @L = (\@a0, \@a1);
	my @pred;

	@pred = qw(abel baker camera delta edward fargo golfer hilton);
	is_deeply([get_union(@L)], \@pred, 'dual get_union');
	is(scalar(get_union(@L)), scalar(@pred), 'dual get_union: count');

	# get_shared and get_intersection agree for two lists.
	@pred = qw(baker camera delta edward fargo golfer);
	is_deeply([intersection(@L)], \@pred, 'dual get_intersection');
	is(scalar(intersection(@L)), scalar(@pred), 'dual get_intersection: count');

	@pred = qw(abel);
	is_deeply([Lonly(@L)], \@pred, 'dual get_unique / get_Lonly');
	is(scalar(Lonly(@L)), 1, 'dual get_unique: count');

	@pred = qw(hilton);
	is_deeply([Ronly(@L)], \@pred, 'dual get_complement / get_Ronly');
	is(scalar(Ronly(@L)), 1, 'dual get_complement: count');

	# get_unique_all: [ [abel], [hilton] ]; get_complement_all: [ [hilton], [abel] ].
	my @unique_all = ([qw(abel)], [qw(hilton)]);
	only_in(\@L, $_, $unique_all[$_], 'dual get_unique_all') for 0..$#L;
	is_deeply([Ronly(reverse @L)], [qw(abel)], 'dual get_complement_all, list 1');
	is_deeply([Lonly(reverse @L)], [qw(hilton)], 'dual get_unique_all, list 1, via Lonly');

	# get_symmetric_difference, get_symdiff and get_nonintersection agree for two lists.
	@pred = qw(abel hilton);
	is_deeply([get_union([Lonly(@L)], [Ronly(@L)])], \@pred, 'dual get_symmetric_difference');
	is_deeply([symdiff(@L)], \@pred, 'dual get_symmetric_difference, by rotation');
	is_deeply([Lonly([get_union(@L)], [intersection(@L)])], \@pred, 'dual get_nonintersection');

	is(scalar(Lonly(@L)) == 0 ? 1 : 0, 0, 'dual is_LsubsetR: a0 is not a subset of a1');
	is(scalar(Ronly(@L)) == 0 ? 1 : 0, 0, 'dual is_RsubsetL: a1 is not a subset of a0');
	is(is_equivalent(@L), 0, 'dual is_LequivalentR: a0, a1 not equivalent');
	is(is_equivalent(reverse @L), 0, 'dual is_LequivalentR: symmetric');
	is(scalar(intersection(@L)) == 0 ? 1 : 0, 0, 'dual is_LdisjointR: a0, a1 not disjoint');

	# is_member_which, are_members_which, is_member_any, are_members_any.
	my $test_member_which_dual = [
		[ qw( 0   ) ],
		[ qw( 0 1 ) ],
		[ qw( 0 1 ) ],
		[ qw( 0 1 ) ],
		[ qw( 0 1 ) ],
		[ qw( 0 1 ) ],
		[ qw( 0 1 ) ],
		[ qw(   1 ) ],
		[ qw(     ) ],
		[ qw(     ) ],
		[ qw(     ) ],
	];
	my $test_members_which = {
		abel   => [ 1, [ qw< 0   > ] ],
		baker  => [ 2, [ qw< 0 1 > ] ],
		camera => [ 2, [ qw< 0 1 > ] ],
		delta  => [ 2, [ qw< 0 1 > ] ],
		edward => [ 2, [ qw< 0 1 > ] ],
		fargo  => [ 2, [ qw< 0 1 > ] ],
		golfer => [ 2, [ qw< 0 1 > ] ],
		hilton => [ 1, [ qw<   1 > ] ],
		icon   => [ 0, [ qw<     > ] ],
		jerky  => [ 0, [ qw<     > ] ],
		zebra  => [ 0, [ qw<     > ] ],
	};
	my $test_member_any_dual = [ 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 ];
	my $test_members_any = {
		abel  => 1, baker => 1, camera => 1, delta => 1, edward => 1, fargo => 1,
		golfer => 1, hilton => 1, icon => 0, jerky => 0, zebra => 0,
	};
	is_deeply([map { member_which(\@L, $_) } @args], $test_member_which_dual, 'dual is_member_which');
	for my $v (sort keys %$test_members_which) {
		my $which = member_which(\@L, $v);
		is_deeply([scalar(@$which), $which], $test_members_which->{$v}, "dual are_members_which: $v");
	}
	my $U = [get_union(@L)];
	is_deeply([map { scalar(intersection([$_], $U)) } @args], $test_member_any_dual, 'dual is_member_any');
	is_deeply({ map { $_ => scalar(intersection([$_], $U)) } keys %$test_members_any },
		$test_members_any, 'dual are_members_any');
}

# Further two-list pairs, also from t/33.
is(scalar(Lonly(\@a2, \@a3)) == 0 ? 1 : 0, 0, 'a2, a3: is_LsubsetR false');
is(scalar(Ronly(\@a2, \@a3)) == 0 ? 1 : 0, 1, 'a2, a3: is_RsubsetL true');
is(is_equivalent(\@a2, \@a3), 0, 'a2, a3: is_LequivalentR false');
is(scalar(intersection(\@a2, \@a3)) == 0 ? 1 : 0, 0, 'a2, a3: is_LdisjointR false');

is(is_equivalent(\@a3, \@a4), 1, 'a3, a4: is_LequivalentR true');
is(is_equivalent(\@a4, \@a3), 1, 'a4, a3: is_LequivalentR true, reversed');
is(scalar(intersection(\@a3, \@a4)) == 0 ? 1 : 0, 0, 'a3, a4: is_LdisjointR false');

is(scalar(intersection(\@a4, \@a8)), 0, 'a4, a8: no intersection (scalar)');
is_deeply([intersection(\@a4, \@a8)], [], 'a4, a8: no intersection (list)');

# ---------------------------------------------------------------------------
# Five and six lists, t/35_func_lists_mult_sorted.t
# ---------------------------------------------------------------------------
{
	my @L = (\@a0, \@a1, \@a2, \@a3, \@a4);
	my @pred;

	@pred = qw(abel baker camera delta edward fargo golfer hilton icon jerky);
	is_deeply([get_union(@L)], \@pred, 'mult get_union');
	is(scalar(get_union(@L)), scalar(@pred), 'mult get_union: count');

	@pred = qw(fargo golfer);
	is_deeply([intersection(@L)], \@pred, 'mult get_intersection');
	is(scalar(intersection(@L)), scalar(@pred), 'mult get_intersection: count');

	# get_unique with no index defaults to list 0.
	is_deeply([Lonly(@L)], [qw(abel)], 'mult get_unique, default list 0');
	is(scalar(Lonly(@L)), 1, 'mult get_unique, default list 0: count');

	# get_unique([..], [2]) is jerky.
	is_deeply([Lonly($L[2], others(\@L, 2))], [qw(jerky)], 'mult get_unique([2])');

	# Ronly() takes the last list where List::Compare's get_Ronly would take
	# the complement of list 0; get_unique_all's entry for list 4 is its answer.
	is_deeply([Ronly(@L)], [], 'mult Ronly: nothing is only in list 4');
	is(scalar(Ronly(@L)), 0, 'mult Ronly: count 0');

	my @unique_all = ([qw(abel)], [], [qw(jerky)], [], []);
	only_in(\@L, $_, $unique_all[$_], 'mult get_unique_all') for 0..$#L;

	# get_complement([..], [1]) and get_complement_all; the default index is 0.
	my @complement_all = (
		[ qw( hilton icon jerky ) ],
		[ qw( abel icon jerky ) ],
		[ qw( abel baker camera delta edward ) ],
		[ qw( abel baker camera delta edward jerky ) ],
		[ qw( abel baker camera delta edward jerky ) ],
	);
	for my $k (0..$#L) {
		is_deeply([Lonly([get_union(others(\@L, $k))], $L[$k])], $complement_all[$k],
			"mult get_complement_all, list $k");
		is_deeply([Ronly($L[$k], [get_union(others(\@L, $k))])], $complement_all[$k],
			"mult get_complement_all, list $k, via Ronly");
	}

	@pred = qw(abel jerky);
	my @sd = symdiff(@L);
	is_deeply(\@sd, \@pred, 'mult get_symmetric_difference');

	@pred = qw(abel baker camera delta edward hilton icon jerky);
	is_deeply([Lonly([get_union(@L)], [intersection(@L)])], \@pred, 'mult get_nonintersection');

	@pred = qw(baker camera delta edward fargo golfer hilton icon);
	is_deeply([Lonly([get_union(@L)], \@sd)], \@pred, 'mult get_shared');

	# is_LsubsetR([3, 2]) true, ([2, 3]) false, default [0, 1] false.
	is(scalar(Lonly($L[3], $L[2])) == 0 ? 1 : 0, 1, 'mult is_LsubsetR([3, 2]) true');
	is(scalar(Lonly($L[2], $L[3])) == 0 ? 1 : 0, 0, 'mult is_LsubsetR([2, 3]) false');
	is(scalar(Lonly($L[0], $L[1])) == 0 ? 1 : 0, 0, 'mult is_LsubsetR default false');

	is(is_equivalent($L[3], $L[4]), 1, 'mult is_LequivalentR([3, 4]) true');
	is(is_equivalent($L[2], $L[4]), 0, 'mult is_LequivalentR([2, 4]) false');

	my $test_member_which_mult = [
		[ qw( 0         ) ],
		[ qw( 0 1       ) ],
		[ qw( 0 1       ) ],
		[ qw( 0 1       ) ],
		[ qw( 0 1       ) ],
		[ qw( 0 1 2 3 4 ) ],
		[ qw( 0 1 2 3 4 ) ],
		[ qw(   1 2 3 4 ) ],
		[ qw(     2 3 4 ) ],
		[ qw(     2     ) ],
		[ qw(           ) ],
	];
	my $test_members_which_mult = {
		abel   => [ qw< 0         > ],
		baker  => [ qw< 0 1       > ],
		camera => [ qw< 0 1       > ],
		delta  => [ qw< 0 1       > ],
		edward => [ qw< 0 1       > ],
		fargo  => [ qw< 0 1 2 3 4 > ],
		golfer => [ qw< 0 1 2 3 4 > ],
		hilton => [ qw<   1 2 3 4 > ],
		icon   => [ qw<     2 3 4 > ],
		jerky  => [ qw<     2     > ],
		zebra  => [ qw<           > ],
	};
	my $test_member_any_mult = [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ];
	my $test_members_any_mult = {
		abel  => 1, baker => 1, camera => 1, delta => 1, edward => 1, fargo => 1,
		golfer => 1, hilton => 1, icon => 1, jerky => 1, zebra => 0,
	};
	is_deeply([map { member_which(\@L, $_) } @args], $test_member_which_mult, 'mult is_member_which');
	is_deeply({ map { $_ => member_which(\@L, $_) } keys %$test_members_which_mult },
		$test_members_which_mult, 'mult are_members_which');
	my $U = [get_union(@L)];
	is_deeply([map { scalar(intersection([$_], $U)) } @args], $test_member_any_mult, 'mult is_member_any');
	is_deeply({ map { $_ => scalar(intersection([$_], $U)) } keys %$test_members_any_mult },
		$test_members_any_mult, 'mult are_members_any');

	# is_LdisjointR over six lists: default [0, 1] and [2, 3] false, [4, 5] true.
	my @L6 = (@L, \@a8);
	is(scalar(intersection($L6[0], $L6[1])) == 0 ? 1 : 0, 0, 'six lists is_LdisjointR default false');
	is(scalar(intersection($L6[2], $L6[3])) == 0 ? 1 : 0, 0, 'six lists is_LdisjointR([2, 3]) false');
	is(scalar(intersection($L6[4], $L6[5])) == 0 ? 1 : 0, 1, 'six lists is_LdisjointR([4, 5]) true');
	is(scalar(intersection(@L6)), 0, 'six lists: a8 empties the whole intersection');
}

# ---------------------------------------------------------------------------
# Subsets, t/50_lcf_subset.t (and t/49_lc_subset.t)
# ---------------------------------------------------------------------------
{
	my @s0 = qw(alpha);
	my @s1 = qw(alpha beta);
	my @s2 = qw(alpha beta gamma);
	my @s3 = qw(gamma);
	# [ left, right, is_LsubsetR, is_RsubsetL, description ]
	my @cases = (
		[ [],   [],   1, 1, 'empty array is subset of itself' ],
		[ \@s0, \@s0, 1, 1, 'array is subset of itself' ],
		[ \@s0, \@s3, 0, 0, 'disjoint are not subsets' ],
		[ \@s0, \@s1, 1, 0, 'left is subset of right' ],
		[ \@s1, \@s0, 0, 1, 'right is subset of left' ],
	);
	for my $c (@cases) {
		my ($l, $r, $LR, $RL, $what) = @$c;
		is(scalar(Lonly($l, $r)) == 0 ? 1 : 0, $LR, "is_LsubsetR: $what");
		is(scalar(Ronly($l, $r)) == 0 ? 1 : 0, $RL, "is_RsubsetL: $what");
		# t/50 does not ask is_LequivalentR of these pairs; equivalence is
		# subset both ways, so its verdicts imply the answer.
		is(is_equivalent($l, $r), ($LR && $RL) ? 1 : 0, "is_equivalent: $what");
	}
	# The pair argument: [ \@s0, \@s1, \@s2 ] with [1, 2] is a subset, and
	# [ \@s2, \@s1, \@s0 ] with [1, 2] is not.
	my @up   = (\@s0, \@s1, \@s2);
	my @down = reverse @up;
	is(scalar(Lonly($up[1],   $up[2]))   == 0 ? 1 : 0, 1, 'is_LsubsetR, 3 lists, pair [1, 2]: subset');
	is(scalar(Lonly($down[1], $down[2])) == 0 ? 1 : 0, 0, 'is_LsubsetR, 3 lists reversed, pair [1, 2]: not a subset');
}

# ---------------------------------------------------------------------------
# Constructor errors, t/01_oo_lists_dual_reg_sorted.t
# ---------------------------------------------------------------------------
# List::Compare->new dies on a mix of array and hash references, on a scalar
# reference, and on a single list.  Each function here croaks on the first two;
# only is_equivalent() needs two lists, the others accept one.
{
	my %h5 = (golfer => 1, lambda => 0);
	my $scalar = 'test';
	my %fn = (
		get_union     => \&get_union,
		intersection  => \&intersection,
		Lonly         => \&Lonly,
		Ronly         => \&Ronly,
		is_equivalent => \&is_equivalent,
	);
	for my $name (sort keys %fn) {
		my $f = $fn{$name};
		throws_ok { my @x = $f->(\@a0, \%h5) }      qr/not an array reference/, "$name: array ref then hash ref";
		throws_ok { my @x = $f->(\%h5, \@a0) }      qr/not an array reference/, "$name: hash ref then array ref";
		throws_ok { my @x = $f->(\$scalar, \@a0) }  qr/not an array reference/, "$name: scalar ref";
	}
	throws_ok { is_equivalent(\@a0) } qr/needs >= 2 array refs/, 'is_equivalent: a single list';
}

done_testing;
