use utf8;

package SemanticWeb::Schema::Offer;

# ABSTRACT: An offer to transfer some rights to an item or to provide a service â for example

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Offer';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has accepted_payment_method => (
    is        => 'rw',
    predicate => '_has_accepted_payment_method',
    json_ld   => 'acceptedPaymentMethod',
);



has add_on => (
    is        => 'rw',
    predicate => '_has_add_on',
    json_ld   => 'addOn',
);



has advance_booking_requirement => (
    is        => 'rw',
    predicate => '_has_advance_booking_requirement',
    json_ld   => 'advanceBookingRequirement',
);



has aggregate_rating => (
    is        => 'rw',
    predicate => '_has_aggregate_rating',
    json_ld   => 'aggregateRating',
);



has area_served => (
    is        => 'rw',
    predicate => '_has_area_served',
    json_ld   => 'areaServed',
);



has availability => (
    is        => 'rw',
    predicate => '_has_availability',
    json_ld   => 'availability',
);



has availability_ends => (
    is        => 'rw',
    predicate => '_has_availability_ends',
    json_ld   => 'availabilityEnds',
);



has availability_starts => (
    is        => 'rw',
    predicate => '_has_availability_starts',
    json_ld   => 'availabilityStarts',
);



has available_at_or_from => (
    is        => 'rw',
    predicate => '_has_available_at_or_from',
    json_ld   => 'availableAtOrFrom',
);



has available_delivery_method => (
    is        => 'rw',
    predicate => '_has_available_delivery_method',
    json_ld   => 'availableDeliveryMethod',
);



has business_function => (
    is        => 'rw',
    predicate => '_has_business_function',
    json_ld   => 'businessFunction',
);



has category => (
    is        => 'rw',
    predicate => '_has_category',
    json_ld   => 'category',
);



has delivery_lead_time => (
    is        => 'rw',
    predicate => '_has_delivery_lead_time',
    json_ld   => 'deliveryLeadTime',
);



has eligible_customer_type => (
    is        => 'rw',
    predicate => '_has_eligible_customer_type',
    json_ld   => 'eligibleCustomerType',
);



has eligible_duration => (
    is        => 'rw',
    predicate => '_has_eligible_duration',
    json_ld   => 'eligibleDuration',
);



has eligible_quantity => (
    is        => 'rw',
    predicate => '_has_eligible_quantity',
    json_ld   => 'eligibleQuantity',
);



has eligible_region => (
    is        => 'rw',
    predicate => '_has_eligible_region',
    json_ld   => 'eligibleRegion',
);



has eligible_transaction_volume => (
    is        => 'rw',
    predicate => '_has_eligible_transaction_volume',
    json_ld   => 'eligibleTransactionVolume',
);



has gtin => (
    is        => 'rw',
    predicate => '_has_gtin',
    json_ld   => 'gtin',
);



has gtin12 => (
    is        => 'rw',
    predicate => '_has_gtin12',
    json_ld   => 'gtin12',
);



has gtin13 => (
    is        => 'rw',
    predicate => '_has_gtin13',
    json_ld   => 'gtin13',
);



has gtin14 => (
    is        => 'rw',
    predicate => '_has_gtin14',
    json_ld   => 'gtin14',
);



has gtin8 => (
    is        => 'rw',
    predicate => '_has_gtin8',
    json_ld   => 'gtin8',
);



has includes_object => (
    is        => 'rw',
    predicate => '_has_includes_object',
    json_ld   => 'includesObject',
);



has ineligible_region => (
    is        => 'rw',
    predicate => '_has_ineligible_region',
    json_ld   => 'ineligibleRegion',
);



has inventory_level => (
    is        => 'rw',
    predicate => '_has_inventory_level',
    json_ld   => 'inventoryLevel',
);



has item_condition => (
    is        => 'rw',
    predicate => '_has_item_condition',
    json_ld   => 'itemCondition',
);



has item_offered => (
    is        => 'rw',
    predicate => '_has_item_offered',
    json_ld   => 'itemOffered',
);



has lease_length => (
    is        => 'rw',
    predicate => '_has_lease_length',
    json_ld   => 'leaseLength',
);



has mpn => (
    is        => 'rw',
    predicate => '_has_mpn',
    json_ld   => 'mpn',
);



has offered_by => (
    is        => 'rw',
    predicate => '_has_offered_by',
    json_ld   => 'offeredBy',
);



