##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Order.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/orders/object
package Net::API::Stripe::Order;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_returned { return( shift->_set_get_number( 'amount_returned', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub application_fee { return( shift->_set_get_number( 'application_fee', @_ ) ); }

sub charge { return( shift->_set_get_scalar_or_object( 'charge', 'Net::API::Stripe::Charge', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub external_coupon_code { return( shift->_set_get_scalar( 'external_coupon_code', @_ ) ); }

## Array of Net::API::Stripe::Order::Item
sub items { return( shift->_set_get_object_array( 'items', 'Net::API::Stripe::Order::Item', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub returns { return( shift->_set_get_object( 'returns', 'Net::API::Stripe::Order::Returns', @_ ) ); }

sub selected_shipping_method { return( shift->_set_get_scalar( 'selected_shipping_method', @_ ) ); }

sub shipping { return( shift->_set_get_object( 'shipping', 'Net::API::Stripe::Shipping', @_ ) ); }

sub shipping_methods { return( shift->_set_get_object_array( 'shipping_methods', 'Net::API::Stripe::Order::ShippingMethod', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub status_transitions { return( shift->_set_get_object( 'status_transitions', 'Net::API::Stripe::Order::StatusTransitions', @_ ) ); }

sub updated { return( shift->_set_get_datetime( 'updated', @_ ) ); }

sub upstream_id { return( shift->_set_get_scalar( 'upstream_id', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Order - A Stripe Order Object

=head1 SYNOPSIS

    my $order = $stripe->order({
        amount => 2000,
        amount_returned => undef,
        application => $connect_account_object,
        application_fee => 20,
        charge => $charge_object,
        currency => 'jpy',
        customer => $customer_object,
        email => 'john.doe@example.com',
        metadata => { transaction_id => 123, customer_id => 456 },
        returns => [],
        status => 'paid',
        status_transitions => $status_transitions_object,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Order objects are created to handle end customers' purchases of previously defined products (L<https://stripe.com/docs/api/orders#products>). You can create, retrieve, and pay individual orders, as well as list all orders. Orders are identified by a unique, random ID.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Order> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "order"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount for the order.

=head2 amount_returned integer

The total amount that was returned to the customer.

=head2 application string

ID of the Connect Application that created the order.

If this was somehow expanded, this would be a L<Net::API::Stripe::Connect::Account> object.

=head2 application_fee integer

A fee in cents that will be applied to the order and transferred to the application owner’s Stripe account. The request must be made with an OAuth key or the Stripe-Account header in order to take an application fee. For more information, see the application fees documentation.

=head2 charge string (expandable)

The ID of the payment used to pay for the order. Present if the order status is paid, fulfilled, or refunded.

When expanded, this is a L<Net::API::Stripe::Charge> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 customer string (expandable)

The customer used for the order.

When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 email string

The email address of the customer placing the order.

=head2 external_coupon_code string

External coupon code to load for this order.

=head2 items array of hashes

List of items constituting the order. An order can have up to 25 items.

This is an array of L<Net::API::Stripe::Order::Item> objects.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 returns list

This is an array of L<Net::API::Stripe::Order::Returns> objects.

=head2 selected_shipping_method string

The shipping method that is currently selected for this order, if any. If present, it is equal to one of the ids of shipping methods in the shipping_methods array. At order creation time, if there are multiple shipping methods, Stripe will automatically selected the first method.

=head2 shipping hash

The shipping address for the order. Present if the order is for goods to be shipped.

This is a L<Net::API::Stripe::Shipping> object.

=head2 shipping_methods array of hashes

A list of supported shipping methods for this order. The desired shipping method can be specified either by updating the order, or when paying it.

This is an array of L<Net::API::Stripe::Order::ShippingMethod> objects.

=head2 status string

Current order status. One of created, paid, canceled, fulfilled, or returned. More details in the Orders Guide.

=head2 status_transitions hash

The timestamps at which the order status was updated.

This is a L<Net::API::Stripe::Order::StatusTransitions> object.

=head2 updated timestamp

Time at which the object was last updated. Measured in seconds since the Unix epoch.

=head2 upstream_id string

The user’s order ID if it is different from the Stripe order ID.

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

L<https://stripe.com/docs/api/orders>, L<https://stripe.com/docs/orders>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
