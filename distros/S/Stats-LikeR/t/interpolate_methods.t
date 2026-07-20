#!/usr/bin/env perl
# interpolate(): full pandas DataFrame.interpolate method parity.
#
# The reference values in @cases were generated directly from pandas 2.2.3 /
# scipy 1.15.2 (see the git history for the generator).  Each case interpolates
# a single HoA column { v => [...] } and is compared to pandas within a small
# tolerance.  'spline' is our interpolating spline (pandas' 'spline' with s=0),
# since pandas' default 'spline' is a non-reproducible FITPACK smoothing spline.

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub close_enough {
	my ($got, $exp, $label) = @_;
	if (@$got != @$exp) { return fail("$label: length ".scalar(@$got)." != ".scalar(@$exp)); }
	for my $i (0 .. $#$exp) {
		my ($a, $b) = ($got->[$i], $exp->[$i]);
		if (!defined $a && !defined $b) { next }
		if (!defined $a || !defined $b) {
			return fail("$label: NA mismatch at $i (got ".(defined $a?$a:'NA').", exp ".(defined $b?$b:'NA').")");
		}
		if (abs($a - $b) > 1e-6 * (1 + abs $b)) {
			return fail("$label: at $i got $a exp $b");
		}
	}
	return pass($label);
}

my @cases = (
	{ label => "linear|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'linear' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, 16.0 ] },
	{ label => "linear|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'linear', limit_direction => 'both' ], exp => [ 1.0, 1.0, 4.0, 9.0, 16.0, 16.0 ] },
	{ label => "nearest|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'nearest' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "nearest|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'nearest', limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "zero|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'zero' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "zero|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'zero', limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "slinear|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'slinear' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "slinear|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'slinear', limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "quadratic|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'quadratic' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "quadratic|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'quadratic', limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "cubic|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'cubic' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "cubic|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'cubic', limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "pchip|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'pchip' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, 24.666666666666668 ] },
	{ label => "pchip|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'pchip', limit_direction => 'both' ], exp => [ 0.5, 1.0, 4.0, 9.0, 16.0, 24.666666666666668 ] },
	{ label => "akima|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'akima' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "akima|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'akima', limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "cubicspline|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'cubicspline' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, 25.000000000000018 ] },
	{ label => "cubicspline|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'cubicspline', limit_direction => 'both' ], exp => [ 0.0, 1.0, 4.0, 9.0, 16.0, 25.000000000000018 ] },
	{ label => "barycentric|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'barycentric' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, 25.0 ] },
	{ label => "barycentric|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'barycentric', limit_direction => 'both' ], exp => [ 0.0, 1.0, 4.0, 9.0, 16.0, 25.0 ] },
	{ label => "krogh|S2|fwd", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'krogh' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, 25.0 ] },
	{ label => "krogh|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'krogh', limit_direction => 'both' ], exp => [ 0.0, 1.0, 4.0, 9.0, 16.0, 25.0 ] },
	{ label => "poly1|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'polynomial', order => 1, limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "spline1|Yint|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'spline', order => 1, limit_direction => 'both' ], exp => [ 2.0, 2.5, 3.0, 2.6666666666666665, 2.333333333333333, 2.0, 5.0, 2.5, 0.0 ] },
	{ label => "poly2|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'polynomial', order => 2, limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "spline2|Yint|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'spline', order => 2, limit_direction => 'both' ], exp => [ 2.0, 2.942982456140351, 3.0, 2.1710526315789473, 0.9166666666666654, 2.0, 5.0, 4.627192982456141, 0.0 ] },
	{ label => "poly3|S2|both", series => [ undef, 1.0, 4.0, 9.0, 16.0, undef ], kw => [ method => 'polynomial', order => 3, limit_direction => 'both' ], exp => [ undef, 1.0, 4.0, 9.0, 16.0, undef ] },
	{ label => "spline3|Yint|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'spline', order => 3, limit_direction => 'both' ], exp => [ 2.0, 3.5079365079365097, 3.0, 1.7380952380952395, 0.9841269841269846, 2.0, 5.0, 6.007936507936508, 0.0 ] },
	{ label => "linear|S3|limit1fwd", series => [ 1.0, undef, undef, undef, 5.0 ], kw => [ method => 'linear', limit => 1 ], exp => [ 1.0, 2.0, undef, undef, 5.0 ] },
	{ label => "linear|S3|limit1bwd", series => [ 1.0, undef, undef, undef, 5.0 ], kw => [ method => 'linear', limit => 1, limit_direction => 'backward' ], exp => [ 1.0, undef, undef, 4.0, 5.0 ] },
	{ label => "cubic|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'cubic', limit_direction => 'both' ], exp => [ 2.0, 3.5079365079365084, 3.0, 1.7380952380952381, 0.9841269841269837, 2.0, 5.0, 6.007936507936508, 0.0 ] },
	{ label => "pchip|Yg|fwd", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'pchip' ], exp => [ 2.0, 2.7083333333333335, 3.0, 2.7407407407407405, 2.2592592592592595, 2.0, 5.0, 4.041666666666667, 0.0 ] },
	{ label => "akima|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'akima', limit_direction => 'both' ], exp => [ 2.0, 2.6458333333333335, 3.0, 2.865497076023392, 2.2865497076023393, 2.0, 5.0, 4.043632075471698, 0.0 ] },
	{ label => "cubicspline|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'cubicspline', limit_direction => 'both' ], exp => [ 2.0, 3.507936507936508, 3.0, 1.7380952380952377, 0.984126984126984, 2.0, 5.0, 6.007936507936508, 0.0 ] },
	{ label => "barycentric|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'barycentric', limit_direction => 'both' ], exp => [ 2.0, 4.861111111111111, 3.0, 0.6249999999999999, 0.11111111111111116, 2.0, 5.0, 5.986111111111111, 0.0 ] },
	{ label => "krogh|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'krogh', limit_direction => 'both' ], exp => [ 2.0, 4.861111111111111, 3.0, 0.6250000000000002, 0.1111111111111116, 2.0, 5.0, 5.986111111111111, 0.0 ] },
	{ label => "quadratic|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'quadratic', limit_direction => 'both' ], exp => [ 2.0, 2.942982456140351, 3.0, 2.171052631578948, 0.9166666666666666, 2.0, 5.0, 4.62719298245614, 0.0 ] },
	{ label => "nearest|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'nearest', limit_direction => 'both' ], exp => [ 2.0, 2.0, 3.0, 3.0, 2.0, 2.0, 5.0, 5.0, 0.0 ] },
	{ label => "zero|Yg|both", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'zero', limit_direction => 'both' ], exp => [ 2.0, 2.0, 3.0, 3.0, 3.0, 2.0, 5.0, 5.0, 0.0 ] },
	{ label => "linear|Yg|inside", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'linear', limit_area => 'inside', limit_direction => 'both' ], exp => [ 2.0, 2.5, 3.0, 2.6666666666666665, 2.3333333333333335, 2.0, 5.0, 2.5, 0.0 ] },
	{ label => "linear|Yg|outside", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'linear', limit_area => 'outside', limit_direction => 'both' ], exp => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ] },
	{ label => "pchip|Yg|both|limit2", series => [ 2.0, undef, 3.0, undef, undef, 2.0, 5.0, undef, 0.0 ], kw => [ method => 'pchip', limit_direction => 'both', limit => 2 ], exp => [ 2.0, 2.7083333333333335, 3.0, 2.7407407407407405, 2.2592592592592595, 2.0, 5.0, 4.041666666666667, 0.0 ] },
	{ label => "index|Yx|x", series => [ 0.0, undef, undef, undef, 10.0 ], kw => [ method => 'index' ], exp => [ 0.0, 2.5, 5.0, 7.5, 10.0 ] },
);

for my $c (@cases) {
	my $got = interpolate({ v => [ @{ $c->{series} } ] }, @{ $c->{kw} });
	close_enough($got->{v}, $c->{exp}, $c->{label});
}

#========
# the `x` argument: custom abscissae change the spacing of a linear fit
#========
close_enough(
	interpolate({ v => [ 0, undef, undef, 10 ] }, method => 'index', x => [ 0, 1, 3, 4 ])->{v},
	[ 0, 2.5, 7.5, 10 ], 'x arrayref: linear on unequal spacing');

# x supplied as a column: interpolate v against t
{
	my $df = { t => [ 0, 1, 3, 4 ], v => [ 0, undef, undef, 10 ] };
	my $r  = interpolate($df, cols => [ 'v' ], x => 't', method => 'index');
	close_enough($r->{v}, [ 0, 2.5, 7.5, 10 ], 'x as column key');
	is_deeply($df->{v}, [ 0, undef, undef, 10 ], 'x-as-column: input not mutated');
}

#========
# method aliases route to ffill / bfill semantics
#========
is_deeply(
	interpolate({ v => [ 1, undef, undef, 4, undef ] }, method => 'ffill')->{v},
	[ 1, 1, 1, 4, 4 ], "method 'ffill' holds the last value forward");
is_deeply(
	interpolate({ v => [ undef, 1, undef, 4 ] }, method => 'bfill')->{v},
	[ 1, 1, 4, 4 ], "method 'bfill' holds the next value backward");

#========
# every shape reaches the same result for one method
#========
close_enough(
	[ map { $_->{v} } @{ interpolate([ { v => 1 }, { v => undef }, { v => 3 } ], method => 'cubicspline') } ],
	[ 1, 2, 3 ], 'AoH cubicspline');
close_enough(
	interpolate([ [ 1 ], [ undef ], [ 3 ] ], cols => [ 0 ], method => 'pchip')->[1],
	[ 2 ], 'AoA pchip col 0');

#========
# original frame never mutated (fit method)
#========
{
	my $df = { v => [ 1, undef, undef, 4, 9, 16 ] };
	interpolate($df, method => 'cubic');
	is_deeply($df, { v => [ 1, undef, undef, 4, 9, 16 ] }, 'cubic: input not mutated');
}

#========
# error paths for the new arguments
#========
use Test::Exception;
throws_ok { interpolate({ v => [ 1, 2 ] }, method => 'spline') }
	qr/requires an integer 'order'/, 'spline without order dies';
throws_ok { interpolate({ v => [ 1, 2 ] }, method => 'polynomial', order => 4) }
	qr/order 1, 2, or 3/, 'polynomial order 4 dies';
throws_ok { interpolate({ v => [ 1, undef, 3, undef ] }, method => 'cubic') }
	qr/at least 4 numeric anchors/, 'cubic with too few anchors dies';
throws_ok { interpolate({ v => [ 1, undef ] }, method => 'index', x => [ 3, 1 ]) }
	qr/strictly increasing/, 'non-increasing x dies';
throws_ok { interpolate({ v => [ 1, undef, 3 ] }, method => 'index', x => [ 0, 1 ]) }
	qr/length/, 'x length mismatch dies';

#========
# cubicspline with exactly 3 anchors -> the unique parabola (interp1d 'cubic'
# would need 4; cubicspline handles 3).  Matches pandas.
#========
close_enough(
	interpolate({ v => [ 0, undef, 4, undef, 16 ] },
		method => 'cubicspline', limit_direction => 'both')->{v},
	[ 0, 1, 4, 9, 16 ], 'cubicspline: 3 anchors -> exact parabola');

#========
# direct XS-kernel guards (the Perl wrapper prevents these, so exercise them
# straight against _interp_column_xs to confirm the C-side checks hold)
#========
throws_ok { Stats::LikeR::_interp_column_xs(42, [ 0, 1 ], 'linear', undef, 'forward', undef, undef) }
	qr/values must be an array reference/, 'XS: non-arrayref values dies';
throws_ok { Stats::LikeR::_interp_column_xs([ 1, undef ], 42, 'linear', undef, 'forward', undef, undef) }
	qr/x must be an array reference/, 'XS: non-arrayref x dies';
throws_ok { Stats::LikeR::_interp_column_xs([ 1, undef, 3, undef, 5 ], [ 0, 1, 2, 1, 0 ], 'cubic', undef, 'both', undef, undef) }
	qr/strictly increasing/, 'XS: non-increasing x in the fit path dies';

#========
# memory: the fit-method path builds closures / matrices -- make sure it is clean
#========
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok {
	my $x = interpolate({ v => [ 1, undef, undef, 4, 9, 16, undef ] },
		method => 'cubic', limit_direction => 'both');
} 'no leaks (cubic fit path)';
no_leaks_ok {
	my $x = interpolate({ v => [ 2, undef, 3, undef, undef, 2, 5, undef, 0 ] },
		method => 'pchip', limit => 2, limit_direction => 'both');
} 'no leaks (pchip + limit)';
no_leaks_ok {
	my $x = interpolate({ v => [ 1, undef, 4, 9 ] }, method => 'barycentric');
} 'no leaks (barycentric)';

done_testing;