has price => (
    is        => 'rw',
    predicate => '_has_price',
    json_ld   => 'price',
);



has price_currency => (
    is        => 'rw',
    predicate => '_has_price_currency',
    json_ld   => 'priceCurrency',
);



has price_specification => (
    is        => 'rw',
    predicate => '_has_price_specification',
    json_ld   => 'priceSpecification',
);



has price_valid_until => (
    is        => 'rw',
    predicate => '_has_price_valid_until',
    json_ld   => 'priceValidUntil',
);



has review => (
    is        => 'rw',
    predicate => '_has_review',
    json_ld   => 'review',
);



has reviews => (
    is        => 'rw',
    predicate => '_has_reviews',
    json_ld   => 'reviews',
);



has seller => (
    is        => 'rw',
    predicate => '_has_seller',
    json_ld   => 'seller',
);



has serial_number => (
    is        => 'rw',
    predicate => '_has_serial_number',
    json_ld   => 'serialNumber',
);



has shipping_details => (
    is        => 'rw',
    predicate => '_has_shipping_details',
    json_ld   => 'shippingDetails',
);



has sku => (
    is        => 'rw',
    predicate => '_has_sku',
    json_ld   => 'sku',
);



has valid_from => (
    is        => 'rw',
    predicate => '_has_valid_from',
    json_ld   => 'validFrom',
);



has valid_through => (
    is        => 'rw',
    predicate => '_has_valid_through',
    json_ld   => 'validThrough',
);



