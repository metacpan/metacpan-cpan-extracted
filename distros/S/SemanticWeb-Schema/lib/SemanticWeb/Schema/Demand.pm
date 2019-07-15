use utf8;

package SemanticWeb::Schema::Demand;

# ABSTRACT: A demand entity represents the public

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Demand';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has accepted_payment_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'acceptedPaymentMethod',
);



has advance_booking_requirement => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'advanceBookingRequirement',
);



has area_served => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'areaServed',
);



has availability => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availability',
);



has availability_ends => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availabilityEnds',
);



has availability_starts => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availabilityStarts',
);



has available_at_or_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableAtOrFrom',
);



has available_delivery_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableDeliveryMethod',
);



has business_function => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'businessFunction',
);



has delivery_lead_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'deliveryLeadTime',
);



has eligible_customer_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eligibleCustomerType',
);



has eligible_duration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eligibleDuration',
);



has eligible_quantity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eligibleQuantity',
);



has eligible_region => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eligibleRegion',
);



has eligible_transaction_volume => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eligibleTransactionVolume',
);



has gtin12 => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'gtin12',
);



has gtin13 => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'gtin13',
);



has gtin14 => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'gtin14',
);



has gtin8 => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'gtin8',
);



has includes_object => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'includesObject',
);



has ineligible_region => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'ineligibleRegion',
);



has inventory_level => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inventoryLevel',
);



has item_condition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemCondition',
);



has item_offered => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemOffered',
);



has mpn => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'mpn',
);



has price_specification => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'priceSpecification',
);



has seller => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seller',
);



has serial_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'serialNumber',
);



has sku => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sku',
);



has valid_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validFrom',
);



has valid_through => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validThrough',
);



has warranty => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'warranty',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Demand - A demand entity represents the public

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A demand entity represents the public, not necessarily binding, not
necessarily exclusive, announcement by an organization or person to seek a
certain type of goods or services. For describing demand using this type,
the very same properties used for Offer apply.

=head1 ATTRIBUTES

=head2 C<accepted_payment_method>

C<acceptedPaymentMethod>

The payment method(s) accepted by seller for this offer.

A accepted_payment_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::LoanOrCredit']>

=item C<InstanceOf['SemanticWeb::Schema::PaymentMethod']>

=back

=head2 C<advance_booking_requirement>

C<advanceBookingRequirement>

The amount of time that is required between accepting the offer and the
actual usage of the resource or service.

A advance_booking_requirement should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<area_served>

C<areaServed>

The geographic area where a service or offered item is provided.

A area_served should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<availability>

The availability of this item&#x2014;for example In stock, Out of stock,
Pre-order, etc.

A availability should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ItemAvailability']>

=back

=head2 C<availability_ends>

C<availabilityEnds>

The end of the availability of the product or service included in the
offer.

A availability_ends should be one of the following types:

=over

=item C<Str>

=back

=head2 C<availability_starts>

C<availabilityStarts>

The beginning of the availability of the product or service included in the
offer.

A availability_starts should be one of the following types:

=over

=item C<Str>

=back

=head2 C<available_at_or_from>

C<availableAtOrFrom>

The place(s) from which the offer can be obtained (e.g. store locations).

A available_at_or_from should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<available_delivery_method>

C<availableDeliveryMethod>

The delivery method(s) available for this offer.

A available_delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head2 C<business_function>

C<businessFunction>

The business function (e.g. sell, lease, repair, dispose) of the offer or
component of a bundle (TypeAndQuantityNode). The default is
http://purl.org/goodrelations/v1#Sell.

A business_function should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusinessFunction']>

=back

=head2 C<delivery_lead_time>

C<deliveryLeadTime>

The typical delay between the receipt of the order and the goods either
leaving the warehouse or being prepared for pickup, in case the delivery
method is on site pickup.

A delivery_lead_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<eligible_customer_type>

C<eligibleCustomerType>

The type(s) of customers for which the given offer is valid.

A eligible_customer_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusinessEntityType']>

=back

=head2 C<eligible_duration>

C<eligibleDuration>

The duration for which the given offer is valid.

A eligible_duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<eligible_quantity>

C<eligibleQuantity>

