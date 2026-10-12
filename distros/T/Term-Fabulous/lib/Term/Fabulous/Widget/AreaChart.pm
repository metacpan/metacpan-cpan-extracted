package Term::Fabulous::Widget::AreaChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::XYChart;

class Term::Fabulous::Widget::AreaChart :isa(Term::Fabulous::Widget::XYChart) :strict(params) {
	method default_series_type () { return 'area' }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::AreaChart - Lines with the area below them filled

=head1 SYNOPSIS

	use Term::Fabulous::Widget::AreaChart;

	my $chart = Term::Fabulous::Widget::AreaChart->new(
		title   => 'Traffic by source',
		stacked => 1,
		curve   => 'monotone',
		labels  => [qw(Mon Tue Wed Thu Fri Sat Sun)],
		series  => [
			{ name => 'Search', data => [ 420, 460, 455, 510, 480, 300, 280 ] },
			{ name => 'Social', data => [ 180, 150, 210, 260, 300, 340, 310 ] },
			{ name => 'Direct', data => [ 120, 130, 125, 140, 135, 110, 100 ] },
		],
	);

	$chart->stacked('percent');    # each day as shares of 100%

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-area-chart.svg" alt="Three stacked areas for Search, Social and Direct over the months of a year, with a title and a legend at the top"></p>

=end html

The program is F<examples/widgets/area-chart.pl>.

=head1 DESCRIPTION

An area chart is a line chart whose series are filled down to the
baseline, in block characters placed to an eighth of a cell, translucent
so that overlapping areas show through each other: 0.6 of the color
over the background, 0.8 when the areas are stacked. With C<stacked> the areas lie on each other and show
how parts add up to a whole; C<< stacked =E<gt> 'percent' >> shows the
shares. The y axis includes zero, where the areas grow from.

An area has no line along its top by default; C<< line =E<gt> 1 >>
adds one in Braille dots. C<fill_opacity> sets the translucency,
C<curve> the shape of the top. Everything else is described on
L<Term::Fabulous::Widget::XYChart>; an AreaChart is an XYChart whose
series are C<area> series unless they say otherwise.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::AreaChart->new(%parameters);

The parameters of L<Term::Fabulous::Widget::XYChart/CONSTRUCTOR> and
L<Term::Fabulous::Widget::Chart/CONSTRUCTOR>. For areas: C<stacked>,
C<fill_opacity>, C<line>, C<curve>, C<marker> (C<block> by default).

=head1 METHODS

Those of L<Term::Fabulous::Widget::XYChart/METHODS>.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::AreaChart as AreaChart

	AreaChart "traffic" {
		stacked #true
		curve "monotone"
		labels "Mon" "Tue" "Wed"
		series "Search" { data 420 460 455 }
		series "Social" { data 180 150 210 }
	}

See L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>, L<Term::Fabulous::Widget::LineChart>,
L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/Stacked areas and shares of 100% (AreaChart)>.

=cut
