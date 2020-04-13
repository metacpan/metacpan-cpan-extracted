##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/ShippingMethod.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Order::ShippingMethod;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub delivery_estimate { shift->_set_get_object( 'delivery_estimate', 'Net::API::Stripe::Order::DeliveryEstimate', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::ShippingMethod - A Stripe Order Shipping Method Object

=head1 SYNOPSIS

    my $meth = $stripe->order->shipping_method({
        id => 'SP2020041201',
        amount => 2000,
        currency => 'jpy',
        delivery_estimate => $estimate_object,
        description => 'Easter present',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

A list of supported shipping methods for this order. The desired shipping method can be specified either by updating the order, or when paying it.

This is instantiated by method B<shipping_methods> in module L<Net::API::Stripe::Order>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Order::ShippingMethod> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<amount> integer

A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount for the line item.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<delivery_estimate> hash

The estimated delivery date for the given shipping method. Can be either a specific date or a range.

This is a L<Net::API::Stripe::Order::DeliveryEstimate> object.

=back

=head1 API SAMPLE

	{
	  "id": "or_fake123456789",
	  "object": "order",
	  "amount": 1500,
	  "amount_returned": null,
	  "application": null,
	  "application_fee": null,
	  "charge": null,
	  "created": 1571480453,
	  "currency": "jpy",
	  "customer": null,
	  "email": null,
	  "items": [
		{
		  "object": "order_item",
		  "amount": 1500,
		  "currency": "jpy",
		  "description": "T-shirt",
		  "parent": "sk_fake123456789",
		  "quantity": null,
		  "type": "sku"
		}
	  ],
	  "livemode": false,
	  "metadata": {},
	  "returns": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/order_returns?order=or_fake123456789"
	  },
	  "selected_shipping_method": null,
	  "shipping": {
		"address": {
		  "city": "Anytown",
		  "country": "US",
		  "line1": "1234 Main street",
		  "line2": null,
		  "postal_code": "123456",
		  "state": null
		},
		"carrier": null,
		"name": "Jenny Rosen",
		"phone": null,
		"tracking_number": null
	  },
	  "shipping_methods": null,
	  "status": "created",
	  "status_transitions": {
		"canceled": null,
		"fulfiled": null,
		"paid": null,
		"returned": null
	  },
	  "updated": 1571480453
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/orders/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
