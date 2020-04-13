##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Checkout/Item.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/12/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Checkout::Item;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.2';
};

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub custom { return( shift->_set_get_hash( 'custom', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub images { return( shift->_set_get_array( 'images', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

sub quantity { return( shift->_set_get_number( 'quantity', @_ ) ); }

sub sku { return( shift->_set_get_object( 'sku', 'Net::API::Stripe::Order::SKU', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Checkout::Item - A Stripe Checkout Item

=head1 SYNOPSIS

    my $item = $stripe->session->display_items([
    {
        amount => 2000,
        currency => 'jpy',
        description => 'Some item',
        name => 'Session item',
        plan => $plan_object,
        quantity => 1,
        type => 'plan',
    }]);

=head1 VERSION

    0.2

=head1 DESCRIPTION

The line items, plans, or SKUs purchased by the customer.

This is part of the L<Net::API::Stripe::Checkout::Session> object an called from the method B<display_items>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Checkout::Item> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<amount> integer

Amount for the display item.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<custom> hash

=over 8

=item I<description> string

The description of the line item.

=item I<images> array containing strings

The images of the line item.

=item I<name> string

The name of the line item.

=back

=item B<description> string

The description for the line item.  This is used in session checkout I<line_items>.

=item B<images> string

A list of images representing this line item.  This is used in session checkout I<line_items>.

=item B<name> string

The name for the line item.  This is used in session checkout I<line_items>.

=item B<plan> hash, plan object

This is a L<Net::API::Stripe::Billing::Plan> object.

=item B<quantity> integer

Quantity of the display item being purchased.

=item B<sku> hash, sku object

This is a L<Net::API::Stripe::Order::SKU> object.

=item B<type> string

The type of display item. One of custom, plan or sku

=back

=head1 API SAMPLE

	{
	  "id": "ppage_fake123456789",
	  "object": "checkout.session",
	  "billing_address_collection": null,
	  "cancel_url": "https://example.com/cancel",
	  "client_reference_id": null,
	  "customer": null,
	  "customer_email": null,
	  "display_items": [
		{
		  "amount": 1500,
		  "currency": "usd",
		  "custom": {
			"description": "Comfortable cotton t-shirt",
			"images": null,
			"name": "T-shirt"
		  },
		  "quantity": 2,
		  "type": "custom"
		}
	  ],
	  "livemode": false,
	  "locale": null,
	  "mode": null,
	  "payment_intent": "pi_fake123456789",
	  "payment_method_types": [
		"card"
	  ],
	  "setup_intent": null,
	  "submit_type": null,
	  "subscription": null,
	  "success_url": "https://example.com/success",
	  "line_items": [
		{
		  "name": "T-shirt",
		  "description": "Comfortable cotton t-shirt",
		  "amount": 1500,
		  "currency": "jpy",
		  "quantity": 2
		}
	  ]
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

