use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use ChartTest;
use Term::Fabulous::Layout;
use Term::Fabulous::Widget::BarChart;
use Term::Fabulous::Widget::PieChart;

# A chart of the class built from the KDL of its block.
sub chart_from ( $class, $body ) {
	return Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::$class as Chart\nChart \"chart\" {\n$body\n}\n" )->build;
}

subtest 'what every chart takes' => sub {
	my $chart = chart_from( LineChart => <<'KDL' );
title "Load"
title_align "center"
legend "bottom"
theme "light"
hover #false
hover_fade 0.5
highlight "cpu"
palette "#ff0000" "#00ff00"
title_color "#010203"
text_color "#040506"
label_color "#070809"
axis_color "#0a0b0c"
grid_color "#0d0e0f"
KDL
	is [ map { $chart->$_ } qw(title title_align legend theme hover hover_fade highlight) ], [ 'Load', 'center', 'bottom', 'light', 0, 0.5, 'cpu' ], 'the settings';
	is $chart->palette,                                                                      [ 0xFF0000, 0x00FF00 ],                                 'a palette of colors';
	is [ map { $chart->$_ } qw(title_color text_color label_color axis_color grid_color) ],  [ 0x010203, 0x040506, 0x070809, 0x0A0B0C, 0x0D0E0F ],   'the ink colors';
	is chart_from( LineChart => 'palette "vivid"' )->palette,                                'vivid',                                                'a palette by name';
};

subtest 'XY charts' => sub {
	my $chart = chart_from( LineChart => <<'KDL' );
max_points 3
curve "monotone"
tension 0.5
line #true
line_style "dotted"
points #true
point "x"
fill_opacity 0.4
span_gaps #true
value_labels #true
marker "half"
labels "a" "b" "c" "d"
x_axis title="day" grid="dashed"
y_axis min=0 max=10
transform "cumulative"
transform "moving_average" 2
series "cpu" color="#3987e5" line_style="dashed" {
	data 1 2
	data 3
	point "d" 5
	transform "index" 10
}
series "mem" type="area" { data 4 5 6; }
KDL
	is [ map { $chart->$_ } qw(max_points curve tension line line_style points point fill_opacity span_gaps value_labels marker) ], [ 3, 'monotone', 0.5, 1, 'dotted', 1, 'x', 0.4, 1, 1, 'half' ],
		'the series defaults';
	is [ $chart->labels, $chart->x_axis, $chart->y_axis ], [ [qw(a b c d)], { type => 'auto', title => 'day', grid => 'dashed' }, { type => 'linear', min => 0, max => 10 } ], 'labels and axes';
	is [ map { $_->[0] } $chart->series_default('transform')->@* ], [ 'cumulative', 'moving_average' ], 'transform nodes add steps';
	is $chart->series('cpu'), { name => 'cpu', type => 'line', color => '#3987e5', line_style => 'dashed', data => [ 2, 3, [ d => 5 ] ] }, 'a series with data and points, kept to max_points';
	is $chart->series('mem')->{type},                                                                                                      'area', 'series of other types';

	my $bars = chart_from( BarChart => 'stacked "percent"; horizontal #true; bar_width 0.5; series "x" { data 1 2; }' );
	is [ $bars->stacked, $bars->horizontal, $bars->bar_width ],                      [ 'percent', 1, 0.5 ], 'bar settings';
	is chart_from( BarChart => 'stacked #true; series "x" { data 1 2; }' )->stacked, 1,                     'stacked takes a KDL boolean';
};

subtest 'a layout draws what the same Perl code draws' => sub {
	my $from_kdl = chart_from( BarChart => <<'KDL' );
sizing width="fixed(30)" height="fixed(10)"
title "Sales"
labels "Q1" "Q2"
y_axis title="units"
series "north" { data 3 5; }
series "south" { data 4 1; }
KDL
	my $from_perl = sized(
		'Term::Fabulous::Widget::BarChart', 30, 10,
		title  => 'Sales',
		labels => [qw(Q1 Q2)],
		y_axis => { title => 'units' },
		series => [ { name => 'north', data => [ 3, 5 ] }, { name => 'south', data => [ 4, 1 ] } ],
	);
	my @lines = draw($from_kdl);
	is \@lines, [ draw($from_perl) ], 'a bar chart';
	like $lines[0], qr/\ASales/, 'with its title';

	my $pie = chart_from( PieChart => qq{sizing width="fixed(40)" height="fixed(12)"\nslice "Rent" 1200 color="#3987e5"\nslice "Food" 400} );
	is [ draw($pie) ], [ draw( sized( 'Term::Fabulous::Widget::PieChart', 40, 12, data => [ { label => 'Rent', value => 1200, color => '#3987e5' }, [ Food => 400 ] ] ) ) ], 'a pie chart';
};

