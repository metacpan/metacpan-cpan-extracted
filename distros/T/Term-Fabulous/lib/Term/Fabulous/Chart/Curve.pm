package Term::Fabulous::Chart::Curve;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(curve_points curve_names is_curve check_curve y_at);

use Carp qw(croak);
use List::Util qw(max min);
use Term::Fabulous::Chart::Easing qw(easing easing_names is_easing_name);
use Term::Fabulous::Check qw(describe);

my %SHAPES = map { $_ => 1 } qw(linear step step-after step-before step-middle monotone catmull-rom natural);

sub curve_names () {
	my @names = ( sort( keys %SHAPES ), grep { $_ ne 'linear' } easing_names() );
	return @names;
}

sub is_curve ($curve) {
	return 1 if ref $curve eq 'CODE';
	return defined $curve && !ref $curve && ( $SHAPES{$curve} || is_easing_name($curve) ) ? 1 : 0;
}

sub check_curve ( $owner, $name, $curve ) {
	croak "$owner: $name must be a curve name ("
		. join( ', ', sort keys %SHAPES )
		. ", or an easing such as ease-in-out-sine) or a code reference, got "
		. ( defined $curve ? ( ref $curve ? ref($curve) . ' reference' : "'$curve'" ) : 'undef' )
		unless is_curve($curve);
	return $curve;
}

