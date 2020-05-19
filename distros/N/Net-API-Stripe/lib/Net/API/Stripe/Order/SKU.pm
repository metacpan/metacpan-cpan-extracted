##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/SKU.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/skus/object
package Net::API::Stripe::Order::SKU;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.100.0';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub active { shift->_set_get_boolean( 'active', @_ ); }

sub attributes { shift->_set_get_hash( 'attributes', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub image { shift->_set_get_uri( 'image', @_ ); }

sub inventory { shift->_set_get_object( 'inventory', 'Net::API::Stripe::Order::SKU::Inventory', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub package_dimensions { shift->_set_get_object( 'package_dimensions', 'Net::API::Stripe::Order::SKU::PackageDimensions', @_ ); }

sub price { shift->_set_get_number( 'price', @_ ); }

sub product { shift->_set_get_scalar_or_object( 'product', 'Net::API::Stripe::Product', @_ ); }

sub updated { shift->_set_get_datetime( 'updated', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::SKU - A Stripe SKU Object

=head1 SYNOPSIS

    my $sku = $stripe->sku({
        active => $stripe->true,
        attributes => 
        {
            size => 'Medium',
            gender => 'Unisex',
        },
        currency => 'jpy',
        image => 'https://example.com/path/product.jpg',
        inventory => $inventory_object,
        metadata => { transaction_id => 123 },
        package_dimensions =>
        {
            # In inches
			height => 6,
			length => 20,
			# Ounce
			weight => 21
			width => 12
        },
        price => 2000,
        product => $product_object,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Stores representations of stock keeping units (L<http://en.wikipedia.org/wiki/Stock_keeping_unit>). SKUs describe specific product variations, taking into account any combination of: attributes, currency, and cost. For example, a product may be a T-shirt, whereas a specific SKU represents the size: large, color: red version of that shirt.

Can also be used to manage inventory.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Order::SKU> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "sku"

String representing the object’s type. Objects of the same type share the same value.

=item B<active> boolean

Whether the SKU is available for purchase.

=item B<attributes> hash

A dictionary of attributes and values for the attributes defined by the product. If, for example, a product’s attributes are ["size", "gender"], a valid SKU has the following dictionary of attributes: {"size": "Medium", "gender": "Unisex"}.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<image> string

The URL of an image for this SKU, meant to be displayable to the customer.

This is a L<URI> object.

=item B<inventory> hash

Description of the SKU’s inventory.

This is a L<Net::API::Stripe::Order::SKU::Inventory> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<package_dimensions> hash

The dimensions of this SKU for shipping purposes.

This is a L<Net::API::Stripe::Order::SKU::PackageDimensions> object.

=item B<price> positive integer or zero

The cost of the item as a positive integer in the smallest currency unit (that is, 100 cents to charge $1.00, or 100 to charge ¥100, Japanese Yen being a zero-decimal currency).

=item B<product> string (expandable)

The ID of the product this SKU is associated with. The product must be currently active.

When expanded, this is a L<Net::API::Stripe::Product> object.

=item B<updated> timestamp

=back

=head1 API SAMPLE

	{
	  "id": "sku_fake123456789",
	  "object": "sku",
	  "active": true,
	  "attributes": {
		"size": "Medium",
		"gender": "Unisex"
	  },
	  "created": 1571480453,
	  "currency": "jpy",
	  "image": null,
	  "inventory": {
		"quantity": 50,
		"type": "finite",
		"value": null
	  },
	  "livemode": false,
	  "metadata": {},
	  "package_dimensions": null,
	  "price": 1500,
	  "product": "prod_fake123456789",
	  "updated": 1571480453
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/skus>, L<https://stripe.com/docs/orders>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
