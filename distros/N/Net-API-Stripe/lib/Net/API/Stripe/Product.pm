##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Product.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## "A list of up to 5 attributes that each SKU can provide values for (e.g., ["color", "size"]). Only applicable to products of type=good."
package Net::API::Stripe::Product;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub active { shift->_set_get_boolean( 'active', @_ ); }

sub attributes { shift->_set_get_array( 'attributes', @_ ); }

sub caption { shift->_set_get_scalar( 'caption', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub deactivate_on { shift->_set_get_array( 'deactivate_on', @_ ); }

sub deleted { return( shift->_set_get_boolean( 'deleted', @_ ) ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub images { shift->_set_get_array( 'images', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub name { shift->_set_get_scalar( 'name', @_ ); }

sub package_dimensions { shift->_set_get_object( 'package_dimensions', 'Net::API::Stripe::Product::PackageDimension', @_ ); }

sub shippable { shift->_set_get_scalar( 'shippable', @_ ); }

## List of Net::API::Stripe::Order::SKU objects
sub skus { return( shift->_set_get_object( 'Net::API::Stripe::List', @_ ) ); }

sub statement_descriptor { shift->_set_get_scalar( 'statement_descriptor', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

sub unit_label { shift->_set_get_scalar( 'unit_label', @_ ); }

sub updated { shift->_set_get_datetime( 'updated', @_ ); }

sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Product - A Stripe Product Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Store representations of products you sell in Product objects, used in conjunction with SKUs (L<https://stripe.com/docs/api/products#skus>). Products may be physical goods, to be shipped, or digital.

Documentation on Products for use with Subscriptions can be found at Subscription Products (L<https://stripe.com/docs/api/products#service_products>).

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "product"

String representing the object’s type. Objects of the same type share the same value.

=item B<active> boolean

Whether the product is currently available for purchase.

=item B<attributes> array containing strings

A list of up to 5 attributes that each SKU can provide values for (e.g., ["color", "size"]). Only applicable to products of type=good.

=item B<caption> string

A short one-line description of the product, meant to be displayable to the customer. Only applicable to products of type=good.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<deactivate_on> array containing strings

An array of connect application identifiers that cannot purchase this product. Only applicable to products of type=good.

=item B<deleted> boolean

Set to true when the product has been deleted.

=item B<description> string

The product’s description, meant to be displayable to the customer. Only applicable to products of type=good.

=item B<images> array containing strings

A list of up to 8 URLs of images for this product, meant to be displayable to the customer. Only applicable to products of type=good.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<name> string

The product’s name, meant to be displayable to the customer. Applicable to both service and good types.

=item B<package_dimensions> hash

The dimensions of this product for shipping purposes. A SKU associated with this product can override this value by having its own package_dimensions. Only applicable to products of type=good.

This is a C<Net::API::Stripe::Product::PackageDimension> object.

=item B<shippable> boolean

Whether this product is a shipped good. Only applicable to products of type=good.

=item B<skus> list

This is a list (C<Net::API::Stripe::List>) of C<Net::API::Stripe::Order::SKU> objects.

This is an undocumented property.

=item B<statement_descriptor> string

Extra information about a product which will appear on your customer’s credit card statement. In the case that multiple products are billed at once, the first statement descriptor will be used. Only available on products of type=service.

=item B<type> string

The type of the product. The product is either of type good, which is eligible for use with Orders and SKUs, or service, which is eligible for use with Subscriptions and Plans.

=item B<unit_label> string

A label that represents units of this product, such as seat(s), in Stripe and on customers’ receipts and invoices. Only available on products of type=service.

=item B<updated> timestamp

=item B<url> string

A URL of a publicly-accessible webpage for this product. Only applicable to products of type=good

=back

=head1 API SAMPLE

	{
	  "id": "prod_Dwk1FH8ifmrGgw",
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
	  "name": "Angels, Inc investor yearly membership",
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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
