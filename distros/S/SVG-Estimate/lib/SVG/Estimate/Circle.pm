package SVG::Estimate::Circle;
$SVG::Estimate::Circle::VERSION = '1.0108';
use Moo;
use Math::Trig qw/pi/;

extends 'SVG::Estimate::Shape';
with 'SVG::Estimate::Role::MakePolygon';
with 'SVG::Estimate::Role::ArgsWithUnits';

=head1 NAME

SVG::Estimate::Circle - Handles estimating circles.

=head1 VERSION

version 1.0108

=head1 SYNOPSIS

 my $circle = SVG::Estimate::Circle->new(
    transformer => $transform,
    start_point => [45,13],
    cx          => 1,
    cy          => 3,
    r           => 1,
 );

 my $length = $circle->length;

=head1 INHERITANCE

This class extends L<SVG::Estimate::Shape>.

=head1 METHODS

=head2 new()

Constructor.

=over

=item cx

Float representing center x.

=item cy

Float representing center y.

=item r

Float representing the radius.

=back

=cut

has cx => (
    is => 'ro',
    default => sub { 0 },
);

has cy => (
    is => 'ro',
    default => sub { 0 },
);

has r => (
    is => 'ro',
    required => 1,
);

sub args_with_units {
    return qw/r/;
}

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    my $center   = [ $args->{cx}, $args->{cy} ];
    if ($args->{transformer}->has_transforms) {
        ##Approximate the circle with a polygon
        my $poly = $class->make_polygon($args);
        $args->{draw_start}   = $poly->draw_start;
        $args->{draw_end}     = $poly->draw_end;
        $args->{shape_length} = $poly->shape_length;
        $args->{min_x}        = $poly->min_x;
        $args->{min_y}        = $poly->min_y;
        $args->{max_x}        = $poly->max_x;
        $args->{max_y}        = $poly->max_y;
        return $args;
    }
    $args->{draw_start}   = [$args->{cx}+$args->{r}, $args->{cy}];
    $args->{draw_end}     = $args->{draw_start};
    $args->{shape_length} = 2 * pi * $args->{r};
    $args->{min_x}        = $args->{cx} - $args->{r};
    $args->{min_y}        = $args->{cy} - $args->{r};
    $args->{max_x}        = $args->{cx} + $args->{r};
    $args->{max_y}        = $args->{cy} + $args->{r};
    return $args;
}

=head2 this_point ($args, $t)

This class method is used to calculate a point on a circle, given it's relative position (C<$t>, ranging
from 0 to 1, inclusive), and the radius and center of the circle from a hashref of C<$args> (C<r> and C<cx> and <cy>).

=cut

sub this_point {
    my $class = shift;
    my $args  = shift;
    my $t     = shift;
    my $angle = $t * 2 * pi;
    my $cosr  = cos $angle;
    my $sinr  = sin $angle;
    my $x     = $cosr * $args->{r} + $args->{cx};
    my $y     = $sinr * $args->{r} + $args->{cy};
    return [$x, $y];
}

1;
