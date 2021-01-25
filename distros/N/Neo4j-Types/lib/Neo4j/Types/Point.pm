use strict;
use warnings;

package Neo4j::Types::Point;
# ABSTRACT: Represents a Neo4j spatial point value
$Neo4j::Types::Point::VERSION = '1.00';

use Carp qw(croak);


my %DIM = ( 4326 => 2, 4979 => 3, 7203 => 2, 9157 => 3 );

sub new {
	my ($class, $srid, @coordinates) = @_;
	
	croak "Points must have SRID" unless defined $srid;
	my $dim = $DIM{$srid};
	croak "Unsupported SRID $srid" unless defined $dim;
	croak "Points with SRID $srid must have $dim dimensions" if @coordinates < $dim;
	return bless [ $srid, @coordinates[0 .. $dim - 1] ], $class;
}


sub X { shift->[1] }
sub Y { shift->[2] }
sub Z { shift->[3] }

sub longitude { shift->[1] }
sub latitude  { shift->[2] }
sub height    { shift->[3] }

sub srid { shift->[0] }

sub coordinates { @{$_[0]}[ 1 .. $#{$_[0]} ] }


1;

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Types::Point - Represents a Neo4j spatial point value

=head1 VERSION

version 1.00

=head1 SYNOPSIS

 $longitude  = $point->X;
 $latitude   = $point->Y;
 $height     = $point->Z;
 $neo4j_srid = $point->srid;
 
 @coords = ($x, $y, $z);
 $point  = Neo4j::Types::Point->new( $neo4j_srid, @coords );

=head1 DESCRIPTION

Represents a spatial point value in Neo4j. Includes coordinates in
two or three dimensions and a SRID that may define their semantics.

The SRID and thereby the coordinate semantics are defined by Neo4j.
See L</"srid"> for details.

This module makes no assumptions about its internal data structure.
While default implementations for all methods are provided,
inheritors are free to override these according to their needs.
The default implementations assume the data is stored in an array
reference whose order of elements matches that of
L<Bolt PackStream|https://7687.org/packstream/packstream-specification-1.html#point2d---structure>
for Point2D/Point3D.

Supported in Neo4j S<version 3.4> and above.

=head1 METHODS

L<Neo4j::Types::Point> implements the following methods.

=head2 coordinates

 @coordinates = $point->coordinates;
 ($x, $y, $z) = @coordinates;

Retrieve the point's coordinates as a list.

=head2 height

 $value = $point->height;

Alias for L<C<Z()>|/"Z">.

=head2 latitude

 $value = $point->latitude;

Alias for L<C<Y()>|/"Y">.

=head2 longitude

 $value = $point->longitude;

Alias for L<C<X()>|/"X">.

=head2 new

 $point = Neo4j::Types::Point->new($neo4j_srid, @coordinates);

Creates a new Point instance with the specified value.

This method will fail if the SRID provided is not supported by Neo4j
or if it requires a greater number of coordinates than provided.

=head2 srid

 $neo4j_srid = $point->srid;

Retrieve an identifier for this point's spatial reference system.
This SRID has no meaning outside the context of Neo4j; in particular,
it is B<not an EPSG code.>

To date, Neo4j has defined four SRIDs: 4326, 4979, 7203, and 9157.
Every point retrieved from Neo4j is referred to a coordinate system
identified by one of them.

=over

=item Neo4j SRID 4326

Geographical ellipsoidal coordinates, referred to WGS84
(but spherically developed with C<distance()> in Cypher).
Axes: longitude (East), latitude (North). Units: decimal degrees.
Neo4j moniker: C<wgs-84>.

=item Neo4j SRID 4979

Geographical ellipsoidal coordinates, referred to WGS84
(but spherically developed with C<distance()> in Cypher).
Axes: longitude (East), latitude (North), height (Up).
Units: decimal degrees; height in metres. The height is
referred to the ellipsoid (which is not at sea level).
Neo4j moniker: C<wgs-84-3d>.

=item Neo4j SRID 7203

Coordinates in a two-dimensional Euclidian space (a plane).
The geodetic datum, axis orientation and units are all undefined,
but both axes must use the same unit.
Neo4j moniker: C<cartesian>.

=item Neo4j SRID 9157

Coordinates in a three-dimensional Euclidian space. The geodetic
datum, axis orientation and units are all undefined, but all axes
must use the same unit.
Neo4j moniker: C<cartesian-3d>.

=back

The primary semantics of a Neo4j SRID can be easily determined by
simple boolean expressions.

 $is_geographic = $neo4j_srid == 4326 or $neo4j_srid == 4979;
 $is_euclidian  = $neo4j_srid == 7203 or $neo4j_srid == 9157;
 $is_2d         = $neo4j_srid == 4326 or $neo4j_srid == 7203;
 $is_3d         = $neo4j_srid == 4979 or $neo4j_srid == 9157;

Note that Neo4j does not support geographic coordinates that are
referred to any other geodetic datum than WGS84 (such as GCJ02,
ETRS89, NAD27, or local datums), nor does it support geographic
coordinates that are referred to an unknown datum. While it is
technically possible to ignore Neo4j SRID semantics and just use
other geographic coordinate reference systems anyway, you should
be aware that this may create interoperability issues, particularly
if more than a single client uses the Neo4j database.

Neo4j does I<not> impose constraints on the datum of Euclidian
coordinates, so using (for example) cartesian coordinates referred
to WGS84 is possible. However, Neo4j does not offer a way to tag
point values with the datum they actually use. Care should be taken
not to mix different geodetic datums in the same database without
considering the interoperability issues that this may cause, again
particularly if more than a single client uses the Neo4j database.

=head2 X

 $value = $point->X;

Retrieve the point's first ordinate, also known as the abscissa.
Commonly used for the horizontal axis in an Euclidean plane or for
the geographical longitude.

=head2 Y

 $value = $point->Y;

Retrieve the point's second ordinate. Commonly used for the vertical
axis in an Euclidean plane or for the geographical latitude.

=head2 Z

 $value = $point->Z;

Retrieve the point's third ordinate. Commonly used for height.

For points in coordinate systems that have no more than two
dimensions, this method returns an undefined value.

=head1 BUGS

The behaviour of the C<coordinates()> method when called in scalar
context has not yet been defined.

There are currently no methods named C<x()>, C<y()>, or C<z()>.
This is to avoid confusion with Perl's C<y///> operator.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver::Type::Point>

=item * L<"Spatial values" in Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/spatial/>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__


Neo4j actually does falsely claim EPSG or spatialreference.org conformance in at least one place. However:

- EPSG:4326/EPSG:4979 treat the earth as a WGS84 ellipsoid, NEO4J:4326/NEO4J:4979 use spherical development of WGS84 ellipsoidal coordinates
- EPSG:4326 uses the axis order latitude/longitude, NEO4J:4326 uses longitude/latitude
- EPSG:4979 uses the axis order latitude/longitude/height, NEO4J:4326 uses longitude/latitude/height
- SR-ORG:4326/SR-ORG:4979 are undefined, NEO4J:4326/NEO4J:4979 are not
- EPSG:7203 is undefined, NEO4J:7203 is generic Euclidian plane
- EPSG:9157 is Angola RSAO13 UTM 33, NEO4J:9157 is generic Euclidian 3D space
- SR-ORG:7203/SR-ORG:9157 define units and axis orientation, NEO4J:7203/NEO4J:9157 do not

