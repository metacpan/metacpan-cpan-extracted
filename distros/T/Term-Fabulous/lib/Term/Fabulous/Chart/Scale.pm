package Term::Fabulous::Chart::Scale;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::Chart::Scale :abstract {
	field $min   :param :reader;
	field $max   :param :reader;
	field $cells :param :reader;    # the cells the axis was fitted to
	field $used  :param :reader;    # the cells its ticks span (at most cells)
	field $ticks :param = [];    # [ { value, label } ], in order

	# Where a value lies on the axis: 0 at min, 1 at max (outside for
	# values outside), undef for values the scale cannot show.
	method position;

	method kind;

	method value_at;

	method ticks () {
		return map {
			{ %$_, position => $self->position( $_->{value} ) }
		} @$ticks;
	}

	method tick_count () {
		return scalar @$ticks;
	}

	# A band scale gives each value a slot; the others place values on
	# points.
	method is_band () {
		return 0;
	}

	method contains ($value) {
		my $position = $self->position($value) // return 0;
		return $position >= -1e-9 && $position <= 1 + 1e-9 ? 1 : 0;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Scale - What the scales of chart axes have in
common

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Scale::Linear;

	my $scale = Term::Fabulous::Chart::Scale::Linear->fit( extent => [ 3, 97 ], cells => 21 );
	say $scale->min, ' .. ', $scale->max;                  # 0 .. 100
	say join ' ', map { $_->{label} } $scale->ticks;      # 0 25 50 75 100
	say $scale->position(50);                             # 0.5

=head1 DESCRIPTION

A scale maps the values of one axis to positions from 0 (the start of the
axis) to 1 (its end) and chooses the ticks shown on it. The chart widgets
fit a scale to the data and to the cells the axis has every time they are
drawn:

=over

=item L<Term::Fabulous::Chart::Scale::Linear>

Numbers, evenly spaced ticks at "nice" numbers (1, 2, 2.5 and 5 times a
power of ten).

=item L<Term::Fabulous::Chart::Scale::Log>

Positive numbers on a logarithmic axis, ticks at the powers of the base.

=item L<Term::Fabulous::Chart::Scale::Time>

Points in time (epoch seconds), ticks at calendar boundaries: whole
minutes, hours, days, months, years.

=item L<Term::Fabulous::Chart::Scale::Category>

Labels, one slot each.

=back

=head1 METHODS

=head2 min, max

The domain: the values at position 0 and 1.

=head2 position

	my $t = $scale->position($value);

0 for C<min>, 1 for C<max>, values in between in between; values outside
the domain lie outside 0 to 1. C<undef> for a value the scale cannot show
(zero or less on a logarithmic scale).

=head2 value_at

The value at a position; the inverse of C<position>.

=head2 ticks

	foreach my $tick ( $scale->ticks ) {
		my ( $value, $label, $position ) = @$tick{qw(value label position)};
	}

The ticks in order, as hashes with the value, its label and its position.

=head2 tick_count

The number of ticks.

=head2 cells, used

The number of cells the scale was fitted to, and the number of cells its
ticks span: scales whose ticks are evenly spaced choose them so that each
tick falls on a whole cell, and then may span fewer cells than they were
given. The chart lays the axis out over C<used> cells, so every grid line
lies exactly at its label.

=head2 is_band

True for scales that give each value a slot (categories) instead of a
point.

=head2 contains

True when a value lies within the domain.

=head2 kind

C<linear>, C<log>, C<time> or C<category>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart>.

=cut
