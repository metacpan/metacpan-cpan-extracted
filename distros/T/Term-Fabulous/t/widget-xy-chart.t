use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Time::HiRes ();

use FindBin;
use lib "$FindBin::Bin/lib";

use ChartTest;
use Clay::UI::Revision qw(current_revision);
use Clay::XS qw(sizing_fixed);
use Term::Fabulous::Static;
use Term::Fabulous::Widget::AreaChart;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::LineChart;
use Term::Fabulous::Widget::ScatterPlot;

my ( $RED, $GREEN, $BLUE ) = map { rgb($_) } '#ff0000', '#00ff00', '#0000ff';
my $EIGHTH_BLOCKS = qr/[\x{2581}-\x{2588}]/;

sub line_chart (%args) { return sized( 'Term::Fabulous::Widget::LineChart', 30, 10, %args ) }
sub bar_chart  (%args) { return sized( 'Term::Fabulous::Widget::BarChart',  30, 10, %args ) }

# The rows whose text matches.
sub rows_like ( $lines, $pattern ) {
	return [ grep { ( $lines->[$_] // '' ) =~ $pattern } 0 .. $#$lines ];
}

subtest 'each chart draws its own series type' => sub {
	my %type_of = ( LineChart => 'line', AreaChart => 'area', BarChart => 'bar', ScatterPlot => 'scatter' );
	foreach my $class ( sort keys %type_of ) {
		my $chart = "Term::Fabulous::Widget::$class"->new( series => [ { data => [1] }, { data => [2] } ] );
		is [ $chart->series_names ],           [ 'Series 1', 'Series 2' ], "$class names unnamed series";
		is $chart->series('Series 1')->{type}, $type_of{$class},           "$class makes $type_of{$class} series";
	}
	my $mixed = Term::Fabulous::Widget::BarChart->new( series => [ { name => 'trend', type => 'line', data => [1] } ] );
	is $mixed->series('trend')->{type}, 'line', 'a series may have a type of its own';
};

subtest 'title, legend and axis titles' => sub {
	my @series = ( { name => 'one', data => [ 1, 2, 3 ] }, { name => 'two', data => [ 3, 1, 2 ] } );
	my $legend = "\x{2501}\x{2501} one   \x{2501}\x{2501} two";
	my @lines  = draw( line_chart( series => [@series] ) );
	is [ @lines[ 0, 1 ] ], [ $legend, '' ], 'two series: a legend at the top';
	like( ( draw( line_chart( series => [ $series[0] ] ) ) )[0], qr/\A3 /, 'one series: none' );

	@lines = draw( line_chart( legend => 'bottom', series => [@series] ) );
	is [ @lines[ -2, -1 ] ], [ '', $legend ], 'at the bottom';
	@lines = draw(
		sized(
			'Term::Fabulous::Widget::BarChart', 30, 14, legend => 'bottom', labels => [qw(A B)], y_axis => { max => 3 },
			series => [ { name => 'one', data => [ 1, 2 ] }, { name => 'two', data => [ 3, 1 ] } ]
		)
	);
	is [ @lines[ 10 .. 13 ] ], [ match qr/\A +A +B\z/, '', "\x{25A0} one   \x{25A0} two", '' ], 'right below the plot when the ticks leave rows free';
	@lines = draw(
		sized(
			'Term::Fabulous::Widget::BarChart', 30, 16, legend => 'bottom', labels => [qw(A B)], x_axis => { title => 'quarter' }, y_axis => { max => 3, title => 'units' },
			series => [ { name => 'one', data => [ 1, 2 ] }, { name => 'two', data => [ 3, 1 ] } ]
		)
	);
	is [ $lines[0], @lines[ 11 .. 14 ] ], [ 'units', match qr/\A +A +B\z/, match qr/\A +quarter\z/, '', "\x{25A0} one   \x{25A0} two" ], 'below the x axis title when both axes have one';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 30, 6, series => [ map { { name => "Series number $_", data => [ 1, 2 ] } } 1 .. 6 ] ) );
	is [ @lines[ 0, 1 ] ], [ "\x{2501}\x{2501} Series number 1", "\x{2501}\x{2501} Series number 2   +4 more" ], 'entries that do not fit are counted';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 20, 8, series => [ map { { name => "Series number $_", data => [ 1, 2 ] } } 1 .. 3 ] ) );
	like $lines[1], qr/\A\x{2501}\x{2501} Series\S*   \+1 more\z/, 'a lone entry is cut short before the count';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 14, 8, series => [ map { { name => "Series number $_", data => [ 1, 2 ] } } 1 .. 3 ] ) );
	unlike join( '', @lines ), qr/\x{2501}|more/, 'a chart too narrow for a letter of the entry beside the count has no legend';
	like $lines[0],            qr/\A2 /,          'and the plot takes its rows';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 40, 2, legend => 'left', series => [ map { { name => "s$_", data => [ 1, 2 ] } } 1 .. 4 ] ) );
	like $lines[1], qr/\A\+3 more /, 'a legend beside the plot has room for the count';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 30, 1, legend => 'bottom', series => [@series] ) );
	is $lines[0], $legend, 'a bottom legend is drawn also when no plot fits';
	@lines = draw(
		sized(
			'Term::Fabulous::Widget::BarChart', 30, 4, horizontal => 1, legend => 'bottom', labels => [qw(A B)], x_axis => { title => 'x' }, y_axis => { title => 'y' },
			series => [ { name => 's', data => [ 1, 2 ] }, { name => 't', data => [ 3, 1 ] } ]
		)
	);
	is $lines[3], "\x{25A0} s   \x{25A0} t", 'a horizontal chart in little room drops its axis titles and keeps the legend row to itself';
	@lines = draw( line_chart( legend => 'left', series => [@series] ) );
	is [ @lines[ 4, 5 ] ], [ match qr/\A\x{2501}\x{2501} one  2 \x{2500}/, match qr/\A\x{2501}\x{2501} two  / ], 'on the left, beside the plot';
	@lines = draw( line_chart( legend => 'right', series => [@series] ) );
	is [ @lines[ 4, 5 ] ], [ match qr/\S   \x{2501}\x{2501} one\z/, match qr/\x{2501}\x{2501} two\z/ ], 'on the right';
	unlike join( '', draw( line_chart( legend => 'none', series => [@series] ) ) ), qr/\x{2501}/, 'or none';

	my $chart = sized( 'Term::Fabulous::Widget::LineChart', 30, 12, title => 'T', x_axis => { title => 'time' }, y_axis => { title => 'load' }, series => [ $series[0] ] );
	@lines = draw($chart);
	is [ @lines[ 0 .. 3 ] ], [ 'T', '', 'load', match qr/\A3 \x{2500}/ ], 'the title, a free row, the y axis title above the highest value';
	like $lines[-1], qr/\A {13}time\z/, 'the x axis title centered below the x values';
	$chart->title_align('center');
	is( ( draw($chart) )[0], ( ' ' x 14 ) . 'T', 'a centered title' );
	$chart->title_align('right');
	is( ( draw($chart) )[0], ( ' ' x 29 ) . 'T', 'a title on the right' );
};

