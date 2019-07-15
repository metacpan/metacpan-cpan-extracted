use utf8;

package SemanticWeb::Schema::Product;

# ABSTRACT: Any offered product or service

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'Product';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has additional_property => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'additionalProperty',
);



has aggregate_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'aggregateRating',
);



has audience => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'audience',
);



has award => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'award',
);



has awards => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'awards',
);



has brand => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'brand',
);



has category => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'category',
);



has color => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'color',
);



has depth => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'depth',
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



has height => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'height',
);



has is_accessory_or_spare_part_for => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isAccessoryOrSparePartFor',
);



has is_consumable_for => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isConsumableFor',
);



has is_related_to => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isRelatedTo',
);



has is_similar_to => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isSimilarTo',
);



has item_condition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemCondition',
);



has logo => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'logo',
);



has manufacturer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'manufacturer',
);



has material => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'material',
);



has model => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'model',
);



has mpn => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'mpn',
);



has offers => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'offers',
);



has product_id => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'productID',
);



has production_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'productionDate',
);



has purchase_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'purchaseDate',
);



has release_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'releaseDate',
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



has sku => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sku',
);



has slogan => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'slogan',
);



has weight => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'weight',
);



has width => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'width',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Product - Any offered product or service

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Any offered product or service. For example: a pair of shoes; a concert
ticket; the rental of a car; a haircut; or an episode of a TV show streamed
online.

=head1 ATTRIBUTES

=head2 C<additional_property>

C<additionalProperty>

=for html A property-value pair representing an additional characteristics of the
entitity, e.g. a product feature or another characteristic for which there
is no matching property in schema.org.<br/><br/> Note: Publishers should be
aware that applications designed to use specific schema.org properties
(e.g. http://schema.org/width, http://schema.org/color,
http://schema.org/gtin13, ...) will typically expect such data to be
provided using those properties, rather than using the generic
property/value mechanism.

A additional_property should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PropertyValue']>

=back

=head2 C<aggregate_rating>

C<aggregateRating>

The overall rating, based on a collection of reviews or ratings, of the
item.

A aggregate_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AggregateRating']>

=back

=head2 C<audience>

An intended audience, i.e. a group for whom something was created.

A audience should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=back

=head2 C<award>

An award won by or for this item.

A award should be one of the following types:

=over

=item C<Str>

=back

=head2 C<awards>

Awards won by or for this item.

A awards should be one of the following types:

=over

=item C<Str>

=back

=head2 C<brand>

The brand(s) associated with a product or service, or the brand(s)
maintained by an organization or business person.

A brand should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Brand']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<category>

A category for the item. Greater signs or slashes can be used to informally
indicate a category hierarchy.

A category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PhysicalActivityCategory']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<color>

The color of the product.

A color should be one of the following types:

=over

=item C<Str>

=back

=head2 C<depth>

The depth of the item.

A depth should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

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

=head2 C<height>

The height of the item.

A height should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<is_accessory_or_spare_part_for>

C<isAccessoryOrSparePartFor>

A pointer to another product (or multiple products) for which this product
is an accessory or spare part.

A is_accessory_or_spare_part_for should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=back

=head2 C<is_consumable_for>

C<isConsumableFor>

A pointer to another product (or multiple products) for which this product
is a consumable.

A is_consumable_for should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=back

=head2 C<is_related_to>

C<isRelatedTo>

A pointer to another, somehow related product (or multiple products).

A is_related_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<InstanceOf['SemanticWeb::Schema::Service']>

=back

=head2 C<is_similar_to>

C<isSimilarTo>

A pointer to another, functionally similar product (or multiple products).

A is_similar_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<InstanceOf['SemanticWeb::Schema::Service']>

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

=head2 C<logo>

An associated logo.

A logo should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=item C<Str>

=back

=head2 C<manufacturer>

The manufacturer of the product.

A manufacturer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<material>

A material that something is made from, e.g. leather, wool, cotton, paper.

A material should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<Str>

=back

=head2 C<model>

The model of the product. Use with the URL of a ProductModel or a textual
representation of the model identifier. The URL of the ProductModel can be
from an external source. It is recommended to additionally provide strong
product identifiers via the gtin8/gtin13/gtin14 and mpn properties.

A model should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ProductModel']>

=item C<Str>

=back

=head2 C<mpn>

The Manufacturer Part Number (MPN) of the product, or the product to which
the offer refers.

A mpn should be one of the following types:

=over

=item C<Str>

=back

=head2 C<offers>

An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event.

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<product_id>

C<productID>

=for html The product identifier, such as ISBN. For example: <code>meta
itemprop="productID" content="isbn:123-456-789"</code>.

A product_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<production_date>

C<productionDate>

The date of production of the item, e.g. vehicle.

A production_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<purchase_date>

C<purchaseDate>

The date the item e.g. vehicle was purchased by the current owner.

A purchase_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<release_date>

C<releaseDate>

The release date of a product or product model. This can be used to
distinguish the exact variant of a product.

A release_date should be one of the following types:

=over

=item C<Str>

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

=head2 C<sku>

The Stock Keeping Unit (SKU), i.e. a merchant-specific identifier for a
product or service, or the product to which the offer refers.

A sku should be one of the following types:

=over

=item C<Str>

=back

=head2 C<slogan>

A slogan or motto associated with the item.

A slogan should be one of the following types:

=over

=item C<Str>

=back

=head2 C<weight>

The weight of the product or person.

A weight should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<width>

The width of the item.

A width should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Thing>

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
