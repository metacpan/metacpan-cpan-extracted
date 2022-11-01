##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Product.pm
## Version v0.101.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
## "A list of up to 5 attributes that each SKU can provide values for (e.g., ["color", "size"]). Only applicable to products of type=good."
package Net::API::Stripe::Product;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub attributes { return( shift->_set_get_array( 'attributes', @_ ) ); }

sub caption { return( shift->_set_get_scalar( 'caption', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub deactivate_on { return( shift->_set_get_array( 'deactivate_on', @_ ) ); }

sub default_price { return( shift->_set_get_scalar_or_object( 'default_price', 'Net::API::Stripe::Price', @_ ) ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub images { return( shift->_set_get_array( 'images', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub package_dimensions { return( shift->_set_get_object( 'package_dimensions', 'Net::API::Stripe::Product::PackageDimension', @_ ) ); }

sub shippable { return( shift->_set_get_scalar( 'shippable', @_ ) ); }

## List of Net::API::Stripe::Order::SKU objects

sub skus { return( shift->_set_get_object( 'Net::API::Stripe::List', @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub tax_code { return( shift->_set_get_scalar_or_object( 'tax_code', 'Net::API::Stripe::Product::TaxCode', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub unit_label { return( shift->_set_get_scalar( 'unit_label', @_ ) ); }

sub updated { return( shift->_set_get_datetime( 'updated', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Product - A Stripe Product Object

=head1 SYNOPSIS

    my $prod = $stripe->product({
        active => $stripe->true,
        attributes => [qw( colour size gender )],
        caption => 'Fashionable T-shirt',
        description => 'Product for limited edition t-shirt',
        images => [qw(
            https://img.example.com/p12/file1.jpg
            https://img.example.com/p12/file2.jpg
            https://img.example.com/p12/file3.jpg
        )],
        livemode => $stripe->false,
        metadata => { product_id => 123, customer_id => 456 },
        name => 'Limited Edition Shirt',
        package_dimensions =>
        {
            use_metric => 1,
            width => 30,
            length => 50,
            height => 15,
            weight => 500,
        },
        shippable => $stripe->true,
        type => 'good',
        url => 'https://store.example.com/p12/',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Store representations of products you sell in Product objects, used in conjunction with L<SKUs|https://stripe.com/docs/api/products#skus>. Products may be physical goods, to be shipped, or digital.

Documentation on Products for use with Subscriptions can be found at L<Subscription Products|https://stripe.com/docs/api/products#service_products>.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Product> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "product"

String representing the object’s type. Objects of the same type share the same value.

=head2 active boolean

Whether the product is currently available for purchase.

=head2 attributes array containing strings

A list of up to 5 attributes that each SKU can provide values for (e.g., ["color", "size"]). Only applicable to products of type=good.

=head2 caption string

A short one-line description of the product, meant to be displayable to the customer. Only applicable to products of type=good.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 deactivate_on array containing strings

An array of connect application identifiers that cannot purchase this product. Only applicable to products of type=good.

=head2 default_price expandable

The ID of the L<Price|https://stripe.com/docs/api/prices> object that is the default price for this product.

When expanded this is an L<Net::API::Stripe::Price> object.

=head2 deleted boolean

Set to true when the product has been deleted.

=head2 description string

The product’s description, meant to be displayable to the customer. Only applicable to products of type=good.

=head2 images array containing strings

A list of up to 8 URLs of images for this product, meant to be displayable to the customer. Only applicable to products of type=good.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 name string

The product’s name, meant to be displayable to the customer. Applicable to both service and good types.

=head2 package_dimensions hash

The dimensions of this product for shipping purposes. A SKU associated with this product can override this value by having its own package_dimensions. Only applicable to products of type=good.

This is a L<Net::API::Stripe::Product::PackageDimension> object.

=head2 shippable boolean

Whether this product is a shipped good. Only applicable to products of type=good.

=head2 skus list

This is a list (L<Net::API::Stripe::List>) of L<Net::API::Stripe::Order::SKU> objects.

This is an undocumented property.

=head2 statement_descriptor string

Extra information about a product which will appear on your customer’s credit card statement. In the case that multiple products are billed at once, the first statement descriptor will be used. Only available on products of type=service.

=head2 tax_code expandable

A L<tax code|https://stripe.com/docs/tax/tax-categories> ID.

When expanded this is an L<Net::API::Stripe::Product::TaxCode> object.

=head2 type string

The type of the product. The product is either of type good, which is eligible for use with Orders and SKUs, or service, which is eligible for use with Subscriptions and Plans.

=head2 unit_label string

A label that represents units of this product, such as seat(s), in Stripe and on customers’ receipts and invoices. Only available on products of type=service.

=head2 updated timestamp

Time at which the object was last updated. Measured in seconds since the Unix epoch.

=head2 url string

A URL of a publicly-accessible webpage for this product. Only applicable to products of type=good

This returns a L<URI> object.

=head1 API SAMPLE

    {
      "id": "prod_fake123456789",
      "object": "product",
      "active": true,
      "attributes": [],
      "caption": null,
      "created": 1541833574,
      "deactivate_on": [],
      "description": null,
      "images": [],
      "livemode": false,
      "metadata": {},
      "name": "Provider, Inc investor yearly membership",
      "package_dimensions": null,
      "shippable": null,
      "statement_descriptor": null,
      "type": "service",
      "unit_label": null,
      "updated": 1565089803,
      "url": null
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2018-05-21

Products no longer have SKU lists embedded.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/products>, L<https://stripe.com/docs/orders#define-products-skus>, L<https://stripe.com/docs/billing/subscriptions/products-and-plans#products>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
