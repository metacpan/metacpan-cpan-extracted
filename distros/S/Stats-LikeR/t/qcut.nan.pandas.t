#!/usr/bin/env perl
# qcut() with missing values, against pandas.
#
# Provenance: t/qcut.nan.pandas.py (committed next to this file) printed every
# value below under pandas 3.0.4 and NumPy 2.5.2; re-run it with
#     python3 -I t/qcut.nan.pandas.py
# This test never runs Python.  The cases are pandas' own,
# pandas/tests/reshape/test_qcut.py:
#   nas            test_qcut_nas: 100 standard normals from
#                  np.random.default_rng(2), the first 20 set to NaN, in 4
#                  bins.  pandas asserts only that those 20 are missing; the
#                  edges and codes of the other 80 are pinned here too.
#   nullable_q*    test_qcut_nullable_integer: 0..99 with every other value
#                  NA, in 2, 5 and 10 bins, which pandas requires to bin as
#                  the float array with NaN there.  Both spellings of NA are
#                  run here, undef and NaN, and must agree.
#
# Up to 0.3413 qcut() treated only undef as missing, so NaN was binned as a
# number and every edge it touched came back NaN.
#
# Tolerance: the edges are numpy's linear interpolation, which _qcut_core
# repeats; on the double build on 2026-11-03 the worst disagreement was
# 4.1e-16 relative, the last bit of an interpolated edge.  1e-12 relative
# leaves room for the wider NV builds, whose h = (n - 1) * p and its
# interpolation round differently.  The codes are compared exactly.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(qcut);

my $NAN = 9**9**9 - 9**9**9;
my @NAS = ($NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, $NAN, 0.8414649723701431, 0.18803508698068597, 0.33057100813532614, 0.41050391297026284, -1.0107575001533344, 0.7831809961440773, 2.0567028183423686, -1.6384425032355252, -1.7294114671544816, -1.50483141386432, 0.8414588934539998, 0.12871565747406846, 1.078342440739298, 0.722430872307499, 0.21057181237528058, 0.28403814525037085, -0.16976049772313542, 0.8684602112115102, -1.1297159617807548, -0.4218588261783162, 0.2429388530987352, 1.8014208584493328, -0.7644641157203993, -1.0790604591369424, -0.5632871985040379, 0.9692722011381628, -0.23500550689182578, 1.324347019236957, -1.872529517606024, 1.128523141900478, 1.0348662399295387, -1.4186656898014849, 0.15358188653595775, 1.2157576351945363, 0.08791904230952238, 0.99970142215178, 2.3748869133171437, 0.2739322545923299, -0.2803823139429379, -0.7710521598195307, 0.6480646015444852, -0.19673006635772372, -0.17874637079406783, -0.1052597784150319, 0.6498696525854939, -1.0663396121649127, -1.5298764906705564, -2.4338766971489387, 1.1986708993900783, 0.07379335958326627, 1.5101194131223459, -0.00895629811039896, -0.7421554551991772, 0.477929298799656, -0.07658841293719656, -1.2541866619736308, -0.885066581450772, 1.766779317484588, 0.3543505953235256, 0.4163865350301778, -0.27655171832101155, -0.6897195637660919, 0.8916558155709342, -0.10462645267369168, -0.7591081117479301, -0.13412851934954786, -0.9056060167223513, 0.19004583859111193, 1.12922763006904, -0.8360851661432465, 1.428544005170784, -0.6676199486614574, 0.15341216272393984, -0.8363865253041882, -0.22223516635433505, 0.047404412494126226, -0.4346849461734271, -0.7028878955725052, -0.6778861906636612, -0.8211599492508597);

my %EXPECT = (
	nas => {
		q     => 4,
		edges => [-2.4338766971489387, -0.7463936193363655, 0.019224057191863632, 0.7376184032666436, 2.3748869133171437],
		codes => [undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, 3, 2, 2, 2, 0, 3, 3, 0, 0, 0, 3, 2, 3, 2, 2, 2, 1, 3, 0, 1, 2, 3, 0, 0, 1, 3, 1, 3, 0, 3, 3, 0, 2, 3, 2, 3, 3, 2, 1, 0, 2, 1, 1, 1, 2, 0, 0, 0, 3, 2, 3, 1, 1, 2, 1, 0, 0, 3, 2, 2, 1, 1, 3, 1, 0, 1, 0, 2, 3, 0, 3, 1, 2, 0, 1, 2, 1, 1, 1, 0],
	},
	nullable_q2 => {
		q     => 2,
		edges => [1.0, 50.0, 99.0],
		codes => [undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1],
	},
	nullable_q5 => {
		q     => 5,
		edges => [1.0, 20.6, 40.2, 59.80000000000002, 79.4, 99.0],
		codes => [undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 2, undef, 2, undef, 2, undef, 2, undef, 2, undef, 2, undef, 2, undef, 2, undef, 2, undef, 2, undef, 3, undef, 3, undef, 3, undef, 3, undef, 3, undef, 3, undef, 3, undef, 3, undef, 3, undef, 3, undef, 4, undef, 4, undef, 4, undef, 4, undef, 4, undef, 4, undef, 4, undef, 4, undef, 4, undef, 4],
	},
	nullable_q10 => {
		q     => 10,
		edges => [1.0, 10.8, 20.6, 30.40000000000001, 40.2, 50.0, 59.80000000000002, 69.60000000000002, 79.4, 89.2, 99.0],
		codes => [undef, 0, undef, 0, undef, 0, undef, 0, undef, 0, undef, 1, undef, 1, undef, 1, undef, 1, undef, 1, undef, 2, undef, 2, undef, 2, undef, 2, undef, 2, undef, 3, undef, 3, undef, 3, undef, 3, undef, 3, undef, 4, undef, 4, undef, 4, undef, 4, undef, 4, undef, 5, undef, 5, undef, 5, undef, 5, undef, 5, undef, 6, undef, 6, undef, 6, undef, 6, undef, 6, undef, 7, undef, 7, undef, 7, undef, 7, undef, 7, undef, 8, undef, 8, undef, 8, undef, 8, undef, 8, undef, 9, undef, 9, undef, 9, undef, 9, undef, 9],
	},
);

sub close_list {
	my ($got, $want, $name) = @_;
	is(scalar @$got, scalar @$want, "$name: count") or return;
	my $worst = 0;
	for my $i (0 .. $#$want) {
		my $d = abs($got->[$i] - $want->[$i]);
		my $s = abs($want->[$i]) > 1 ? abs($want->[$i]) : 1;
		$worst = $d / $s if $d / $s > $worst;
	}
	ok($worst <= 1e-12, "$name: within 1e-12") or diag("worst relative difference $worst");
}

for my $key (sort keys %EXPECT) {
	my $e = $EXPECT{$key};
	my @data;
	if ($key eq 'nas') { @data = @NAS }
	else { @data = map { $_ % 2 ? $_ : $NAN } 0 .. 99 }
	my @spellings = ([NaN => [@data]]);
	push @spellings, [undef => [map { $_ == $_ ? $_ : undef } @data]];
	for my $sp (@spellings) {
		my ($how, $d) = @$sp;
		my ($codes, $edges) = qcut($d, $e->{q}, codes => 1, edges => 1);
		close_list($edges, $e->{edges}, "$key ($how as NA): edges");
		is_deeply($codes, $e->{codes}, "$key ($how as NA): codes, with NA left missing");
		my @flat = qcut($d, $e->{q});
		close_list(\@flat, $e->{edges}, "$key ($how as NA): edges alone");
	}
}

done_testing();
