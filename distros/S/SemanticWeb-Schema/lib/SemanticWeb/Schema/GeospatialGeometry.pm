use utf8;

package SemanticWeb::Schema::GeospatialGeometry;

# ABSTRACT: (Eventually to be defined as) a supertype of GeoShape designed to accommodate definitions from Geo-Spatial best practices.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'GeospatialGeometry';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has geo_contains => (
    is        => 'rw',
    predicate => '_has_geo_contains',
    json_ld   => 'geoContains',
);



has geo_covered_by => (
    is        => 'rw',
    predicate => '_has_geo_covered_by',
    json_ld   => 'geoCoveredBy',
);



has geo_covers => (
    is        => 'rw',
    predicate => '_has_geo_covers',
    json_ld   => 'geoCovers',
);



has geo_crosses => (
    is        => 'rw',
    predicate => '_has_geo_crosses',
    json_ld   => 'geoCrosses',
);



has geo_disjoint => (
    is        => 'rw',
    predicate => '_has_geo_disjoint',
    json_ld   => 'geoDisjoint',
);



has geo_equals => (
    is        => 'rw',
    predicate => '_has_geo_equals',
    json_ld   => 'geoEquals',
);



has geo_intersects => (
    is        => 'rw',
    predicate => '_has_geo_intersects',
    json_ld   => 'geoIntersects',
);



has geo_overlaps => (
    is        => 'rw',
    predicate => '_has_geo_overlaps',
    json_ld   => 'geoOverlaps',
);



has geo_touches => (
    is        => 'rw',
    predicate => '_has_geo_touches',
    json_ld   => 'geoTouches',
);



has geo_within => (
    is        => 'rw',
    predicate => '_has_geo_within',
    json_ld   => 'geoWithin',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::GeospatialGeometry - (Eventually to be defined as) a supertype of GeoShape designed to accommodate definitions from Geo-Spatial best practices.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

(Eventually to be defined as) a supertype of GeoShape designed to
accommodate definitions from Geo-Spatial best practices.

=head1 ATTRIBUTES

=head2 C<geo_contains>

C<geoContains>

=for html <p>Represents a relationship between two geometries (or the places they
represent), relating a containing geometry to a contained geometry. "a
contains b iff no points of b lie in the exterior of a, and at least one
point of the interior of b lies in the interior of a". As defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>.<p>

A geo_contains should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_contains>

A predicate for the L</geo_contains> attribute.

=head2 C<geo_covered_by>

C<geoCoveredBy>

=for html <p>Represents a relationship between two geometries (or the places they
represent), relating a geometry to another that covers it. As defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>.<p>

A geo_covered_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_covered_by>

A predicate for the L</geo_covered_by> attribute.

=head2 C<geo_covers>

C<geoCovers>

=for html <p>Represents a relationship between two geometries (or the places they
represent), relating a covering geometry to a covered geometry. "Every
point of b is a point of (the interior or boundary of) a". As defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>.<p>

A geo_covers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_covers>

A predicate for the L</geo_covers> attribute.

=head2 C<geo_crosses>

C<geoCrosses>

=for html <p>Represents a relationship between two geometries (or the places they
represent), relating a geometry to another that crosses it: "a crosses b:
they have some but not all interior points in common, and the dimension of
the intersection is less than that of at least one of them". As defined in
<a href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>.<p>

A geo_crosses should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_crosses>

A predicate for the L</geo_crosses> attribute.

=head2 C<geo_disjoint>

C<geoDisjoint>

=for html <p>Represents spatial relations in which two geometries (or the places they
represent) are topologically disjoint: they have no point in common. They
form a set of disconnected geometries." (a symmetric relationship, as
defined in <a href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>)<p>

A geo_disjoint should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_disjoint>

A predicate for the L</geo_disjoint> attribute.

=head2 C<geo_equals>

C<geoEquals>

=for html <p>Represents spatial relations in which two geometries (or the places they
represent) are topologically equal, as defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>. "Two geometries are
topologically equal if their interiors intersect and no part of the
interior or boundary of one geometry intersects the exterior of the other"
(a symmetric relationship)<p>

A geo_equals should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_equals>

A predicate for the L</geo_equals> attribute.

=head2 C<geo_intersects>

C<geoIntersects>

=for html <p>Represents spatial relations in which two geometries (or the places they
represent) have at least one point in common. As defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>.<p>

A geo_intersects should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_intersects>

A predicate for the L</geo_intersects> attribute.

=head2 C<geo_overlaps>

C<geoOverlaps>

=for html <p>Represents a relationship between two geometries (or the places they
represent), relating a geometry to another that geospatially overlaps it,
i.e. they have some but not all points in common. As defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>.<p>

A geo_overlaps should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_overlaps>

A predicate for the L</geo_overlaps> attribute.

=head2 C<geo_touches>

C<geoTouches>

=for html <p>Represents spatial relations in which two geometries (or the places they
represent) touch: they have at least one boundary point in common, but no
interior points." (a symmetric relationship, as defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a> )<p>

A geo_touches should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_touches>

A predicate for the L</geo_touches> attribute.

=head2 C<geo_within>

C<geoWithin>

=for html <p>Represents a relationship between two geometries (or the places they
represent), relating a geometry to one that contains it, i.e. it is inside
(i.e. within) its interior. As defined in <a
href="https://en.wikipedia.org/wiki/DE-9IM">DE-9IM</a>.<p>

A geo_within should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeospatialGeometry']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_geo_within>

A predicate for the L</geo_within> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
