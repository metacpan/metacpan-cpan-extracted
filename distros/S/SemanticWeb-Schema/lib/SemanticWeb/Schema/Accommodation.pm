use utf8;

package SemanticWeb::Schema::Accommodation;

# ABSTRACT: An accommodation is a place that can accommodate human beings

use Moo;

extends qw/ SemanticWeb::Schema::Place /;


use MooX::JSON_LD 'Accommodation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has amenity_feature => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'amenityFeature',
);



has floor_size => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'floorSize',
);



has number_of_rooms => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfRooms',
);



has permitted_usage => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'permittedUsage',
);



has pets_allowed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'petsAllowed',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Accommodation - An accommodation is a place that can accommodate human beings

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html An accommodation is a place that can accommodate human beings, e.g. a hotel
room, a camping pitch, or a meeting room. Many accommodations are for
overnight stays, but this is not a mandatory requirement. For more specific
types of accommodations not defined in schema.org, one can use
additionalType with external vocabularies. <br /><br /> See also the <a
href="/docs/hotels.html">dedicated document on the use of schema.org for
marking up hotels and other forms of accommodations</a>.

=head1 ATTRIBUTES

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

=head2 C<floor_size>

C<floorSize>

The size of the accommodation, e.g. in square meter or squarefoot. Typical
unit code(s): MTK for square meter, FTK for square foot, or YDK for square
yard

A floor_size should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<number_of_rooms>

C<numberOfRooms>

The number of rooms (excluding bathrooms and closets) of the accommodation
or lodging business. Typical unit code(s): ROM for room or C62 for no unit.
The type of room can be put in the unitText property of the
QuantitativeValue.

A number_of_rooms should be one of the following types:

=over

=item C<Num>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<permitted_usage>

C<permittedUsage>

Indications regarding the permitted usage of the accommodation.

A permitted_usage should be one of the following types:

=over

=item C<Str>

=back

=head2 C<pets_allowed>

C<petsAllowed>

Indicates whether pets are allowed to enter the accommodation or lodging
business. More detailed information can be put in a text value.

A pets_allowed should be one of the following types:

=over

=item C<Str>

=item C<Bool>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Place>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
