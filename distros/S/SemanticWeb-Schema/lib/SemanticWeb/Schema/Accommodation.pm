use utf8;

package SemanticWeb::Schema::Accommodation;

# ABSTRACT: An accommodation is a place that can accommodate human beings

use Moo;

extends qw/ SemanticWeb::Schema::Place /;


use MooX::JSON_LD 'Accommodation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has accommodation_category => (
    is        => 'rw',
    predicate => '_has_accommodation_category',
    json_ld   => 'accommodationCategory',
);



has accommodation_floor_plan => (
    is        => 'rw',
    predicate => '_has_accommodation_floor_plan',
    json_ld   => 'accommodationFloorPlan',
);



has amenity_feature => (
    is        => 'rw',
    predicate => '_has_amenity_feature',
    json_ld   => 'amenityFeature',
);



has floor_level => (
    is        => 'rw',
    predicate => '_has_floor_level',
    json_ld   => 'floorLevel',
);



has floor_size => (
    is        => 'rw',
    predicate => '_has_floor_size',
    json_ld   => 'floorSize',
);



has lease_length => (
    is        => 'rw',
    predicate => '_has_lease_length',
    json_ld   => 'leaseLength',
);



has number_of_bathrooms_total => (
    is        => 'rw',
    predicate => '_has_number_of_bathrooms_total',
    json_ld   => 'numberOfBathroomsTotal',
);



has number_of_bedrooms => (
    is        => 'rw',
    predicate => '_has_number_of_bedrooms',
    json_ld   => 'numberOfBedrooms',
);



has number_of_full_bathrooms => (
    is        => 'rw',
    predicate => '_has_number_of_full_bathrooms',
    json_ld   => 'numberOfFullBathrooms',
);



has number_of_partial_bathrooms => (
    is        => 'rw',
    predicate => '_has_number_of_partial_bathrooms',
    json_ld   => 'numberOfPartialBathrooms',
);



has number_of_rooms => (
    is        => 'rw',
    predicate => '_has_number_of_rooms',
    json_ld   => 'numberOfRooms',
);



has permitted_usage => (
    is        => 'rw',
    predicate => '_has_permitted_usage',
    json_ld   => 'permittedUsage',
);



has pets_allowed => (
    is        => 'rw',
    predicate => '_has_pets_allowed',
    json_ld   => 'petsAllowed',
);



has tour_booking_page => (
    is        => 'rw',
    predicate => '_has_tour_booking_page',
    json_ld   => 'tourBookingPage',
);



