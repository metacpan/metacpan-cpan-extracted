use utf8;

package SemanticWeb::Schema::ApartmentComplex;

# ABSTRACT: Residence type: Apartment complex.

use Moo;

extends qw/ SemanticWeb::Schema::Residence /;


use MooX::JSON_LD 'ApartmentComplex';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has number_of_accommodation_units => (
    is        => 'rw',
    predicate => '_has_number_of_accommodation_units',
    json_ld   => 'numberOfAccommodationUnits',
);



has number_of_available_accommodation_units => (
    is        => 'rw',
    predicate => '_has_number_of_available_accommodation_units',
    json_ld   => 'numberOfAvailableAccommodationUnits',
);



has number_of_bedrooms => (
    is        => 'rw',
    predicate => '_has_number_of_bedrooms',
    json_ld   => 'numberOfBedrooms',
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





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ApartmentComplex - Residence type: Apartment complex.

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

Residence type: Apartment complex.

=head1 ATTRIBUTES

=head2 C<number_of_accommodation_units>

C<numberOfAccommodationUnits>

=for html <p>Indicates the total (available plus unavailable) number of accommodation
units in an <a class="localLink"
href="http://schema.org/ApartmentComplex">ApartmentComplex</a>, or the
number of accommodation units for a specific <a class="localLink"
href="http://schema.org/FloorPlan">FloorPlan</a> (within its specific <a
class="localLink"
href="http://schema.org/ApartmentComplex">ApartmentComplex</a>). See also
<a class="localLink"
href="http://schema.org/numberOfAvailableAccommodationUnits">numberOfAvaila
bleAccommodationUnits</a>.<p>

A number_of_accommodation_units should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_number_of_accommodation_units>

A predicate for the L</number_of_accommodation_units> attribute.

=head2 C<number_of_available_accommodation_units>

C<numberOfAvailableAccommodationUnits>

=for html <p>Indicates the number of available accommodation units in an <a
class="localLink"
href="http://schema.org/ApartmentComplex">ApartmentComplex</a>, or the
number of accommodation units for a specific <a class="localLink"
href="http://schema.org/FloorPlan">FloorPlan</a> (within its specific <a
class="localLink"
href="http://schema.org/ApartmentComplex">ApartmentComplex</a>). See also
<a class="localLink"
href="http://schema.org/numberOfAccommodationUnits">numberOfAccommodationUn
its</a>.<p>

A number_of_available_accommodation_units should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_number_of_available_accommodation_units>

A predicate for the L</number_of_available_accommodation_units> attribute.

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

=head1 SEE ALSO

L<SemanticWeb::Schema::Residence>

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
