package Term::Fabulous::Chart::Scale::Linear;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Chart::Scale;

class Term::Fabulous::Chart::Scale::Linear :isa(Term::Fabulous::Chart::Scale) {
	use Carp qw(croak);
	use List::Util ();
	use POSIX qw(ceil floor);
	use Term::Fabulous::Chart::Format qw(number_formatter);

	use constant {
		EPSILON    => 1e-9,
		MOST_TICKS => 10_000,    # more never fit an axis; a step that needs them is skipped
	};

	field $step :param :reader;

	method kind () { return 'linear' }

	method position ($value) {
		my ( $low, $high ) = ( $self->min, $self->max );
		return ( $value - $low ) / ( $high - $low );
	}

	method value_at ($position) {
		return $self->min + $position * ( $self->max - $self->min );
	}

	# The nice steps (1, 2, 2.5 and 5 times a power of ten) between two
	# sizes. Whole-number data takes no steps below 1 and no 2.5 below 25.
	sub _nice_steps ( $smallest, $largest, $integer ) {
		my @steps;
		foreach my $exponent ( floor( log($smallest) / log(10) ) - 1 .. ceil( log($largest) / log(10) ) + 1 ) {
			foreach my $mantissa ( 1, 2, 2.5, 5 ) {
				my $step = $mantissa * 10**$exponent;
				next if $integer && ( $step < 1 || ( $mantissa == 2.5 && $step < 25 ) );
				push @steps, $step if $step >= $smallest * ( 1 - EPSILON ) && $step <= $largest * ( 1 + EPSILON );
			}
		}
		return @steps;
	}

	# The multiples of $step from $low to $high; none when there would be
	# more than MOST_TICKS.
	sub _multiples ( $low, $high, $step ) {
		my $first = ceil( $low / $step - EPSILON );
		return () if floor( $high / $step + EPSILON ) - $first + 1 > MOST_TICKS;
		my @values;
		for ( my $index = $first; $index * $step <= $high + $step * EPSILON; $index++ ) {
			my $value = $index * $step;
			push @values, abs($value) < $step * EPSILON ? 0 : $value;
		}
		return @values;
	}

