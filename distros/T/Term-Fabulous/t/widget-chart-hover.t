use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use ChartTest;
use Scalar::Util qw(refaddr);
use Term::Fabulous::Event::SeriesHover;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::DonutChart;
use Term::Fabulous::Widget::Histogram;
use Term::Fabulous::Widget::LineChart;
use Term::Fabulous::Widget::RadarChart;

my ( $RED, $BLUE ) = map { rgb($_) } '#ff0000', '#0000ff';

# Two series of bars: 'one' (red) in columns 5 to 8, 'two' (blue) in 9
# to 12; their legend entries at columns 0 and 8 of the first row.
sub bars (%args) {
	return sized(
		'Term::Fabulous::Widget::BarChart', 30, 10,
		labels => [qw(A B)],
		series => [ { name => 'one', data => [ 1, 2 ], color => '#ff0000' }, { name => 'two', data => [ 3, 1 ], color => '#0000ff' } ],
		%args,
	);
}

subtest 'the pointer on a bar' => sub {
	my $h     = hover_ui( bars() );
	my $chart = $h->{chart};
	is [ bg_at( $chart, 6, 7 ), bg_at( $chart, 10, 4 ) ], [ $RED, $BLUE ], 'nothing is faded at first';

	pointer_to( $h, 10, 4 );
	is hovers($h),                                                                         [ { series => 'two', index => 0, label => 'A', value => 3, x => 0 } ], 'fires SeriesHover with the point';
	is $chart->hovered, { series => 'two', index => 0, label => 'A', value => 3, x => 0 }, 'hovered tells the same';
	isnt bg_at( $chart, 6, 7 ),                                                            $RED,     'the other series fades';
	is bg_at( $chart, 10, 4 ),                                                             $BLUE,    'the series under the pointer keeps its color';
	is [ is_bold( $chart, 10, 0 ), is_bold( $chart, 2, 0 ) ],                              [ 1, 0 ], 'its legend entry is bold';

	pointer_to( $h, 11, 5 );
	is hovers($h), [], 'moving within the same bar fires nothing';
	pointer_to( $h, 6, 7 );
	is hovers($h), [ { series => 'one', index => 0, label => 'A', value => 1, x => 0 } ], 'another bar';
	pointer_to( $h, 20, 3 );
	is [ hovers($h), $chart->hovered ], [ [ {} ], undef ], 'off the series: an empty event';
	is bg_at( $chart, 6, 7 ),           $RED,              'and nothing faded';

	pointer_to( $h, 10, 4 );
	hovers($h);
	pointer_to( $h, 35, 15, screen => 1 );
	is [ hovers($h), $chart->hovered ], [ [ {} ], undef ], 'leaving the chart ends the hover';
};

subtest 'the pointer on a legend entry' => sub {
	my $h = hover_ui( bars() );
	pointer_to( $h, 1, 0 );
	is hovers($h),                    [ { series => 'one', label => 'one' } ], 'names the series, no point';
	isnt bg_at( $h->{chart}, 10, 4 ), $BLUE,                                   'and emphasizes it';
};

subtest 'thin lines can be hit from the next cell' => sub {
	my $h = hover_ui( sized( 'Term::Fabulous::Widget::LineChart', 30, 10, series => [ { name => 'one', data => [ 1, 5, 2 ] }, { name => 'two', data => [ 3, 1, 4 ] } ] ) );
	pointer_to( $h, 3, 8 );
	is hovers($h), [ { series => 'one', index => 0, label => '0', value => 1, x => 0 } ], 'the cell below the line';
};

