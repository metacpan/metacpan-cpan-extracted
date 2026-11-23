#!/usr/bin/env perl
# Regression tests for the frame fixes made after 0.3427: dropna() on a HoA
# with an undef or non-array column, melt()'s variable cells on an AoA,
# interpolate() against pandas, summary() with NaN, and csort() with a tied
# cell that changes the frame while it is copied.
#
# Provenance.  interpolate(): pandas 3.0.4 (scipy 1.18.0), Series.interpolate;
# the expected values were computed with it and are frozen here (repr() of each
# float), since pandas has no test for these corners:
#   Series([0,nan,nan,10], index=[0,1,3,4]).interpolate('linear')
#       -> 0.0, 3.3333333333333335, 6.666666666666667, 10.0  (index ignored)
#       and 'index' -> 0.0, 2.5, 7.5, 10.0
#   Series([nan,5,nan,nan]).interpolate('barycentric') / 'krogh'
#       -> nan, 5.0, 5.0, 5.0; with limit_direction='both' -> 5.0 x 4
#   Series([1,2]).interpolate('quadratic') / 'cubic' -> 1.0, 2.0 (unchanged)
#   Series([1,2,4]).interpolate('cubic') -> 1.0, 2.0, 4.0
#   Series([nan,2,nan]).interpolate('cubic') -> ValueError
#   Series(...).interpolate('spline', order=1e30 or inf) -> ValueError
# summary(): R 4.6.1 summary(c(1,NaN,3,Inf)) gives Min 1, 1st Qu 2, Median 3,
# Mean Inf, 3rd Qu Inf, Max Inf, NA's 1 (summary.default drops NA and NaN from
# the quantiles and reports them as NA's).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use B ();
use Stats::LikeR qw(dropna melt interpolate summary csort);

# --- dropna: undef and non-array columns of a HoA ---------------------------
{
	my $df = { a => [1, undef, 3], b => undef };
	my $r = dropna($df, rows => [1]);
	is_deeply($r, { a => [1, 3], b => [undef, undef] }, 'rows: an undef column is all undef');
	ok(!defined $df->{b}, 'rows: the undef column is not autovivified in the caller');
	is_deeply(dropna($df, cols => ['a']), { a => [1, 3], b => [undef, undef] }, 'cols => [a]: the reference path');
	$r = dropna($df, cols => []);
	is_deeply($r, { a => [1, undef, 3], b => [undef, undef, undef] }, 'cols => []: an undef column is all undef');
	ok(!defined $df->{b}, 'cols => []: not autovivified');
	my $bad = { a => [1, undef, 3], b => 'x' };
	throws_ok { dropna($bad, rows => [1]) } qr/column 'b' is not an ARRAY reference/, 'rows: a string column dies naming it';
	throws_ok { dropna($bad, cols => []) } qr/column 'b' is not an ARRAY reference/, 'cols => []: a string column dies naming it';
	throws_ok { dropna($bad, cols => ['a']) } qr/column 'b' is not an ARRAY reference/, 'cols => [a]: same message';
}

# --- melt: an AoA's variable cells are plain strings -------------------------
{
	my $m = melt([ [1, 2, 3], [4, 5, 6] ], id_vars => ['0'], value_vars => ['1', '2']);
	my $f = B::svref_2object(\$m->[0][1])->FLAGS;
	ok(($f & B::SVf_POK) && !($f & B::SVf_IOK), 'variable cell is POK without IOK, as in 0.3424');
	my $ids = ['1'];
	melt([ [1, 2], [3, 4] ], id_vars => ['0'], value_vars => $ids);
	$f = B::svref_2object(\$ids->[0])->FLAGS;
	ok(!($f & B::SVf_IOK), "the caller's own column id gained no IOK");
}

