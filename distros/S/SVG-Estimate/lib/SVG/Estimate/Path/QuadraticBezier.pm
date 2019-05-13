package SVG::Estimate::Path::QuadraticBezier;
$SVG::Estimate::Path::QuadraticBezier::VERSION = '1.0114';
use Moo;
use List::Util qw/min max/;
use Clone qw/clone/;

extends 'SVG::Estimate::Path::Command';
with 'SVG::Estimate::Role::Pythagorean';
with 'SVG::Estimate::Role::SegmentLength';
with 'SVG::Estimate::Role::EndToPoint';

=head1 NAME

SVG::Estimate::Path::QuadraticBezier - Handles estimating quadratic bezier curves.

=head1 VERSION

version 1.0114

=head1 SYNOPSIS

 my $curve = SVG::Estimate::Path::QuadraticBezier->new(
    transformer     => $transform,
    start_point     => [13, 19],
    point           => [45,13],
    control         => [10,3],
 );

 my $length = $curve->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Path::Command> and consumes L<SVG::Estimate::Role::EndToPoint> and L<SVG::Estimate::Role::SegmentLength>

=head1 METHODS

=head2 new()

Constructor.

=over

=item point

An array ref containing two floats that represent a point. 

=item control

An array ref containing two floats that represent a point. 

=back

=cut

has point => (
    is          => 'ro',
    required    => 1,
);

has control => (
    is          => 'ro',
    required    => 1,
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    if ($args->{transformer}->has_transforms) {
        $args->{point}   = $args->{transformer}->transform($args->{point});
        $args->{control} = $args->{transformer}->transform($args->{control});
    }
    $args->{end_point} = clone $args->{point};
    #$args->{shape_length}  = $class->_calculate_length($args);
    my $start      = $class->this_point($args, 0);
    my $end        = $class->this_point($args, 1);
    ##Bounding box points approximated by the control points.
    $args->{min_x} = min $args->{start_point}->[0], $args->{control}->[0], $args->{point}->[0];
    $args->{max_x} = max $args->{start_point}->[0], $args->{control}->[0], $args->{point}->[0];
    $args->{min_y} = min $args->{start_point}->[1], $args->{control}->[1], $args->{point}->[1];
    $args->{max_y} = max $args->{start_point}->[1], $args->{control}->[1], $args->{point}->[1];

    $args->{shape_length}  = $class->segment_length($args, 0, 1, $start, $end, 1e-4, 5, 0);
    $args->{travel_length} = 0;

    return $args;
}

sub _calculate_length {
    my $class = shift;
    my $args  = shift;
    my $start   = $args->{start_point};
    my $control = $args->{control};
    my $end     = $args->{point};

    ##http://www.malczak.info/blog/quadratic-bezier-curve-length/
    my $a_x = $start->[0] - 2 * $control->[0] + $end->[0];
    my $a_y = $start->[1] - 2 * $control->[1] + $end->[1];
    my $b_x = 2 * ($end->[0] - $start->[0]);
    my $b_y = 2 * ($end->[1] - $start->[1]);

    my $A = 4 * ($a_x**2 + $a_y**2);
    my $B = 4 * ($a_x*$b_x + $a_y*$b_y);
    my $C = $b_x**2 + $b_y**2;

    my $SABC = 2 * sqrt($A + $B +$C);
    my $SA   = sqrt($A);
    my $A32  = 2 * $A * $SA;
    my $SC   = 2*sqrt($C);
    my $BA   = $B / $SA;

    my $length = ( $A32 + $SA*$B*($SABC-$SC) + (4*$C*$A - $B*$B)*log( (2*$SA + $BA + $SABC)/($BA + $SC) ) ) / (4*($A32));
    return $length;
}

sub this_point {
    my $class = shift;
    my $args  = shift;
    my $t     = shift;
    return [
        $class->_this_point($t, $args->{start_point}->[0], $args->{control}->[0], $args->{point}->[0]),
        $class->_this_point($t, $args->{start_point}->[1], $args->{control}->[1], $args->{point}->[1])
    ];
}

sub _this_point {
    shift;
    my ($t, $s, $c, $p) = @_;
    return ((1 - $t)**2 * $s)
         + (2*(1 - $t)*$t*$c)
         + ($t**2 * $p)
    ;
}

1;
