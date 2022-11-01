##----------------------------------------------------------------------------
## Stripe API - ~/usr/local/src/perl/Net-API-Stripe/lib/Net/API/Stripe/Issuing/Authorization.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/11/16
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/issuing/authorizations/object
package Net::API::Stripe::Issuing::Authorization;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_details { return( shift->_set_get_class( 'amount_details',
{ atm_fee => { type => "number" } }, @_ ) ); }

sub approved { return( shift->_set_get_boolean( 'approved', @_ ) ); }

sub authorization_method { return( shift->_set_get_scalar( 'authorization_method', @_ ) ); }

sub authorized_amount { return( shift->_set_get_number( 'authorized_amount', @_ ) ); }

sub authorized_currency { return( shift->_set_get_scalar( 'authorized_currency', @_ ) ); }

sub balance_transactions { return( shift->_set_get_object_array( 'balance_transactions', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub card { return( shift->_set_get_object( 'card', 'Net::API::Stripe::Issuing::Card', @_ ) ); }

sub cardholder { return( shift->_set_get_scalar_or_object( 'cardholder', 'Net::API::Stripe::Issuing::Card::Holder', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_number( 'currency', @_ ) ); }

sub held_amount { return( shift->_set_get_number( 'held_amount', @_ ) ); }

sub held_currency { return( shift->_set_get_number( 'held_currency', @_ ) ); }

sub is_held_amount_controllable { return( shift->_set_get_boolean( 'is_held_amount_controllable', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub merchant_amount { return( shift->_set_get_number( 'merchant_amount', @_ ) ); }

sub merchant_currency { return( shift->_set_get_number( 'merchant_currency', @_ ) ); }

sub merchant_data { return( shift->_set_get_object( 'merchant_data', 'Net::API::Stripe::Issuing::MerchantData', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub pending_authorized_amount { return( shift->_set_get_number( 'pending_authorized_amount', @_ ) ); }

sub pending_held_amount { return( shift->_set_get_number( 'pending_held_amount', @_ ) ); }

sub pending_request { return( shift->_set_get_class( 'pending_request',
{
  amount => { type => "number" },
  amount_details => { definition => { atm_fee => { type => "number" } }, type => "class" },
  currency => { type => "number" },
  is_amount_controllable => { type => "boolean" },
  merchant_amount => { type => "number" },
  merchant_currency => { type => "number" },
}, @_ ) ); }

sub request_history { return( shift->_set_get_object_array( 'request_history', 'Net::API::Stripe::Issuing::Authorization::RequestHistory', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub transactions { return( shift->_set_get_object_array( 'transactions', 'Net::API::Stripe::Issuing::Authorization::Transaction', @_ ) ); }

sub verification_data { return( shift->_set_get_object( 'verification_data', 'Net::API::Stripe::Issuing::Authorization::VerificationData', @_ ) ); }

sub wallet { return( shift->_set_get_scalar( 'wallet', @_ ) ); }

sub wallet_provider { return( shift->_set_get_scalar( 'wallet_provider', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Authorization - A Stripe Issued Authorization Object

=head1 SYNOPSIS

    my $auth = $stripe->authorization({
        approved => $stripe->true,
        authorization_method => 'online',
        authorized_amount => 2000,
        authorized_currency => 'jpy',
        balance_transactions => 
        [
            {
            amount => 2000,
            authorization => $authorization_object,
            card => $card_object,
            cardholder => $cardholder_object,
            currency => 'jpy',
            merchant_amount => 2000,
            merchant_currency => 'jpy',
            merchant_data => $merchant_data_object,
            metadata => { transaction_id => 123 },
            type => 'capture',
            },
        ],
        card => $card_object,
        cardholder => $cardholder_object,
        created => '2020-04-12T04:07:30',
        held_amount => 2000,
        held_currency => 'jpy',
        is_held_amount_controllable => $stripe->true,
        merchant_data => $merchant_data_object,
        metadata => { transaction_id => 123 },
        pending_authorized_amount => 2000,
        pending_held_amount => 2000,
        request_history => [ $request_history_obj1, $request_history_obj2 ],
        status => 'pending',
        transactions => [ $transactions_obj1, $transactions_obj2, $transactions_obj3 ],
        verification_data => $verification_data_object,
        wallet_provider => undef,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

When an issued card is used to make a purchase, an Issuing Authorization object is created. Authorisations (L<https://stripe.com/docs/issuing/authorizations>) must be approved for the purchase to be completed successfully.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Authorization> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "issuing.authorization"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

The total amount that was authorized or rejected. This amount is in the card's currency and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

=head2 amount_details hash

Detailed breakdown of amount components. These amounts are denominated in `currency` and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

It has the following properties:

=over 4

=item I<atm_fee> integer

The fee charged by the ATM for the cash withdrawal.

=back

=head2 approved boolean

Whether the authorization has been approved.

=head2 authorization_method string

How the card details were provided. One of chip, contactless, keyed_in, online, or swipe.

=head2 authorized_amount integer

The amount that has been authorized. This will be 0 when the object is created, and increase after it has been approved.

=head2 authorized_currency currency

The currency that was presented to the cardholder for the authorization. Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 balance_transactions array, contains: balance_transaction object

This is an array of L<Net::API::Stripe::Balance::Transaction> objects.

=head2 card hash

This is a L<Net::API::Stripe::Issuing::Card> object.

=head2 cardholder string (expandable)

The cardholder to whom this authorization belongs.

When expanded, this is a L<Net::API::Stripe::Issuing::Card::Holder> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 held_amount integer

The amount the authorization is expected to be in held_currency. When Stripe holds funds from you, this is the amount reserved for the authorization. This will be 0 when the object is created, and increase after it has been approved. For multi-currency transactions, held_amount can be used to determine the expected exchange rate.

=head2 held_currency currency

The currency of the held amount. This will always be the card currency.

=head2 is_held_amount_controllable boolean

Deprecated as of L<2020-04-15|https://github.com/stripe/stripe-java/pull/1009>

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 merchant_amount integer

The total amount that was authorized or rejected. This amount is in the `merchant_currency` and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

=head2 merchant_currency currency

The currency that was presented to the cardholder for the authorization. Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 merchant_data hash

This is a L<Net::API::Stripe::Issuing::MerchantData> object.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 pending_authorized_amount integer

The amount the user is requesting to be authorized. This field will only be non-zero during an issuing.authorization.request webhook.

=head2 pending_held_amount integer

The additional amount Stripe will hold if the authorization is approved. This field will only be non-zero during an issuing.authorization.request webhook.

=head2 pending_request hash

The pending authorization request. This field will only be non-null during an C<issuing_authorization.request> webhook.

It has the following properties:

=over 4

=item I<amount> integer

The additional amount Stripe will hold if the authorization is approved, in the card's L<currency|https://stripe.com/docs/api#issuing_authorization_object-pending-request-currency> and in the [smallest currency unit](/docs/currencies#zero-decimal).

=item I<amount_details> hash

Detailed breakdown of amount components. These amounts are denominated in C<currency> and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

=over 8

=item I<atm_fee> integer

The fee charged by the ATM for the cash withdrawal.

=back

=item I<currency> currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=item I<is_amount_controllable> boolean

If set C<true>, you may provide L<amount|https://stripe.com/docs/api/issuing/authorizations/approve#approve_issuing_authorization-amount> to control how much to hold for the authorization.

=item I<merchant_amount> integer

The amount the merchant is requesting to be authorized in the C<merchant_currency>. The amount is in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

=item I<merchant_currency> currency

The local currency the merchant is requesting to authorize.

=back

=head2 request_history array of hashes

This is an array of L<Net::API::Stripe::Issuing::Authorization::RequestHistory> objects.

=head2 status string

One of pending, reversed, or closed.

=head2 transactions array of hashes

This is an array of L<Net::API::Stripe::Issuing::Authorization::Transaction> objects.

=head2 verification_data hash

This is a L<Net::API::Stripe::Issuing::Authorization::VerificationData> object.

=head2 wallet string

What, if any, digital wallet was used for this authorization. One of `apple_pay`, `google_pay`, or `samsung_pay`.

=head2 wallet_provider string

What, if any, digital wallet was used for this authorization. One of apple_pay, google_pay, or samsung_pay.

=head1 API SAMPLE

    {
      "id": "iauth_fake123456789",
      "object": "issuing.authorization",
      "approved": true,
      "authorization_method": "online",
      "authorized_amount": 500,
      "authorized_currency": "usd",
      "balance_transactions": [],
      "card": null,
      "cardholder": null,
      "created": 1540642827,
      "held_amount": 0,
      "held_currency": "usd",
      "is_held_amount_controllable": false,
      "livemode": false,
      "merchant_data": {
        "category": "taxicabs_limousines",
        "city": "San Francisco",
        "country": "US",
        "name": "Rocket Rides",
        "network_id": "1234567890",
        "postal_code": "94107",
        "state": "CA",
        "url": null
      },
      "metadata": {},
      "pending_authorized_amount": 0,
      "pending_held_amount": 0,
      "request_history": [],
      "status": "reversed",
      "transactions": [
        {
          "id": "ipi_fake123456789",
          "object": "issuing.transaction",
          "amount": -100,
          "authorization": "iauth_fake123456789",
          "balance_transaction": null,
          "card": "ic_fake123456789",
          "cardholder": null,
          "created": 1540642827,
          "currency": "usd",
          "dispute": null,
          "livemode": false,
          "merchant_amount": null,
          "merchant_currency": null,
          "merchant_data": {
            "category": "taxicabs_limousines",
            "city": "San Francisco",
            "country": "US",
            "name": "Rocket Rides",
            "network_id": "1234567890",
            "postal_code": "94107",
            "state": "CA",
            "url": null
          },
          "metadata": {},
          "type": "capture"
        },
        {
          "id": "ipi_fake123456789",
          "object": "issuing.transaction",
          "amount": -100,
          "authorization": "iauth_fake123456789",
          "balance_transaction": null,
          "card": "ic_fake123456789",
          "cardholder": null,
          "created": 1540642827,
          "currency": "usd",
          "dispute": null,
          "livemode": false,
          "merchant_amount": null,
          "merchant_currency": null,
          "merchant_data": {
            "category": "taxicabs_limousines",
            "city": "San Francisco",
            "country": "US",
            "name": "Rocket Rides",
            "network_id": "1234567890",
            "postal_code": "94107",
            "state": "CA",
            "url": null
          },
          "metadata": {},
          "type": "capture"
        }
      ],
      "verification_data": {
        "address_line1_check": "not_provided",
        "address_zip_check": "match",
        "authentication": "none",
        "cvc_check": "match"
      },
      "wallet_provider": null
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/issuing/authorizations>, L<https://stripe.com/docs/issuing/authorizations>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
