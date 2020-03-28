##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order/Item.pm
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
## https://stripe.com/docs/api/order_items/object
package Net::API::Stripe::Order::Item;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub parent { shift->_set_get_scalar_or_object( 'parent', 'Net::API::Stripe::Order', @_ ); }

sub quantity { shift->_set_get_number( 'quantity', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order::Item - A Stripe Order Item Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

A representation of the constituent items of any given order. Can be used to represent SKUs, shipping costs, or taxes owed on the order.

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

=item B<object> string, value is "order_item"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> integer

A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount for the line item.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<description> string

Description of the line item, meant to be displayable to the user (e.g., "Express shipping").

=item B<parent> string (expandable) discount or sku

The ID of the associated object for this line item. Expandable if not null (e.g., expandable to a SKU).

When expanded, this is a C<Net::API::Stripe::Order> object.

=item B<quantity> positive integer

A positive integer representing the number of instances of parent that are included in this order item. Applicable/present only if type is sku.

=item B<type> string

The type of line item. One of sku, tax, shipping, or discount.

=back

=head1 API SAMPLE

	{
	  "object": "order_item",
	  "amount": 1500,
	  "currency": "jpy",
	  "description": "T-shirt",
	  "parent": "sk_19eIKPCeyNCl6fY2Bxpfr8bb",
	  "quantity": null,
	  "type": "sku"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/order_items>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
