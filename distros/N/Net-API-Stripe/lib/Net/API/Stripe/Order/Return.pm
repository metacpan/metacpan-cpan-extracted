##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/Return.pm
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
## https://stripe.com/docs/api/order_returns/object
package Net::API::Stripe::Order::Return;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

## Array of Net::API::Stripe::Order::Item
sub items { shift->_set_get_object_array( 'items', 'Net::API::Stripe::Order::Item', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub order { shift->_set_get_scalar_or_object( 'order', 'Net::API::Stripe::Order', @_ ); }

sub refund { shift->_set_get_scalar_or_object( 'refund', 'Net::API::Stripe::Refund', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::Return - A Stripe Order Return Object

=head1 SYNOPSIS

    my $return = $stripe->return({
        amount => 2000,
        currency => 'jpy',
        items => [ $item_object1, $item_object2 ],
        order => $order_object,
        refund => undef,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

A return represents the full or partial return of a number of order items (L<https://stripe.com/docs/api/order_returns#order_items>). Returns always belong to an order, and may optionally contain a refund.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Order::Return> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "order_return"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount for the returned line item.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<items> array of hashes

The items included in this order return.

This is an array of L<Net::API::Stripe::Order::Item> objects.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<order> string (expandable)

The order that this return includes items from.

When expanded, this is a L<Net::API::Stripe::Order> object.

=item B<refund> string (expandable)

The ID of the refund issued for this return.

When expanded, this is a L<Net::API::Stripe::Refund> object.

=back

=head1 API SAMPLE

	{
	  "id": "orret_fake123456789",
	  "object": "order_return",
	  "amount": 1500,
	  "created": 1571480456,
	  "currency": "jpy",
	  "items": [
		{
		  "object": "order_item",
		  "amount": 1500,
		  "currency": "jpy",
		  "description": "Provider, Inc investor yearly membership",
		  "parent": "sk_fake123456789",
		  "quantity": null,
		  "type": "sku"
		}
	  ],
	  "livemode": false,
	  "order": "or_fake123456789",
	  "refund": "re_fake123456789"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/order_returns>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
