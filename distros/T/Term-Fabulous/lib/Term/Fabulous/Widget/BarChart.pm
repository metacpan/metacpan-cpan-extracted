package Term::Fabulous::Widget::BarChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::XYChart;

class Term::Fabulous::Widget::BarChart :isa(Term::Fabulous::Widget::XYChart) :strict(params) {
	method default_series_type () { return 'bar' }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::BarChart - Values as bars, grouped, stacked or
horizontal

=head1 SYNOPSIS

	use Term::Fabulous::Widget::BarChart;

	my $chart = Term::Fabulous::Widget::BarChart->new(
		title        => 'Revenue by quarter',
		labels       => [qw(Q1 Q2 Q3 Q4)],
		value_labels => 1,
		y_axis       => { title => 'million EUR' },
		series       => [
			{ name => '2025', data => [ 42.5, 51.2, 48.0, 63.4 ] },
			{ name => '2026', data => [ 47.1, 58.3, 61.0, 72.2 ] },
		],
	);

	$chart->add_series( name => 'Target', type => 'line', data => [ 50, 55, 60, 65 ] );    # a line over the bars
	$chart->remove_series('Target');
	$chart->stacked(1);       # 2026 on top of 2025
	$chart->horizontal(1);    # categories down the left; only bar series

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-bar-chart.svg" alt="Pairs of bars for 2025 and 2026 in four quarters, each bar with its value written above it"></p>

=end html

The program is F<examples/widgets/bar-chart.pl>.

=head1 DESCRIPTION

A bar chart compares values across categories. Each category has a slot
on the x axis; the bars of several series stand side by side in it
(grouped), or on each other with C<stacked>. Bars grow from zero (or
from the baseline, downwards for negative values), in block characters
placed to an eighth of a cell, and are opaque. On a numeric or time x
axis, bars are centered on their x, in slots as wide as the smallest distance
between two bars.

Options for bars: C<value_labels> writes each bar's value above it (a
stack's total); C<bar_width> (0 to 1, default 0.7) is the share of the
slot the bars take; C<horizontal> turns the chart on its side, for long
category names or many categories; C<stack> on a series puts it in a
named stack group; C<marker> changes the character set. Everything else,
including the axes and live data, is described on
L<Term::Fabulous::Widget::XYChart>; a BarChart is an XYChart whose series
are C<bar> series unless they say otherwise. A horizontal chart shows
bar series only. The options are described with pictures in
L<Term::Fabulous::Widget::XYChart/LOOKS>.

For the distribution of values, use L<Term::Fabulous::Widget::Histogram>,
which counts them into bins first.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::BarChart->new(%parameters);

The parameters of L<Term::Fabulous::Widget::XYChart/CONSTRUCTOR> and
L<Term::Fabulous::Widget::Chart/CONSTRUCTOR>. For bars: C<labels>,
C<stacked>, C<horizontal>, C<bar_width>, C<value_labels>,
C<fill_opacity>, C<marker>.

=head1 METHODS

Those of L<Term::Fabulous::Widget::XYChart/METHODS>.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::BarChart as BarChart

	BarChart "revenue" {
		labels "Q1" "Q2" "Q3" "Q4"
		value_labels #true
		horizontal #false
		bar_width 0.6
		series "2025" { data 42.5 51.2 48 63.4 }
		series "2026" { data 47.1 58.3 61 72.2 }
	}

See L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>, L<Term::Fabulous::Widget::Histogram>,
L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/Grouped, stacked and horizontal bars (BarChart)>.

=cut
