package SVG::Estimate::Role::SegmentLength;
$SVG::Estimate::Role::SegmentLength::VERSION = '1.0109';
use strict;
use Moo::Role;

=head1 NAME

SVG::Estimate::Role::SegmentLength - Estimate the distance along a curve 

=head1 VERSION

version 1.0109

=head1 METHODS

=head2 segment_length ( args, t0, t1, start_point, end_point, tolerance, minimum_iterations, current_iteration)

Calculate the distance along a curve using straight line approximations along segments of the curve

=cut

sub segment_length {
    my $class = shift;
    my ($args, $t0, $t1, $start, $end, $error, $min_depth, $depth) = @_;
    my $th = ($t1 + $t0) / 2;  ##half-way
    my $mid = $class->this_point($args, $th);
    $args->{min_x} = $mid->[0] if $mid->[0] < $args->{min_x};
    $args->{max_x} = $mid->[0] if $mid->[0] > $args->{max_x};
    $args->{min_y} = $mid->[1] if $mid->[1] < $args->{min_y};
    $args->{max_y} = $mid->[1] if $mid->[1] > $args->{max_y};
    my $length = $class->pythagorean($start, $end); ##Segment from start to end
    my $left   = $class->pythagorean($start, $mid);
    my $right  = $class->pythagorean($mid,   $end);
    my $length2 = $left + $right;  ##Sum of segments through midpoint
    if ($length2 - $length > $error || $depth < $min_depth) {
        ++$depth;
        return $class->segment_length($args, $t0, $th, $start, $mid, $error, $min_depth, $depth)
             + $class->segment_length($args, $th, $t1, $mid,   $end, $error, $min_depth, $depth)
    }
    return $length2;
}

1;