subtest 'round charts' => sub {
	my $donut = chart_from( DonutChart => <<'KDL' );
hole 0.5
start_angle 90
sort "desc"
slice_labels "value"
legend_values "both"
center_text "Budget"
marker "half"
other 0.1
other_label "Rest"
gap #true
format "%.1f"
slice "Rent" 1200 color="#3987e5"
slice "Food" 400
KDL
	is [ map { $donut->$_ } qw(hole start_angle sort slice_labels legend_values center_text marker other other_label gap format) ],
		[ 0.5, 90, 'desc', 'value', 'both', 'Budget', 'half', 0.1, 'Rest', 1, '%.1f' ], 'pie and donut settings';
	is [ $donut->slices ], [ { label => 'Rent', value => 1200, color => '#3987e5' }, { label => 'Food', value => 400 } ], 'slices';

	my $polar = chart_from( PolarAreaChart => 'max 10; ticks 5; slice "a" 3' );
	is [ $polar->max, $polar->ticks, $polar->total ], [ 10, 5, 3 ], 'polar area settings';

	my $radar = chart_from( RadarChart => <<'KDL' );
series "s" type="line" color="#3987e5" { data 1 2; data 3; }
series "t" { point "c" 4; point "a" 2; }
labels "a" "b" "c"
min 0
max 5
ticks 5
grid "circle"
format "%.1f"
start_angle 45
marker "half"
line_style "dotted"
points #true
point "x"
fill_opacity 0.5
KDL
	is [ map { $radar->$_ } qw(labels min max ticks grid format start_angle marker line_style points point fill_opacity) ],
		[ [qw(a b c)], 0, 5, 5, 'circle', '%.1f', 45, 'half', 'dotted', 1, 'x', 0.5 ], 'radar settings';
	is $radar->series('s'), { name => 's', type => 'line', color => '#3987e5', data => [ 1, 2, 3 ] }, 'radar series, after the labels';
	is $radar->series('t'), { name => 't', type => 'area', data => [ [ c => 4 ], [ a => 2 ] ] }, 'radar points name their axis';
};

subtest 'histograms and sparklines' => sub {
	my $histogram = chart_from( Histogram => 'bins 5; bin_width 2; measure "percent"; cumulative #true; range 0 10; series "s" { data 1 2 3; }' );
	is [ map { $histogram->$_ } qw(bins bin_width measure cumulative range) ], [ 5, 2, 'percent', 1, [ 0, 10 ] ], 'histogram settings';
	is $histogram->series('s')->{data}, [ 1, 2, 3 ], 'and data';

	my $sparkline = chart_from( Sparkline => 'type "bar"; color "#ff0000"; min 0; max 10; values 1 2 3' );
	is [ map { $sparkline->$_ } qw(type min max values) ], [ 'bar', 0, 10, [ 1, 2, 3 ] ], 'sparkline settings';
	is $sparkline->series('values')->{color},              '#ff0000',                     'its color';
};

subtest 'invalid layouts die' => sub {
	my @cases = (
		[ LineChart  => 'colour "#fff"',                 qr/unknown layout property 'colour' \(known: axis_color, /,                  'an unknown property' ],
		[ LineChart  => 'series',                        qr/layout property 'series' needs the series name as its one argument/,      'a series without a name' ],
		[ LineChart  => 'series "a" { values 1 2; }',    qr/a series node holds 'data', 'point' and 'transform' nodes, got 'values'/, 'an unknown node in a series' ],
		[ LineChart  => 'series "a" { point 1; }',       qr/'point' in series 'a' takes an x and a y value/,                          'a point of one value' ],
		[ LineChart  => 'series "a" { data 1 step=2; }', qr/'data' in series 'a' takes no properties or children/,                    'data with a property' ],
		[ LineChart  => 'series "a" b="c"',              qr/series 'a' does not take b/,                                              'an unknown series property' ],
		[ LineChart  => 'x_axis kind="time"',            qr/layout property 'x_axis' does not accept kind/,                           'an unknown axis key' ],
		[ LineChart  => 'x_axis "time"',                 qr/layout property 'x_axis' takes key=value properties only/,                'an axis with an argument' ],
		[ LineChart  => 'palette',                       qr/layout property 'palette' takes a palette name or one or more colors/,    'a palette without colors' ],
		[ LineChart  => 'hover "yes"',                   qr/layout property 'hover' must be #true or #false, got 'yes'/,              'a boolean as a string' ],
		[ LineChart  => 'transform',                     qr/layout property 'transform' takes a step name and its arguments/,         'a transform without a step' ],
		[ LineChart  => 'labels',                        qr/layout property 'labels' takes one or more labels/,                       'no labels' ],
		[ PieChart   => 'slice "A"',                     qr/layout property 'slice' takes a label and a value/,                       'a slice without a value' ],
		[ PieChart   => 'slice "A" 1 size=2',            qr/layout property 'slice' takes only the property color, got size/,         'an unknown slice property' ],
		[ Histogram  => 'range 1',                       qr/layout property 'range' takes a low and a high value/,                    'a range of one value' ],
		[ RadarChart => 'series "a" { point "Speed"; }', qr/'point' in series 'a' takes a label and a value/,                         'a radar point without a value' ],
		[ RadarChart => 'series "a" { point #null 3; }', qr/'point' in series 'a' takes a label and a value/,                         'a radar point without a label' ],
		[ Sparkline  => 'values 1 x=2',                  qr/layout property 'values' takes numbers/,                                  'values with a property' ],
		[ BarChart   => 'bar_width 2',                   qr/bar_width must be a number from 0 to 1, got '2'/,                         'a value the accessor rejects' ],
	);
	foreach my $case (@cases) {
		my ( $class, $body, $error, $name ) = @$case;
		like dies { chart_from( $class, $body ) }, $error, $name;
	}
};

done_testing;
