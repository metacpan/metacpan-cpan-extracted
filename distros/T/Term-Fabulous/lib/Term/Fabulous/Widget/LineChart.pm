package Term::Fabulous::Widget::LineChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::XYChart;

class Term::Fabulous::Widget::LineChart :isa(Term::Fabulous::Widget::XYChart) :strict(params) {
	method default_series_type () { return 'line' }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::LineChart - A chart of lines through data points

=head1 SYNOPSIS

	use Term::Fabulous::Widget::LineChart;

	my $chart = Term::Fabulous::Widget::LineChart->new(
		title  => 'Monthly active users',
		labels => [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)],
		curve  => 'monotone',
		y_axis => { title => 'thousands' },
		series => [
			{ name => 'Web',     data => [ 120, 132, 151, 149, 170, 205, 261, 252, 196, 178, 164, 183 ] },
			{ name => 'iOS',     data => [ 82,  97,  108, 141, 166, 192, 228, 247, 223, 206, 214, 238 ] },
			{ name => 'Android', data => [ 31,  35,  41,  57,  62,  61,  74,  88,  95,  113, 128, 141 ] },
		],
	);

	$chart->append( 'Jan 27', { Web => 190, iOS => 241, Android => 150 } );    # a 13th month
	$chart->set_series( iOS => ( line_style => 'dashed', points => 1 ) );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-line-chart.svg" alt="Three smooth lines for Web, iOS and Android over the months of a year, with a legend at the top and a y axis in thousands"></p>

=end html

The program is F<examples/widgets/line-chart.pl>.

=head1 DESCRIPTION

A line chart shows how values change along the x axis: over time, over
categories or over a number. Each series is a line through its points,
drawn in Braille dots (a quarter of a cell wide, an eighth of a cell
high), straight between the points or along a L<curve|Term::Fabulous::Widget::XYChart/Curves>;
the y axis does not include zero unless asked to, so the differences
between values stay visible.

Everything a line chart does is described on
L<Term::Fabulous::Widget::XYChart>: the series and their data forms,
category, numeric and time axes, curves, line styles, points, rendering
styles, transforms, live data, hover. A LineChart is an XYChart whose
series are C<line> series unless they say otherwise; a line chart may
also carry area, bar and scatter series.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::LineChart->new(%parameters);

The parameters of L<Term::Fabulous::Widget::XYChart/CONSTRUCTOR> and
L<Term::Fabulous::Widget::Chart/CONSTRUCTOR>. The options that matter
most for lines: C<curve>, C<line_style>, C<points> and C<point>,
C<marker> (C<braille> by default, or C<box> for a chart of box drawing
characters), C<span_gaps>, C<max_points>.

=head1 METHODS

Those of L<Term::Fabulous::Widget::XYChart/METHODS>.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::LineChart as LineChart

	LineChart "users" {
		title "Monthly active users"
		labels "Jan" "Feb" "Mar" "Apr"
		curve "monotone"
		series "Web" { data 120 132 151 149 }
		series "iOS" line_style="dashed" { data 82 97 108 141 }
	}

See L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>, L<Term::Fabulous::Widget::AreaChart>,
L<Term::Fabulous::Widget::Sparkline>, L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/Draw a line chart with labels and points (LineChart)>.

=cut
