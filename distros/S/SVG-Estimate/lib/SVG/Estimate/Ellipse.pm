package SVG::Estimate::Ellipse;
$SVG::Estimate::Ellipse::VERSION = '1.0111';
use Moo;
use Math::Trig qw/pi/;

extends 'SVG::Estimate::Shape';
with 'SVG::Estimate::Role::MakePolygon';
with 'SVG::Estimate::Role::ArgsWithUnits';

=head1 NAME

SVG::Estimate::Ellipse - Handles estimating ellipses.

=head1 VERSION

version 1.0111

=head1 SYNOPSIS

 my $ellipse = SVG::Estimate::Ellipse->new(
    transformer => $transform,
    start_point => [45,13],
    cx          => 1,
    cy          => 3,
    rx          => 1,
    ry          => 1.5,
 );

 my $length = $ellipse->length;

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

=item rx

Float representing the x radius.

=item ry

Float representing the y radius.

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

has rx => (
    is => 'ro',
    required => 1,
);

has ry => (
    is => 'ro',
    required => 1,
);

sub BUILDARGS {
    my ($class, @args) = @_;
    ##Upgrade to hashref
    my $args = @args % 2 ? $args[0] : { @args };
    $args->{cx} //= 0;
    $args->{cy} //= 0;
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
    $args->{draw_start}   = [$args->{cx}+$args->{rx}, $args->{cy}];
    $args->{draw_end}     = $args->{draw_start};

    ##https://www.mathsisfun.com/geometry/ellipse-perimeter.html, Series #2
    my $h = ($args->{rx} - $args->{ry})**2 / ($args->{rx} + $args->{ry}) **2;
    my $len = pi * ( $args->{rx} + $args->{ry} ) * ( 1 + $h/4 + ($h**2)/64 + ($h**3)/256 + ($h**4 * (25/16384)));
    $args->{shape_length} = $len;

    $args->{min_x}        = $args->{cx} - $args->{rx};
    $args->{min_y}        = $args->{cy} - $args->{ry};
    $args->{max_x}        = $args->{cx} + $args->{rx};
    $args->{max_y}        = $args->{cy} + $args->{ry};
    return $args;
}

sub args_with_units {
    return qw/rx ry/;
}

sub this_point {
    my $class = shift;
    my $args  = shift;
    my $t     = shift;
    my $angle = $t * 2 * pi;
    my $cosr  = cos $angle;
    my $sinr  = sin $angle;
    my $x     = $cosr * $args->{rx} + $args->{cx};
    my $y     = $sinr * $args->{ry} + $args->{cy};
    return [$x, $y];
}

1;
