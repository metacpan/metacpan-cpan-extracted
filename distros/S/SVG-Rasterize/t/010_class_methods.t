#!perl -T
use strict;
use warnings;

use Test::More tests => 86;

use Test::Exception;
use SVG::Rasterize;

sub angle {
    my $pi = atan2(0, -1);
    my $diff;
    my $angle;
    foreach my $glob ($pi/4, 3*$pi/4, 5*$pi/4, 7*$pi/4) {
	$diff  = $pi / 4;
	$angle = SVG::Rasterize::_angle(cos($glob),
					sin($glob),
					cos($glob + $diff),
					sin($glob + $diff));
	ok($angle > 0, '1. quadrant > 0');
	ok($angle < $pi / 2, '1. quadrant < pi / 2');
	$diff  = 3 * $pi / 4;
	$angle = SVG::Rasterize::_angle(cos($glob),
					sin($glob),
					cos($glob + $diff),
					sin($glob + $diff));
	ok($angle > $pi / 2, '2. quadrant > pi / 2');
	ok($angle < $pi, '2. quadrant < pi');
	$diff  = 5 * $pi / 4;
	$angle = SVG::Rasterize::_angle(cos($glob),
					sin($glob),
					cos($glob + $diff),
					sin($glob + $diff));
	ok($angle > -$pi, '3. quadrant < -pi');
	ok($angle < -$pi / 2, '3. quadrant < -pi / 2');
	$diff  = 7 * $pi / 4;
	$angle = SVG::Rasterize::_angle(cos($glob),
					sin($glob),
					cos($glob + $diff),
					sin($glob + $diff));
	ok($angle > -$pi / 2, '4. quadrant > -pi / 2');
	ok($angle < 0, '4. quadrant < 0');
    }
}

sub adjust_arc_radii {
    my @result;

    @result = SVG::Rasterize::adjust_arc_radii(1, 0, 0, 1, 0, -1, 0);
    is(scalar(@result), 2, 'rx 0');
    is_deeply(\@result, [0, 1], 'radii untouched');
    @result = SVG::Rasterize::adjust_arc_radii(1, 0, 0, -1, 0, -1, 0);
    is(scalar(@result), 2, 'rx 0');
    is_deeply(\@result, [0, 1], 'radii positive');
    @result = SVG::Rasterize::adjust_arc_radii(1, 0, 1, 0, 0, -1, 0);
    is(scalar(@result), 2, 'ry 0');
    is_deeply(\@result, [1, 0], 'radii untouched');
    @result = SVG::Rasterize::adjust_arc_radii(1, 0, -1, 0, 0, -1, 0);
    is(scalar(@result), 2, 'ry 0');
    is_deeply(\@result, [1, 0], 'radii positive');

    @result = SVG::Rasterize::adjust_arc_radii(1, 0, 1, 1, 0, 1, 0);
    is(scalar(@result), 6, 'end = start');
    is($result[0], 1, 'rx');
    is($result[1], 1, 'ry');
    cmp_ok(abs($result[2] - 0), '<', 1e-12, 'sin(phi)');
    cmp_ok(abs($result[3] - 1), '<', 1e-12, 'cos(phi)');
    cmp_ok(abs($result[4] - 0), '<', 1e-12, 'x1_p');
    cmp_ok(abs($result[5] - 0), '<', 1e-12, 'y1_p');

    @result = SVG::Rasterize::adjust_arc_radii(1, 0, 1, 1, 0, -1, 0);
    is(scalar(@result), 7, 'end = start');
    is($result[0], 1, 'rx');
    is($result[1], 1, 'ry');
    cmp_ok(abs($result[2] - 0), '<', 1e-12, 'sin(phi)');
    cmp_ok(abs($result[3] - 1), '<', 1e-12, 'cos(phi)');
    cmp_ok(abs($result[4] - 1), '<', 1e-12, 'x1_p');
    cmp_ok(abs($result[5] - 0), '<', 1e-12, 'y1_p');
    cmp_ok(abs($result[6] - 0), '<', 1e-12, 'radicand');

    @result = SVG::Rasterize::adjust_arc_radii(1, 0, 1, 1, 0, -1.2, 0);
    is(scalar(@result), 7, 'end = start');
    cmp_ok(abs($result[0] - 1.1), '<', 1e-12, 'rx');
    cmp_ok(abs($result[1] - 1.1), '<', 1e-12, 'ry');
    cmp_ok(abs($result[2] - 0), '<', 1e-12, 'sin(phi)');
    cmp_ok(abs($result[3] - 1), '<', 1e-12, 'cos(phi)');
    cmp_ok(abs($result[4] - 1.1), '<', 1e-12, 'x1_p');
    cmp_ok(abs($result[5] - 0), '<', 1e-12, 'y1_p');
    cmp_ok(abs($result[6] - 0), '<', 1e-12, 'radicand');

    @result = SVG::Rasterize::adjust_arc_radii(6, 4, 1, 1, 0, 3.8, 4);
    is(scalar(@result), 7, 'end = start');
    cmp_ok(abs($result[0] - 1.1), '<', 1e-12, 'rx');
    cmp_ok(abs($result[1] - 1.1), '<', 1e-12, 'ry');
    cmp_ok(abs($result[2] - 0), '<', 1e-12, 'sin(phi)');
    cmp_ok(abs($result[3] - 1), '<', 1e-12, 'cos(phi)');
    cmp_ok(abs($result[4] - 1.1), '<', 1e-12, 'x1_p');
    cmp_ok(abs($result[5] - 0), '<', 1e-12, 'y1_p');
    cmp_ok(abs($result[6] - 0), '<', 1e-12, 'radicand');

    @result = SVG::Rasterize::adjust_arc_radii(1, 0, 2, 2, 0, -1, 0);
    is(scalar(@result), 7, 'end = start');
    cmp_ok(abs($result[0] - 2), '<', 1e-12, 'rx');
    cmp_ok(abs($result[1] - 2), '<', 1e-12, 'ry');
    cmp_ok(abs($result[2] - 0), '<', 1e-12, 'sin(phi)');
    cmp_ok(abs($result[3] - 1), '<', 1e-12, 'cos(phi)');
    cmp_ok(abs($result[4] - 1), '<', 1e-12, 'x1_p');
    cmp_ok(abs($result[5] - 0), '<', 1e-12, 'y1_p');
    cmp_ok(abs($result[6] - 3), '<', 1e-12, 'radicand');

    @result = SVG::Rasterize::adjust_arc_radii(5, 4, 2, 2, 0.3, 5, 2);
    is(scalar(@result), 7, 'end = start');
    cmp_ok(abs($result[0] - 2), '<', 1e-12, 'rx');
    cmp_ok(abs($result[1] - 2), '<', 1e-12, 'ry');
    cmp_ok(abs($result[2] - sin(0.3)), '<', 1e-12, 'sin(phi)');
    cmp_ok(abs($result[3] - cos(0.3)), '<', 1e-12, 'cos(phi)');
    cmp_ok(abs($result[4]**2 + $result[5]**2 - 1), '<', 1e-12, 'd_p');
    cmp_ok(abs($result[6] - 3), '<', 1e-12, 'radicand');
}

angle;
adjust_arc_radii;
