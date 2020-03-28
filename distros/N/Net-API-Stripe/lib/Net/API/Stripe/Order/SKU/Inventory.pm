##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/SKU/Inventory.pm
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
package Net::API::Stripe::Order::SKU::Inventory;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub quantity { shift->_set_get_scalar( 'quantity', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

sub value { shift->_set_get_scalar( 'value', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::SKU::Inventory - A Stripe SKU Inventory Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Description of the SKU’s inventory.

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

=item B<quantity> positive integer or zero

The count of inventory available. Will be present if and only if type is finite.

=item B<type> string

Inventory type. Possible values are finite, bucket (not quantified), and infinite.

=item B<value> string

An indicator of the inventory available. Possible values are in_stock, limited, and out_of_stock. Will be present if and only if type is bucket.

=back

=head1 API SAMPLE

	{
	  "id": "sku_G1HcdqsCPOkGA7",
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
	  "product": "prod_Dwk1FH8ifmrGgw",
	  "updated": 1571480453
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