	# Fits a scale to data and to the cells of an axis. See the POD.
	method fit :common (%options) {
		my $cells = $options{cells} // croak "$class: fit needs cells";
		croak "$class: cells must be a positive integer, got $cells" unless $cells =~ /\A[1-9][0-9]*\z/;
		my $vertical = ( $options{orientation} // 'vertical' ) eq 'vertical';
		my $align    = $options{align} // $vertical;
		my ( $fixed_low, $fixed_high ) = @options{qw(min max)};
		croak "$class: min ($fixed_low) must be less than max ($fixed_high)" if defined $fixed_low && defined $fixed_high && $fixed_low >= $fixed_high;

		my ( $low, $high ) = $options{extent} ? $options{extent}->@* : ( 0, 1 );
		( $low, $high ) = ( List::Util::min( $low, 0 ), List::Util::max( $high, 0 ) ) if $options{zero};
		$low  = $fixed_low if defined $fixed_low;
		$high = $fixed_high if defined $fixed_high;
		( $low, $high ) = _widened( $low, $high, $fixed_low, $fixed_high ) if $high <= $low;

		my $measure = $options{measure} // sub ($label) { length $label };
		my @steps
			= defined $options{step}
			? ( $options{step} )
			: _nice_steps( ( $high - $low ) / List::Util::max( 1, $cells - 1 ), $high - $low, $options{integer} );
		my $wanted_ticks = $options{ticks};

		my $best;
		foreach my $step (@steps) {
			next if ( $high - $low ) / $step > $cells;    # more intervals than cells: no tick could get a cell of its own
			my $candidate = _candidate( $low, $high, $step, $fixed_low, $fixed_high, $options{nice} // 1 ) // next;
			my ( $domain_low, $domain_high, $values ) = @$candidate{qw(low high values)};
			my $intervals = @$values - 1;
			next if $intervals < 1;

			my $format = number_formatter( $options{format}, $step, List::Util::max( map { abs } @$values ) );
			my @labels = map { $format->($_) } @$values;
			my $widest = List::Util::max( map { $measure->($_) } @labels );
			my ( $least, $ideal );
			if ($vertical) {
				( $least, $ideal ) = ( $cells >= 8 ? 2 : 1, $cells >= 8 ? List::Util::min( 6, List::Util::max( 3, $cells / 4 ) ) : 2 );
			}
			else {
				( $least, $ideal ) = ( $widest + 2, List::Util::max( $widest + 4, 10 ) );
			}
			my $headroom = ( ( $domain_high - $domain_low ) - ( $high - $low ) ) / ( $domain_high - $domain_low );

			# Evenly spaced ticks from end to end land on whole cells when the
			# axis spans a multiple of the intervals, which may leave a few
			# cells unused. Ticks that do not span the domain (a fixed end
			# between two of them) are placed as near as they can be.
			my $spans_domain = abs( $values->[0] - $domain_low ) < $step * EPSILON && abs( $values->[-1] - $domain_high ) < $step * EPSILON;
			my ( $per_interval, $used )
				= $align && $spans_domain
				? ( floor( ( $cells - 1 ) / $intervals ), $intervals * floor( ( $cells - 1 ) / $intervals ) + 1 )
				: ( ( $cells - 1 ) * ( $values->[-1] - $values->[0] ) / ( $domain_high - $domain_low ) / $intervals, $cells );
			next if $per_interval < 1 || ( $per_interval < $least && !defined $options{step} );
			my $waste   = ( $cells - $used ) / $cells;
			my $density = defined $wanted_ticks ? abs( @$values - $wanted_ticks ) / $wanted_ticks : abs( log( $per_interval / $ideal ) );
			my $score   = 3 * $waste + 3 * $headroom + $density + ( @$values < 3 && $cells >= 6 ? 0.5 : 0 );
			$best = { score => $score, step => $step, low => $domain_low, high => $domain_high, used => $used, values => $values, labels => \@labels }
				if !defined $best || $score < $best->{score} - EPSILON;
		}

		# Too little room for any two ticks: the two ends.
		$best //= do {
			my $format = number_formatter( $options{format}, $high - $low, List::Util::max( abs $low, abs $high ) );
			{ step => $high - $low, low => $low, high => $high, used => $cells, values => [ $low, $high ], labels => [ map { $format->($_) } $low, $high ] };
		};
		my @ticks = map { { value => $best->{values}[$_], label => $best->{labels}[$_] } } 0 .. $best->{values}->$#*;
		return $class->new( min => $best->{low}, max => $best->{high}, cells => $cells, used => $best->{used}, step => $best->{step}, ticks => \@ticks );
	}

	sub _widened ( $low, $high, $fixed_low, $fixed_high ) {
		my $margin = $low == 0 ? 1 : abs($low) / 10;
		return ( $low,            $low + $margin ) if defined $fixed_low;
		return ( $high - $margin, $high ) if defined $fixed_high;
		return $low == 0 ? ( 0, 1 ) : ( $low - $margin, $high + $margin );
	}

	sub _candidate ( $low, $high, $step, $fixed_low, $fixed_high, $nice ) {
		my $domain_low  = defined $fixed_low  || !$nice ? $low  : floor( $low / $step + EPSILON ) * $step;
		my $domain_high = defined $fixed_high || !$nice ? $high : ceil( $high / $step - EPSILON ) * $step;
		$domain_high += $step if $domain_high <= $domain_low;
		my @values = _multiples( $domain_low, $domain_high, $step );
		return undef unless @values;
		return { low => $domain_low, high => $domain_high, values => \@values };
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Scale::Linear - A numeric axis with evenly spaced
ticks

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Scale::Linear;

	# A vertical axis of 17 rows for data from 3 to 97:
	my $scale = Term::Fabulous::Chart::Scale::Linear->fit( extent => [ 3, 97 ], cells => 17 );
	say join ' ', map { $_->{label} } $scale->ticks;    # 0 25 50 75 100
	say $scale->used;                                   # 17: a tick every 4 rows

=head1 DESCRIPTION

A L<Term::Fabulous::Chart::Scale> for numbers. L</fit> chooses the domain
and the ticks: the ticks are multiples of a nice step (1, 2, 2.5 or 5
times a power of ten), the domain is the data rounded out to the nearest
ticks, and the choice balances

=over

=item * that the ticks fall on whole cells, so that grid lines lie
exactly beside their labels and at the height of the values they name
(an axis may then use a few cells less than it has),

=item * how much empty room the rounding adds above and below the data,

=item * and a comfortable distance between the ticks: about every three
to six rows on a vertical axis, and on a horizontal axis far enough apart
that the labels do not touch.

=back

=head1 CLASS METHODS

=head2 fit

	my $scale = Term::Fabulous::Chart::Scale::Linear->fit(%options);

=over

=item C<cells>

The cells the axis has, a positive integer; required.

=item C<extent>

C<[ $lowest, $highest ]> value of the data; C<undef> for no data (the
axis then shows 0 to 1).

=item C<min>, C<max>

Fixed ends of the domain. A fixed end is not rounded. C<min> must be
less than C<max>, or C<fit> dies.

=item C<zero>

True to include 0 in the domain (bars and areas grow from 0).

=item C<orientation>

C<vertical> (the default) or C<horizontal>; a horizontal axis spaces its
ticks by the width of their labels.

=item C<measure>

A function returning the columns a label takes; for horizontal axes.

=item C<format>

The label format (see L<Term::Fabulous::Chart::Format>).

=item C<step>

A fixed distance between ticks. A step too small for the cells (more
intervals across the data than the axis has cells) gives no ticks
between the two ends, as when nothing else fits.

=item C<ticks>

The number of ticks wanted; the closest fitting choice wins.

=item C<integer>

True when all values are whole numbers: no ticks less than 1 apart
(and no steps of 2.5 below 25), so no tick lies between two whole
numbers.

=item C<nice>

False to keep the domain at the data instead of rounding it to ticks.

=item C<align>

True to choose ticks that fall on whole cells, at the price of a few
unused cells at the end of the axis; the default for vertical axes,
where every tick has a grid line and a label beside it.

=back

=head1 METHODS

Those of L<Term::Fabulous::Chart::Scale>, and C<step>, the distance
between two ticks.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Scale>.

=cut
