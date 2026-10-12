use v5.32;
use warnings;
use utf8;

use Test2::V0;

use List::Util qw(all max);
use Term::Fabulous::Chart::Curve qw(curve_points curve_names is_curve check_curve y_at);
use Term::Fabulous::Chart::Easing qw(easing easing_names is_easing_name);

my @FAMILIES = qw(back bounce circ cubic elastic expo quad quart quint sine);

sub ys {
	my ($polyline) = @_;
	return [ map { $_->[1] } @$polyline ];
}

subtest 'easing' => sub {
	is [ easing_names() ], [ sort 'linear', map { ( "ease-in-$_", "ease-out-$_", "ease-in-out-$_" ) } @FAMILIES ], 'linear and three forms of every family, sorted';
	foreach my $name ( easing_names() ) {
		my $ease = easing($name);
		is [ $ease->(0), $ease->(1) ], [ float( 0, tolerance => 1e-9 ), float( 1, tolerance => 1e-9 ) ], "$name runs from 0 to 1";
	}
	is [ easing('ease-in-quad')->(0.5), easing('ease-out-quad')->(0.5), easing('ease-in-out-cubic')->(0.25), easing('linear')->(0.3) ], [ 0.25, 0.75, 0.0625, 0.3 ], 'in, out and in-out';
	ok easing('ease-in-back')->(0.2) < 0, 'back overshoots';
	ok is_easing_name('ease-out-bounce'), 'is_easing_name';
	ok !is_easing_name($_),               'not an easing name: ' . ( $_ // 'undef' ) foreach 'ease-in', undef, [];
	like dies { easing('wobble') }, qr/unknown easing 'wobble' \(known: ease-in-back, /, 'an unknown easing dies';
};

subtest 'names and checks' => sub {
	my @names = curve_names();
	is [ @names[ 0 .. 7 ] ], [qw(catmull-rom linear monotone natural step step-after step-before step-middle)], 'the shapes first';
	is scalar(@names),       8 + 30,                                                                            'then the easings but linear';
	ok is_curve($_),              "is_curve: $_" foreach 'monotone', 'ease-in-out-sine';
	ok is_curve( sub { $_[0] } ), 'is_curve: a code reference';
	ok !is_curve($_),             'not a curve: ' . ( $_ // 'undef' ) foreach 'smooth', undef, [];
	is check_curve( 'Chart', 'curve', 'natural' ), 'natural', 'check_curve returns the curve';
	like dies { check_curve( 'Chart', 'curve', 'smooth' ) }, qr/\AChart: curve must be a curve name \(catmull-rom, linear, .*\) or a code reference, got 'smooth'/, 'an unknown curve dies';
	like dies { check_curve( 'Chart', 'curve', undef ) },    qr/got undef/,                                                                                         'so does undef';
};

subtest 'straight lines and steps' => sub {
	my @points   = ( [ 0, 1 ], [ 2, 3 ], [ 4, 2 ] );
	my $polyline = curve_points( \@points, 'linear' );
	is $polyline, \@points, 'linear: the points';
	ok $polyline->[0] != $points[0], 'as copies';
	is curve_points( [ [ 0, 1 ] ], 'monotone' ), [ [ 0, 1 ] ],                                                             'a single point';
	is curve_points( \@points, 'step' ),         [ [ 0, 1 ], [ 2, 1 ], [ 2, 3 ], [ 4, 3 ], [ 4, 2 ] ],                     'step: the value holds until the next point';
	is curve_points( \@points, 'step-after' ),   curve_points( \@points, 'step' ),                                         'step-after is step';
	is curve_points( \@points, 'step-before' ),  [ [ 0, 1 ], [ 0, 3 ], [ 2, 3 ], [ 2, 2 ], [ 4, 2 ] ],                     'step-before jumps at the start';
	is curve_points( \@points, 'step-middle' ),  [ [ 0, 1 ], [ 1, 1 ], [ 1, 3 ], [ 2, 3 ], [ 3, 3 ], [ 3, 2 ], [ 4, 2 ] ], 'step-middle jumps halfway';
};

subtest 'smooth curves' => sub {
	is curve_points( [ [ 0, 0 ], [ 4, 8 ] ], 'ease-in-quad' ),                   [ [ 0, 0 ], [ 1, 0.5 ], [ 2, 2 ], [ 3, 4.5 ], [ 4, 8 ] ],           'an easing: a vertex every step';
	is curve_points( [ [ 0, 0 ], [ 4, 8 ] ], 'ease-in-quad', step => 2 ),        [ [ 0, 0 ], [ 2, 2 ], [ 4, 8 ] ],                                   'a larger step';
	is curve_points( [ [ 0, 0 ], [ 4, 4 ] ], sub { $_[0] < 0.5 ? 0 : 1 } ),      [ [ 0, 0 ], [ 1, 0 ], [ 2, 4 ], [ 3, 4 ], [ 4, 4 ] ],               'a code reference eases each segment';
	is curve_points( [ [ 0, 0 ], [ 1, 1 ], [ 2, 0 ] ], 'natural', step => 0.5 ), [ [ 0, 0 ], [ 0.5, 0.6875 ], [ 1, 1 ], [ 1.5, 0.6875 ], [ 2, 0 ] ], 'natural: the cubic spline';

	my @peak     = ( [ 0, 0 ], [ 2, 10 ], [ 4, 0 ], [ 6, 10 ], [ 8, 10 ], [ 10, 3 ] );
	my $monotone = curve_points( \@peak, 'monotone', step => 0.25 );
	ok( ( all { $_ >= 0 && $_ <= 10 } ys($monotone)->@* ), 'monotone never overshoots the data' );
	is [ map { y_at( $monotone, $_ ) } 6.5, 7, 7.5 ], [ 10, 10, 10 ], 'and is flat between equal values';
	my $rising  = curve_points( [ [ 0, 0 ], [ 1, 1 ], [ 2, 5 ], [ 3, 5.5 ], [ 4, 10 ] ], 'monotone', step => 0.1 );
	my @heights = ys($rising)->@*;
	ok( ( all { $heights[$_] <= $heights[ $_ + 1 ] } 0 .. $#heights - 1 ), 'rising data gives a rising curve' );

	my $catmull = curve_points( \@peak, 'catmull-rom', step => 0.25 );
	ok max( ys($catmull)->@* ) > 10, 'catmull-rom may overshoot';
	is [ map { y_at( $catmull, $_->[0] ) } @peak ], [ map { $_->[1] } @peak ], 'every curve passes through the points';
	my $tight = curve_points( \@peak, 'catmull-rom', step => 0.25, tension => 1 );
	is [ map { y_at( $tight, $_ ) } 1, 3, 9 ], [ float(5), float(5), float(6.5) ], 'tension 1 gives straight lines';

	like dies { curve_points( \@peak, 'catmull-rom', tension => 2 ) }, qr/tension must be between 0 and 1, got 2/, 'a tension above 1 dies';
	like dies { curve_points( \@peak, 'monotone',    step    => 0 ) }, qr/step must be positive/,                  'step 0 dies';
	like dies { curve_points( \@peak, 'zigzag' ) }, qr/unknown curve 'zigzag'/, 'an unknown curve dies';
};

subtest 'natural: several points at one x' => sub {
	my @tower    = ( [ 0, 1 ], [ 1, 2 ], [ 1, 3 ], [ 1, 4 ], [ 2, 0 ] );
	my $polyline = curve_points( \@tower, 'natural', step => 0.5 );
	is [ grep { $_->[0] == int $_->[0] } @$polyline ], \@tower, 'three points at one x: the curve runs through all of them';
	is curve_points( [ [ 0, 0 ], [ 1, 3 ], [ 3, 1 ], [ 4, 4 ] ], 'natural', step => 0.5 ),
		[ [ 0, 0 ], [ 0.5, 1.875 ], [ 1, 3 ], [ 1.5, 2.875 ], [ 2, 2 ], [ 2.5, 1.125 ], [ 3, 1 ], [ 3.5, 2.125 ], [ 4, 4 ] ], 'points at distinct x give the spline they always gave';
};

subtest 'between: a part of the curve' => sub {
	my @peak = ( [ 0, 0 ], [ 2, 10 ], [ 4, 0 ], [ 6, 10 ], [ 8, 10 ], [ 10, 3 ] );
	foreach my $curve (qw(linear step-middle monotone catmull-rom natural ease-in-out-sine)) {
		my $whole = curve_points( \@peak, $curve, step => 0.25 );
		my $part  = curve_points( \@peak, $curve, step => 0.25, between => [ 2, 4 ] );
		is $part, [ grep { $_->[0] >= 4 && $_->[0] <= 8 } @$whole ], "$curve: the vertices the whole curve has from point 2 to point 4";
	}
	is curve_points( \@peak, 'monotone', between => [ 3, 3 ] ), [ [ 6, 10 ] ], 'one point';
	like dies { curve_points( \@peak, 'linear', between => [  4, 2 ] ) }, qr/between \[ 4, 2 \] must run forward within the points 0 \.\. 5/,            'backwards dies';
	like dies { curve_points( \@peak, 'linear', between => [  0, 6 ] ) }, qr/must run forward within the points/,                                        'past the last point dies';
	like dies { curve_points( \@peak, 'linear', between => [ -1, 2 ] ) }, qr/between must be \[ first, last \], two point indexes, got \[ '-1', '2' \]/, 'a negative index dies';
	like dies { curve_points( \@peak, 'linear', between => 2 ) }, qr/two point indexes, got '2'/, 'so does a plain value';
};

subtest 'y_at' => sub {
	my $polyline = [ [ 0, 0 ], [ 2, 4 ], [ 2, 8 ], [ 4, 8 ] ];
	is [ map { y_at( $polyline, $_ ) } 0, 1, 3, 4 ],                       [ 0, 2, 8, 8 ],          'between the vertices around x';
	is y_at( $polyline, 2 ),                                               8,                       'a vertical run gives the y where it ends';
	is [ y_at( $polyline, -0.1 ), y_at( $polyline, 4.1 ), y_at( [], 0 ) ], [ undef, undef, undef ], 'undef outside';
};

done_testing;