# --- interpolate vs pandas 3.0.4 ---------------------------------------------
{
	my $r = interpolate({ v => [0, undef, undef, 10] }, x => [0, 1, 3, 4]);
	is_deeply([ map { sprintf '%.15g', $_ } @{ $r->{v} } ],
		[ map { sprintf '%.15g', $_ } 0.0, 3.3333333333333335, 6.666666666666667, 10.0 ],
		"linear ignores x, as pandas' linear ignores the index");
	$r = interpolate({ v => [0, undef, undef, 10] }, method => 'index', x => [0, 1, 3, 4]);
	is_deeply($r->{v}, [0, 2.5, 7.5, 10], 'index uses x');

	for my $m (qw(barycentric krogh)) {
		$r = interpolate({ v => [undef, 5, undef, undef] }, method => $m);
		is_deeply($r->{v}, [undef, 5, 5, 5], "$m, one anchor: held forward");
		$r = interpolate({ v => [undef, 5, undef, undef] }, method => $m, limit_direction => 'both');
		is_deeply($r->{v}, [5, 5, 5, 5], "$m, one anchor, both directions");
	}
	for my $m (qw(quadratic cubic)) {
		is_deeply(interpolate({ v => [1, 2] }, method => $m)->{v}, [1, 2], "$m, two complete values: unchanged");
	}
	is_deeply(interpolate({ v => [1, 2, 4] }, method => 'cubic')->{v}, [1, 2, 4], 'cubic, three complete values: unchanged');
	throws_ok { interpolate({ v => [1, undef, 4, 9] }, method => 'cubic') } qr/needs at least 4 numeric anchors/,
		'cubic with a gap and three anchors still dies (pandas: ValueError)';
	# perl's own spelling of 1e30: "1e+30" on a double or long double NV, all
	# 31 digits on __float128, whose 33 significant digits hold it exactly
	my $big = 1e30;
	throws_ok { interpolate({ v => [1, undef, 2, 5] }, method => 'spline', order => $big) } qr/\(got \Q$big\E\)/,
		'spline order 1e30 reports 1e30, not -1';
	throws_ok { interpolate({ v => [1, undef, 2, 5] }, method => 'spline', order => 'inf') } qr/\(got inf\)/i,
		'spline order inf reports inf';
}

# --- summary: NaN is NA -------------------------------------------------------
{
	my $s = summary([1, 'NaN', 3, 'Inf'], return_only => 1);
	my @l = split /\n/, $s;
	like($l[1], qr/# values\s+Min\.\s+1st Qu\.\s+Median\s+Mean\s+3rd Qu\.\s+Max\.\s+NA's/, "an NA's column appears");
	like($l[2], qr/^\s*3\s+1\s+2\s+3\s+[Ii]nf\s+[Ii]nf\s+[Ii]nf\s+1\s*$/, 'R: n 3, Min 1, 1st Qu 2, Median 3, Mean Inf, 3rd Qu Inf, Max Inf, NA 1');
	unlike(summary([1, 2, 3], return_only => 1), qr/NA's/, 'no NA column without a NaN');
	like(summary({ x => [1, 2, 3], y => [1, 'nan', 5] }, return_only => 1), qr/^y\s+2\s+1\s+2\s+3\s+3\s+4\s+5\s+1$/m,
		'a HoA: the NaN is dropped from y and counted');
}

# --- csort: a tied cell whose FETCH changes the frame -------------------------
{
	package OnceThen;
	sub TIESCALAR { my ($c, $v, $code) = @_; return bless { v => $v, code => $code }, $c }
	sub FETCH { my $s = shift; if (my $c = delete $s->{code}) { $c->() } return $s->{v} }
	sub STORE { $_[0]{v} = $_[1] }
}
package main;
for my $out (qw(hoa aoh aoa)) {
	my %df = (x => [3, 1, 2], y => [30, 10, 20]);
	my $ycol = $df{y};
	tie $ycol->[0], 'OnceThen', 30, sub { delete $df{y}; @$ycol = (); $#{ $df{x} } = 0 if $df{x} };
	my $r;
	lives_ok { $r = csort(\%df, 'x', $out) } "HoA -> $out: a FETCH that deletes and empties a column does not crash";
	ok(defined $r, "HoA -> $out: a result");
}
{
	my %df = (x => [3, 1, 2], y => [30, 10, 20]);
	is_deeply(csort(\%df, 'x'), { x => [1, 2, 3], y => [10, 20, 30] }, 'plain HoA still sorts');
	my @col = (30, 10, 20);
	my $big = [ map { $_ % 7 } 1 .. 50 ];
	is_deeply(csort({ x => [3, 1, 2], y => \@col }, 'x', 'aoa'), [ [1, 10], [2, 20], [3, 30] ], 'HoA -> AoA');
	my $c = csort({ x => $big, y => [ 1 .. 50 ] }, 'x');
	is(scalar @{ $c->{y} }, 50, 'a longer column');
}

done_testing;
