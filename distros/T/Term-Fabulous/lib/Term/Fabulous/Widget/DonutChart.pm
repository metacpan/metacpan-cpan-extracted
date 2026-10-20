package Term::Fabulous::Widget::DonutChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::PieChart;

class Term::Fabulous::Widget::DonutChart :isa(Term::Fabulous::Widget::PieChart) :strict(params) {
	method default_hole :override () { return 0.6 }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::DonutChart - A pie chart with a hole

=head1 SYNOPSIS

	use Term::Fabulous::Widget::DonutChart;

	my $chart = Term::Fabulous::Widget::DonutChart->new(
		title         => 'Sales by region',
		legend_values => 'value',
		format        => 'si',
		data          => [ [ Europe => 412_000 ], [ 'North America' => 365_000 ], [ Asia => 290_000 ] ],
	);

	$chart->center_text("1.07M\norders");    # instead of the total
	$chart->hole(0.5);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-donut-chart.svg" alt="A donut of a monthly budget with the total in the middle and the amounts and shares in the legend"></p>

=end html

F<examples/widgets/donut-chart.pl> draws this chart.

=head1 DESCRIPTION

A donut is a L<Term::Fabulous::Widget::PieChart> whose C<hole> is 0.6
of the radius by default. A ring shows shares as well as a pie does, and
the hole holds a text.

=head2 The text in the hole

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-donut-chart-centers.svg" alt="Three donuts of the same budget: the total 2170 euros in the middle of the first, 21% Food in the middle of the second with the other slices faded, and a text of its own, 2170 euros per month, in the third"></p>

=end html

The hole shows, in this order of preference:

=over

=item *

the C<center_text>, when it is set: one or more lines separated by
newlines, the first in bold (an empty string shows nothing);

=item *

the share and the label of the emphasized slice, while the pointer is
on a slice or its legend entry, or while C<highlight> names a slice;

=item *

the total of the slices in bold, with the word C<Total> below it.

=back

Values are written with the chart's C<format>. The text appears when the
radius of the hole is at least three cell widths, that is when the hole
is at least six columns wide; lines wider than the hole are cut.
F<examples/widgets/donut-chart-centers.pl> shows the three cases.

Everything else, the data forms, the parameters, methods, events and KDL
properties, is on L<Term::Fabulous::Widget::PieChart>.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::DonutChart->new(%parameters);

The parameters of L<Term::Fabulous::Widget::PieChart/CONSTRUCTOR>, with
C<hole> defaulting to 0.6.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::DonutChart as DonutChart

	DonutChart "sales" {
		hole 0.5
		center_text "Orders"
		slice "Europe" 412000
		slice "Asia" 290000
	}

See L<Term::Fabulous::Widget::PieChart/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::PieChart>, L<Term::Fabulous::Widget::Chart>,
L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/Show shares as a pie or donut (PieChart, DonutChart)>,
the example programs F<examples/widgets/donut-chart.pl> and
F<examples/widgets/donut-chart-centers.pl>.

=cut
