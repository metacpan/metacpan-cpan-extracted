package Term::Fabulous::Chart::Scale::Category;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Chart::Scale;

class Term::Fabulous::Chart::Scale::Category :isa(Term::Fabulous::Chart::Scale) {
	use Carp qw(croak);
	use List::Util ();
	use POSIX qw(ceil);

	use constant SHORTEST_CUT_LABEL => 4;

	field $labels :param;
	field $band   :param = 1;
	field $offset :param = 0;    # cells before the first slot
	field $pitch  :param = undef;    # cells per slot; undef: the cells shared evenly

	method kind () { return 'category' }

	method is_band () {
		return $band;
	}

	method labels () {
		return @$labels;
	}

	method count () {
		return scalar @$labels;
	}

	# The label of category number $index (from 0); undef past the last.
	method label_at ($index) {
		return $labels->[$index];
	}

	# The position of category number $index (from 0).
	method position ($index) {
		my $count = @$labels || 1;
		return ( $offset + ( $index + 0.5 ) * $self->slot_cells ) / $self->cells if $band;
		return $count > 1 ? $index / ( $count - 1 ) : 0.5;
	}

	method value_at ($position) {
		my $count = @$labels || 1;
		return ( $position * $self->cells - $offset ) / $self->slot_cells - 0.5 if $band;
		return $position * ( $count - 1 );
	}

	# The cells one category's slot takes.
	method slot_cells () {
		my $count = @$labels || 1;
		return $pitch // $self->cells / $count if $band;
		return $count > 1 ? ( $self->cells - 1 ) / ( $count - 1 ) : $self->cells;
	}

	# Every category is a tick. On a horizontal axis whose slots are too
	# narrow for the labels, only every second (third, ...) one is
	# labeled; labels that are only a little too wide are cut by the chart.
	method fit :common (%options) {
		my $cells = $options{cells} // croak "$class: fit needs cells";
		croak "$class: cells must be a positive integer, got $cells" unless $cells =~ /\A[1-9][0-9]*\z/;
		my @labels   = ( $options{labels} // [] )->@*;
		my $band     = $options{band}    // 1;
		my $measure  = $options{measure} // sub ($label) { length $label };
		my $vertical = ( $options{orientation} // 'horizontal' ) eq 'vertical';

		my $count = @labels || 1;
		my $slot  = $band ? $cells / $count : ( $count > 1 ? ( $cells - 1 ) / ( $count - 1 ) : $cells );

		# Slots of whole cells keep the gaps between bars equal; the cells
		# left over go to both ends, unless that wastes too much room.
		my ( $pitch, $offset ) = ( undef, 0 );
		if ( $band && $slot >= 1 ) {
			my $whole = int $slot;
			my $spare = $cells - $whole * $count;
			( $pitch, $offset, $slot ) = ( $whole, int( $spare / 2 ), $whole ) if $spare <= List::Util::max( 3, $cells / 5 );
		}
		my $widest = List::Util::max( 0, map { $measure->($_) } @labels );
		my $stride = 1;
		if ( !$vertical && $widest + 1 > $slot && $slot < SHORTEST_CUT_LABEL + 1 ) {
			$stride = ceil( ( List::Util::min( $widest, SHORTEST_CUT_LABEL ) + 1 ) / ( $slot || 1 ) );
		}
		elsif ( $vertical && $slot < 1 ) {
			$stride = ceil( 1 / $slot );
		}
		my @ticks = map { { value => $_, label => $labels[$_] } } grep { $_ % $stride == 0 } 0 .. $#labels;
		return $class->new( min => 0, max => List::Util::max( 0, $#labels ), cells => $cells, used => $cells, labels => \@labels, band => $band, pitch => $pitch, offset => $offset, ticks => \@ticks );
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Scale::Category - An axis of named categories

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Scale::Category;

	my $scale = Term::Fabulous::Chart::Scale::Category->fit( labels => [qw(Jan Feb Mar)], cells => 30 );
	say $scale->position(1);     # 0.5: the middle of the second slot
	say $scale->slot_cells;      # 10

=head1 DESCRIPTION

A L<Term::Fabulous::Chart::Scale> for labels such as months, products or
names. The values are the category numbers, from 0. A I<band> scale (the
default, and what bar charts use) gives each category an equal slot and
places it at the slot's middle; the slots are whole cells wide when the
cells left over (shared by both ends of the axis) are few, so the gaps
between bars are all equal. A I<point> scale places the first category
at the start of the axis and the last at its end, as line charts of
categories do.

Every category is a tick. When the labels do not fit beside each other,
only every second (third, ...) category is labeled.

=head1 CLASS METHODS

=head2 fit

	my $scale = Term::Fabulous::Chart::Scale::Category->fit( labels => \@labels, cells => $cells, band => 1 );

C<cells> is required; C<labels> defaults to none, C<band> to true (false
makes a point scale). Also takes C<orientation> (default C<horizontal>)
and C<measure> like L<Term::Fabulous::Chart::Scale::Linear/fit>. The
labels are shown as they are: a category scale takes no C<format>.

=head1 METHODS

Those of L<Term::Fabulous::Chart::Scale>, and:

=head2 labels, count

The labels and their number.

=head2 label_at

	my $label = $scale->label_at($index);

The label of category number C<$index> (from 0), or C<undef> when there
is no such category.

=head2 slot_cells

The cells one category takes along the axis; it can be a fraction.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Scale>.

=cut
