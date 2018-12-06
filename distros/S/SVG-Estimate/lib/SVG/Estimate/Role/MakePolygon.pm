package SVG::Estimate::Role::MakePolygon;
$SVG::Estimate::Role::MakePolygon::VERSION = '1.0109';
use strict;
use Moo::Role;
use Image::SVG::Transform;
use SVG::Estimate::Polygon;

=head1 NAME

SVG::Estimate::Role::MakePolygon - Approximate shapes that are hard to estimate

=head1 VERSION

version 1.0109

=head1 METHODS

=head2 make_polygon ( $args )

Class method.

Make an SVG::Estimate::Polygon out of a set of point approximating the consumer's shape.

Requires that the consumer provide a C<this_point> method.

=cut

sub make_polygon {
    my ($class, $args) = @_;
    my @points;
    for (my $t = 0.0; $t <= 1.0; $t += 1/12) {
        my $point = $class->this_point($args, $t);
        $point = $args->{transformer}->transform($point);
        push @points, $point;
    }
    my $polygon_points = join ' ', map { join ',', @{ $_ } } @points;
    ##Have to send in an empty transform object
    my $littleT = Image::SVG::Transform->new();
    return SVG::Estimate::Polygon->new(points => $polygon_points, transformer => $littleT, start_point => $args->{start_point}, );
}


1;
