##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Issuing/Authorization/Transaction.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Issuing::Authorization::Transaction;
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

sub authorization { return( shift->_set_get_scalar_or_object( 'authorization', 'Net::API::Stripe::Issuing::Authorization', @_ ) ); }

sub balance_transaction { return( shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ) ); }

sub card { return( shift->_set_get_scalar_or_object( 'card', 'Net::API::Stripe::Issuing::Card', @_ ) ); }

sub cardholder { return( shift->_set_get_scalar_or_object( 'cardholder', 'Net::API::Stripe::Issuing::Card::Holder', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub dispute { return( shift->_set_get_scalar_or_object( 'dispute', 'Net::API::Stripe::Issuing::Dispute', @_ ) ); }

sub livemode { return( shift->_set_get_scalar( 'livemode', @_ ) ); }

sub merchant_amount { return( shift->_set_get_number( 'merchant_amount', @_ ) ); }

sub merchant_currency { return( shift->_set_get_scalar( 'merchant_currency', @_ ) ); }

sub merchant_data { return( shift->_set_get_object( 'merchant_data', 'Net::API::Stripe::Issuing::MerchantData', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Issuing::Authorization::Transaction - A Stripe Authorization Transaction Object

=head1 SYNOPSIS

    my $tr = $stripe->issuing_transaction({
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
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

No documentation on Stripe.com.

This is instantiated by method B<transactions> in module L<Net::API::Stripe::Issuing::Authorization>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Issuing::Authorization::Transaction> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "issuing.transaction"

String representing the object’s type. Objects of the same type share the same value.

=head2 amount integer

The transaction amount, which will be reflected in your balance. This amount is in your currency and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>.

=head2 authorization string (expandable)

The Authorization object that led to this transaction.

When expanded, this is a L<Net::API::Stripe::Issuing::Authorization> object.

=head2 balance_transaction string (expandable)

When expanded, this is a L<Net::API::Stripe::Balance::Transaction> object.

=head2 card string (expandable)

The card used to make this transaction.

When expanded, this is a L<Net::API::Stripe::Issuing::Card> object.

=head2 cardholder string (expandable)

The cardholder to whom this transaction belongs.

When expanded, this is a L<Net::API::Stripe::Issuing::Card::Holder> object.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=head2 dispute string (expandable)

When expanded, this is a L<Net::API::Stripe::Issuing::Dispute> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 merchant_amount integer

The amount that the merchant will receive, denominated in L</merchant_currency> and in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal>. It will be different from L</amount> if the merchant is taking payment in a different currency.

=head2 merchant_currency currency

The currency with which the merchant is taking payment.

=head2 merchant_data hash

More information about the user involved in the transaction.

This is a L<Net::API::Stripe::Issuing::MerchantData> object.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 type string

One of capture, refund, cash_withdrawal, refund_reversal, dispute, or dispute_loss.

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

L<https://stripe.com/docs/api/issuing/transactions>, L<https://stripe.com/docs/api/issuing/authorizations/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