subtest 'size and colors' => sub {
	my $chart = Term::Fabulous::Widget::LineChart->new( title => 'T', series => [ { data => [ 1, 2 ] } ] );
	my $root  = Term::Fabulous::Widget::Box->new( background_color => [ 250, 250, 250, 255 ], layout => { sizing => { width => sizing_fixed(30), height => sizing_fixed(8) } } );
	$root->add_child($chart);
	my $page = Term::Fabulous::Static->new( root => $root, width => 30 );
	$page->render_lines;
	is [ $chart->columns, $chart->rows ], [ 30, 8 ], 'a chart without a size takes the room it gets';
	is $chart->effective_background,      0xFAFAFA,  'and is drawn on the background of its parent';

	my $revision = current_revision();
	$chart->theme('dark');
	ok current_revision() > $revision, 'a change marks the chart changed';
	$page->render_lines;
	my $dark = fg_at( $chart, 0, 0 );
	$chart->theme('auto');
	$page->render_lines;
	isnt fg_at( $chart, 0, 0 ), $dark, 'the auto theme picks the light ink on a light background';
	$chart->title_color('#ff0000');
	$page->render_lines;
	is fg_at( $chart, 0, 0 ), $RED, 'a color of its own wins';
};

subtest 'tick labels sit on the rows of their grid lines' => sub {
	my $chart = sized( 'Term::Fabulous::Widget::BarChart', 20, 10, labels => [qw(A B C D)], y_axis => { max => 8 }, series => [ { name => 's', data => [ 8, 7.5, 6.25, 3.125 ] } ] );
	my @lines = draw($chart);
	is rows_like( \@lines, qr/\A\d\.\d / ), [ 1, 3, 6, 8 ], 'the value labels';
	is rows_like( \@lines, qr/\x{2500}/ ),  [ 1, 3, 6, 8 ], 'are on the rows of the grid lines';
	like $lines[8], qr/\A0\.0 \x{2500}/,          'the baseline is the grid line of 0';
	like $lines[9], qr/\A {6}A {3}B {3}C {3}D\z/, 'the categories below their bars';
};