has warranty => (
    is        => 'rw',
    predicate => '_has_warranty',
    json_ld   => 'warranty',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Offer - An offer to transfer some rights to an item or to provide a service â for example

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

=for html <p>An offer to transfer some rights to an item or to provide a service â
for example, an offer to sell tickets to an event, to rent the DVD of a
movie, to stream a TV show over the internet, to repair a motorcycle, or to
loan a book.<br/><br/> Note: As the <a class="localLink"
href="http://schema.org/businessFunction">businessFunction</a> property,
which identifies the form of offer (e.g. sell, lease, repair, dispose),
defaults to http://purl.org/goodrelations/v1#Sell; an Offer without a
defined businessFunction value can be assumed to be an offer to
sell.<br/><br/> For <a
href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GTIN</a>-related
fields, see <a
href="http://www.gs1.org/barcodes/support/check_digit_calculator">Check
Digit calculator</a> and <a
href="http://www.gs1us.org/resources/standards/gtin-validation-guide">valid
ation guide</a> from <a href="http://www.gs1.org/">GS1</a>.<p>

=head1 ATTRIBUTES

=head2 C<accepted_payment_method>

C<acceptedPaymentMethod>

The payment method(s) accepted by seller for this offer.

A accepted_payment_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::LoanOrCredit']>

=item C<InstanceOf['SemanticWeb::Schema::PaymentMethod']>

=back

=head2 C<_has_accepted_payment_method>

A predicate for the L</accepted_payment_method> attribute.

=head2 C<add_on>

C<addOn>

An additional offer that can only be obtained in combination with the first
base offer (e.g. supplements and extensions that are available for a
surcharge).

A add_on should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_add_on>

A predicate for the L</add_on> attribute.

=head2 C<advance_booking_requirement>

C<advanceBookingRequirement>

The amount of time that is required between accepting the offer and the
actual usage of the resource or service.

A advance_booking_requirement should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_advance_booking_requirement>

A predicate for the L</advance_booking_requirement> attribute.

=head2 C<aggregate_rating>

C<aggregateRating>

The overall rating, based on a collection of reviews or ratings, of the
item.

A aggregate_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AggregateRating']>

=back

=head2 C<_has_aggregate_rating>

A predicate for the L</aggregate_rating> attribute.

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

=head2 C<_has_area_served>

A predicate for the L</area_served> attribute.

=head2 C<availability>

The availability of this item&#x2014;for example In stock, Out of stock,
Pre-order, etc.

A availability should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ItemAvailability']>

=back

=head2 C<_has_availability>

A predicate for the L</availability> attribute.

=head2 C<availability_ends>

C<availabilityEnds>

The end of the availability of the product or service included in the
offer.

A availability_ends should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_availability_ends>

A predicate for the L</availability_ends> attribute.

=head2 C<availability_starts>

C<availabilityStarts>

The beginning of the availability of the product or service included in the
offer.

A availability_starts should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_availability_starts>

A predicate for the L</availability_starts> attribute.

=head2 C<available_at_or_from>

C<availableAtOrFrom>

The place(s) from which the offer can be obtained (e.g. store locations).

A available_at_or_from should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_available_at_or_from>

A predicate for the L</available_at_or_from> attribute.

=head2 C<available_delivery_method>

C<availableDeliveryMethod>

The delivery method(s) available for this offer.

A available_delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head2 C<_has_available_delivery_method>

A predicate for the L</available_delivery_method> attribute.

=head2 C<business_function>

C<businessFunction>

The business function (e.g. sell, lease, repair, dispose) of the offer or
component of a bundle (TypeAndQuantityNode). The default is
http://purl.org/goodrelations/v1#Sell.

A business_function should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusinessFunction']>

=back

=head2 C<_has_business_function>

A predicate for the L</business_function> attribute.

=head2 C<category>

A category for the item. Greater signs or slashes can be used to informally
indicate a category hierarchy.

A category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PhysicalActivityCategory']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<_has_category>

A predicate for the L</category> attribute.

=head2 C<delivery_lead_time>

C<deliveryLeadTime>

The typical delay between the receipt of the order and the goods either
leaving the warehouse or being prepared for pickup, in case the delivery
method is on site pickup.

A delivery_lead_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_delivery_lead_time>

A predicate for the L</delivery_lead_time> attribute.

=head2 C<eligible_customer_type>

C<eligibleCustomerType>

The type(s) of customers for which the given offer is valid.

A eligible_customer_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusinessEntityType']>

=back

=head2 C<_has_eligible_customer_type>

A predicate for the L</eligible_customer_type> attribute.

=head2 C<eligible_duration>

C<eligibleDuration>

The duration for which the given offer is valid.

A eligible_duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_eligible_duration>

A predicate for the L</eligible_duration> attribute.

=head2 C<eligible_quantity>

C<eligibleQuantity>

The interval and unit of measurement of ordering quantities for which the
offer or price specification is valid. This allows e.g. specifying that a
certain freight charge is valid only for a certain quantity.

A eligible_quantity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_eligible_quantity>

A predicate for the L</eligible_quantity> attribute.

=head2 C<eligible_region>

C<eligibleRegion>

=for html <p>The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or
the GeoShape for the geo-political region(s) for which the offer or
delivery charge specification is valid.<br/><br/> See also <a
class="localLink"
href="http://schema.org/ineligibleRegion">ineligibleRegion</a>.<p>

A eligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_eligible_region>

A predicate for the L</eligible_region> attribute.

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

=head2 C<_has_eligible_transaction_volume>

A predicate for the L</eligible_transaction_volume> attribute.

=head2 C<gtin>

=for html <p>A Global Trade Item Number (<a
href="https://www.gs1.org/standards/id-keys/gtin">GTIN</a>). GTINs identify
trade items, including products and services, using numeric identification
codes. The <a class="localLink" href="http://schema.org/gtin">gtin</a>
property generalizes the earlier <a class="localLink"
href="http://schema.org/gtin8">gtin8</a>, <a class="localLink"
href="http://schema.org/gtin12">gtin12</a>, <a class="localLink"
href="http://schema.org/gtin13">gtin13</a>, and <a class="localLink"
href="http://schema.org/gtin14">gtin14</a> properties. The GS1 <a
href="https://www.gs1.org/standards/Digital-Link/">digital link
specifications</a> express GTINs as URLs. A correct <a class="localLink"
href="http://schema.org/gtin">gtin</a> value should be a valid GTIN, which
means that it should be an all-numeric string of either 8, 12, 13 or 14
digits, or a "GS1 Digital Link" URL based on such a string. The numeric
component should also have a <a
href="https://www.gs1.org/services/check-digit-calculator">valid GS1 check
digit</a> and meet the other rules for valid GTINs. See also <a
href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1's GTIN
Summary</a> and <a
href="https://en.wikipedia.org/wiki/Global_Trade_Item_Number">Wikipedia</a>
for more details. Left-padding of the gtin values is not required or
encouraged.<p>

A gtin should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_gtin>

A predicate for the L</gtin> attribute.

=head2 C<gtin12>

=for html <p>The GTIN-12 code of the product, or the product to which the offer
refers. The GTIN-12 is the 12-digit GS1 Identification Key composed of a
U.P.C. Company Prefix, Item Reference, and Check Digit used to identify
trade items. See <a
href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1 GTIN
Summary</a> for more details.<p>

A gtin12 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_gtin12>

A predicate for the L</gtin12> attribute.

=head2 C<gtin13>

=for html <p>The GTIN-13 code of the product, or the product to which the offer
refers. This is equivalent to 13-digit ISBN codes and EAN UCC-13. Former
12-digit UPC codes can be converted into a GTIN-13 code by simply adding a
preceeding zero. See <a
href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1 GTIN
Summary</a> for more details.<p>

A gtin13 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_gtin13>

A predicate for the L</gtin13> attribute.

=head2 C<gtin14>

=for html <p>The GTIN-14 code of the product, or the product to which the offer
refers. See <a href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1
GTIN Summary</a> for more details.<p>

A gtin14 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_gtin14>

A predicate for the L</gtin14> attribute.

=head2 C<gtin8>

=for html <p>The <a
href="http://apps.gs1.org/GDD/glossary/Pages/GTIN-8.aspx">GTIN-8</a> code
of the product, or the product to which the offer refers. This code is also
known as EAN/UCC-8 or 8-digit EAN. See <a
href="http://www.gs1.org/barcodes/technical/idkeys/gtin">GS1 GTIN
Summary</a> for more details.<p>

A gtin8 should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_gtin8>

A predicate for the L</gtin8> attribute.

=head2 C<includes_object>

C<includesObject>

This links to a node or nodes indicating the exact quantity of the products
included in the offer.

A includes_object should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TypeAndQuantityNode']>

=back

=head2 C<_has_includes_object>

A predicate for the L</includes_object> attribute.

=head2 C<ineligible_region>

C<ineligibleRegion>

=for html <p>The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or
the GeoShape for the geo-political region(s) for which the offer or
delivery charge specification is not valid, e.g. a region where the
transaction is not allowed.<br/><br/> See also <a class="localLink"
href="http://schema.org/eligibleRegion">eligibleRegion</a>.<p>

A ineligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_ineligible_region>

A predicate for the L</ineligible_region> attribute.

=head2 C<inventory_level>

C<inventoryLevel>

The current approximate inventory level for the item or items.

A inventory_level should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_inventory_level>

A predicate for the L</inventory_level> attribute.

=head2 C<item_condition>

C<itemCondition>

A predefined value from OfferItemCondition or a textual description of the
condition of the product or service, or the products or services included
in the offer.

A item_condition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OfferItemCondition']>

=back

=head2 C<_has_item_condition>

A predicate for the L</item_condition> attribute.

=head2 C<item_offered>

C<itemOffered>

=for html <p>An item being offered (or demanded). The transactional nature of the
offer or demand is documented using <a class="localLink"
href="http://schema.org/businessFunction">businessFunction</a>, e.g. sell,
lease etc. While several common expected types are listed explicitly in
this definition, others can be used. Using a second type, such as Product
or a subtype of Product, can clarify the nature of the offer.<p>

A item_offered should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AggregateOffer']>

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=item C<InstanceOf['SemanticWeb::Schema::MenuItem']>

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<InstanceOf['SemanticWeb::Schema::Service']>

=item C<InstanceOf['SemanticWeb::Schema::Trip']>

=back

=head2 C<_has_item_offered>

A predicate for the L</item_offered> attribute.

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

=head2 C<mpn>

The Manufacturer Part Number (MPN) of the product, or the product to which
the offer refers.

A mpn should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_mpn>

A predicate for the L</mpn> attribute.

=head2 C<offered_by>

C<offeredBy>

A pointer to the organization or person making the offer.

A offered_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_offered_by>

A predicate for the L</offered_by> attribute.

=head2 C<price>

=for html <p>The offer price of a product, or of a price component when attached to
PriceSpecification and its subtypes.<br/><br/> Usage guidelines:<br/><br/>
<ul> <li>Use the <a class="localLink"
href="http://schema.org/priceCurrency">priceCurrency</a> property (with
standard formats: <a href="http://en.wikipedia.org/wiki/ISO_4217">ISO 4217
currency format</a> e.g. "USD"; <a
href="https://en.wikipedia.org/wiki/List_of_cryptocurrencies">Ticker
symbol</a> for cryptocurrencies e.g. "BTC"; well known names for <a
href="https://en.wikipedia.org/wiki/Local_exchange_trading_system">Local
Exchange Tradings Systems</a> (LETS) and other currency types e.g. "Ithaca
HOUR") instead of including <a
href="http://en.wikipedia.org/wiki/Dollar_sign#Currencies_that_use_the_doll
ar_or_peso_sign">ambiguous symbols</a> such as '$' in the value.</li>
<li>Use '.' (Unicode 'FULL STOP' (U+002E)) rather than ',' to indicate a
decimal point. Avoid using these symbols as a readability separator.</li>
<li>Note that both <a
href="http://www.w3.org/TR/xhtml-rdfa-primer/#using-the-content-attribute">
RDFa</a> and Microdata syntax allow the use of a "content=" attribute for
publishing simple machine-readable values alongside more human-friendly
formatting.</li> <li>Use values from 0123456789 (Unicode 'DIGIT ZERO'
(U+0030) to 'DIGIT NINE' (U+0039)) rather than superficially similiar
Unicode symbols.</li> </ul> <p>

A price should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<_has_price>

A predicate for the L</price> attribute.

=head2 C<price_currency>

C<priceCurrency>

=for html <p>The currency of the price, or a price component when attached to <a
class="localLink"
href="http://schema.org/PriceSpecification">PriceSpecification</a> and its
subtypes.<br/><br/> Use standard formats: <a
href="http://en.wikipedia.org/wiki/ISO_4217">ISO 4217 currency format</a>
e.g. "USD"; <a
href="https://en.wikipedia.org/wiki/List_of_cryptocurrencies">Ticker
symbol</a> for cryptocurrencies e.g. "BTC"; well known names for <a
href="https://en.wikipedia.org/wiki/Local_exchange_trading_system">Local
Exchange Tradings Systems</a> (LETS) and other currency types e.g. "Ithaca
HOUR".<p>

A price_currency should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_price_currency>

A predicate for the L</price_currency> attribute.

=head2 C<price_specification>

C<priceSpecification>

One or more detailed price specifications, indicating the unit price and
delivery or payment charges.

A price_specification should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=back

=head2 C<_has_price_specification>

A predicate for the L</price_specification> attribute.

=head2 C<price_valid_until>

C<priceValidUntil>

The date after which the price is no longer available.

A price_valid_until should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_price_valid_until>

A predicate for the L</price_valid_until> attribute.

=head2 C<review>

A review of the item.

A review should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

=back

=head2 C<_has_review>

A predicate for the L</review> attribute.

=head2 C<reviews>

Review of the item.

A reviews should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

=back

=head2 C<_has_reviews>

A predicate for the L</reviews> attribute.

=head2 C<seller>

An entity which offers (sells / leases / lends / loans) the services /
goods. A seller may also be a provider.

A seller should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_seller>

A predicate for the L</seller> attribute.

=head2 C<serial_number>

C<serialNumber>

The serial number or any alphanumeric identifier of a particular product.
When attached to an offer, it is a shortcut for the serial number of the
product included in the offer.

A serial_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_serial_number>

A predicate for the L</serial_number> attribute.

=head2 C<shipping_details>

C<shippingDetails>

=for html <p>Indicates information about the shipping policies and options associated
with an <a class="localLink" href="http://schema.org/Offer">Offer</a>.<p>

A shipping_details should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OfferShippingDetails']>

=back

=head2 C<_has_shipping_details>

A predicate for the L</shipping_details> attribute.

=head2 C<sku>

The Stock Keeping Unit (SKU), i.e. a merchant-specific identifier for a
product or service, or the product to which the offer refers.

A sku should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_sku>

A predicate for the L</sku> attribute.

=head2 C<valid_from>

C<validFrom>

The date when the item becomes valid.

A valid_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_valid_from>

A predicate for the L</valid_from> attribute.

=head2 C<valid_through>

C<validThrough>

The date after when the item is not valid. For example the end of an offer,
salary period, or a period of opening hours.

A valid_through should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_valid_through>

A predicate for the L</valid_through> attribute.

=head2 C<warranty>

The warranty promise(s) included in the offer.

A warranty should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WarrantyPromise']>

=back

=head2 C<_has_warranty>

A predicate for the L</warranty> attribute.

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