# The polyline that draws a curve through points ([x, y], x ascending):
# the points themselves for straight lines, the corners of steps, and
# for smooth curves a point every $step along x besides the data points.
# With between => [ first, last ] only the part from point first to
# point last is made; the shape there is the shape of the whole curve.
sub curve_points ( $points, $curve, %options ) {
	my $step = $options{step} // 1;
	croak "Term::Fabulous::Chart::Curve: step must be positive" unless $step > 0;
	my ( $first, $last ) = _checked_between( $options{between}, $points );
	return [ map { [@$_] } @$points[ $first .. $last ] ] if @$points < 2 || $curve eq 'linear';
	return _steps( $points, $curve, $first, $last ) if !ref $curve && $curve =~ /\Astep/;

	my $segment
		= ref $curve eq 'CODE'    ? _eased($curve)
		: is_easing_name($curve)  ? _eased( easing($curve) )
		: $curve eq 'monotone'    ? _hermite( $points, _monotone_tangents($points) )
		: $curve eq 'catmull-rom' ? _hermite( $points, _cardinal_tangents( $points, $options{tension} // 0 ) )
		: $curve eq 'natural'     ? _natural($points)
		:                           croak "Term::Fabulous::Chart::Curve: unknown curve '$curve'";

	my @polyline = ( [ @{ $points->[$first] } ] );
	foreach my $index ( $first .. $last - 1 ) {
		my ( $from, $to ) = ( $points->[$index], $points->[ $index + 1 ] );
		my $width = $to->[0] - $from->[0];
		my $count = $width > 0 ? int( $width / $step ) : 0;
		foreach my $sample ( 1 .. $count ) {
			my $t = $sample * $step / $width;
			last if $t >= 1;
			push @polyline, [ $from->[0] + $t * $width, $segment->( $index, $t, $from, $to ) ];
		}
		push @polyline, [@$to];
	}
	return \@polyline;
}

# The indexes of the first and last point the polyline runs through: all
# points, or the two of between => [ first, last ].
sub _checked_between ( $between, $points ) {
	return ( 0, $#$points ) unless defined $between;
	my $valid = ref $between eq 'ARRAY' && @$between == 2 && !grep { !defined || ref || !/\A[0-9]+\z/ } @$between;
	croak "Term::Fabulous::Chart::Curve: between must be [ first, last ], two point indexes, got "
		. ( ref $between eq 'ARRAY' ? '[ ' . join( ', ', map { describe($_) } @$between ) . ' ]' : describe($between) )
		unless $valid;
	my ( $first, $last ) = @$between;
	croak "Term::Fabulous::Chart::Curve: between [ $first, $last ] must run forward within the points 0 .. $#$points" unless $first <= $last && $last <= $#$points;
	return ( $first, $last );
}

sub _steps ( $points, $curve, $first, $last ) {
	my @polyline = ( [ @{ $points->[$first] } ] );
	foreach my $index ( $first + 1 .. $last ) {
		my ( $from, $to ) = ( $points->[ $index - 1 ], $points->[$index] );
		if ( $curve eq 'step-before' ) {
			push @polyline, [ $from->[0], $to->[1] ];
		}
		elsif ( $curve eq 'step-middle' ) {
			my $middle = ( $from->[0] + $to->[0] ) / 2;
			push @polyline, [ $middle, $from->[1] ], [ $middle, $to->[1] ];
		}
		else {
			push @polyline, [ $to->[0], $from->[1] ];
		}
		push @polyline, [@$to];
	}
	return \@polyline;
}

sub _eased ($ease) {
	return sub ( $index, $t, $from, $to ) { $from->[1] + ( $to->[1] - $from->[1] ) * $ease->($t) };
}

# Cubic Hermite segments through the points with the given slopes.
sub _hermite ( $points, $slopes ) {
	return sub ( $index, $t, $from, $to ) {
		my $width = $to->[0] - $from->[0];
		my ( $t2, $t3 ) = ( $t**2, $t**3 );
		return ( 2 * $t3 - 3 * $t2 + 1 ) * $from->[1] + ( $t3 - 2 * $t2 + $t ) * $width * $slopes->[$index] + ( -2 * $t3 + 3 * $t2 ) * $to->[1] + ( $t3 - $t2 ) * $width * $slopes->[ $index + 1 ];
	};
}

sub _secants ($points) {
	return map {
		my $width = $points->[ $_ + 1 ][0] - $points->[$_][0];
		$width ? ( $points->[ $_ + 1 ][1] - $points->[$_][1] ) / $width : 0
	} 0 .. $#$points - 1;
}

# Fritsch-Carlson: slopes that keep the curve monotone between any two
# points, so it never overshoots the data.
sub _monotone_tangents ($points) {
	my @secant = _secants($points);
	my @slope  = ( $secant[0], ( map { $secant[ $_ - 1 ] * $secant[$_] <= 0 ? 0 : ( $secant[ $_ - 1 ] + $secant[$_] ) / 2 } 1 .. $#secant ), $secant[-1] );
	foreach my $index ( 0 .. $#secant ) {
		if ( $secant[$index] == 0 ) {
			@slope[ $index, $index + 1 ] = ( 0, 0 );
			next;
		}
		my ( $alpha, $beta ) = ( $slope[$index] / $secant[$index], $slope[ $index + 1 ] / $secant[$index] );
		my $length = $alpha**2 + $beta**2;
		next if $length <= 9;
		my $tau = 3 / sqrt $length;
		@slope[ $index, $index + 1 ] = ( $tau * $alpha * $secant[$index], $tau * $beta * $secant[$index] );
	}
	return \@slope;
}

# Cardinal spline slopes; tension 0 is Catmull-Rom, 1 straight lines.
sub _cardinal_tangents ( $points, $tension ) {
	croak "Term::Fabulous::Chart::Curve: tension must be between 0 and 1, got $tension" unless $tension >= 0 && $tension <= 1;
	my @secant = _secants($points);
	my @slope;
	foreach my $index ( 0 .. $#$points ) {
		my ( $before, $after ) = ( $points->[ max( 0, $index - 1 ) ], $points->[ min( $#$points, $index + 1 ) ] );
		my $width = $after->[0] - $before->[0];
		push @slope, ( 1 - $tension ) * ( $width ? ( $after->[1] - $before->[1] ) / $width : 0 );
	}
	return \@slope;
}

# The natural cubic spline: smooth second derivatives, straight at the
# ends. It may overshoot between points. A point between two others at
# its x (three or more points at one x) is pinned straight like the ends:
# its equation would be all zeros.
sub _natural ($points) {
	my $last  = $#$points;
	my @width = map { $points->[ $_ + 1 ][0] - $points->[$_][0] } 0 .. $last - 1;
	my ( @lower, @diagonal, @upper, @right );
	@diagonal[ 0, $last ] = ( 1, 1 );
	@right[ 0, $last ] = ( 0, 0 );
	foreach my $index ( 1 .. $last - 1 ) {
		my ( $before, $after ) = ( $width[ $index - 1 ], $width[$index] );
		if ( $before == 0 && $after == 0 ) {
			( $lower[$index], $diagonal[$index], $upper[$index], $right[$index] ) = ( 0, 1, 0, 0 );
			next;
		}
		( $lower[$index], $diagonal[$index], $upper[$index] ) = ( $before, 2 * ( $before + $after ), $after );
		$right[$index] = 6 * ( ( $points->[ $index + 1 ][1] - $points->[$index][1] ) / ( $after || 1 ) - ( $points->[$index][1] - $points->[ $index - 1 ][1] ) / ( $before || 1 ) );
	}

	# Thomas algorithm for the second derivatives.
	my ( @c, @d );
	( $c[0], $d[0] ) = ( 0, 0 );
	foreach my $index ( 1 .. $last ) {
		my $denominator = $diagonal[$index] - ( $lower[$index] // 0 ) * $c[ $index - 1 ];
		$c[$index] = ( $upper[$index] // 0 ) / $denominator;
		$d[$index] = ( $right[$index] - ( $lower[$index] // 0 ) * $d[ $index - 1 ] ) / $denominator;
	}
	my @second = (0) x ( $last + 1 );
	for ( my $index = $last - 1; $index > 0; $index-- ) {
		$second[$index] = $d[$index] - $c[$index] * $second[ $index + 1 ];
	}
	return sub ( $index, $t, $from, $to ) {
		my $h = $width[$index];
		my ( $before, $after ) = ( 1 - $t, $t );
		return $before * $from->[1] + $after * $to->[1] + ( ( $before**3 - $before ) * $second[$index] + ( $after**3 - $after ) * $second[ $index + 1 ] ) * $h**2 / 6;
	};
}

# The y of a polyline at x, between the vertices around it; undef
# outside it. Vertical runs (steps) give the y where the run ends.
sub y_at ( $polyline, $x ) {
	return undef if !@$polyline || $x < $polyline->[0][0] || $x > $polyline->[-1][0];
	my ( $low, $high ) = ( 0, $#$polyline );
	while ( $high - $low > 1 ) {
		my $middle = int( ( $low + $high ) / 2 );
		$polyline->[$middle][0] <= $x ? ( $low = $middle ) : ( $high = $middle );
	}
	my ( $from, $to ) = @$polyline[ $low, $high ];
	return $from->[1] if $to->[0] == $from->[0];
	return $from->[1] + ( $to->[1] - $from->[1] ) * ( $x - $from->[0] ) / ( $to->[0] - $from->[0] );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Curve - How lines connect the points of a series

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Curve qw(curve_points y_at);

	my @points   = ( [ 0, 10 ], [ 10, 30 ], [ 20, 15 ] );
	my $polyline = curve_points( \@points, 'monotone', step => 0.5 );
	my $height   = y_at( $polyline, 12.5 );

=head1 DESCRIPTION

The C<curve> of a line or area series decides how the line runs from one
data point to the next. Every curve passes through all data points.

=over

=item C<linear> (the default)

Straight lines.

=item C<step>, C<step-after>

The value holds until the next point, where the line jumps: right for
counters and states that change at the moment of a sample. C<step> is
short for C<step-after>.

=item C<step-before>

The line jumps at the start of each interval to the next value.

=item C<step-middle>

The line jumps halfway between two points.

=item C<monotone>

A smooth curve that never overshoots: between two points it stays
between their values, and it is flat at local highs and lows (the
Fritsch-Carlson method). The best smooth curve for data.

=item C<catmull-rom>

A smooth curve through all points (a cardinal spline). The series option
C<tension> (0 to 1, default 0) tightens it; 1 gives straight lines. It
may overshoot a little.

=item C<natural>

The smoothest curve through the points (a natural cubic spline); it may
overshoot noticeably.

=item an easing name, or a code reference

Each segment follows an easing function from
L<Term::Fabulous::Chart::Easing> (C<ease-in-out-sine>, C<ease-out-bounce>,
...), or your own function from C<t> (0 to 1) to the share of the change.

=back

A chart takes the curve as the C<curve> option of a series or of the
whole chart (see L<Term::Fabulous::Widget::XYChart/Curves>):

	curve  => 'monotone',
	series => [ { name => 'load', data => \@load, curve => 'step' } ],
	series => [ { name => 'eased', data => \@data, curve => sub ($t) { $t**2 } } ],

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/cookbook-chart-curves.svg" alt="Six small charts of the same seven points connected linear, step, monotone, catmull-rom, ease-in-out-sine and ease-out-bounce"></p>

=end html

The program is in
L<Term::Fabulous::Cookbook::ChartStyles/Connect points with curves and easings (curve)>.

=head1 FUNCTIONS

=head2 curve_points

	my $polyline = curve_points( \@points, $curve, step => $step, tension => $tension );

The vertices of a polyline drawing the curve through the points (array
references C<[x, y]>, x ascending, in any units), as an array reference
of C<[x, y]>. Straight lines return the points, steps the corners of
the steps. Smooth curves and easings get a vertex every C<$step> along x
(default 1, a positive number) besides the points; the chart passes the
width of one subpixel. C<tension> (0 to 1, default 0) is used by
C<catmull-rom>. Several points may share an x (repeated samples): the
polyline runs straight up or down through them, for every curve. Dies
for an unknown curve.

C<< between =E<gt> [ $first, $last ] >> (two point indexes, C<$first> not
after C<$last>) returns only the part of the polyline from point
C<$first> to point C<$last>: the vertices the whole polyline has there,
as the slopes of smooth curves are worked out from all points. A chart
passes the points around its plot, so a long series outside the plot
costs no vertices. Dies for indexes outside the points.

=head2 y_at

	my $y = y_at( $polyline, $x );

The height of a polyline at C<$x>, interpolated between the vertices
around it; C<undef> outside the polyline. Where the polyline runs
straight up or down (a step), the y where that run ends.

=head2 curve_names

All curve names: the shapes, sorted, then the easing names, sorted.

=head2 is_curve, check_curve

	check_curve( $owner, $name, $curve );

C<is_curve> returns 1 for a curve name or a code reference, else 0.
C<check_curve> returns the curve, or dies with C<$owner> and C<$name> at
the start of the message.

=head1 SEE ALSO

L<Term::Fabulous::Chart::Easing>, L<Term::Fabulous::Widget::XYChart>.

=cut
