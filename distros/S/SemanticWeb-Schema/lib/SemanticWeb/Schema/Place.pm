package SemanticWeb::Schema::Place;

# ABSTRACT: Entities that have a somewhat fixed

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'Place';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has additional_property => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'additionalProperty',
);



has address => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'address',
);



has aggregate_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'aggregateRating',
);



has amenity_feature => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'amenityFeature',
);



has branch_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'branchCode',
);



has contained_in => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'containedIn',
);



has contained_in_place => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'containedInPlace',
);



has contains_place => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'containsPlace',
);



has event => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'event',
);



has events => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'events',
);



has fax_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'faxNumber',
);



has geo => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'geo',
);



has global_location_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'globalLocationNumber',
);



has has_map => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasMap',
);



has is_accessible_for_free => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isAccessibleForFree',
);



has isic_v4 => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isicV4',
);



has logo => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'logo',
);



has map => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'map',
);



has maps => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'maps',
);



has maximum_attendee_capacity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'maximumAttendeeCapacity',
);



has opening_hours_specification => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'openingHoursSpecification',
);



has photo => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'photo',
);



has photos => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'photos',
);



has public_access => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'publicAccess',
);



has review => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'review',
);



has reviews => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'reviews',
);



has smoking_allowed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'smokingAllowed',
);



has special_opening_hours_specification => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'specialOpeningHoursSpecification',
);



has telephone => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'telephone',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Place - Entities that have a somewhat fixed

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

Entities that have a somewhat fixed, physical extension.

=head1 ATTRIBUTES

=head2 C<additional_property>

C<additionalProperty>

=for html A property-value pair representing an additional characteristics of the
entitity, e.g. a product feature or another characteristic for which there
is no matching property in schema.org.</p> <p>Note: Publishers should be
aware that applications designed to use specific schema.org properties
(e.g. http://schema.org/width, http://schema.org/color,
http://schema.org/gtin13, ...) will typically expect such data to be
provided using those properties, rather than using the generic
property/value mechanism.

A additional_property should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PropertyValue']>

=back

=head2 C<address>

Physical address of the item.

A address should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=back

=head2 C<aggregate_rating>

C<aggregateRating>

The overall rating, based on a collection of reviews or ratings, of the
item.

A aggregate_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AggregateRating']>

=back

=head2 C<amenity_feature>

C<amenityFeature>

An amenity feature (e.g. a characteristic or service) of the Accommodation.
This generic property does not make a statement about whether the feature
is included in an offer for the main accommodation or available at extra
costs.

A amenity_feature should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::LocationFeatureSpecification']>

=back

=head2 C<branch_code>

C<branchCode>

=for html A short textual code (also called "store code") that uniquely identifies a
place of business. The code is typically assigned by the parentOrganization
and used in structured URLs.</p> <p>For example, in the URL
http://www.starbucks.co.uk/store-locator/etc/detail/3047 the code "3047" is
a branchCode for a particular branch.

A branch_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<contained_in>

C<containedIn>

The basic containment relation between a place and one that contains it.

A contained_in should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<contained_in_place>

C<containedInPlace>

The basic containment relation between a place and one that contains it.

A contained_in_place should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<contains_place>

C<containsPlace>

The basic containment relation between a place and another that it
contains.

A contains_place should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<event>

Upcoming or past event associated with this place, organization, or action.

A event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<events>

Upcoming or past events associated with this place or organization.

A events should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<fax_number>

C<faxNumber>

The fax number.

A fax_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<geo>

The geo coordinates of the place.

A geo should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::GeoCoordinates']>

=back

=head2 C<global_location_number>

C<globalLocationNumber>

=for html The <a href="http://www.gs1.org/gln">Global Location Number</a> (GLN,
sometimes also referred to as International Location Number or ILN) of the
respective organization, person, or place. The GLN is a 13-digit number
used to identify parties and physical locations.

A global_location_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<has_map>

C<hasMap>

A URL to a map of the place.

A has_map should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::Map']>

=back

=head2 C<is_accessible_for_free>

C<isAccessibleForFree>

A flag to signal that the item, event, or place is accessible for free.

A is_accessible_for_free should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<isic_v4>

C<isicV4>

The International Standard of Industrial Classification of All Economic
Activities (ISIC), Revision 4 code for a particular organization, business
person, or place.

A isic_v4 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<logo>

An associated logo.

A logo should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<map>

A URL to a map of the place.

A map should be one of the following types:

=over

=item C<Str>

=back

=head2 C<maps>

A URL to a map of the place.

A maps should be one of the following types:

=over

=item C<Str>

=back

=head2 C<maximum_attendee_capacity>

C<maximumAttendeeCapacity>

The total number of individuals that may attend an event or venue.

A maximum_attendee_capacity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<opening_hours_specification>

C<openingHoursSpecification>

The opening hours of a certain place.

A opening_hours_specification should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OpeningHoursSpecification']>

=back

=head2 C<photo>

A photograph of this place.

A photo should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=item C<InstanceOf['SemanticWeb::Schema::Photograph']>

=back

=head2 C<photos>

Photographs of this place.

A photos should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Photograph']>

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<public_access>

C<publicAccess>

=for html A flag to signal that the <a class="localLink"
href="http://schema.org/Place">Place</a> is open to public visitors. If
this property is omitted there is no assumed default boolean value

A public_access should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<review>

A review of the item.

A review should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

=back

=head2 C<reviews>

Review of the item.

A reviews should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

=back

=head2 C<smoking_allowed>

C<smokingAllowed>

Indicates whether it is allowed to smoke in the place, e.g. in the
restaurant, hotel or hotel room.

A smoking_allowed should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<special_opening_hours_specification>

C<specialOpeningHoursSpecification>

=for html The special opening hours of a certain place.</p> <p>Use this to explicitly
override general opening hours brought in scope by <a class="localLink"
href="http://schema.org/openingHoursSpecification">openingHoursSpecificatio
n</a> or <a class="localLink"
href="http://schema.org/openingHours">openingHours</a>.

A special_opening_hours_specification should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OpeningHoursSpecification']>

=back

=head2 C<telephone>

The telephone number.

A telephone should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Thing>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
