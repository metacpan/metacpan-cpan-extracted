use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Chart::Series;

my $Series = 'Term::Fabulous::Chart::Series';

sub series {
	my (%options) = @_;
	return $Series->new( owner => 'Chart', name => 'CPU', type => 'line', slot => 0, %options );
}

package Moment {    ## no critic (Modules::RequireFilenameMatchesPackage) a stand-in date object

	sub new {
		my ( $class, $epoch ) = @_;
		return bless { epoch => $epoch }, $class;
	}

	sub epoch {
		my ($self) = @_;
		return $self->{epoch};
	}
}

subtest 'construction' => sub {
	my $series = series( slot => 3, data => [ 1, 2 ] );
	is [ $series->name, $series->type, $series->slot, $series->count ], [ 'CPU', 'line', 3, 2 ], 'name, type, slot and data';
	is [ $series->color, $series->color_opacity, $series->is_visible ], [ undef, 1, 1 ],         'no color of its own, visible';
	is [ $series->option('curve'), $series->option('marker') ],         [ undef, undef ],        'options default to the chart settings';
	is [ series()->points ],                                            [ [] ],                  'no data';

	like dies { series( name  => '' ) },      qr/\AChart: a series name must be a non-empty string, got ''/,                          'an empty name dies';
	like dies { series( name  => [] ) },      qr/a series name must be a non-empty string, got an ARRAY reference/,                   'so does a reference';
	like dies { series( type  => 'pie' ) },   qr/\AChart: type of series 'CPU' must be one of area, bar, line, scatter, got 'pie'/,   'an unknown type dies';
	like dies { series( shape => 'round' ) }, qr/series 'CPU' does not take shape \(known: name, type, data, color, marker, curve, /, 'an unknown option dies';
};

subtest 'color' => sub {
	my $series = series( color => '#3987e580' );
	is [ $series->color, $series->color_opacity ], [ 0x3987e5, 128 / 255 ], 'a color with alpha';
	my $revision = $series->revision;
	ref_is $series->set_color(undef), $series, 'set_color returns the series';
	is [ $series->color, $series->color_opacity, $series->revision ], [ undef, 1, $revision + 1 ], 'undef is the palette color';
	like dies { series( color => 'nonsense' ) }, qr/\AChart: color of series 'CPU' must be a color, got 'nonsense'/, 'an invalid color dies';
};

subtest 'options' => sub {
	my $series   = series();
	my $revision = $series->revision;
	ref_is $series->set_option( curve => 'monotone' ), $series, 'set_option returns the series';
	is [ $series->option('curve'), $series->revision ], [ 'monotone', $revision + 1 ], 'and counts as a change';
	$series->set_option( curve => undef );
	is $series->option('curve'), undef, 'undef returns to the chart setting';

	$series->set_option( marker => 'sextant' )->set_option( line_style => 'dashed' )->set_option( tension => '0.5' )->set_option( fill_opacity => 1 );
	is [ map { $series->option($_) } qw(marker line_style tension fill_opacity) ], [ 'sextant', 'dashed', 0.5, 1 ], 'marker, line style and fractions';
	is [ $series->dash_pattern('dashed'), $series->dash_pattern('dotted'), $series->dash_pattern('solid') ], [ [ 5, 3 ], [ 1, 2 ], undef ], 'dash patterns';
	$series->set_option( point => 'square' )->set_option( stack => 7 )->set_option( from => 3 )->set_option( to => Moment->new(9) );
	is [ map { $series->option($_) } qw(point stack from) ], [ 'square', '7', 3 ], 'point, stack group and range';
	isa_ok $series->option('to'), 'Moment';
	is series( point => 'x' )->option('point'), 'x', 'a point glyph';
	$series->set_option( transform => 'cumulative' );
	is [ map { $_->[0] } $series->option('transform')->@* ], ['cumulative'], 'transforms are parsed';
	$series->set_option( visible => 0 )->set_option( trend => 'yes' );
	is [ $series->option('visible'), $series->option('trend'), $series->is_visible ], [ 0, 1, 0 ], 'switches are 0 or 1';

	is [ $Series->marker_names('bar') ], [qw(block braille half quadrant sextant)], 'the markers of a type';
	is [ $Series->marker_names('pie') ], [],                                        'none for an unknown type';
	is [ $Series->option_names ], [qw(marker curve tension line line_style points point fill_opacity stack from to transform span_gaps visible max_points trend value_labels)], 'the option names';
	ok series( type => 'bar', marker => 'block' ), 'a bar series takes block';

	my @cases = (
		[ 'a marker the type cannot draw with', [ marker       => 'block' ],  qr/\AChart: marker of series 'CPU' must be one of braille, half, quadrant, sextant, box for a line series, got 'block'/ ],
		[ 'an unknown curve',                   [ curve        => 'smooth' ], qr/curve of series 'CPU' must be a curve name/ ],
		[ 'an unknown line style',              [ line_style   => 'wavy' ],   qr/line_style of series 'CPU' must be one of dashed, dotted, solid, got 'wavy'/ ],
		[ 'a tension above 1',                  [ tension      => 1.5 ],      qr/tension of series 'CPU' must be a number from 0 to 1, got '1.5'/ ],
		[ 'a word as fill_opacity',             [ fill_opacity => 'half' ],   qr/fill_opacity of series 'CPU' must be a number from 0 to 1/ ],
		[ 'a wide point glyph',                 [ point        => "\x{65E5}" ], qr/point of series 'CPU' must be a single character one column wide/ ],
		[ 'a reference as stack',               [ stack        => [] ],         qr/stack of series 'CPU' must be a group name, got an ARRAY reference/ ],
		[ 'a reference as from',                [ from         => {} ],         qr/from of series 'CPU' must be an x value, got a HASH reference/ ],
		[ 'an invalid transform',               [ transform    => 'blur' ],     qr/every step of transform of series 'CPU' must be a transform name/ ],
		[ 'max_points 0',                       [ max_points   => 0 ],          qr/max_points of series 'CPU' must be a positive integer, got '0'/ ],
		[ 'a reference as switch',              [ visible      => [] ],         qr/visible of series 'CPU' must be a plain true or false value, got an ARRAY reference/ ],
	);
	foreach my $case (@cases) {
		my ( $name, $option, $error ) = @$case;
		like dies { series()->set_option(@$option) }, $error, "$name dies";
	}
	like dies { series()->option('shape') }, qr/unknown series option 'shape'/, 'reading an unknown option dies';
};

subtest 'data points' => sub {
	my $series = series( data => [ 3, undef, [ 5, 6 ], { x => 7, y => 8 }, { y => '1.5' }, [ 'Jan', undef ] ] );
	is $series->points, [ [ undef, 3 ], [ undef, undef ], [ 5, 6 ], [ 7, 8 ], [ undef, 1.5 ], [ 'Jan', undef ] ], 'a number, a gap, [ x, y ] and { x, y }; x labels';
	isa_ok series( data => [ [ Moment->new(1), 2 ] ] )->points->[0][0], 'Moment';

	my @cases = (
		[ 'not an array',       {},                     qr/\AChart: the data of series 'CPU' must be an array reference, got a HASH reference/ ],
		[ 'three values',       [ 1, [ 1, 2, 3 ] ],     qr/data point 1 of series 'CPU' must be \[ x, y \], got an array of 3 values/ ],
		[ 'unknown keys',       [ { x => 1, z => 2 } ], qr/data point 0 of series 'CPU' takes only the keys x and y, got z/ ],
		[ 'a scalar reference', [ \'5' ],               qr/data point 0 of series 'CPU' must be a number, \[ x, y \] or \{ x, y \}, got a SCALAR reference/ ],
		[ 'a word as y',        ['abc'],                qr/the y value of data point 0 of series 'CPU' must be a finite number or undef, got 'abc'/ ],
		[ 'an infinite y',      [ [ 1, 'inf' ] ],       qr/the y value of data point 0 .* must be a finite number or undef, got 'inf'/ ],
		[ 'a reference as x',   [ [ [1], 2 ] ],         qr/the x value of data point 0 of series 'CPU' must be a number, a label or a date, got an ARRAY reference/ ],
	);
	foreach my $case (@cases) {
		my ( $name, $data, $error ) = @$case;
		like dies { series()->set_data($data) }, $error, "$name dies";
	}

	$series = series( data => [1] );
	my $revision = $series->revision;
	ref_is $series->add_points( 2, [ 9, 3 ] ), $series, 'add_points returns the series';
	is [ $series->points, $series->revision ], [ [ [ undef, 1 ], [ undef, 2 ], [ 9, 3 ] ], $revision + 1 ], 'add_points appends';
	like dies { $series->add_points( 4, 'x' ) }, qr/data point 4 of series 'CPU'/, 'and counts the points on';
	ref_is $series->clear, $series, 'clear returns the series';
	is $series->count, 0, 'clear removes all points';
};

subtest 'check_points' => sub {
	my @seen;
	my $refuse_tens = sub {
		my ( $series, $points ) = @_;
		push @seen, [ map { $_->[1] } @$points ];
		die "no tens\n" if grep { ( $_->[1] // 0 ) >= 10 } @$points;
	};
	my $series = series( data => [ 1, 2 ], check_points => $refuse_tens );
	is \@seen, [ [ 1, 2 ] ], 'the constructor runs the check on the parsed points';
	like dies { $series->add_points( 3, 10 ) }, qr/\Ano tens\n\z/, 'a refused point dies';
	is $series->count, 2, 'and nothing is added';
	like dies { $series->set_data( [10] ) }, qr/\Ano tens\n\z/, 'set_data runs it too';
	is [ map { $_->[1] } $series->points->@* ], [ 1, 2 ], 'and the data is as it was';
	$series->add_points(3);
	is $seen[-1], [3], 'the check gets the new points only';
};

subtest 'parsed_points and push_parsed' => sub {
	my $series = series(
		data         => [1],
		check_points => sub {
			die "no tens\n" if grep { ( $_->[1] // 0 ) >= 10 } $_[1]->@*;
		}
	);
	my $revision = $series->revision;
	my @parsed   = $series->parsed_points( 2, [ 9, 3 ] );
	is [ \@parsed, $series->count, $series->revision ], [ [ [ undef, 2 ], [ 9, 3 ] ], 1, $revision ], 'parsed_points parses new points and stores nothing';
	like dies { $series->parsed_points('x') }, qr/data point 1 of series 'CPU'/, 'it counts on from the stored points';
	like dies { $series->parsed_points(10) },  qr/\Ano tens\n\z/,                'and runs check_points';
	ref_is $series->push_parsed(@parsed), $series, 'push_parsed returns the series';
	is [ $series->points, $series->revision ], [ [ [ undef, 1 ], [ undef, 2 ], [ 9, 3 ] ], $revision + 1 ], 'and stores the points';
};

subtest 'max_points and keep_last' => sub {
	my $series = series( max_points => 3, data => [ 1 .. 5 ] );
	is [ map { $_->[1] } $series->points->@* ], [ 3, 4, 5 ], 'the newest points are kept';
	$series->add_points( 6, 7 );
	is [ map { $_->[1] } $series->points->@* ], [ 5, 6, 7 ], 'also when points are added';
	$series->set_option( max_points => 2 );
	is [ map { $_->[1] } $series->points->@* ], [ 6, 7 ], 'a smaller limit trims at once';

	$series = series( data => [ 1 .. 4 ] );
	my $revision = $series->revision;
	ref_is $series->keep_last(2), $series, 'keep_last returns the series';
	is [ [ map { $_->[1] } $series->points->@* ], $series->revision ], [ [ 3, 4 ], $revision + 1 ], 'keep_last drops all but the newest';
	$series->keep_last(5);
	is [ $series->count, $series->revision ], [ 2, $revision + 1 ], 'fewer points than the limit: no change';
};

subtest 'set_type' => sub {
	my $series = series( type => 'area', marker => 'block' );
	ref_is $series->set_type('line'), $series, 'set_type returns the series';
	is [ $series->type, $series->option('marker') ], [ 'line', undef ], 'a marker the new type cannot draw with is dropped';
	$series = series( type => 'area', marker => 'braille' )->set_type('scatter');
	is $series->option('marker'), 'braille', 'one it can draw with is kept';
	like dies { $series->set_type('pie') }, qr/type of series 'CPU' must be one of area, bar, line, scatter, got 'pie'/, 'an unknown type dies';
};

done_testing;