subtest 'bars grow from the baseline with eighth-block tops' => sub {
	my $chart = sized(
		'Term::Fabulous::Widget::BarChart', 20, 10, labels => [qw(A B C D)], bar_width => 0.5, y_axis => { max => 8 },
		series => [ { name => 's', data => [ 8, 7.5, 6.25, 3.125 ], color => '#ff0000' } ]
	);
	draw($chart);
	is [ map { bar_eighths( $chart, $_, $RED ) } 5, 9, 13, 17 ],                        [ 64, 60, 50, 25 ],                     'eight units on eight cells: each unit is an eighth of a cell';
	is [ map { glyph_at( $chart, $_->[0], $_->[1] ) } [ 5, 0 ], [ 13, 2 ], [ 17, 5 ] ], [ "\x{2584}", "\x{2586}", "\x{2585}" ], 'the tops are eighth blocks';
	is glyph_at( $chart, 5, 8 ),                                                        "\x{2580}",                             'a bar starts at the middle of the baseline row';
	is glyph_at( $chart, 7, 4 ),                                                        undef,                                  'the gap between the bars is empty';

	$chart->set_data( s => [ 8, 7.5, 6.25, 6.25 ] );
	draw($chart);
	is bar_eighths( $chart, 17, $RED ), 50, 'set_data changes what is drawn';
};

subtest 'grouped, stacked and stack groups' => sub {
	my @series = ( { name => 'a', data => [ 1, 2 ], color => '#ff0000' }, { name => 'b', data => [ 3, 1 ], color => '#00ff00' } );
	my $chart  = bar_chart( labels => [qw(A B)], series => [@series] );
	draw($chart);
	is [ bar_eighths( $chart, 5, $RED ), bar_eighths( $chart, 9, $GREEN ) ], [ 16, 48 ], 'grouped bars stand side by side';

	$chart->stacked(1);
	draw($chart);
	is [ map { bg_at( $chart, 6, $_ ) } 3 .. 7 ], [ ($GREEN) x 4, $RED ], 'stacked bars: the first series at the bottom, the next on top of it';
	is [ bar_eighths( $chart, 6, $RED ), bar_eighths( $chart, 6, $GREEN ) ], [ 12, 36 ], 'each as high as its value';

	my $groups = bar_chart(
		labels => [qw(A B)],
		series => [
			map {
				{ %$_, stack => 'g1' }
			} @series
		],
	);
	$groups->add_series( name => 'c', data => [ 2, 1 ], stack => 'g2', color => '#0000ff' );
	draw($groups);
	is [ bar_eighths( $groups, 6, $RED ), bar_eighths( $groups, 6, $GREEN ), bar_eighths( $groups, 10, $BLUE ) ], [ 12, 36, 24 ], 'each stack group is a bar of its own';
	is [ map { bar_chart( stacked => $_ )->stacked } 0, '', undef, 1, 'percent' ], [ 0, 0, 0, 1, 'percent' ], 'stacked takes 0, the empty string, undef, 1 and percent';
};

subtest 'percent stacking' => sub {
	my $chart = bar_chart( labels => [qw(A B)], stacked => 'percent', series => [ { name => 'a', data => [ 1, 3 ], color => '#ff0000' }, { name => 'b', data => [ 3, 1 ], color => '#00ff00' } ] );
	my @lines = draw($chart);
	like $lines[2], qr/\A100% \x{2500}/, 'the axis runs to 100%';
	like $lines[8], qr/\A  0% \x{2500}/, 'from 0%';
	is [ bar_eighths( $chart, 8, $RED ) + bar_eighths( $chart, 8, $GREEN ), bar_eighths( $chart, 21, $RED ) + bar_eighths( $chart, 21, $GREEN ) ], [ 48, 48 ], 'every stack reaches the top';
	is [ bar_eighths( $chart, 8, $RED ), bar_eighths( $chart, 21, $RED ) ], [ 12, 36 ], 'each series takes its share';
};

