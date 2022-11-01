package Net::API::Stripe::Product::PromotionCode;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }

sub code { return( shift->_set_get_scalar( 'code', @_ ) ); }

sub coupon { return( shift->_set_get_object( 'coupon', 'Net::API::Stripe::Product::Coupon', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub expires_at { return( shift->_set_get_datetime( 'expires_at', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub max_redemptions { return( shift->_set_get_number( 'max_redemptions', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub restrictions { return( shift->_set_get_class( 'restrictions',
{
  first_time_transaction  => { type => "boolean" },
  minimum_amount          => { type => "number" },
  minimum_amount_currency => { type => "scalar" },
}, @_ ) ); }

sub times_redeemed { return( shift->_set_get_number( 'times_redeemed', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Product::PromotionCode - The promotion code object

=head1 SYNOPSIS

    my $promo = $stripe->promotion_code({
        active => $stripe->true,
        code => 'TS0EQJHH',
        ## Net::API::Stripe::Product::Coupon
        coupon => $coupon_object,
        created => 'now',
        ## Net::API::Stripe::Customer
        customer => $customer_object,
        expires_at => '+3M',
        livemode => $stripe->false,
        max_redemptions => 10,
        metadata => { customer_id => 123, trans_id => 456 },
        restrictions =>
        {
            first_time_transaction => $stripe->true,
            minimum_amount => 1000,
            minimum_amount_currency => 'jpy',
        },
        times_redeemed => 0,
    });

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A Promotion Code represents a customer-redeemable code for a coupon. It can be used to create multiple codes for a single coupon.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 active boolean

Whether the promotion code is currently active. A promotion code is only active if the coupon is also valid.

=head2 code string

The customer-facing code. Regardless of case, this code must be unique across all active promotion codes for each customer.

=head2 coupon hash

Hash describing the coupon for this promotion code.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 customer expandable

The customer that this promotion code can be used by.

When expanded this is an L<Net::API::Stripe::Customer> object.

=head2 expires_at timestamp

Date at which the promotion code can no longer be redeemed.

=head2 livemode boolean

Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.

=head2 max_redemptions positive_integer

Maximum number of times this promotion code can be redeemed.

=head2 metadata hash

Set of [key-value pairs](/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 restrictions hash

Settings that restrict the redemption of the promotion code.

It has the following properties:

=over 4

=item I<first_time_transaction> boolean

A Boolean indicating if the Promotion Code should only be redeemed for Customers without any successful payments or invoices

=item I<minimum_amount> positive_integer

Minimum amount required to redeem this Promotion Code into a Coupon (e.g., a purchase must be $100 or more to work).

=item I<minimum_amount_currency> string

Three-letter [ISO code](https://stripe.com/docs/currencies) for minimum_amount

=back

=head2 times_redeemed nonnegative_integer

Number of times this promotion code has been used.

=head1 API SAMPLE

    {
      "id": "promo_1HMxuf2eZvKYlo2CmGXSyhRx",
      "object": "promotion_code",
      "active": true,
      "code": "TS0EQJHH",
      "coupon": {
        "id": "123",
        "object": "coupon",
        "amount_off": null,
        "created": 1507799684,
        "currency": null,
        "duration": "repeating",
        "duration_in_months": 3,
        "livemode": false,
        "max_redemptions": 14,
        "metadata": {
          "teste": "test"
        },
        "name": null,
        "percent_off": 34.0,
        "redeem_by": null,
        "times_redeemed": 0,
        "valid": true
      },
      "created": 1599060617,
      "customer": null,
      "expires_at": null,
      "livemode": false,
      "max_redemptions": null,
      "metadata": {
      },
      "restrictions": {
        "first_time_transaction": false,
        "minimum_amount": null,
        "minimum_amount_currency": null
      },
      "times_redeemed": 0
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api#promotion_code_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