subtest 'highlight' => sub {
	my $h       = hover_ui( bars( highlight => 'two' ) );
	my $chart   = $h->{chart};
	my $colored = sub ($color) {
		scalar cells_with( $chart, sub ( $c, $x, $y ) { ( bg_at( $c, $x, $y ) // -1 ) == $color } );
	};
	is [ $colored->($RED), $colored->($BLUE) > 0 ], [ 0, 1 ], 'emphasizes a series without the pointer';
	pointer_to( $h, 1, 0 );
	is [ $colored->($RED) > 0, $colored->($BLUE) ], [ 1, 0 ], 'the pointer wins';
	pointer_to( $h, 20, 3 );
	$chart->highlight(undef);
	$h->{ui}->step;
	is [ $colored->($RED) > 0, $colored->($BLUE) > 0 ], [ 1, 1 ], 'undef ends it';

	$chart->highlight('one');
	$h->{ui}->step;
	is [ bg_at( $chart, 6, 7 ), defined bg_at( $chart, 10, 4 ) ? 1 : 0 ], [ $RED, 1 ], 'grouped bars stay in their places while one series is emphasized';
};

subtest 'hover and hover_fade' => sub {
	my $h     = hover_ui( bars( hover => 0 ) );
	my $chart = $h->{chart};
	pointer_to( $h, 10, 4 );
	is [ hovers($h), $chart->hovered, bg_at( $chart, 6, 7 ) ], [ [], undef, $RED ], 'hover 0: no events, no fading';

	$h     = hover_ui( bars( hover_fade => 0 ) );
	$chart = $h->{chart};
	pointer_to( $h, 10, 4 );
	is [ scalar hovers($h)->@*, bg_at( $chart, 6, 7 ) ], [ 1, $RED ], 'hover_fade 0: events, no fading';
	$chart->hover_fade(1);
	$h->{ui}->step;
	my ( $x0, $y0 ) = $chart->content_origin;
	is [ bg_at( $chart, 6, 7 ), $h->{terminal}->cell( $x0 + 6, $y0 + 7 )->[2] ], [ undef, rgb('#161622') ], 'hover_fade 1: the others fade into the background, here the screen';

	$chart->hover(0);
	is [ hovers($h), $chart->hovered ], [ [ {} ], undef ], 'turning hover off ends the hover';
};

subtest 'the hovered series goes away' => sub {
	my %gone = (
		remove_series => sub ($chart) { $chart->remove_series('one') },
		hide_series   => sub ($chart) { $chart->hide_series('one') },
		set_series    => sub ($chart) { $chart->set_series( one => ( visible => 0 ) ) },
		clear_series  => sub ($chart) { $chart->clear_series },
	);
	foreach my $method ( sort keys %gone ) {
		my $h     = hover_ui( bars() );
		my $chart = $h->{chart};
		pointer_to( $h, 1, 0 );
		hovers($h);
		$gone{$method}->($chart);
		$h->{ui}->step;
		is [ hovers($h), $chart->hovered ], [ [ {} ], undef ], "$method ends the hover";
		next if $method eq 'clear_series';
		ok scalar( cells_with( $chart, sub ( $c, $x, $y ) { ( bg_at( $c, $x, $y ) // -1 ) == $BLUE } ) ), 'and the series left is not faded';
	}

	my $h = hover_ui( bars() );
	pointer_to( $h, 1, 0 );
	hovers($h);
	$h->{chart}->hide_series('two');
	is [ hovers($h), $h->{chart}->hovered->{series} ], [ [], 'one' ], 'hiding another series keeps the hover';

	my %slices_gone = (
		remove_slice => sub ($chart) { $chart->remove_slice('B') },
		set_data     => sub ($chart) { $chart->set_data( [ [ A => 1 ], [ C => 2 ] ] ) },
		clear_slices => sub ($chart) { $chart->clear_slices },
	);
	foreach my $method ( sort keys %slices_gone ) {
		my $donut = hover_ui( sized( 'Term::Fabulous::Widget::DonutChart', 40, 14, data => [ [ A => 50 ], [ B => 30 ], [ C => 20 ] ] ) );
		pointer_to( $donut, 33, 6 );
		hovers($donut);
		$slices_gone{$method}->( $donut->{chart} );
		is [ hovers($donut), $donut->{chart}->hovered ], [ [ {} ], undef ], "$method ends the hover on a slice";
	}
};

subtest 'slices' => sub {
	my $h     = hover_ui( sized( 'Term::Fabulous::Widget::DonutChart', 40, 14, data => [ [ A => 50 ], [ B => 30 ], [ C => 20 ] ] ) );
	my $chart = $h->{chart};
	like glyph_row( $chart, 6 ), qr/ 100 /, 'a donut shows the total';
	pointer_to( $h, 25, 6 );
	is hovers($h),                                         [ { series => 'A', index => 0, label => 'A', value => 50 } ], 'a slice: its label and value';
	is [ glyph_row( $chart, 6 ), glyph_row( $chart, 7 ) ], [ match qr/ 50% /, match qr/ A / ],                           'and its share in the hole';
	pointer_to( $h, 33, 6 );
	is hovers($h), [ { series => 'B', label => 'B', value => 30 } ], 'a legend entry';
};

subtest 'radar charts' => sub {
	my $h = hover_ui(
		sized(
			'Term::Fabulous::Widget::RadarChart', 40, 14,
			labels => [qw(Speed Power Range Cost)],
			series => [ { name => 'X', data => [ 4, 3, 5, 2 ] }, { name => 'Y', type => 'line', data => [ 2, 5, 1, 4 ] } ],
		)
	);
	pointer_to( $h, 29, 7 );
	is hovers($h), [ { series => 'Y', index => 1, label => 'Power', value => 5 } ], 'the axis and value of a point';
	pointer_to( $h, 20, 9 );
	is hovers($h), [ { series => 'X', index => 2, label => 'Range', value => 5 } ], 'inside an area: the nearest axis';
};

subtest 'what x and label say' => sub {
	my $h = hover_ui( sized( 'Term::Fabulous::Widget::LineChart', 30, 8, series => [ { name => 't', data => [ [ '2026-06-10', 1 ], [ '2026-06-12', 3 ] ] } ] ) );
	pointer_to( $h, 3, 5 );
	my ($event) = hovers($h)->@*;
	is $event, { series => 't', index => 0, label => '2026-06-10 00:00', value => 1, x => match qr/\A[0-9]+\z/ }, 'a time axis: epoch seconds, written as a date';

	$h = hover_ui( sized( 'Term::Fabulous::Widget::Histogram', 40, 10, bins => 4, series => [ { name => 'h', data => [ 1, 2, 2, 3, 3, 3, 4, 4, 4, 4 ] } ] ) );
	pointer_to( $h, 5, 7 );
	is hovers($h), [ { series => 'h', index => 0, label => "1\x{2013}1.75", value => 1, x => 1.375 } ], 'a histogram bin: its range and count';
};

subtest 'the event' => sub {
	my $h = hover_ui( bars() );
	my @seen;
	$h->{root}->on( SeriesHover => sub ($event) { push @seen, refaddr $event->target; return } );
	pointer_to( $h, 10, 4 );
	is \@seen, [ refaddr $h->{chart} ], 'bubbles up, with the chart as its target';
	is( Term::Fabulous::Event::SeriesHover->event_name, 'SeriesHover', 'its name' );
	like dies { Term::Fabulous::Event::SeriesHover->new( slice => 'A' ) }, qr/slice/, 'unknown parameters die';
};

done_testing;