subtest 'horizontal bars' => sub {
	my $chart = bar_chart( horizontal => 1, labels => [qw(A B)], series => [ { name => 's', data => [ 2, 4 ], color => '#ff0000' } ] );
	my @lines = draw($chart);
	like $lines[-1], qr/\A  0 +2 +4\z/, 'the values along the bottom';
	is [ map { substr $_, 0, 1 } @lines[ 0 .. 8 ] ], [ ' ', 'A', (' ') x 3, 'B', (' ') x 3 ], 'the categories down the left';
	my @red = cells_with( $chart, sub ( $c, $x, $y ) { ( bg_at( $c, $x, $y ) // -1 ) == $RED } );
	is {
		map { $_->[1] => 1 } @red
	}, { 1 => 1, 2 => 1, 5 => 1, 6 => 1 }, 'each bar takes the rows of its category';
	my %longest = map {
		my $y = $_;
		$y => scalar grep { $_->[1] == $y } @red
	} 1, 5;
	ok $longest{5} > $longest{1} * 1.8, 'and is as long as its value';
	like glyph_row( $chart, 1 ), qr/\x{2590}/, 'bars start with a block at the baseline';

	like dies { bar_chart( horizontal => 1, series => [ { name => 'l', type => 'line' } ] ) }, qr/a horizontal chart shows only bar series, but 'l' is a line series/, 'a line series dies';
	my $vertical = bar_chart( series => [ { name => 'b' }, { name => 'l', type => 'line' } ] );
	like dies { $vertical->horizontal(1) }, qr/'l' is a line series/, 'turning a chart with a line series horizontal dies';
	is $vertical->horizontal, 0, 'and leaves it vertical';
	like dies { $chart->add_series( name => 'late', type => 'line' ) }, qr/'late' is a line series/, 'adding a line series to a horizontal chart dies';
	like dies { $chart->set_series( s => ( type => 'line' ) ) },        qr/'s' is a line series/,    'so does changing a series to a line';
	is [ $chart->series_names, $chart->series('s')->{type} ], [ 's', 'bar' ], 'and nothing changed';
};

subtest 'value labels' => sub {
	my $chart = bar_chart( labels => [qw(A B)], value_labels => 1, y_axis => { max => 40 }, series => [ { name => 's', data => [ 10, 20 ] } ] );
	my @lines = draw($chart);
	is [ rows_like( \@lines, qr/\A +10\b/ ), rows_like( \@lines, qr/\A +20\b/ ) ], [ [5], [3] ], 'each value above its bar';

	$chart->horizontal(1);
	@lines = draw($chart);
	like $lines[1], qr/\AA \x{2590} +10\b/, 'right of a horizontal bar';
};

subtest 'lines, points and markers' => sub {
	my @data  = ( 1, 4, 2 );
	my $chart = line_chart( series => [ { name => 'p', data => [@data] } ] );
	draw($chart);
	my $solid = braille_dots($chart);
	ok $solid > 20, 'a line is drawn in Braille dots';

	$chart->line_style('dashed');
	draw($chart);
	ok braille_dots($chart) < $solid * 0.8, 'a dashed line leaves gaps';
	$chart->line_style(undef);

	$chart->points(1);
	draw($chart);
	is scalar( cells_with( $chart, sub ( $c, $x, $y ) { ( glyph_at( $c, $x, $y ) // '' ) eq "\x{2022}" } ) ), 3, 'points mark the data points';
	$chart->set_series( p => ( point => 'x' ) );
	draw($chart);
	is scalar( cells_with( $chart, sub ( $c, $x, $y ) { ( glyph_at( $c, $x, $y ) // '' ) eq 'x' } ) ), 3, 'with a glyph of their own';

	my $boxed = line_chart( marker => 'box', series => [ { name => 'p', data => [@data] } ] );
	my @lines = draw($boxed);
	is braille_dots($boxed), 0, 'the box marker draws no Braille';
	like join( '', @lines ), qr/\x{256D}.*\x{256E}.*\x{256F}.*\x{2570}/s, 'but box drawing lines and corners';
};

subtest 'the box marker stays in the plot' => sub {
	my @data   = map { [ $_, $_ % 10 ] } 0 .. 100;
	my $gutter = sub (@lines) {
		[ map { sprintf '%-3s', substr( $_, 0, 3 ) } @lines[ 0 .. 8 ] ]
	};
	my @labels = ( '10 ', ('   ') x 3, ' 5 ', ('   ') x 3, ' 0 ' );
	my $fixed  = sized( 'Term::Fabulous::Widget::LineChart', 40, 10, marker => 'box', x_axis => { min => 50, max => 100 }, series => [ { name => 'p', data => [@data] } ] );
	is $gutter->( draw($fixed) ), \@labels, 'points left of a fixed x min leave the labels of the y axis alone';
	my $spanned = sized( 'Term::Fabulous::Widget::LineChart', 40, 10, marker => 'box', x_axis => { span => 50 }, series => [ { name => 'p', data => [@data] } ] );
	is $gutter->( draw($spanned) ), \@labels, 'so do points older than the span';
	my @lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 40, 10, marker => 'box', x_axis => { min => 0, max => 50 }, series => [ { name => 'p', data => [@data] } ] ) );
	is [ grep { length > length $lines[0] } @lines[ 1 .. 8 ] ], [], 'and points right of a fixed x max end at the right edge of the plot, where its grid lines end';
};

subtest 'thousands of points draw fast' => sub {
	my $line  = sized( 'Term::Fabulous::Widget::LineChart', 80, 20, series => [ { name => 'p', data => [ map { sin( $_ / 50 ) * 10 } 1 .. 4000 ] } ] );
	my $start = Time::HiRes::time();
	draw($line);
	ok Time::HiRes::time() - $start < 0.5, 'a line of 4000 points draws in well under a second';

	my $area      = sized( 'Term::Fabulous::Widget::AreaChart', 40, 10, x_axis => { span => 300 }, series => [ { name => 'p', data => [ map { [ $_ * 100, sin($_) + 2 ] } 0 .. 1000 ] } ] );
	my $looked_up = 0;
	{
		no warnings 'redefine';
		my $y_at = \&Term::Fabulous::Widget::XYChart::y_at;
		local *Term::Fabulous::Widget::XYChart::y_at = sub { $looked_up++; goto &$y_at };
		draw($area);
	}
	ok $looked_up <= 40, "an area with a short span over a long history fills only the columns of the plot ($looked_up lookups)";
};

subtest 'scatter points and trend lines' => sub {
	my $chart = sized( 'Term::Fabulous::Widget::ScatterPlot', 30, 8, series => [ { name => 'p', data => [ [ 1, 1 ], [ 2, 4 ], [ 3, 2 ] ] } ] );
	draw($chart);
	is scalar( cells_with( $chart, sub ( $c, $x, $y ) { ( glyph_at( $c, $x, $y ) // '' ) eq "\x{2836}" } ) ), 3,  'a point is a square of four dots';
	is braille_dots($chart),                                                                                  12, 'and nothing joins them';
	$chart->set_series( p => ( trend => 1 ) );
	draw($chart);
	ok braille_dots($chart) > 20, 'a trend line runs through them';
};

subtest 'areas fill down to the baseline' => sub {
	my $chart  = sized( 'Term::Fabulous::Widget::AreaChart', 30, 8, series => [ { name => 'p', data => [ 1, 4, 2 ], color => '#ff0000' } ] );
	my @lines  = draw($chart);
	my @filled = cells_with( $chart, sub ( $c, $x, $y ) { defined bg_at( $c, $x, $y ) } );
	ok @filled > 40,                                       'the area is filled';
	ok !( grep { bg_at( $chart, @$_ ) == $RED } @filled ), 'translucent, blended with the background';
	like $lines[0], $EIGHTH_BLOCKS, 'its top edge in eighth blocks';
	is braille_dots($chart), 0, 'without a line';
	$chart->line(1);
	draw($chart);
	ok braille_dots($chart) > 10, 'line adds one';
};

subtest 'x values decide the kind of axis' => sub {
	my $kind = sub (%args) { ( Term::Fabulous::Widget::LineChart->new(%args)->prepare_series )[0] };
	is $kind->( series => [ { data => [ 1, 2 ] } ] ),                                     'linear',   'plain values: their index on a linear axis';
	is $kind->( series => [ { data => [ [ 1.5, 2 ], [ 3, 1 ] ] } ] ),                     'linear',   'numbers';
	is $kind->( series => [ { data => [ [ '2026-06-10', 2 ], [ '2026-06-12', 1 ] ] } ] ), 'time',     'dates';
	is $kind->( series => [ { data => [ [ 'mon', 2 ], [ 'tue', 1 ] ] } ] ),               'category', 'labels';
	is $kind->( labels => [qw(a b)], series => [ { data => [ 1, 2 ] } ] ),                'category', 'the labels parameter';
	is( ( Term::Fabulous::Widget::BarChart->new( series => [ { data => [ 1, 2 ] } ] )->prepare_series )[0], 'category', 'bars without x values' );
	is $kind->( x_axis => { type => 'log' }, series => [ { data => [ [ 1, 1 ] ] } ] ), 'log', 'the axis type wins';

	like dies { $kind->( x_axis => { type => 'time' }, series => [ { name => 's', data => [ 1, 2 ] } ] ) }, qr/series 's' needs x values for a time axis/, 'a time axis needs x values';
	like dies { $kind->( x_axis => { type => 'linear' }, series => [ { name => 's', data => [ [ 'mon', 1 ] ] } ] ) }, qr/the x value 'mon' of series 's' is not a number/,
		'a linear axis needs numbers';

	my @lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 40, 6, series => [ { data => [ [ 'mon', 1 ], [ 'tue', 3 ], [ 'wed', 2 ] ] } ] ) );
	like $lines[-1], qr/\A mon +tue +wed\z/, 'categories in the order they come';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 40, 6, series => [ { data => [ [ '2026-06-10', 1 ], [ '2026-06-12', 3 ] ] } ] ) );
	like $lines[-1], qr/Jun 1[01]/, 'dates on a time axis';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 40, 8, x_axis => { type => 'log' }, series => [ { data => [ [ 1, 1 ], [ 10, 3 ], [ 100, 2 ] ] } ] ) );
	like $lines[-1], qr/\A  1 +10 +100\z/, 'powers on a log axis';
	@lines = draw( sized( 'Term::Fabulous::Widget::LineChart', 40, 8, y_axis => { type => 'log' }, series => [ { data => [ 0, 1, 10, -5, 100 ] } ] ) );
	is [ map { /\A *([0-9]+) / ? $1 : () } @lines[ 0 .. 6 ] ], [ 100, 10, 1 ], 'a log value axis leaves out values of zero and below';
};

subtest 'from, to and span' => sub {
	my $chart = line_chart( series => [ { name => 'p', from => 1, to => 3, data => [ 1, 2, 3, 2, 1 ] } ] );
	my @lines = draw($chart);
	like $lines[-1], qr/\A  1 +2 +3\z/, 'from and to cut a series and the axis';
	$chart = line_chart( x_axis => { span => 2 }, series => [ { name => 'p', data => [ 1, 2, 3, 2, 1 ] } ] );
	@lines = draw($chart);
	like $lines[-1], qr/\A  2 +3 +4\z/, 'span shows the newest x values';
	$chart = line_chart( x_axis => { span => 2 }, series => [ { name => 'p', data => [ 50, 1, 2, 3, 2 ] } ] );
	@lines = draw($chart);
	like $lines[0], qr/\A3 /, 'points older than the span do not count for the y axis';
};

subtest 'grids' => sub {
	my %glyphs = ( dashed => [ "\x{254C}", "\x{254E}" ], dotted => [ "\x{2508}", "\x{250A}" ], solid => [ "\x{2500}", "\x{2502}" ] );
	foreach my $style ( sort keys %glyphs ) {
		my $text = join "\n", draw( line_chart( x_axis => { grid => $style }, y_axis => { grid => $style }, series => [ { data => [ 1, 2 ] } ] ) );
		my ( $across, $down ) = $glyphs{$style}->@*;
		like $text, qr/$across/, "$style grid lines across";
		like $text, qr/$down/,   "$style grid lines down";
	}
	like join( '', draw( line_chart( x_axis => { grid => 1 }, series => [ { data => [ 1, 2 ] } ] ) ) ), qr/\x{253C}/, 'solid lines cross';
	my @lines = draw( line_chart( y_axis => { grid => 0 }, series => [ { data => [ 1, 2 ] } ] ) );
	is rows_like( \@lines, qr/\x{2500}/ ), [ $#lines - 1 ], 'without a grid only the baseline is left';
};

subtest 'transforms' => sub {
	my @lines = draw( line_chart( transform => 'cumulative', series => [ { data => [ 1, 1, 1, 1 ] } ] ) );
	like $lines[0], qr/\A4 /, 'the chart transforms all series';
	@lines = draw( line_chart( series => [ { data => [ 2, 4, 6 ], transform => [ [ 'index', 10 ] ] } ] ) );
	like $lines[0],  qr/\A30 /, 'a series transforms its own data';
	like $lines[-2], qr/\A10 /, 'from its first value';
};

subtest 'series management' => sub {
	my $chart = line_chart( palette => [ '#ff0000', '#00ff00', '#0000ff' ] );
	ref_is $chart->add_series( name => 'a', data => [ 1, 2 ] ), $chart, 'add_series returns the chart';
	$chart->add_series( { name => 'b', data => [ 3, 4 ], curve => 'monotone' } );
	is [ $chart->series_names ],                             [qw(a b)], 'in order';
	is [ $chart->has_series('b'), $chart->has_series('c') ], [ 1, 0 ],  'has_series';
	is $chart->series('b'), { name => 'b', type => 'line', curve => 'monotone', data => [ 3, 4 ] }, 'series describes a series';
	like dies { $chart->set_series( b => ( type => 'area', curve => 'wiggly' ) ) }, qr/curve of series 'b' must be/, 'set_series checks every option first';
	is $chart->series('b')->{type}, 'line', 'and changes nothing when one fails';
	ok dies { $chart->add_series( name => 'bad', data => ['x'] ) }, 'a series with bad data is not added (and takes no palette slot: see the colors below)';

	$chart->set_series( b => ( type => 'area', curve => undef, color => '#123456', data => [ [ 0, 5 ] ] ) );
	is $chart->series('b'), { name => 'b', type => 'area', color => '#123456', data => [ [ 0, 5 ] ] }, 'set_series changes type, color, data and options';
	$chart->set_series( b => ( color => undef ) );

	$chart->add_points( a => 3, [ 5, 4 ] );
	is $chart->series('a')->{data}, [ 1, 2, 3, [ 5, 4 ] ], 'add_points';
	$chart->append( 6, { a => 5, b => 6 } );
	is [ map { $chart->series($_)->{data}[-1] } qw(a b) ], [ [ 6, 5 ], [ 6, 6 ] ], 'append adds to several series at one x';
	$chart->clear_data('a');
	is $chart->series('a')->{data}, [], 'clear_data';

	$chart->remove_series('a');
	$chart->add_series( name => 'c', data => [1] );
	draw($chart);
	is [ fg_at( $chart, 0, 0 ), fg_at( $chart, 6, 0 ) ], [ $GREEN, $BLUE ], 'series keep their palette color when others go';
	$chart->clear_series;
	is [ $chart->series_names ], [], 'clear_series';
};

subtest 'hidden series' => sub {
	my $chart = line_chart( series => [ { name => 'a', data => [ 1, 2 ] }, { name => 'b', data => [ 10, 20 ] } ] );
	$chart->hide_series('b');
	is $chart->is_series_visible('b'), 0, 'is_series_visible';
	my @lines = draw($chart);
	like $lines[0],            qr/\A2 /,     'a hidden series does not count for the axes';
	unlike join( '', @lines ), qr/\x{2501}/, 'and has no legend entry';
	$chart->show_series('b');
	@lines = draw($chart);
	like $lines[2], qr/\A20 /, 'show_series brings it back';
};

subtest 'max_points' => sub {
	my $chart = line_chart( max_points => 3, series => [ { name => 'a', data => [ 1 .. 5 ] }, { name => 'b', data => [ 1 .. 5 ], max_points => 4 } ] );
	is [ map { $chart->series($_)->{data} } qw(a b) ], [ [ 3, 4, 5 ], [ 2 .. 5 ] ], 'the chart keeps the newest points; a series may keep more';
	$chart->add_points( a => 6, 7 );
	$chart->append( undef, { a => 8 } );
	is $chart->series('a')->{data}, [ 6, 7, 8 ], 'also when points are added';
	$chart->max_points(undef);
	$chart->add_points( a => 9 );
	is $chart->series('a')->{data}, [ 6 .. 9 ], 'undef lifts the limit';

	my $window = line_chart( max_points => 3, series => [ { name => 'a', data => [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ] } ] );
	my @before = draw($window);
	$window->append( 4, { a => 4 } );
	my @after = draw($window);
	is [ $before[-1], $after[-1] ], [ match qr/\A  1 +2 +3\z/, match qr/\A  2 +3 +4\z/ ], 'the axis follows the newest points';
};

subtest 'unnamed series after a removal' => sub {
	my $chart = line_chart();
	$chart->add_series( data => [1] )->add_series( data => [2] );
	$chart->remove_series('Series 1');
	$chart->add_series( data => [3] );
	is [ $chart->series_names ], [ 'Series 2', 'Series 3' ], 'a new unnamed series takes the first free number';
};

subtest 'append is all or nothing' => sub {
	my $chart = line_chart( series => [ { name => 'a', data => [ 1, 2 ] }, { name => 'b', data => [ 3, 4 ] } ] );
	like dies { $chart->append( undef, { a => 5, b => 'x' } ) }, qr/the y value of data point 2 of series 'b' must be a finite number or undef, got 'x'/, 'a bad value for one series dies';
	is [ map { $chart->series($_)->{data} } qw(a b) ], [ [ 1, 2 ], [ 3, 4 ] ], 'and no series gains a point';
};

subtest 'axis ends are checked when they are given' => sub {
	my @cases = (
		[ { y_axis => { type => 'log', min => 0 } },                                  qr/the min of y_axis must be greater than 0 on a log axis, got '0'/,           'a log y axis from 0' ],
		[ { x_axis => { type => 'log', max => -1 } },                                 qr/the max of x_axis must be greater than 0 on a log axis, got '-1'/,          'a log x axis to -1' ],
		[ { y_axis => { min => 10, max => 5 } },                                      qr/the min of y_axis \(10\) must be less than its max \(5\)/,                  'a min above the max' ],
		[ { x_axis => { min => 3, max => 3 } },                                       qr/the min of x_axis \(3\) must be less than its max \(3\)/,                   'a min at the max' ],
		[ { x_axis => { type => 'time', min => 'garbage' } },                         qr/the min of x_axis must be a date on a time axis, got 'garbage'/,            'a time axis from no date' ],
		[ { x_axis => { type => 'time', min => '2026-06-12', max => '2026-06-10' } }, qr/the min of x_axis \(2026-06-12\) must be less than its max \(2026-06-10\)/, 'dates in the wrong order' ],
		[ { x_axis => { type => 'linear', max => 'end' } },                           qr/the max of x_axis must be a number, got 'end'/,                             'a linear axis to no number' ],
		[ { x_axis => { max => 'end' } },                                             qr/the max of x_axis must be a number or a date, got 'end'/,                   'an automatic axis to neither' ],
	);
	foreach my $case (@cases) {
		like dies { line_chart( $case->[0]->%* ) }, $case->[1], "$case->[2] dies when the chart is made";
	}

	my $chart = line_chart( y_axis => { min => 0 }, series => [ { data => [ 1, 2 ] } ] );
	like dies { $chart->y_axis( { type => 'log', min => 0 } ) }, qr/the min of y_axis must be greater than 0 on a log axis/, 'the accessor checks the same';
	is $chart->y_axis, { type => 'linear', min => 0 }, 'and keeps the axis it had';

	my $dated = line_chart( x_axis => { type => 'time', min => '2026-06-10', max => '2026-06-12' }, series => [ { data => [ [ '2026-06-11', 1 ] ] } ] );
	ok lives { draw($dated) }, 'dates as the ends of a time axis';
	is $dated->x_axis->{min}, '2026-06-10', 'which the accessor returns as given';
};

subtest 'invalid input dies' => sub {
	my $chart = line_chart( series => [ { name => 'a' } ] );
	my @cases = (
		[ sub { line_chart( series => [ { name => 'a', colour => '#ff0000' } ] ) }, qr/series 'a' does not take colour \(known: name, type, data, color, marker/, 'an unknown series option' ],
		[ sub { $chart->add_series( name => 'a' ) },                                qr/a series named 'a' exists already/,                                        'a duplicate name' ],
		[ sub { line_chart( series => [ { type => 'pie' } ] ) },                    qr/draws series of the types line, area, bar, scatter, not 'pie'/,            'an unknown type' ],
		[
			sub { line_chart( series => [ { name => 'a', marker => 'block' } ] ) }, qr/marker of series 'a' must be one of braille, half, quadrant, sextant, box for a line series/,
			'a marker the type cannot draw'
		],
		[ sub { $chart->set_data( a => { 1 => 2 } ) },                qr/the data of series 'a' must be an array reference, got a HASH reference/,               'data that is no array' ],
		[ sub { $chart->set_data( a => [ [ 1, 2, 3 ] ] ) },           qr/data point 0 of series 'a' must be \[ x, y \], got an array of 3 values/,               'a point of three values' ],
		[ sub { $chart->set_data( a => [ 1, { x => 1, z => 2 } ] ) }, qr/data point 1 of series 'a' takes only the keys x and y, got z/,                         'a point hash with other keys' ],
		[ sub { $chart->set_data( a => ['abc'] ) },                   qr/the y value of data point 0 of series 'a' must be a finite number or undef, got 'abc'/, 'a y value that is no number' ],
		[ sub { $chart->add_points( b => 1 ) },                       qr/no series named 'b'/,                                                                   'an unknown series' ],
		[ sub { $chart->set_series( a => ( name => 'b' ) ) },         qr/set_series cannot rename a series/,                                                     'renaming' ],
		[ sub { $chart->append( 1, [1] ) },                           qr/append needs a hash reference of values by series name/,                                'append without a hash' ],
		[ sub { $chart->series_default( stack => 'x' ) },             qr/unknown series default 'stack'/,                                                        'an unknown series default' ],
		[ sub { line_chart( x_axis      => { kind => 'time' } ) }, qr/x_axis does not take kind \(known: type min max/,                          'an unknown axis key' ],
		[ sub { line_chart( x_axis      => [] ) },                 qr/x_axis must be a hash reference, got an ARRAY reference/,                  'an axis that is no hash' ],
		[ sub { line_chart( y_axis      => { type => 'time' } ) }, qr/y_axis type must be one of linear, log, got 'time'/,                       'a y axis of time' ],
		[ sub { line_chart( y_axis      => { grid => 'wavy' } ) }, qr/the grid of y_axis must be 0, 1, solid, dashed or dotted, got 'wavy'/,     'an unknown grid style' ],
		[ sub { line_chart( y_axis      => { ticks => 0 } ) },     qr/the ticks of y_axis must be a positive integer, got '0'/,                  'zero ticks' ],
		[ sub { line_chart( y_axis      => { min => 'low' } ) },   qr/the min of y_axis must be a number, got 'low'/,                            'a y minimum that is no number' ],
		[ sub { line_chart( x_axis      => { base => 1 } ) },      qr/the base of x_axis must be a number greater than 1/,                       'a log base of 1' ],
		[ sub { line_chart( stacked     => [] ) },                 qr/stacked must be 0, 1 or 'percent', got an ARRAY reference/,                'stacked as an array' ],
		[ sub { line_chart( stacked     => 'percents' ) },         qr/stacked must be 0, 1 or 'percent', got 'percents'/,                        'stacked as a misspelled percent' ],
		[ sub { line_chart( stacked     => '1.0' ) },              qr/stacked must be 0, 1 or 'percent', got '1.0'/,                             'stacked as 1.0' ],
		[ sub { line_chart( curve       => 'wiggly' ) },           qr/LineChart: curve must be /,                                                'a chart-wide option names no series' ],
		[ sub { line_chart( bar_width   => 1.5 ) },                qr/bar_width must be a number from 0 to 1, got '1\.5'/,                       'a bar width above 1' ],
		[ sub { line_chart( labels      => [undef] ) },            qr/every label must be a string, got undef/,                                  'an undefined label' ],
		[ sub { line_chart( series      => 'a' ) },                qr/series must be an array reference of series hashes/,                       'series that are no array' ],
		[ sub { line_chart( legend      => 'middle' ) },           qr/legend must be one of auto, bottom, left, none, right, top, got 'middle'/, 'an unknown legend position' ],
		[ sub { line_chart( title_align => 'top' ) },              qr/title_align must be one of center, left, right, got 'top'/,                'an unknown title alignment' ],
		[ sub { line_chart( theme       => 'blue' ) },             qr/theme must be one of auto, dark, light, got 'blue'/,                       'an unknown theme' ],
		[ sub { line_chart( palette    => 'nope' ) }, qr/palette must be a palette name \(classic, default, pastel, vivid\) or an array reference of colors, got 'nope'/, 'an unknown palette' ],
		[ sub { line_chart( hover_fade => 2 ) },      qr/hover_fade must be a number from 0 to 1, got '2'/,                                                               'a fade above 1' ],
		[ sub { line_chart( title      => [] ) },     qr/title must be a string or undef, got an ARRAY reference/,                                                        'a title that is no string' ],
	);
	foreach my $case (@cases) {
		like dies { $case->[0]->() }, $case->[1], $case->[2];
	}
};

done_testing;
