use utf8;

package SemanticWeb::Schema::ParcelDelivery;

# ABSTRACT: The delivery of a parcel either via the postal service or a commercial service.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ParcelDelivery';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has carrier => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'carrier',
);



has delivery_address => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deliveryAddress',
);



has delivery_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deliveryStatus',
);



has expected_arrival_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'expectedArrivalFrom',
);



has expected_arrival_until => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'expectedArrivalUntil',
);



has has_delivery_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasDeliveryMethod',
);



has item_shipped => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemShipped',
);



has origin_address => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'originAddress',
);



has part_of_order => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfOrder',
);



has provider => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'provider',
);



has tracking_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'trackingNumber',
);



has tracking_url => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'trackingUrl',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ParcelDelivery - The delivery of a parcel either via the postal service or a commercial service.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The delivery of a parcel either via the postal service or a commercial
service.

=head1 ATTRIBUTES

=head2 C<carrier>

'carrier' is an out-dated term indicating the 'provider' for parcel
delivery and flights.

A carrier should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<delivery_address>

C<deliveryAddress>

Destination address.

A delivery_address should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=back

=head2 C<delivery_status>

C<deliveryStatus>

New entry added as the package passes through each leg of its journey (from
shipment to final delivery).

A delivery_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryEvent']>

=back

=head2 C<expected_arrival_from>

C<expectedArrivalFrom>

The earliest date the package may arrive.

A expected_arrival_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<expected_arrival_until>

C<expectedArrivalUntil>

The latest date the package may arrive.

A expected_arrival_until should be one of the following types:

=over

=item C<Str>

=back

=head2 C<has_delivery_method>

C<hasDeliveryMethod>

Method used for delivery or shipping.

A has_delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head2 C<item_shipped>

C<itemShipped>

Item(s) being shipped.

A item_shipped should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=back

=head2 C<origin_address>

C<originAddress>

Shipper's address.

A origin_address should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=back

=head2 C<part_of_order>

C<partOfOrder>

The overall order the items in this delivery were included in.

A part_of_order should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Order']>

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

=head2 C<tracking_number>

C<trackingNumber>

Shipper tracking number.

A tracking_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<tracking_url>

C<trackingUrl>

Tracking url for the parcel delivery.

A tracking_url should be one of the following types:

=over

=item C<Str>

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
