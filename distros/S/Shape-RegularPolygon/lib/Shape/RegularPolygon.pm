package Shape::RegularPolygon;

use 5.008006;
use strict;
use warnings;

use Math::Trig;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.01';


sub new {
    my $class = shift;
    my %params = @_;

    my $self = {CenterX => 0,
		CenterY => 0,
		Sides   => 3,
		Radius  => 50,
		Angle   => 0.0,
               };

    foreach my $name (keys %params) {
	$self->{$name} = $params{$name} if exists $self->{$name};
    }

    ($self->{Sides} >= 3) or die "Sides is too small.";

    bless($self, $class);
}

sub center {
    my ($self, $x, $y) = @_;
    return ($self->{CenterX}, $self->{CenterY})
      if !defined $x || !defined $y;
    $self->{CenterX} = $x;
    $self->{CenterY} = $y;
}
sub sides {
    my ($self, $sides) = @_;
    return $self->{Sides} if not defined $sides;

    ($sides >= 3) or die "Sides is too smaill.";
    $self->{Sides} = $sides;
}
sub radius {
    my ($self, $radius) = @_;
    return $self->{Radius} if not defined $radius;
    $self->{Radius} = $radius;
}
sub angle {
    my ($self, $angle) = @_;
    return $self->{Angle} if not defined $angle;
    $self->{Angle} = $angle;
}

sub points {
    my ($self) = @_;

    my @points;

    my $rad = - pi / 2 + $self->{Angle};     # -90 degree
    for (my $i = 0 ; $i < $self->{Sides} ; $i++) {
	push @points, {x => cos($rad) * $self->{Radius} + $self->{CenterX},
		       y => sin($rad) * $self->{Radius} + $self->{CenterY}};

        $rad += pi * 2 / $self->{Sides};
    }

    return @points;
}

1;
__END__

=head1 NAME

Shape::RegularPolygon - Object that treats the shape of the regular polygon

=head1 SYNOPSIS

  use Shape::RegularPolygon;

  # Create a regular polygon
  $polygon = new Shape::RegularPolygon;
  $polygon->center(100, 50);
  $polygon->sides(3);
  $polygon->radius(100);
  $polygon->angle(3.14 / 6);

  # By named parameter
  $polygon = new Shape::RegularPolygon(CenterX => 100,
                                       CenterY =>  50,
                                       Sides => 3,
                                       Radius => 100,
                                       Angle => 3.14 / 6);

  # get vertexes
  @points = $polygon->points

=head1 DESCRIPTION

Shape::RegularPolygon is a class that treats the shape of the regular polygon.
This object creates and returns vertex list of specified regular polygon.

=head1 Construction

=over 5

=item Simple construction

  new Shape::RegularPolygon;

When the parameter is omitted, the equilateral triangle is made in default.
The parameter can be set later by using method.

=item Construction with named parameters

  new Shape::RegularPolygon(named parameters);

When you construct object, you can specify some parameters.
See below about named parameters.

=back

=head2 Parameters

=over 5

=item CenterX, CenterY

Position of regular polygon

=item Sides

Building n-sides polygon.
When four is specified, square is made.
It must be a value of three or more.

=item Radius

Circumradius of regular polygon

=item Angle

Rotate a polygon in radians (clockwise).

=back

=head1 METHODS

=over 5

=item center(x, y)

Set position of polygon.
Returns current position, when parameters are omitted.

  $shape->center(100, 200);
  ($x, $y) = $shape->center;

=item sides(n)

Set the number of sides.
Returns the number of sides, when parameters are omitted.

  $shape->sides(5);
  $n = $shape->sides;

=item radius(r)

Set circumradius of polygon.
Returns current circumradius, when parameters are omitted.

  $shape->radius(100);
  $r = $shape->radius;

=item angle(rad)

Set rotation angle. Returns current angle, when parameters are omitted.
The rad is in radian. and clockwise.

  $shape->angle(3.14 / 6);	# 30 degree
  $rad = $shape->angle;

=item points()

Returns vertexes list of polygon as follows.

  (
    {x => x0, y => y0},    # Vertex0
    {x => x1, y => y1},    # Vertex1
       :
       :
  )


=back

=head1 Example

The following script builds png image file that regular pentagon was drawn.

 #!/usr/bin/perl
 use strict;
 use warnings;
 use Shape::RegularPolygon;
 use GD;
 
 my $shape = new Shape::RegularPolygon;
 $shape->center(150, 100);
 $shape->sides(5);
 
 my $im = new GD::Image(300, 200);
 $im->fill(0, 0, $im->colorAllocate(0xff, 0xff, 0xff));
 
 my $poly = new GD::Polygon;
 $poly->addPt($_->{x}, $_->{y}) foreach $shape->points;
 
 $im->filledPolygon($poly, $im->colorAllocate(0x80, 0xe0, 0x80));
 
 binmode STDOUT;
 print $im->png;


=head1 SEE ALSO

None

=head1 AUTHOR

Kazuyoshi Tomita, E<lt>kztomita@bit-hive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kazuyoshi Tomita

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
