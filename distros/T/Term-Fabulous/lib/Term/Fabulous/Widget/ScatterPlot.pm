package Term::Fabulous::Widget::ScatterPlot;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::XYChart;

class Term::Fabulous::Widget::ScatterPlot :isa(Term::Fabulous::Widget::XYChart) :strict(params) {
	method default_series_type () { return 'scatter' }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::ScatterPlot - Points by two numbers, with trend
lines

=head1 SYNOPSIS

	use Term::Fabulous::Widget::ScatterPlot;

	my $chart = Term::Fabulous::Widget::ScatterPlot->new(
		title  => 'Power and fuel use',
		x_axis => { title => 'Engine power (kW)' },
		y_axis => { title => 'l/100 km' },
		series => [
			{ name => 'Petrol', data => [ [ 110, 7.1 ], [ 85, 6.2 ], [ 160, 8.4 ] ], trend => 1 },
			{ name => 'Hybrid', data => [ [ 90, 4.1 ], [ 140, 5.0 ], [ 70, 3.6 ] ], trend => 1 },
		],
	);

	$chart->point('x');    # a character instead of the Braille square

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-scatter-plot.svg" alt="Two clouds of points for petrol and hybrid cars, each with a dashed trend line, over an x axis of engine power"></p>

=end html

The program is F<examples/widgets/scatter-plot.pl>.

=head1 DESCRIPTION

A scatter plot shows every observation as one point at its x and y
value, for the relation between two numbers. Points are C<[ x, y ]>
pairs on numeric axes (a category x axis works too, with labels). Each
point is a C<square> of four Braille dots by default, placed to a
quarter of a cell; C<point> makes it a single C<dot> or any character.
C<trend> on a series adds the least-squares line through its points,
dashed, from the first x to the last. Neither axis includes zero unless
asked to.

For series of tens of thousands of points, the C<downsample> transform
of L<Term::Fabulous::Chart::Transform> keeps the shape and draws
faster. Everything else is described on
L<Term::Fabulous::Widget::XYChart>; a ScatterPlot is an XYChart whose
series are C<scatter> series unless they say otherwise, so a line
series can draw a model over the observations.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::ScatterPlot->new(%parameters);

The parameters of L<Term::Fabulous::Widget::XYChart/CONSTRUCTOR> and
L<Term::Fabulous::Widget::Chart/CONSTRUCTOR>. For points: C<point>,
C<marker> (C<braille> by default), and C<trend> on each series.

=head1 METHODS

Those of L<Term::Fabulous::Widget::XYChart/METHODS>.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::ScatterPlot as ScatterPlot

	ScatterPlot "cars" {
		x_axis title="kW"
		point "dot"
		series "Petrol" trend=#true {
			point 110 7.1
			point 85 6.2
		}
	}

See L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>, L<Term::Fabulous::Chart::Transform>,
L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/A scatter plot with trend lines (ScatterPlot)>.

=cut
