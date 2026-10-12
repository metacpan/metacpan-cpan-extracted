package Term::Fabulous::Widget::PolarAreaChart;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::PieChart;

class Term::Fabulous::Widget::PolarAreaChart
	:isa(Term::Fabulous::Widget::PieChart)
	:strict(params)
{
	use List::Util ();
	use POSIX qw(floor);
	use Term::Fabulous::Chart::Format qw(check_number_format);
	use Term::Fabulous::Chart::Marker;
	use Term::Fabulous::Chart::Palette qw(contrast_rgb);
	use Term::Fabulous::Chart::Radial qw(CELL_ASPECT TAU point_at);
	use Term::Fabulous::Chart::Raster;
	use Term::Fabulous::Chart::Scale::Linear;
	use Term::Fabulous::Chart::Surface;

	field $max   :param = undef;    # the value at the outer ring; undef: from the data
	field $ticks :param = undef;    # the number of rings wanted
	field $_scale;    # the scale of the frame being drawn

	ADJUST {
		$self->_fail( 'max',   'a positive number or undef',  $max ) if defined $max     && !( !ref $max && $max   =~ /\A[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?\z/ && $max > 0 );
		$self->_fail( 'ticks', 'a positive integer or undef', $ticks ) if defined $ticks && ( ref $ticks || $ticks !~ /\A[1-9][0-9]*\z/ );
	}

	# The rings show the values; the legend repeats them.
	method default_slice_labels  :override () { return 'none' }
	method default_legend_values :override () { return 'value' }

	method max (@new) {
		return $max unless @new;
		$self->_fail( 'max', 'a positive number or undef', $new[0] ) if defined $new[0] && !( !ref $new[0] && $new[0] =~ /\A[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?\z/ && $new[0] > 0 );
		$max = $new[0];
		$self->mark_changed;
		return $max;
	}

	method ticks (@new) {
		return $ticks unless @new;
		$self->_fail( 'ticks', 'a positive integer or undef', $new[0] ) if defined $new[0] && ( ref $new[0] || $new[0] !~ /\A[1-9][0-9]*\z/ );
		$ticks = $new[0];
		$self->mark_changed;
		return $ticks;
	}

	# Every slice gets the same angle; its value decides how far out it
	# reaches.
	method slice_geometry :override ( $look, @slices ) {
		my $count = @slices;
		my $outer = $_scale ? $_scale->max : List::Util::max( map { $_->{value} } @slices );
		return map { [ $_ / $count, ( $_ + 1 ) / $count, $outer ? $slices[$_]{value} / $outer : 0 ] } 0 .. $#slices;
	}

	# Rings at the ticks of the value scale, behind the slices.
	method draw_background_grid :override ( $surface, $x, $y, $width, $height, $circle, $look, $slices ) {

		# Rings about every three rows (six cell widths) apart.
		my $rows = List::Util::max( 2, floor( $circle->{radius} / 1.5 ) + 1 );
		$_scale = Term::Fabulous::Chart::Scale::Linear->fit(
			extent => [ 0, List::Util::max( map { $_->{value} } @$slices ) ],
			cells  => $rows,
			zero   => 1,
			align  => 0,
			format => $self->format,
			( defined $max   ? ( max   => $max )   : () ),
			( defined $ticks ? ( ticks => $ticks ) : () ),
		);
		my $raster = Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named('braille'), columns => $width, rows => $height );
		foreach my $tick ( $_scale->ticks ) {
			next unless $tick->{value} > 0;
			my $distance = $tick->{position} * $circle->{radius};
			my $steps    = List::Util::max( 24, floor( TAU * $distance * 2 ) );
			my @points   = map { [ point_at( $circle, $distance, $_ / $steps ) ] } 0 .. $steps;
			$raster->line( $points[ $_ - 1 ][0] * 2, $points[ $_ - 1 ][1] * 4, $points[$_][0] * 2, $points[$_][1] * 4, $look->{grid} ) foreach 1 .. $#points;
		}
		$surface->composite( $raster, 'stroke', $x, $y );
		return;
	}

	# The values of the rings along the line to 12 o'clock.
	method draw_foreground_grid :override ( $surface, $x, $y, $width, $height, $circle, $look, $slices ) {
		my $last_row;
		foreach my $tick ( reverse $_scale->ticks ) {
			next unless $tick->{value} > 0;
			my ( $at_x,   $at_y ) = point_at( $circle, $tick->{position} * $circle->{radius}, 0 );
			my ( $column, $row )  = ( floor($at_x) + 1, floor($at_y) );
			next if defined $last_row && $row <= $last_row;
			my $under = $surface->bg_at( $x + $column, $y + $row );
			my $color = defined $under && ( !defined $look->{background} || $under != $look->{background} ) ? contrast_rgb($under) : $look->{label};
			$surface->text( $x + $column, $y + $row, $tick->{label}, $color, max => $width - $column );
			$last_row = $row;
		}
		$_scale = undef;
		return;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, max => 'scalar', ticks => 'scalar' );
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::PolarAreaChart - Slices of equal angle whose
length shows their value

=head1 SYNOPSIS

	use Term::Fabulous::Widget::PolarAreaChart;

	my $chart = Term::Fabulous::Widget::PolarAreaChart->new(
		title => 'Commits by weekday',
		data  => [ [ Monday => 34 ], [ Tuesday => 41 ], [ Wednesday => 38 ], [ Thursday => 45 ], [ Friday => 29 ], [ Saturday => 9 ], [ Sunday => 6 ] ],
	);

	$chart->max(50);      # the value of the outer ring
	$chart->ticks(5);     # about five rings

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-polar-area-chart.svg" alt="Seven slices of equal angle for the weekdays, each reaching out as far as its value, over dotted rings labeled with their values"></p>

=end html

F<examples/widgets/polar-area-chart.pl> draws this chart.

=head1 DESCRIPTION

A polar area chart (a Nightingale rose) gives every slice the same angle
and lets its value decide how far from the center it reaches, so values
of the same kind, such as counts per month or per weekday, compare by
length and by area around a circle. Dotted rings mark round values
behind the slices, and the value of each ring is written along the line
to 12 o'clock; the legend on the right lists the slices with their
values.

It is a L<Term::Fabulous::Widget::PieChart>: the data forms, C<sort>,
C<other>, C<start_angle>, C<gap>, C<marker>, C<format>, the methods and
events are the same, except that the slices show no labels by default
(C<slice_labels> is C<none>, the rings tell the values) and the legend
shows the values (C<legend_values> is C<value>). The ring values are
written with the chart's C<format>. Hover reports a slice as in a pie
chart: its label as the series and the label, its value as the value.

Use it for values of one kind over categories that form a cycle (hours,
weekdays, months, compass directions); for parts of a whole use a
L<Term::Fabulous::Widget::PieChart>, and to compare several series over
the same categories a L<Term::Fabulous::Widget::RadarChart>.

=head1 CONSTRUCTOR

=head2 new

	my $chart = Term::Fabulous::Widget::PolarAreaChart->new(%parameters);

The parameters of L<Term::Fabulous::Widget::PieChart/CONSTRUCTOR>, and:

=over

=item C<max>

A positive number: the value at the outer edge; a slice of this value
reaches the edge. Default: C<undef>, a round value at or above the
largest slice. A slice larger than C<max> is cut at the edge.

=item C<ticks>

A positive integer: about how many rings you want; the chart picks the
round step that comes closest. Default: C<undef>, which spaces the rings
two to three rows apart, so a larger chart has more of them.

=back

=head1 METHODS

C<max> and C<ticks> read and set the parameters (C<undef> restores the
default; an invalid value dies and changes nothing), and the methods of
L<Term::Fabulous::Widget::PieChart/METHODS> manage the slices.

	$chart->max(undef);    # from the data again

=head1 KDL PROPERTIES

=for highlighter language=kdl

	use Term::Fabulous::Widget::PolarAreaChart as PolarAreaChart

	PolarAreaChart "commits" {
		max 50
		ticks 5
		slice "Monday" 34
		slice "Tuesday" 41
	}

C<max> and C<ticks> as the parameters, and the properties of
L<Term::Fabulous::Widget::PieChart/KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::PieChart>, L<Term::Fabulous::Widget::RadarChart>,
L<Term::Fabulous::Widget::Chart>, L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Cookbook::Charts/Compare profiles on radar and polar area charts (RadarChart, PolarAreaChart)>,
the example program F<examples/widgets/polar-area-chart.pl>.

=cut