has year_built => (
    is        => 'rw',
    predicate => '_has_year_built',
    json_ld   => 'yearBuilt',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Accommodation - An accommodation is a place that can accommodate human beings

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>An accommodation is a place that can accommodate human beings, e.g. a
hotel room, a camping pitch, or a meeting room. Many accommodations are for
overnight stays, but this is not a mandatory requirement. For more specific
types of accommodations not defined in schema.org, one can use
additionalType with external vocabularies. <br /><br /> See also the <a
href="/docs/hotels.html">dedicated document on the use of schema.org for
marking up hotels and other forms of accommodations</a>.<p>

=head1 ATTRIBUTES

=head2 C<accommodation_category>

C<accommodationCategory>

=for html <p>Category of an <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>, following real
estate conventions e.g. RESO (see <a
href="https://ddwiki.reso.org/display/DDW17/PropertySubType+Field">Property
SubType</a>, and <a
href="https://ddwiki.reso.org/display/DDW17/PropertyType+Field">PropertyTyp
e</a> fields for suggested values).<p>

A accommodation_category should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_accommodation_category>

A predicate for the L</accommodation_category> attribute.

=head2 C<accommodation_floor_plan>

C<accommodationFloorPlan>

=for html <p>A floorplan of some <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>.<p>

A accommodation_floor_plan should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::FloorPlan']>

=back

=head2 C<_has_accommodation_floor_plan>

A predicate for the L</accommodation_floor_plan> attribute.

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

=head2 C<_has_amenity_feature>

A predicate for the L</amenity_feature> attribute.

=head2 C<floor_level>

C<floorLevel>

=for html <p>The floor level for an <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a> in a multi-storey
building. Since counting systems <a
href="https://en.wikipedia.org/wiki/Storey#Consecutive_number_floor_designa
tions">vary internationally</a>, the local system should be used where
possible.<p>

A floor_level should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_floor_level>

A predicate for the L</floor_level> attribute.

=head2 C<floor_size>

C<floorSize>

The size of the accommodation, e.g. in square meter or squarefoot. Typical
unit code(s): MTK for square meter, FTK for square foot, or YDK for square
yard

A floor_size should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_floor_size>

A predicate for the L</floor_size> attribute.

=head2 C<lease_length>

C<leaseLength>

=for html <p>Length of the lease for some <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>, either particular
to some <a class="localLink" href="http://schema.org/Offer">Offer</a> or in
some cases intrinsic to the property.<p>

A lease_length should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_lease_length>

A predicate for the L</lease_length> attribute.

=head2 C<number_of_bathrooms_total>

C<numberOfBathroomsTotal>

=for html <p>The total integer number of bathrooms in a some <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>, following real
estate conventions as <a
href="https://ddwiki.reso.org/display/DDW17/BathroomsTotalInteger+Field">do
cumented in RESO</a>: "The simple sum of the number of bathrooms. For
example for a property with two Full Bathrooms and one Half Bathroom, the
Bathrooms Total Integer will be 3.". See also <a class="localLink"
href="http://schema.org/numberOfRooms">numberOfRooms</a>.<p>

A number_of_bathrooms_total should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_number_of_bathrooms_total>

A predicate for the L</number_of_bathrooms_total> attribute.

=head2 C<number_of_bedrooms>

C<numberOfBedrooms>

=for html <p>The total integer number of bedrooms in a some <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>, <a
class="localLink"
href="http://schema.org/ApartmentComplex">ApartmentComplex</a> or <a
class="localLink" href="http://schema.org/FloorPlan">FloorPlan</a>.<p>

A number_of_bedrooms should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<_has_number_of_bedrooms>

A predicate for the L</number_of_bedrooms> attribute.

=head2 C<number_of_full_bathrooms>

C<numberOfFullBathrooms>

=for html <p>Number of full bathrooms - The total number of full and Â¾ bathrooms in
an <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>. This corresponds
to the <a
href="https://ddwiki.reso.org/display/DDW17/BathroomsFull+Field">BathroomsF
ull field in RESO</a>.<p>

A number_of_full_bathrooms should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_number_of_full_bathrooms>

A predicate for the L</number_of_full_bathrooms> attribute.

=head2 C<number_of_partial_bathrooms>

C<numberOfPartialBathrooms>

=for html <p>Number of partial bathrooms - The total number of half and Â¼ bathrooms
in an <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>. This corresponds
to the <a
href="https://ddwiki.reso.org/display/DDW17/BathroomsPartial+Field">Bathroo
msPartial field in RESO</a>.<p>

A number_of_partial_bathrooms should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_number_of_partial_bathrooms>

A predicate for the L</number_of_partial_bathrooms> attribute.

=head2 C<number_of_rooms>

C<numberOfRooms>

The number of rooms (excluding bathrooms and closets) of the accommodation
or lodging business. Typical unit code(s): ROM for room or C62 for no unit.
The type of room can be put in the unitText property of the
QuantitativeValue.

A number_of_rooms should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<_has_number_of_rooms>

A predicate for the L</number_of_rooms> attribute.

=head2 C<permitted_usage>

C<permittedUsage>

Indications regarding the permitted usage of the accommodation.

A permitted_usage should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_permitted_usage>

A predicate for the L</permitted_usage> attribute.

=head2 C<pets_allowed>

C<petsAllowed>

Indicates whether pets are allowed to enter the accommodation or lodging
business. More detailed information can be put in a text value.

A pets_allowed should be one of the following types:

=over

=item C<Bool>

=item C<Str>

=back

=head2 C<_has_pets_allowed>

A predicate for the L</pets_allowed> attribute.

=head2 C<tour_booking_page>

C<tourBookingPage>

=for html <p>A page providing information on how to book a tour of some <a
class="localLink" href="http://schema.org/Place">Place</a>, such as an <a
class="localLink" href="http://schema.org/Accommodation">Accommodation</a>
or <a class="localLink"
href="http://schema.org/ApartmentComplex">ApartmentComplex</a> in a real
estate setting, as well as other kinds of tours as appropriate.<p>

A tour_booking_page should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_tour_booking_page>

A predicate for the L</tour_booking_page> attribute.

=head2 C<year_built>

C<yearBuilt>

=for html <p>The year an <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a> was constructed.
This corresponds to the <a
href="https://ddwiki.reso.org/display/DDW17/YearBuilt+Field">YearBuilt
field in RESO</a>.<p>

A year_built should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_year_built>

A predicate for the L</year_built> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Place>

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
