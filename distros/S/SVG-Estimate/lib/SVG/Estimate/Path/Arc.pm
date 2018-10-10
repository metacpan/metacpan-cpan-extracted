package SVG::Estimate::Path::Arc;
$SVG::Estimate::Path::Arc::VERSION = '1.0108';
use Moo;
use Math::Trig qw/pi acos deg2rad rad2deg/;
use Clone qw/clone/;
use strict;

extends 'SVG::Estimate::Path::Command';
with 'SVG::Estimate::Role::Pythagorean';
with 'SVG::Estimate::Role::SegmentLength';

=head1 NAME

SVG::Estimate::Path::Arc - Handles estimating arcs.

=head1 VERSION

version 1.0108

=head1 SYNOPSIS

 my $arc = SVG::Estimate::Path::Arc->new(
    transformer     => $transform,
    start_point     => [13, 19],
    x               => 45,
    y               => 13,
    rx              => 1,
    ry              => 3,
    x_axis_rotation => 0,
    large_arc_flag  => 0,
    sweep_flag      => 0,
 );

 my $length = $arc->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Path::Command> and consumes L<SVG::Estimate::Role::Pythagorean>, L<SVG::Estimate::Role::SegmentLength>, and L<SVG::Estimate::Role::EndToPoint>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item x

The x coordinate for the end-point of the arc.

=item y

The y coordinate for the end-point of the arc.

=item rx

Float representing the x radius.

=item ry

Float representing the y radius.

=item x_axis_rotation

Float that indicates how the ellipse as a whole is rotated relative to the current coordinate system.

=item large_arc_flag

Must be 1 or 0. See details L<http://www.w3.org/TR/SVG/paths.html>.

=item sweep_flag

Must be 1 or 0. See details L<http://www.w3.org/TR/SVG/paths.html>.

=back

=cut

has rx => (
    is          => 'ro',
    required    => 1,
);

has ry => (
    is          => 'ro',
    required    => 1,
);

has x_axis_rotation => (
    is          => 'ro',
    required    => 1,
);

has large_arc_flag => (
    is          => 'ro',
    required    => 1,
);

has sweep_flag => (
    is          => 'ro',
    required    => 1,
);

has x => (
    is          => 'ro',
    required    => 1,
);

has y => (
    is          => 'ro',
    required    => 1,
);

##Used for conversion from endpoint to center parameterization
has _delta => (
    is          => 'rw',
);

has _theta => (
    is          => 'rw',
);

has _center => (
    is          => 'rw',
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    if ($args->{transformer}->has_transforms) {
        ##The start point and end point are in different coordinate systems (view and user, respectively).
        ##To make the set of point in the user space, transform the start_point into user space
        ##Then run all the calculations
        my $view_start_point = clone $args->{start_point};
        $args->{start_point} = $args->{transformer}->untransform($args->{start_point});
        $class->endpoint_to_center($args);
        my $point;
        my $first = 1;
        my $start;
        my $length = 0;
        POINT: for (my $t=0; $t<=1; $t+=1/12) {
            $point = $class->this_point($args, $t);
            $point = $args->{transformer}->transform($point);
            if ($first) {
                $first = 0;
                $start = $point;
                $args->{min_x} = $args->{max_x} = $point->[0];
                $args->{min_y} = $args->{max_y} = $point->[1];
                next POINT;
            }
            $length += $class->pythagorean($start, $point);
            $args->{min_x} = $point->[0] if $point->[0] < $args->{min_x};
            $args->{min_y} = $point->[1] if $point->[1] < $args->{min_y};
            $args->{max_x} = $point->[0] if $point->[0] > $args->{max_x};
            $args->{max_y} = $point->[1] if $point->[1] > $args->{max_y};
            $start = $point;
        }
        ##Restore the original start point in the viewport coordinate system
        $args->{start_point}   = $view_start_point;
        $args->{end_point}     = $point;
        $args->{shape_length}  = $length;
        $args->{travel_length} = 0;
        return $args;
    }
    $class->endpoint_to_center($args);
    $args->{end_point} = clone $args->{point};
    my $start = $class->this_point($args, 0);
    my $end   = $class->this_point($args, 1);
    $args->{min_x}  = $start->[0] < $end->[0] ? $start->[0] : $end->[0];
    $args->{max_x}  = $start->[0] > $end->[0] ? $start->[0] : $end->[0];
    $args->{min_y}  = $start->[1] < $end->[1] ? $start->[1] : $end->[1];
    $args->{max_y}  = $start->[1] > $end->[1] ? $start->[1] : $end->[1];
    $args->{shape_length}  = $class->segment_length($args, 0, 1, $start, $end, 1e-4, 5, 0);
    $args->{travel_length} = 0;
    return $args;
}

