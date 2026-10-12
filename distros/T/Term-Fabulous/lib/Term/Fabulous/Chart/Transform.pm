package Term::Fabulous::Chart::Transform;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(parse_transforms apply_transforms transform_names);

use Carp qw(croak);
use List::Util qw(max min sum0 first);
use POSIX qw(floor);
use Scalar::Util qw(looks_like_number);
use Term::Fabulous::Check qw(describe);

sub _is_number ($value) {
	return defined $value && !ref $value && looks_like_number($value) && $value == $value && $value - $value == 0;
}

sub _defined_ys ($ys) {
	return grep { defined } @$ys;
}

# Each transform: the arguments it takes [ least, most, defaults ], a
# check of them, and a function from (xs, ys, args) to new (xs, ys).
my %TRANSFORM = (
	normalize => {
		arguments => [ 0, 2, [ 0, 1 ] ],
		apply     => sub ( $xs, $ys, $low, $high ) {
			my @values = _defined_ys($ys) or return ( $xs, $ys );
			my ( $least, $most ) = ( min(@values), max(@values) );
			my $range = $most - $least;
			return ( $xs, [ map { defined ? ( $range ? $low + ( $_ - $least ) / $range * ( $high - $low ) : $low ) : undef } @$ys ] );
		},
	},
	share => {
		arguments => [ 0, 0, [] ],
		apply     => sub ( $xs, $ys ) {
			my $total = sum0( map { abs } _defined_ys($ys) );
			return ( $xs, [ map { defined && $total ? $_ / $total : defined ? 0 : undef } @$ys ] );
		},
	},
	zscore => {
		arguments => [ 0, 0, [] ],
		apply     => sub ( $xs, $ys ) {
			my @values    = _defined_ys($ys) or return ( $xs, $ys );
			my $mean      = sum0(@values) / @values;
			my $deviation = sqrt( sum0( map { ( $_ - $mean )**2 } @values ) / @values );
			return ( $xs, [ map { defined ? ( $deviation ? ( $_ - $mean ) / $deviation : 0 ) : undef } @$ys ] );
		},
	},
	index => {
		arguments => [ 0, 1, [100] ],
		apply     => sub ( $xs, $ys, $base ) {
			my $start = first { defined && $_ != 0 } @$ys;
			return ( $xs, [ map { defined && defined $start ? $_ / $start * $base : undef } @$ys ] );
		},
	},
	cumulative => {
		arguments => [ 0, 0, [] ],
		apply     => sub ( $xs, $ys ) {
			my $total = 0;
			return ( $xs, [ map { defined ? ( $total += $_ ) : undef } @$ys ] );
		},
	},
	difference => {
		arguments => [ 0, 0, [] ],
		apply     => sub ( $xs, $ys ) {
			my $previous;
			return ( $xs, [ map { my $change = defined $_ && defined $previous ? $_ - $previous : undef; $previous = $_ if defined; $change } @$ys ] );
		},
	},
	rate => {
		arguments => [ 0, 1, [1] ],
		apply     => sub ( $xs, $ys, $per ) {
			my ( @rates, $before );
			foreach my $index ( 0 .. $#$ys ) {
				my $y = $ys->[$index];
				push @rates, defined $y && defined $before && $xs->[$index] != $before->[0] ? ( $y - $before->[1] ) / ( $xs->[$index] - $before->[0] ) * $per : undef;
				$before = [ $xs->[$index], $y ] if defined $y;
			}
			return ( $xs, \@rates );
		},
	},
	moving_average => {
		arguments => [ 1, 2, [ undef, 'trailing' ] ],
		check     => sub ( $window, $align ) {
			return "a window of at least 1 point" unless defined $window && $window =~ /\A[1-9][0-9]*\z/;
			return "an alignment of 'trailing' or 'center'" unless $align eq 'trailing' || $align eq 'center';
			return undef;
		},
		apply => sub ( $xs, $ys, $window, $align ) {
			my ( $before, $after ) = $align eq 'center' ? ( int( ( $window - 1 ) / 2 ), $window - 1 - int( ( $window - 1 ) / 2 ) ) : ( $window - 1, 0 );
			return ( $xs, [ map { _window_mean( $ys, $_, $before, $after ) } 0 .. $#$ys ] );
		},
	},
	exponential => {
		arguments => [ 1, 1, [] ],
		check     => sub ($alpha) { _is_number($alpha) && $alpha > 0 && $alpha <= 1 ? undef : "a smoothing factor greater than 0 and at most 1" },
		apply     => sub ( $xs, $ys, $alpha ) {
			my $smooth;
			return ( $xs, [ map { defined ? ( $smooth = defined $smooth ? $alpha * $_ + ( 1 - $alpha ) * $smooth : $_ ) : undef } @$ys ] );
		},
	},
	median => {
		arguments => [ 1, 1, [] ],
		check     => sub ($window) { defined $window && $window =~ /\A[1-9][0-9]*\z/ ? undef : "a window of at least 1 point" },
		apply     => sub ( $xs, $ys, $window ) {
			my ( $before, $after ) = ( int( ( $window - 1 ) / 2 ), $window - 1 - int( ( $window - 1 ) / 2 ) );
			my @medians = map {
				my $index = $_;
				!defined $ys->[$index] ? undef : do {
					my @near = sort { $a <=> $b } grep { defined } @$ys[ max( 0, $index - $before ) .. min( $#$ys, $index + $after ) ];
					@near % 2 ? $near[ $#near / 2 ] : ( $near[ @near / 2 - 1 ] + $near[ @near / 2 ] ) / 2;
				}
			} 0 .. $#$ys;
			return ( $xs, \@medians );
		},
	},
	gaussian => {
		arguments => [ 1, 1, [] ],
		check     => sub ($sigma) { _is_number($sigma) && $sigma > 0 ? undef : "a positive standard deviation (in points)" },
		apply     => sub ( $xs, $ys, $sigma ) {
			my $reach   = int( 3 * $sigma + 0.5 );
			my @weights = map { exp( -( $_**2 ) / ( 2 * $sigma**2 ) ) } -$reach .. $reach;
			my @smooth;
			foreach my $index ( 0 .. $#$ys ) {
				if ( !defined $ys->[$index] ) { push @smooth, undef; next }
				my ( $total, $weight ) = ( 0, 0 );
				foreach my $offset ( -$reach .. $reach ) {
					next if $index + $offset < 0;
					my $y = $ys->[ $index + $offset ] // next;
					$total  += $y * $weights[ $offset + $reach ];
					$weight += $weights[ $offset + $reach ];
				}
				push @smooth, $total / $weight;
			}
			return ( $xs, \@smooth );
		},
	},
	scale => {
		arguments => [ 1, 1, [] ],
		check     => sub ($factor) { _is_number($factor) ? undef : "a number to multiply by" },
		apply     => sub ( $xs, $ys, $factor ) {
			( $xs, [ map { defined ? $_ * $factor : undef } @$ys ] )
		},
	},
	offset => {
		arguments => [ 1, 1, [] ],
		check     => sub ($amount) { _is_number($amount) ? undef : "a number to add" },
		apply     => sub ( $xs, $ys, $amount ) {
			( $xs, [ map { defined ? $_ + $amount : undef } @$ys ] )
		},
	},
	clip => {
		arguments => [ 2, 2, [] ],
		check     => sub ( $low, $high ) {
			( !defined $low || _is_number($low) )
				&& ( !defined $high || _is_number($high) )
				&& ( !defined $low || !defined $high || $low <= $high ) ? undef : "a lowest and a highest value (undef for none)";
		},
		apply => sub ( $xs, $ys, $low, $high ) {
			return ( $xs, [ map { !defined ? undef : defined $low && $_ < $low ? $low : defined $high && $_ > $high ? $high : $_ } @$ys ] );
		},
	},
	abs => {
		arguments => [ 0, 0, [] ],
		apply     => sub ( $xs, $ys ) {
			( $xs, [ map { defined ? abs : undef } @$ys ] )
		},
	},
	sort => {
		arguments => [ 0, 0, [] ],
		apply     => sub ( $xs, $ys ) {
			my @order = sort { $xs->[$a] <=> $xs->[$b] } 0 .. $#$xs;
			return ( [ @$xs[@order] ], [ @$ys[@order] ] );
		},
	},
	resample => {
		arguments => [ 1, 2, [ undef, 'mean' ] ],
		check     => sub ( $interval, $aggregate ) {
			return "a positive interval" unless _is_number($interval) && $interval > 0;
			return "an aggregate of mean, sum, min, max, first, last or count" unless $aggregate =~ /\A(?:mean|sum|min|max|first|last|count)\z/;
			return undef;
		},
		apply => sub ( $xs, $ys, $interval, $aggregate ) {
			my ( %bucket, @starts );
			foreach my $index ( 0 .. $#$xs ) {
				my $start = floor( $xs->[$index] / $interval ) * $interval;
				push @starts,              $start unless $bucket{$start};
				push @{ $bucket{$start} }, $ys->[$index] if defined $ys->[$index];
				$bucket{$start} //= [];
			}
			@starts = sort { $a <=> $b } @starts;
			return ( \@starts, [ map { _aggregate( $aggregate, $bucket{$_} ) } @starts ] );
		},
	},
	downsample => {
		arguments => [ 1, 1, [] ],
		check     => sub ($count) { defined $count && $count =~ /\A[0-9]+\z/ && $count >= 3 ? undef : "a number of points of at least 3" },
		apply     => \&_largest_triangles,
	},
	regression => {
		arguments => [ 0, 0, [] ],
		apply     => sub ( $xs, $ys ) {
			my @pairs = map { [ $xs->[$_], $ys->[$_] ] } grep { defined $ys->[$_] } 0 .. $#$xs;
			return ( $xs, [ (undef) x @$ys ] ) if @pairs < 2;
			my ( $mean_x, $mean_y ) = ( sum0( map { $_->[0] } @pairs ) / @pairs, sum0( map { $_->[1] } @pairs ) / @pairs );
			my $spread = sum0( map { ( $_->[0] - $mean_x )**2 } @pairs );
			my $slope  = $spread ? sum0( map { ( $_->[0] - $mean_x ) * ( $_->[1] - $mean_y ) } @pairs ) / $spread : 0;
			return ( $xs, [ map { $mean_y + $slope * ( $_ - $mean_x ) } @$xs ] );
		},
	},
);

sub _window_mean ( $ys, $index, $before, $after ) {
	return undef unless defined $ys->[$index];
	my @near = grep { defined } @$ys[ max( 0, $index - $before ) .. min( $#$ys, $index + $after ) ];
	return sum0(@near) / @near;
}

sub _aggregate ( $aggregate, $values ) {
	return scalar @$values if $aggregate eq 'count';
	return undef unless @$values;
	return sum0(@$values) / @$values if $aggregate eq 'mean';
	return sum0(@$values) if $aggregate eq 'sum';
	return min(@$values) if $aggregate eq 'min';
	return max(@$values) if $aggregate eq 'max';
	return $values->[0] if $aggregate eq 'first';
	return $values->[-1];
}

# Largest-Triangle-Three-Buckets: keeps the points that shape the line,
# so peaks and dips survive. Points without a value are dropped.
sub _largest_triangles ( $xs, $ys, $count ) {
	my @points = map { [ $xs->[$_], $ys->[$_] ] } grep { defined $ys->[$_] } 0 .. $#$xs;
	return ( [ map { $_->[0] } @points ], [ map { $_->[1] } @points ] ) if @points <= $count;
	my @kept   = ( $points[0] );
	my $size   = ( @points - 2 ) / ( $count - 2 );
	my $chosen = 0;
	foreach my $bucket ( 0 .. $count - 3 ) {
		my ( $from, $to )           = ( int( $bucket * $size ) + 1, int( ( $bucket + 1 ) * $size ) + 1 );
		my ( $next_from, $next_to ) = ( $to, min( int( ( $bucket + 2 ) * $size ) + 1, scalar @points ) );
		my @next = @points[ $next_from .. $next_to - 1 ];
		my ( $average_x, $average_y ) = ( sum0( map { $_->[0] } @next ) / @next, sum0( map { $_->[1] } @next ) / @next );
		my ( $best, $largest )        = ( $from, -1 );
		foreach my $index ( $from .. $to - 1 ) {
			my $area = abs( ( $points[$chosen][0] - $average_x ) * ( $points[$index][1] - $points[$chosen][1] ) - ( $points[$chosen][0] - $points[$index][0] ) * ( $average_y - $points[$chosen][1] ) );
			( $best, $largest ) = ( $index, $area ) if $area > $largest;
		}
		push @kept, $points[$best];
		$chosen = $best;
	}
	push @kept, $points[-1];
	return ( [ map { $_->[0] } @kept ], [ map { $_->[1] } @kept ] );
}

sub transform_names () {
	my @names = sort keys %TRANSFORM;
	return @names;
}

# One step: a name, [ name, arguments ], or a code reference.
sub _step ( $owner, $name, $step ) {
	return [ 'code', sub ( $xs, $ys ) { _checked_result( $owner, $name, $step->( [@$xs], [@$ys] ) ) } ] if ref $step eq 'CODE';
	my ( $transform, @arguments ) = ref $step eq 'ARRAY' ? @$step : ($step);
	croak "$owner: every step of $name must be a transform name (" . join( ', ', transform_names() ) . "), [ name, arguments ] or a code reference, got " . describe($transform)
		unless defined $transform && !ref $transform && $TRANSFORM{$transform};
	my $spec = $TRANSFORM{$transform};
	my ( $least, $most, $defaults ) = $spec->{arguments}->@*;
	croak "$owner: the $name step '$transform' takes " . ( $least == $most ? $least : "$least to $most" ) . " argument" . ( $most == 1 ? '' : 's' ) . ", got " . scalar(@arguments)
		if @arguments < $least || @arguments > $most;
	my @values = map { $_ < @arguments ? $arguments[$_] : $defaults->[$_] } 0 .. $most - 1;
	if ( $spec->{check} ) {
		my $problem = $spec->{check}->(@values);
		croak "$owner: the $name step '$transform' needs $problem, got " . join( ', ', map { describe($_) } @arguments ) if defined $problem;
	}
	foreach my $value ( grep { defined } @values ) {
		croak "$owner: the arguments of the $name step '$transform' must be plain values, got " . describe($value) if ref $value;
	}
	return [ $transform, sub ( $xs, $ys ) { $spec->{apply}->( $xs, $ys, @values ) } ];
}

sub _checked_result ( $owner, $name, @result ) {
	croak "$owner: a $name code reference must return two array references of the same length (xs, ys)"
		unless @result == 2 && ref $result[0] eq 'ARRAY' && ref $result[1] eq 'ARRAY' && $result[0]->@* == $result[1]->@*;
	return @result;
}

# A transform specification as a list of steps: a name, a code
# reference, or an array of steps.
sub parse_transforms ( $owner, $name, $spec ) {
	return [] unless defined $spec;
	my @steps = ref $spec eq 'ARRAY' ? @$spec : ($spec);
	croak "$owner: $name is a list of steps; write [ [ '$steps[0]', ... ] ] for one step with arguments"
		if @steps > 1 && defined $steps[0] && !ref $steps[0] && $TRANSFORM{ $steps[0] } && grep { defined && !ref && looks_like_number($_) } @steps[ 1 .. $#steps ];
	return [ map { _step( $owner, $name, $_ ) } @steps ];
}

sub apply_transforms ( $steps, $xs, $ys ) {
	( $xs, $ys ) = $_->[1]->( $xs, $ys ) foreach @$steps;
	return ( $xs, $ys );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Transform - Prepare the data of a chart series:
normalize, smooth, accumulate, resample

=head1 SYNOPSIS

	# In a chart, as the transform of a series (or of all series):
	use Term::Fabulous::Widget::LineChart;

	my $chart = Term::Fabulous::Widget::LineChart->new(
		series => [
			{ name => 'Raw',      data => \@samples },
			{ name => 'Smoothed', data => \@samples, transform => [ [ 'moving_average', 7, 'center' ] ] },
			{ name => 'Indexed',  data => \@prices,  transform => [ 'sort', [ 'index', 100 ] ] },
		],
	);

	# On its own:
	use Term::Fabulous::Chart::Transform qw(parse_transforms apply_transforms);

	my $steps = parse_transforms( 'my program', 'transform', [ [ 'resample', 3600, 'sum' ], 'cumulative' ] );
	my ( $xs, $ys ) = apply_transforms( $steps, \@epochs, \@values );

=head1 DESCRIPTION

A series can be prepared before it is drawn: smoothed, normalized,
summed up, resampled to an interval, thinned out. The C<transform> of a
series (or of the whole chart, for every series without one of its own)
lists the steps, which run in order on the series' points. The data you
give the chart is kept as it is: the steps run again whenever it
changes, so live data stays prepared the same way. How the chart uses
the prepared points is described in
L<Term::Fabulous::Widget::XYChart/Preparing data>.

A step is a name, an array of a name and its arguments, or a code
reference. Write the list of steps as an array, even for one step with
arguments: C<< transform =E<gt> [ [ 'moving_average', 5 ] ] >>. A single
step without arguments can stand alone: C<< transform =E<gt> 'cumulative' >>.
C<< transform =E<gt> [ 'moving_average', 5 ] >> dies with a message that
shows the right form. Unknown names, a wrong number of arguments and
invalid arguments die when the transform is given.

In a KDL layout, each C<transform> node is one step, its name and
arguments as the node's arguments; repeat the node for several steps
(see L<Term::Fabulous::Widget::XYChart/KDL PROPERTIES>):

=for highlighter language=kdl

	series "visits" {
		data 120 135 160 158 171 190 185
		transform "moving_average" 3 "center"
		transform "index" 100
	}

The steps see the x values as numbers: the positions 0, 1, 2, ... of
points without x, the category numbers on a category axis, epoch
seconds on a time axis. Points without a value (C<undef>, gaps in a
line) stay gaps unless a step says otherwise; windows skip them.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/cookbook-chart-transform.svg" alt="Daily visits as a dim raw line with a 7-day moving average and a dashed exponentially smoothed line over it, and below it share and bond prices both indexed to 100 at day 1"></p>

=end html

The program in the picture is in
L<Term::Fabulous::Cookbook::ChartTechniques/Smooth noisy data and index it to 100 (transforms)>.

=head2 Steps

Each example shows the y values a step makes of the y values before it;
the x values are 0, 1, 2, ... unless the example gives them.

=over

=item C<normalize>, C<[ 'normalize', $low, $high ]>

Scales the values linearly so the smallest becomes C<$low> and the
largest C<$high> (default 0 and 1); when all values are equal, all
become C<$low>. Use it to compare the shapes of series of different
sizes on one axis.

=for highlighter language=perl

	transform => 'normalize'                     # 2, 4, 6, 8, 10  =>  0, 0.25, 0.5, 0.75, 1
	transform => [ [ 'normalize', 0, 100 ] ]     # 2, 4, 6, 8, 10  =>  0, 25, 50, 75, 100

=item C<share>

Each value as a fraction of the total of the absolute values of the
series (0 to 1); with the axis C<< format =E<gt> 'percent' >> the axis
shows percentages.

	transform => 'share'                         # 1, 2, 3, 4  =>  0.1, 0.2, 0.3, 0.4

=item C<zscore>

The number of standard deviations (of the whole series) each value lies
from the series mean; when all values are equal, all become 0.

	transform => 'zscore'                        # 2, 4, 4, 6  =>  -1.41, 0, 0, 1.41

=item C<index>, C<[ 'index', $base ]>

Each value relative to the first non-zero value, which becomes C<$base>
(default 100). Use it instead of a second axis to compare the growth of
series of different sizes: all start at 100.

	transform => 'index'                         # 40, 50, 60  =>  100, 125, 150
	transform => [ [ 'index', 1 ] ]              # 40, 50, 60  =>  1, 1.25, 1.5

=item C<cumulative>

The running total.

	transform => 'cumulative'                    # 1, 2, undef, 3  =>  1, 3, undef, 6

=item C<difference>

The change from the previous value; the first point gets none (a gap).
After a gap, the change is counted from the last value before it.

	transform => 'difference'                    # 5, 7, 4, 10  =>  undef, 2, -3, 6

=item C<rate>, C<[ 'rate', $per ]>

The change per unit of x from the previous point, times C<$per>
(default 1): a counter sampled with epoch seconds becomes a rate per
second, with C<< [ 'rate', 60 ] >> per minute. The first point, and a
point at the same x as the one before, get none.

	transform => 'rate'                          # x 0, 10, 20; y 100, 160, 190  =>  undef, 6, 3
	transform => [ [ 'rate', 60 ] ]              # x 0, 10, 20; y 100, 160, 190  =>  undef, 360, 180

=item C<[ 'moving_average', $window ]>, C<[ 'moving_average', $window, 'center' ]>

The mean of the last C<$window> values (C<trailing>, the default), or of
the C<$window> values around each point (C<center>), which does not lag
behind. C<$window> is a whole number of points, at least 1. At the
ends, where fewer values are at hand, the mean is taken of those there
are.

	transform => [ [ 'moving_average', 3 ] ]               # 3, 6, 9, 6, 3  =>  3, 4.5, 6, 7, 6
	transform => [ [ 'moving_average', 3, 'center' ] ]     # 3, 6, 9, 6, 3  =>  4.5, 6, 7, 6, 4.5

=item C<[ 'exponential', $alpha ]>

Exponential smoothing: each value moves C<$alpha> (greater than 0, at
most 1) of the way from the smoothed value before it towards its own
value; the first value stays. Small values smooth more.

	transform => [ [ 'exponential', 0.5 ] ]      # 10, 20, 20, 0  =>  10, 15, 17.5, 8.75

=item C<[ 'median', $window ]>

The median of the C<$window> values around each point (a whole number
of points, at least 1): removes single spikes but keeps steps.

	transform => [ [ 'median', 3 ] ]             # 1, 1, 9, 1, 1  =>  1, 1, 1, 1, 1

=item C<[ 'gaussian', $sigma ]>

A Gaussian blur with a standard deviation of C<$sigma> points (a
positive number); each value is the weighted mean of the values up to
three C<$sigma> away. The smoothest of the smoothing steps.

	transform => [ [ 'gaussian', 1 ] ]           # 0, 0, 10, 0, 0  =>  0.77, 2.57, 4.03, 2.57, 0.77

=item C<[ 'scale', $factor ]>, C<[ 'offset', $amount ]>

Multiply by a number or add a number, for example to convert units.

	transform => [ [ 'scale', 1000 ] ]           # 1.5, 2, 2.5  =>  1500, 2000, 2500
	transform => [ [ 'offset', -273.15 ] ]       # 293.15, 300  =>  20, 26.85

=item C<[ 'clip', $low, $high ]>

Limits the values to a range; either end may be C<undef> for no limit.
C<$low> must not be greater than C<$high>.

	transform => [ [ 'clip', 0, 100 ] ]          # -5, 50, 120, 80  =>  0, 50, 100, 80
	transform => [ [ 'clip', undef, 100 ] ]      # -5, 50, 120, 80  =>  -5, 50, 100, 80

=item C<abs>

The absolute values.

	transform => 'abs'                           # -3, 0, 2  =>  3, 0, 2

=item C<sort>

Sorts the points by x. Lines and areas on numeric and time axes are
sorted anyway; use it before steps that depend on the order, such as
C<cumulative> or C<index>, on bars or points.

	transform => 'sort'                          # x 3, 1, 2; y 30, 10, 20  =>  x 1, 2, 3; y 10, 20, 30

=item C<[ 'resample', $interval ]>, C<[ 'resample', $interval, $aggregate ]>

Groups the points into intervals of x (C<3600> for hours of epoch
seconds) and replaces each group by one point at the start of its
interval: the C<mean> (default), C<sum>, C<min>, C<max>, C<first>, C<last>
value or the C<count> of points. Intervals without points are left out;
a group of gaps only is a gap (a C<count> of 0).

	transform => [ [ 'resample', 10 ] ]           # x 1, 4, 12, 15, 27; y 1, 3, 5, 7, 9  =>  x 0, 10, 20; y 2, 6, 9
	transform => [ [ 'resample', 10, 'sum' ] ]    # same points                          =>  x 0, 10, 20; y 4, 12, 9
	transform => [ [ 'resample', 10, 'count' ] ]  # same points                          =>  x 0, 10, 20; y 2, 2, 1

=item C<[ 'downsample', $count ]>

Thins a long series out to C<$count> points (a whole number, at least
3) with the Largest-Triangle-Three-Buckets method, which keeps peaks
and dips. The first and the last point stay; gaps are dropped. A series
of C<$count> points or fewer only loses its gaps. Charts draw any
number of points; this only makes drawing faster.

	transform => [ [ 'downsample', 3 ] ]         # 1, 5, 2, 8, 3, 4  =>  x 0, 3, 5; y 1, 8, 4

=item C<regression>

The least-squares straight line through the points, at every x of the
series (gaps get a value too). A series with fewer than two values
becomes gaps only. The series option C<trend> draws such a line in
addition to the series.

	transform => 'regression'                    # 1, 3, 2, 4  =>  1.3, 2.1, 2.9, 3.7

=item a code reference

Called with copies of the x and y values as two array references;
returns two array references of equal length, the new x and y values.
Anything else dies when the frame is drawn.

	transform => [ sub ( $xs, $ys ) { return ( $xs, [ map { defined ? $_ * 2 : undef } @$ys ] ) } ]

=back

=head1 FUNCTIONS

=head2 parse_transforms

	my $steps = parse_transforms( $owner, $name, $spec );

Checks a specification and returns its steps. Dies with C<$owner> and
C<$name> in the message for unknown names and wrong arguments.

=head2 apply_transforms

	my ( $xs, $ys ) = apply_transforms( $steps, \@xs, \@ys );

Runs the steps on the values and returns new arrays.

=head2 transform_names

The names of all steps, sorted.

=head1 SEE ALSO

L<Term::Fabulous::Widget::XYChart/Preparing data>,
L<Term::Fabulous::Manual::Charts/Series and data>,
L<Term::Fabulous::Cookbook::ChartTechniques/Smooth noisy data and index it to 100 (transforms)>,
L<Term::Fabulous::Chart::Curve>.

=cut
