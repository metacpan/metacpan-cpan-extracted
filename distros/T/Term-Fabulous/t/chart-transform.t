use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Chart::Transform qw(parse_transforms apply_transforms transform_names);

# The ys after the steps of $spec, for xs 0, 1, 2, ...
sub ys {
	my ( $spec, @ys )     = @_;
	my ( undef, $result ) = apply_transforms( parse_transforms( 'Chart', 'transform', $spec ), [ 0 .. $#ys ], \@ys );
	return $result;
}

sub points {
	my ( $spec, $xs, $ys ) = @_;
	return [ apply_transforms( parse_transforms( 'Chart', 'transform', $spec ), $xs, $ys ) ];
}

subtest 'names and parsing' => sub {
	is [ transform_names() ], [qw(abs clip cumulative difference downsample exponential gaussian index median moving_average normalize offset rate regression resample scale share sort zscore)],
		'all steps, sorted';
	is parse_transforms( 'Chart', 'transform', undef ), [], 'undef is no step';
	is ys( 'cumulative',                     1, 2 ), [ 1, 3 ], 'a single name';
	is ys( [ 'cumulative', [ 'scale', 2 ] ], 1, 2 ), [ 2, 6 ], 'steps run in order';
	is ys( [],                               1, 2 ), [ 1, 2 ], 'no steps keep the values';
};

subtest 'scaling' => sub {
	is ys( 'normalize', 1, undef, 3, 5, 7 ),                    [ 0, undef, float( 1 / 3 ), float( 2 / 3 ), 1 ], 'normalize: 0 to 1, gaps stay gaps';
	is ys( [ [ 'normalize', -1, 1 ] ], 1, 3, 5, 7 ),            [ -1, float( -1 / 3 ), float( 1 / 3 ), 1 ],      'normalize to a range';
	is ys( [ [ 'normalize', 5 ] ], 2, 2 ),                      [ 5, 5 ],                                        'equal values become the low end';
	is ys( 'share', 1, undef, -3, 4 ),                          [ 0.125, undef, -0.375, 0.5 ],                   'share: of the total of the magnitudes';
	is ys( 'share', 0, 0 ),                                     [ 0, 0 ],                                        'share of nothing';
	is ys( 'zscore', 2, 4, 4, 4, 5, 5, 7, 9, undef ),           [ -1.5, -0.5, -0.5, -0.5, 0, 0, 1, 2, undef ],   'zscore';
	is ys( 'zscore', 3, 3 ),                                    [ 0, 0 ],                                        'zscore of equal values';
	is ys( 'index', undef, 0, 50, 100 ),                        [ undef, 0, 100, 200 ],                          'index: relative to the first non-zero value';
	is ys( [ [ 'index', 1 ] ], 4, 2 ),                          [ 1, 0.5 ],                                      'index to another base';
	is ys( 'index', 0, 0 ),                                     [ undef, undef ],                                'index without a non-zero value';
	is ys( [ [ 'scale', 2 ], [ 'offset', -1 ] ], 1, undef, 3 ), [ 1, undef, 5 ],                                 'scale and offset';
	is ys( [ [ 'clip', undef, 3 ] ], 1, 5, undef ),             [ 1, 3, undef ],                                 'clip with one end';
	is ys( [ [ 'clip', 2, 3 ] ], 1, 2.5, 5 ),                   [ 2, 2.5, 3 ],                                   'clip with two';
	is ys( 'abs', -1, undef, 2 ),                               [ 1, undef, 2 ],                                 'abs';
};

subtest 'accumulating' => sub {
	is ys( 'cumulative', 1, undef, 2, 3 ),                                       [ 1, undef, 3, 6 ],            'cumulative';
	is ys( 'difference', 1, undef, 4, 6 ),                                       [ undef, undef, 3, 2 ],        'difference: from the previous value';
	is points( 'rate', [ 0, 10, 20, 30, 30 ], [ 0, 50, undef, 110, 120 ] )->[1], [ undef, 5, undef, 3, undef ], 'rate: per unit of x';
	is points( [ [ 'rate', 60 ] ], [ 0, 10 ], [ 0, 50 ] )->[1],                  [ undef, 300 ],                'rate per 60';
};

subtest 'smoothing' => sub {
	is ys( [ [ 'moving_average', 3 ] ], 1, 2, 3, 4, 5 ),           [ 1, 1.5, 2, 3, 4 ],          'moving_average: trailing';
	is ys( [ [ 'moving_average', 3, 'center' ] ], 1, 2, 3, 4, 5 ), [ 1.5, 2, 3, 4, 4.5 ],        'moving_average: centered';
	is ys( [ [ 'moving_average', 4, 'center' ] ], 1, 2, 3, 4, 5 ), [ 2, 2.5, 3.5, 4, 4.5 ],      'an even centered window reaches further ahead';
	is ys( [ [ 'moving_average', 2 ] ], 1, undef, 3 ),             [ 1, undef, 3 ],              'windows skip gaps';
	is ys( [ [ 'exponential', 0.5 ] ], 2, 4, undef, 8 ),           [ 2, 3, undef, 5.5 ],         'exponential';
	is ys( [ [ 'median', 3 ] ], 1, 9, 2, 3, 100, 4, undef ),       [ 5, 2, 3, 3, 4, 52, undef ], 'median';

	my $sigma   = 1;
	my @weights = map { exp( -( $_**2 ) / 2 ) } -3 .. 3;
	my $total   = 0;
	$total += $_ foreach @weights;
	my $blurred = ys( [ [ 'gaussian', $sigma ] ], 0, 0, 0, 0, 7, 0, 0, 0, 0, undef );
	is $blurred->[4],                               float( 7 / $total ),                                                             'gaussian: a weighted mean';
	is [ @$blurred[ 3, 5, 9 ] ],                    [ float( 7 * $weights[2] / $total ), float( 7 * $weights[4] / $total ), undef ], 'symmetric, gaps stay gaps';
	is ys( [ [ 'gaussian', 2 ] ], 5, 5, undef, 5 ), [ 5, 5, undef, 5 ],                                                              'a constant stays constant';
};

subtest 'reshaping' => sub {
	is points( 'sort', [ 3, 1, 2 ], [ 30, 10, undef ] ), [ [ 1, 2, 3 ], [ 10, undef, 30 ] ], 'sort by x';

	my @xs = ( 0, 5, 12, 31,    35 );
	my @ys = ( 1, 3, 5,  undef, 7 );
	is points( [ [ 'resample', 10 ] ],          \@xs,      \@ys ),              [ [ 0, 10, 30 ], [ 2, 5, 7 ] ], 'resample: the mean at the start of each interval';
	is points( [ [ 'resample', 10, 'count' ] ], [ 0, 31 ], [ 1, undef ] )->[1], [ 1, 0 ],     'count';
	is points( [ [ 'resample', 10 ] ],          [ 0, 31 ], [ 1, undef ] )->[1], [ 1, undef ], 'an interval without values has none';
	is {
		map { $_ => points( [ [ 'resample', 10, $_ ] ], \@xs, \@ys )->[1][0] } qw(sum min max first last)
	}, { sum => 4, min => 1, max => 3, first => 1, last => 3 }, 'the other aggregates';

	is points( [ [ 'downsample', 3 ] ], [ 0 .. 5 ], [ 0, 1, 5, 2, 1, 0 ] ), [ [ 0, 2, 5 ], [ 0, 5, 0 ] ], 'downsample keeps the peaks';
	is points( [ [ 'downsample', 3 ] ], [ 0 .. 3 ], [ 0, undef, 5, 1 ] ), [ [ 0, 2, 3 ], [ 0, 5, 1 ] ], 'and drops gaps';

	is ys( 'regression', 1, 3, undef, 7 ), [ float(1), float(3), float(5), float(7) ], 'regression: the trend line at every x';
	is ys( 'regression', 4, undef ), [ undef, undef ], 'needs two points';
};

subtest 'code references' => sub {
	my @seen;
	my $step = sub { my ( $xs, $ys ) = @_; push @seen, [ [@$xs], [@$ys] ]; push @$xs, 99; return ( [ 1, 2 ], [ 3, 4 ] ) };
	my @xs   = ( 0, 1 );
	is points( [$step], \@xs, [ 5, 6 ] ), [ [ 1, 2 ], [ 3, 4 ] ], 'return the new xs and ys';
	is [ \@seen, \@xs ], [ [ [ [ 0, 1 ], [ 5, 6 ] ] ], [ 0, 1 ] ], 'called with copies';
	like dies {
		points( [ sub { [ 1, 2 ] } ], [0], [0] )
	}, qr/\AChart: a transform code reference must return two array references of the same length \(xs, ys\)/, 'one array dies';
	like dies {
		points( [ sub { ( [1], [ 1, 2 ] ) } ], [0], [0] )
	}, qr/two array references of the same length/, 'so do arrays of different length';
};

subtest 'invalid steps die' => sub {
	my @cases = (
		[ 'an unknown name',    'bogus',                      qr/\AChart: every step of transform must be a transform name \(abs, clip, .*\), \[ name, arguments \] or a code reference, got 'bogus'/ ],
		[ 'too few arguments',  [ ['scale'] ],                qr/the transform step 'scale' takes 1 argument, got 0/ ],
		[ 'too many arguments', [ [ 'normalize', 1, 2, 3 ] ], qr/the transform step 'normalize' takes 0 to 2 arguments, got 3/ ],
		[ 'an empty moving_average window',       [ [ 'moving_average', 0 ] ],         qr/the transform step 'moving_average' needs a window of at least 1 point, got '0'/ ],
		[ 'an unknown alignment',                 [ [ 'moving_average', 3, 'left' ] ], qr/needs an alignment of 'trailing' or 'center', got '3', 'left'/ ],
		[ 'a smoothing factor of 0',              [ [ 'exponential', 0 ] ],            qr/needs a smoothing factor greater than 0 and at most 1/ ],
		[ 'a fractional median window',           [ [ 'median', 1.5 ] ],               qr/needs a window of at least 1 point/ ],
		[ 'a negative sigma',                     [ [ 'gaussian', -1 ] ],              qr/needs a positive standard deviation/ ],
		[ 'a word as factor',                     [ [ 'scale', 'two' ] ],              qr/needs a number to multiply by, got 'two'/ ],
		[ 'an infinite offset',                   [ [ 'offset', 'inf' ] ],             qr/needs a number to add/ ],
		[ 'clip ends in the wrong order',         [ [ 'clip', 3, 1 ] ],                qr/needs a lowest and a highest value/ ],
		[ 'a resample interval of 0',             [ [ 'resample', 0 ] ],               qr/needs a positive interval/ ],
		[ 'an unknown aggregate',                 [ [ 'resample', 10, 'median' ] ],    qr/needs an aggregate of mean, sum, min, max, first, last or count/ ],
		[ 'downsampling to two points',           [ [ 'downsample', 2 ] ],             qr/needs a number of points of at least 3/ ],
		[ 'a reference as argument',              [ [ 'normalize', [0] ] ],            qr/the arguments of the transform step 'normalize' must be plain values, got an ARRAY reference/ ],
		[ 'a step with arguments as a flat list', [ 'moving_average', 3 ], qr/\AChart: transform is a list of steps; write \[ \[ 'moving_average', \.\.\. \] \] for one step with arguments/ ],
		[ 'a hash as step',                       [ { name => 'abs' } ],   qr/got a HASH reference/ ],
	);
	foreach my $case (@cases) {
		my ( $name, $spec, $error ) = @$case;
		like dies { parse_transforms( 'Chart', 'transform', $spec ) }, $error, "$name dies";
	}
};

done_testing;
