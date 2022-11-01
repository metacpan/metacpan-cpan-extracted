##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/Discount.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/discounts
package Net::API::Stripe::Billing::Discount;
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

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub checkout_session { return( shift->_set_get_scalar( 'checkout_session', @_ ) ); }

sub coupon { return( shift->_set_get_object( 'coupon', 'Net::API::Stripe::Billing::Coupon', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub end { return( shift->_set_get_datetime( 'end', @_ ) ); }

sub invoice { return( shift->_set_get_scalar( 'invoice', @_ ) ); }

sub invoice_item { return( shift->_set_get_scalar( 'invoice_item', @_ ) ); }

sub promotion_code { return( shift->_set_get_scalar_or_object( 'promotion_code', 'Net::API::Stripe::Billing::PromotionCode', @_ ) ); }

sub start { return( shift->_set_get_datetime( 'start', @_ ) ); }

sub subscription { return( shift->_set_get_scalar( 'subscription', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::Discount - A Stripe Discount

=head1 SYNOPSIS

    my $discount = $stripe->discount({
        coupon => $stripe->coupon({
            id => 'SUMMER10POFF',
            currency => 'usd',
            duration_in_months => 2,
            max_redemptions => 12,
            name => 'Summer 10% reduction',
            percent_off => 10,
            valid => 1
        }),
        customer => $customer_object,
        # undef() for once or forever
        end => '2020-12-31',
        start => '2020-06-01',
        subscription => 'sub_fake1234567',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

A discount represents the actual application of a coupon to a particular customer. It contains information about when the discount began and when it will end.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Billing::Discount> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 object string, value is "discount"

String representing the object’s type. Objects of the same type share the same value.

=head2 id string

The ID of the discount object. Discounts cannot be fetched by ID. Use C<expand[]=discounts> in API calls to expand discount IDs in an array.

=head2 checkout_session string

The Checkout session that this coupon is applied to, if it is applied to a particular session in payment mode. Will not be present for subscription mode.

=head2 coupon hash, coupon object

Hash describing the coupon applied to create this discount. This is a L<Net::API::Stripe::Billing::Coupon> object.

=head2 customer string (expandable)

This is the Stripe customer id, or when expanded, this is the L<Net::API::Stripe::Customer> object.

=head2 end timestamp

If the coupon has a duration of repeating, the date that this discount will end. If the coupon has a duration of once or forever, this attribute will be null.

=head2 invoice string

The invoice that the discount's coupon was applied to, if it was applied directly to a particular invoice.

=head2 invoice_item string

The invoice item C<id> (or invoice line item C<id> for invoice line items of type='subscription') that the discount's coupon was applied to, if it was applied directly to a particular invoice item or invoice line item.

=head2 promotion_code expandable

The promotion code applied to create this discount.

When expanded this is an L<Net::API::Stripe::Billing::PromotionCode> object.

=head2 start timestamp

Date that the coupon was applied.

=head2 subscription string

The subscription that this coupon is applied to, if it is applied to a particular subscription.

=head1 API SAMPLE

    {
      "object": "discount",
      "coupon": {
        "id": "25_5OFF",
        "object": "coupon",
        "amount_off": null,
        "created": 1571397911,
        "currency": null,
        "duration": "repeating",
        "duration_in_months": 3,
        "livemode": false,
        "max_redemptions": null,
        "metadata": {},
        "name": "25.5% off",
        "percent_off": 25.5,
        "redeem_by": null,
        "times_redeemed": 0,
        "valid": true
      },
      "customer": "cus_fake124567890",
      "end": 1579346711,
      "start": 1571397911,
      "subscription": null
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>, L<https://stripe.com/docs/billing/subscriptions/discounts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