The interval and unit of measurement of ordering quantities for which the
offer or price specification is valid. This allows e.g. specifying that a
certain freight charge is valid only for a certain quantity.

A eligible_quantity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<eligible_region>

C<eligibleRegion>

=for html The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or the
GeoShape for the geo-political region(s) for which the offer or delivery
charge specification is valid.<br/><br/> See also <a class="localLink"
href="http://schema.org/ineligibleRegion">ineligibleRegion</a>.

A eligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<eligible_transaction_volume>

C<eligibleTransactionVolume>

The transaction volume, in a monetary unit, for which the offer or price
specification is valid, e.g. for indicating a minimal purchasing volume, to
express free shipping above a certain order volume, or to limit the
acceptance of credit cards to purchases to a certain minimal amount.

A eligible_transaction_volume should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=back

=head2 C<gtin12>

=for html The GTIN-12 code of the product, or the product to which the offer refers.
The GTIN-12 is the 12-digit GS1 Identification Key composed of a U.P.C.
Company Prefix, Item Reference, and Check Digit used to identify trade
items. See <a href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1
GTIN Summary</a> for more details.

A gtin12 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<gtin13>

=for html The GTIN-13 code of the product, or the product to which the offer refers.
This is equivalent to 13-digit ISBN codes and EAN UCC-13. Former 12-digit
UPC codes can be converted into a GTIN-13 code by simply adding a
preceeding zero. See <a
href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1 GTIN
Summary</a> for more details.

A gtin13 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<gtin14>

=for html The GTIN-14 code of the product, or the product to which the offer refers.
See <a href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1 GTIN
Summary</a> for more details.

A gtin14 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<gtin8>

=for html The <a href="http://apps.gs1.org/GDD/glossary/Pages/GTIN-8.aspx">GTIN-8</a>
code of the product, or the product to which the offer refers. This code is
also known as EAN/UCC-8 or 8-digit EAN. See <a
href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1 GTIN
Summary</a> for more details.

A gtin8 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<includes_object>

C<includesObject>

This links to a node or nodes indicating the exact quantity of the products
included in the offer.

A includes_object should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TypeAndQuantityNode']>

=back

=head2 C<ineligible_region>

C<ineligibleRegion>

=for html The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or the
GeoShape for the geo-political region(s) for which the offer or delivery
charge specification is not valid, e.g. a region where the transaction is
not allowed.<br/><br/> See also <a class="localLink"
href="http://schema.org/eligibleRegion">eligibleRegion</a>.

A ineligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<inventory_level>

C<inventoryLevel>

The current approximate inventory level for the item or items.

A inventory_level should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<item_condition>

C<itemCondition>

A predefined value from OfferItemCondition or a textual description of the
condition of the product or service, or the products or services included
in the offer.

A item_condition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OfferItemCondition']>

=back

=head2 C<item_offered>

C<itemOffered>

The item being offered.

A item_offered should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<InstanceOf['SemanticWeb::Schema::Service']>

=back

=head2 C<mpn>

The Manufacturer Part Number (MPN) of the product, or the product to which
the offer refers.

A mpn should be one of the following types:

=over

=item C<Str>

=back

=head2 C<price_specification>

C<priceSpecification>

One or more detailed price specifications, indicating the unit price and
delivery or payment charges.

A price_specification should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=back

=head2 C<seller>

An entity which offers (sells / leases / lends / loans) the services /
goods. A seller may also be a provider.

A seller should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<serial_number>

C<serialNumber>

The serial number or any alphanumeric identifier of a particular product.
When attached to an offer, it is a shortcut for the serial number of the
product included in the offer.

A serial_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<sku>

The Stock Keeping Unit (SKU), i.e. a merchant-specific identifier for a
product or service, or the product to which the offer refers.

A sku should be one of the following types:

=over

=item C<Str>

=back

=head2 C<valid_from>

C<validFrom>

The date when the item becomes valid.

A valid_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<valid_through>

C<validThrough>

The date after when the item is not valid. For example the end of an offer,
salary period, or a period of opening hours.

A valid_through should be one of the following types:

=over

=item C<Str>

=back

=head2 C<warranty>

The warranty promise(s) included in the offer.

A warranty should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WarrantyPromise']>

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