sub endpoint_to_center {
    my $class = shift;
    my $args  = shift;
    my $rotr = deg2rad($args->{x_axis_rotation});
    my $cosr = cos $rotr;
    my $sinr = sin $rotr;
    my $dx   = ($args->{start_point}->[0] - $args->{x}) / 2; #*
    my $dy   = ($args->{start_point}->[1] - $args->{y}) / 2; #*

    my $x1prim = $cosr * $dx + $sinr * $dy; #*
    my $y1prim = -1*$sinr * $dx + $cosr * $dy; #*

    my $x1prim_sq = $x1prim**2; #*
    my $y1prim_sq = $y1prim**2; #*

    my $rx = $args->{rx}; #*
    my $ry = $args->{ry}; #*

    my $rx_sq = $rx**2; #*
    my $ry_sq = $ry**2; #*

    my $t1 = $rx_sq * $y1prim_sq;
    my $t2 = $ry_sq * $x1prim_sq;
    my $ts = $t1 + $t2;
    my $c  = sqrt(abs( (($rx_sq * $ry_sq) - $ts) / ($ts) ) );

    if ($args->{large_arc_flag} == $args->{sweep_flag}) {
        $c *= -1;
    }
    my $cxprim =     $c * $rx * $y1prim / $ry;
    my $cyprim = -1 *$c * $ry * $x1prim / $rx;

    $args->{_center} = [
        ($cosr * $cxprim - $sinr * $cyprim) + ( ($args->{start_point}->[0] + $args->{x}) / 2 ),
        ($sinr * $cxprim + $cosr * $cyprim) + ( ($args->{start_point}->[1] + $args->{y}) / 2 )
    ];

    ##**

    ##Theta calculation
    my $ux = ($x1prim - $cxprim) / $rx;   #*
    my $uy = ($y1prim - $cyprim) / $ry;   #*
    my $n = sqrt($ux**2 + $uy**2);
    my $p = $ux;
    my $d = $p / $n;
    my $theta = rad2deg(acos($p/$n));
    if ($uy < 0) {
        $theta *= -1;
    }
    $args->{_theta} = $theta % 360;

    my $vx = -1 * ($x1prim + $cxprim) / $rx;
    my $vy = -1 * ($y1prim + $cyprim) / $ry;
    $n = sqrt( ($ux**2 + $uy**2) * ($vx**2 + $vy**2));
    $p = $ux*$vx + $uy*$vy;
    $d = $p / $n;

    my $delta = rad2deg(acos($d));
    if (($ux * $vy - $uy * $vx) < 0 ) {
        $delta *= -1;
    }
    $delta = $delta % 360;

    if (! $args->{sweep_flag}) {
        $delta -= 360;
    }
    $args->{_delta} = $delta;
}

=head2 this_point (args, t)

Calculate a point on the graph, normalized from start point to end point as t, in 2-D space

=cut

sub this_point {
    my $class = shift;
    my $args  = shift;
    my $t     = shift;
    my $angle = deg2rad($args->{_theta} + ($args->{_delta} * $t));
    my $rotr  = deg2rad($args->{x_axis_rotation});
    my $cosr  = cos $rotr;
    my $sinr  = sin $rotr;
    my $x     = ($cosr * cos($angle) * $args->{rx} - $sinr * sin($angle) * $args->{ry} + $args->{_center}->[0]);
    my $y     = ($sinr * cos($angle) * $args->{rx} + $cosr * sin($angle) * $args->{ry} + $args->{_center}->[1]);
    return [$x, $y];
}

1;
