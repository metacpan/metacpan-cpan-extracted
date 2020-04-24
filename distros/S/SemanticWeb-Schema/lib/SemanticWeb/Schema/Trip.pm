use utf8;

package SemanticWeb::Schema::Trip;

# ABSTRACT: A trip or journey

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Trip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has arrival_time => (
    is        => 'rw',
    predicate => '_has_arrival_time',
    json_ld   => 'arrivalTime',
);



has departure_time => (
    is        => 'rw',
    predicate => '_has_departure_time',
    json_ld   => 'departureTime',
);



has itinerary => (
    is        => 'rw',
    predicate => '_has_itinerary',
    json_ld   => 'itinerary',
);



has offers => (
    is        => 'rw',
    predicate => '_has_offers',
    json_ld   => 'offers',
);



has part_of_trip => (
    is        => 'rw',
    predicate => '_has_part_of_trip',
    json_ld   => 'partOfTrip',
);



has provider => (
    is        => 'rw',
    predicate => '_has_provider',
    json_ld   => 'provider',
);



has sub_trip => (
    is        => 'rw',
    predicate => '_has_sub_trip',
    json_ld   => 'subTrip',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Trip - A trip or journey

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

A trip or journey. An itinerary of visits to one or more places.

=head1 ATTRIBUTES

=head2 C<arrival_time>

C<arrivalTime>

The expected arrival time.

A arrival_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_arrival_time>

A predicate for the L</arrival_time> attribute.

=head2 C<departure_time>

C<departureTime>

The expected departure time.

A departure_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_departure_time>

A predicate for the L</departure_time> attribute.

=head2 C<itinerary>

=for html <p>Destination(s) ( <a class="localLink"
href="http://schema.org/Place">Place</a> ) that make up a trip. For a trip
where destination order is important use <a class="localLink"
href="http://schema.org/ItemList">ItemList</a> to specify that order (see
examples).<p>

A itinerary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_itinerary>

A predicate for the L</itinerary> attribute.

=head2 C<offers>

=for html <p>An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event. Use <a class="localLink"
href="http://schema.org/businessFunction">businessFunction</a> to indicate
the kind of transaction offered, i.e. sell, lease, etc. This property can
also be used to describe a <a class="localLink"
href="http://schema.org/Demand">Demand</a>. While this property is listed
as expected on a number of common types, it can be used in others. In that
case, using a second type, such as Product or a subtype of Product, can
clarify the nature of the offer.<p>

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Demand']>

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_offers>

A predicate for the L</offers> attribute.

=head2 C<part_of_trip>

C<partOfTrip>

=for html <p>Identifies that this <a class="localLink"
href="http://schema.org/Trip">Trip</a> is a subTrip of another Trip. For
example Day 1, Day 2, etc. of a multi-day trip.<p>

A part_of_trip should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Trip']>

=back

=head2 C<_has_part_of_trip>

A predicate for the L</part_of_trip> attribute.

=head2 C<provider>

The service provider, service operator, or service performer; the goods
producer. Another party (a seller) may offer those services or goods on
behalf of the provider. A provider may also serve as the seller.

A provider should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_provider>

A predicate for the L</provider> attribute.

=head2 C<sub_trip>

C<subTrip>

=for html <p>Identifies a <a class="localLink" href="http://schema.org/Trip">Trip</a>
that is a subTrip of this Trip. For example Day 1, Day 2, etc. of a
multi-day trip.<p>

A sub_trip should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Trip']>

=back

=head2 C<_has_sub_trip>

A predicate for the L</sub_trip> attribute.

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
