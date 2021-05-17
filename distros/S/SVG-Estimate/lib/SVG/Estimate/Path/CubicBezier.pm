package SVG::Estimate::Path::CubicBezier;
$SVG::Estimate::Path::CubicBezier::VERSION = '1.0116';
use Moo;
use List::Util qw/min max/;
use Clone qw/clone/;

extends 'SVG::Estimate::Path::Command';
with 'SVG::Estimate::Role::Pythagorean';
with 'SVG::Estimate::Role::SegmentLength';
with 'SVG::Estimate::Role::EndToPoint';

=head1 NAME

SVG::Estimate::Path::CubicBezier - Handles estimating cubic bezier curves.

=head1 VERSION

version 1.0116

=head1 SYNOPSIS

 my $curve = SVG::Estimate::Path::CubicBezier->new(
    transformer     => $transform,
    start_point     => [13, 19],
    point           => [45,13],
    control1        => [10,3],
    control2        => [157,40],
 );

 my $length = $curve->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Path::Command> and consumes L<SVG::Estimate::Role::Pythagorean>, L<SVG::Estimate::Role::SegmentLength>, and L<SVG::Estimate::Role::EndToPoint>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item point

An array ref containing two floats that represent a point. 

=item control1

An array ref containing two floats that represent a point. 

=item control2

An array ref containing two floats that represent a point. 

=back

=cut

has point => (
    is          => 'ro',
    required    => 1,
);

has control1 => (
    is          => 'ro',
    required    => 1,
);

has control2 => (
    is          => 'ro',
    required    => 1,
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    if ($args->{transformer}->has_transforms) {
        $args->{point}    = $args->{transformer}->transform($args->{point});
        $args->{control1} = $args->{transformer}->transform($args->{control1});
        $args->{control2} = $args->{transformer}->transform($args->{control2});
    }
    $args->{end_point}    = clone $args->{point};

    my $start      = $class->this_point($args, 0);
    my $end        = $class->this_point($args, 1);
    $args->{min_x} = $start->[0] < $end->[0] ? $start->[0] : $end->[0];
    $args->{max_x} = $start->[0] > $end->[0] ? $start->[0] : $end->[0];
    $args->{min_y} = $start->[1] < $end->[1] ? $start->[1] : $end->[1];
    $args->{max_y} = $start->[1] > $end->[1] ? $start->[1] : $end->[1];

    $args->{shape_length}  = $class->segment_length($args, 0, 1, $start, $end, 1e-4, 7, 0);
    $args->{travel_length} = 0;

    return $args;
}

sub _this_point {
    shift;
    my ($t, $s, $c1, $c2, $p) = @_;
    return ((1 - $t)**3 * $s)
         + (3 * (1 - $t)**2  * $t    * $c1)
         + (3 * (1 - $t)     * $t**2 * $c2)
         + ($t**3  * $p)
         ;
}

sub this_point {
    my $class = shift;
    my $args  = shift;
    my $t     = shift;
    return [
        $class->_this_point($t, $args->{start_point}->[0], $args->{control1}->[0], $args->{control2}->[0], $args->{point}->[0]),
        $class->_this_point($t, $args->{start_point}->[1], $args->{control1}->[1], $args->{control2}->[1], $args->{point}->[1])
    ];
}


1;
