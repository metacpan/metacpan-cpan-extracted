package Term::Fabulous::Chart::Scale::Log;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Chart::Scale;

class Term::Fabulous::Chart::Scale::Log :isa(Term::Fabulous::Chart::Scale) {
	use Carp qw(croak);
	use List::Util ();
	use POSIX qw(ceil floor);
	use Term::Fabulous::Chart::Format qw(number_formatter format_value);

	use constant EPSILON => 1e-9;

	field $base :param :reader;

	method kind () { return 'log' }

	method _log ($value) {
		return log($value) / log($base);
	}

	method position ($value) {
		return undef unless defined $value && $value > 0;
		my ( $low, $high ) = map { $self->_log($_) } $self->min, $self->max;
		return ( $self->_log($value) - $low ) / ( $high - $low );
	}

	method value_at ($position) {
		my ( $low, $high ) = map { $self->_log($_) } $self->min, $self->max;
		return $base**( $low + $position * ( $high - $low ) );
	}

	method fit :common (%options) {
		my $cells = $options{cells} // croak "$class: fit needs cells";
		croak "$class: cells must be a positive integer, got $cells" unless $cells =~ /\A[1-9][0-9]*\z/;
		my $base = $options{base} // 10;
		croak "$class: base must be a number greater than 1, got $base" unless $base > 1;
		my ( $fixed_low, $fixed_high ) = @options{qw(min max)};
		foreach my $end ( [ min => $fixed_low ], [ max => $fixed_high ] ) {
			croak "$class: $end->[0] of a logarithmic axis must be greater than 0, got $end->[1]" if defined $end->[1] && $end->[1] <= 0;
		}
		croak "$class: min ($fixed_low) must be less than max ($fixed_high)" if defined $fixed_low && defined $fixed_high && $fixed_low >= $fixed_high;
		my $vertical  = ( $options{orientation} // 'vertical' ) eq 'vertical';
		my $logarithm = sub ($value) { log($value) / log($base) };

		my ( $low, $high ) = $options{extent} ? $options{extent}->@* : ( 1, $base );
		$low  = $fixed_low if defined $fixed_low;
		$high = $fixed_high if defined $fixed_high;
		( $low, $high ) = defined $fixed_high && !defined $fixed_low ? ( $high / $base, $high ) : ( $low, $low * $base ) if $high <= $low;    # a fixed end stays

		my $first = defined $fixed_low  ? $logarithm->($low)  : floor( $logarithm->($low) + EPSILON );
		my $last  = defined $fixed_high ? $logarithm->($high) : ceil( $logarithm->($high) - EPSILON );
		$last = $first + 1 if $last <= $first;
		my ( $domain_low, $domain_high ) = ( $base**$first, $base**$last );

		my @powers       = grep { $_ >= $first - EPSILON && $_ <= $last + EPSILON } ceil( $first - EPSILON ) .. floor( $last + EPSILON );
		my $decades      = @powers - 1;
		my $spans_domain = @powers && abs( $powers[0] - $first ) < EPSILON && abs( $powers[-1] - $last ) < EPSILON && $decades > 0;
		my $per_decade   = $spans_domain                     ? floor( ( $cells - 1 ) / $decades ) : 0;
		my $used         = $spans_domain && $per_decade >= 1 ? $decades * $per_decade + 1         : $cells;

		# Label every power when there is room, else every second or third.
		my $format  = $options{format};
		my $measure = $options{measure} // sub ($label) { length $label };
		my @values  = map { $base**$_ } @powers;
		my @labels  = map { _label( $format, $_ ) } @values;
		my $room    = $vertical ? 2 : 2 + List::Util::max( 1, map { $measure->($_) } @labels );
		my $stride  = 1;
		$stride++ while @powers > 1 && ( $cells - 1 ) * $stride / ( $last - $first ) < $room && $stride < @powers;
		my @ticks = map { { value => $values[$_], label => $labels[$_] } } grep { ( $powers[$_] - $powers[0] ) % $stride == 0 } 0 .. $#powers;

		return $class->new( min => $domain_low, max => $domain_high, cells => $cells, used => $used, base => $base, ticks => \@ticks );
	}

	# Powers from 1 up are written with SI prefixes (1k, 10k), smaller
	# ones as decimals (0.01).
	sub _label ( $format, $value ) {
		return number_formatter( $format, $value, $value )->($value) if defined $format;
		return format_value( $value, 'si' ) if $value >= 1;
		my $text = sprintf '%.10f', $value;
		$text =~ s/0+\z//;
		return $text;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Scale::Log - A logarithmic numeric axis

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Scale::Log;

	my $scale = Term::Fabulous::Chart::Scale::Log->fit( extent => [ 3, 42_000 ], cells => 17 );
	say join ' ', map { $_->{label} } $scale->ticks;    # 1 10 100 1k 10k 100k

=head1 DESCRIPTION

A L<Term::Fabulous::Chart::Scale> on which every power of the base
(10 by default) is the same distance from the next one, so values that
span several orders of magnitude, or grow by a constant factor, can be
read. Its domain runs from the power at or below the smallest value to
the power at or above the largest. The ticks are the powers; where they
would crowd, only every second (third, ...) power is labeled.

Values of zero or below have no position on a logarithmic axis; charts
leave them out (a line has a gap there).

=head1 CLASS METHODS

=head2 fit

	my $scale = Term::Fabulous::Chart::Scale::Log->fit(%options);

Takes C<cells>, C<extent>, C<min>, C<max>, C<orientation>, C<measure> and
C<format> like L<Term::Fabulous::Chart::Scale::Linear/fit> (the format
defaults to C<si>), and C<base>, a number greater than 1 (default 10).
C<min> and C<max> must be greater than 0. A fixed end is kept also when
the data lies beyond it: the other end then moves a power of the base
away from it.

=head1 METHODS

Those of L<Term::Fabulous::Chart::Scale>, and C<base>.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Scale>.

=cut
