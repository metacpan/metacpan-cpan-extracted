##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Checkout/Item.pm
## Version v0.200.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Checkout::Item;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::List::Item );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.200.0';
};

use strict;
use warnings;

# Method amount is inherited

# Method currency is inherited

sub custom { return( shift->_set_get_hash( 'custom', @_ ) ); }

# Method description is inherited

sub images { return( shift->_set_get_array( 'images', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub plan { return( shift->_set_get_object( 'plan', 'Net::API::Stripe::Billing::Plan', @_ ) ); }

# Method quantity is inherited

sub sku { return( shift->_set_get_object( 'sku', 'Net::API::Stripe::Order::SKU', @_ ) ); }

# Method type is inherited

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

    v0.200.0

=head1 DESCRIPTION

The line items, plans, or SKUs purchased by the customer.

This is part of the L<Net::API::Stripe::Checkout::Session> object an called from the method B<display_items>

It inherits from L<Net::API::Stripe::List::Item>

=head1 CONSTRUCTOR

=head2 new

Creates a new L<Net::API::Stripe::Checkout::Item> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 amount integer

Amount for the display item.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 custom hash

=over 4

=item I<description> string

The description of the line item.

=item I<images> array containing strings

The images of the line item.

=item I<name> string

The name of the line item.

=back

=head2 description string

The description for the line item.  This is used in session checkout I<line_items>.

=head2 images string

A list of images representing this line item.  This is used in session checkout I<line_items>.

=head2 name string

The name for the line item.  This is used in session checkout I<line_items>.

=head2 plan hash, plan object

This is a L<Net::API::Stripe::Billing::Plan> object.

=head2 quantity integer

Quantity of the display item being purchased.

=head2 sku hash, sku object

This is a L<Net::API::Stripe::Order::SKU> object.

=head2 type string

The type of display item. One of custom, plan or sku

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

