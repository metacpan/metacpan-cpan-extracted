use utf8;

package SemanticWeb::Schema::Trip;

# ABSTRACT: A trip or journey

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Trip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';


has arrival_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'arrivalTime',
);



has departure_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'departureTime',
);



has itinerary => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itinerary',
);



has offers => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'offers',
);



has part_of_trip => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfTrip',
);



has provider => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'provider',
);



has sub_trip => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'subTrip',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Trip - A trip or journey

=head1 VERSION

version v3.9.0

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

=head2 C<departure_time>

C<departureTime>

The expected departure time.

A departure_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<itinerary>

=for html Destination(s) ( <a class="localLink"
href="http://schema.org/Place">Place</a> ) that make up a trip. For a trip
where destination order is important use <a class="localLink"
href="http://schema.org/ItemList">ItemList</a> to specify that order (see
examples).

A itinerary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<offers>

An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event.

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<part_of_trip>

C<partOfTrip>

=for html Identifies that this <a class="localLink"
href="http://schema.org/Trip">Trip</a> is a subTrip of another Trip. For
example Day 1, Day 2, etc. of a multi-day trip.

A part_of_trip should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Trip']>

=back

=head2 C<provider>

The service provider, service operator, or service performer; the goods
producer. Another party (a seller) may offer those services or goods on
behalf of the provider. A provider may also serve as the seller.

A provider should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<sub_trip>

C<subTrip>

=for html Identifies a <a class="localLink" href="http://schema.org/Trip">Trip</a>
that is a subTrip of this Trip. For example Day 1, Day 2, etc. of a
multi-day trip.

A sub_trip should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Trip']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
