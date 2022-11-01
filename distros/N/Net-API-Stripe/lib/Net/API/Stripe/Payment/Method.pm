##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Method.pm
## Version v0.3.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/payment_methods
package Net::API::Stripe::Payment::Method;
BEGIN
{
    use strict;
    use warnings;
#     use parent qw( Net::API::Stripe::Generic );
#     use Net::API::Stripe::Payment::Method::Options qw( :all );
    # We inherit rather than import so overriding does not trigger an error about subroutine being redefined
    use parent qw( Net::API::Stripe::Payment::Method::Options );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.3.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

# NOTE: alipay is inherited

# NOTE: au_becs_debit is inherited

# NOTE: bacs_debit is inherited

# NOTE: bancontact is inherited

sub billing_details { return( shift->_set_get_object( 'billing_details', 'Net::API::Stripe::Billing::Details', @_ ) ); }

# NOTE: blik is inherited

# NOTE: boleto is inherited

# NOTE: card is inherited

# NOTE: card_present is inherited

sub boleto { return( shift->_set_get_class( 'boleto',
{ fingerprint => { type => "scalar" }, tax_id => { type => "scalar" } }, @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

# Expandable so either we get an id or we get the underlying object

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

# NOTE: eps is inherited

# NOTE: fpx is inherited

# NOTE: giropay is inherited

# NOTE: grabpay is inherited

# NOTE: ideal is inherited

# NOTE: interac_present is inherited

# NOTE: klarna is inherited

# NOTE: konbini is inherited

sub klarna { return( shift->_set_get_object( 'klarna', 'Net::API::Stripe::Connect::Person', @_ ) ); }

sub link { return( CORE::shift->_set_get_class( 'link',
{
  email => { type => "scalar" },
  persistent_token => { type => "scalar" },
}, @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

# NOTE: multibanco is inherited

# NOTE: oxxo is inherited

# NOTE: p24 is inherited

# NOTE: sepa_debit is inherited

# NOTE: sofort is inherited

sub paynow { return( CORE::shift->_set_get_hash( 'paynow', @_ ) ); }

sub promptpay { return( CORE::shift->_set_get_hash( 'promptpay', @_ ) ); }

sub radar_options { return( CORE::shift->_set_get_object( 'radar_options', 'Net::API::Stripe::Fraud::Review', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub us_bank_account { return( shift->_set_get_object( 'us_bank_account', 'Net::API::Stripe::Connect::ExternalAccount::Bank', @_ ) ); }

sub wechat_pay { return( CORE::shift->_set_get_hash( 'wechat_pay', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Method - A Stripe Payment Method Object

=head1 SYNOPSIS

    my $pm = $stripe->payment_method({
        billing_details => $billing_details_object,
        card => $card_object,
        metadata => { transaction_id => 123, customer_id => 456 },
        type => 'card',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents (L<https://stripe.com/docs/payments/payment-intents>) to collect payments or saved to Customer objects to store instrument details for future payments.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Method> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "payment_method"

String representing the object’s type. Objects of the same type share the same value.

=head2 alipay hash

If this is an `Alipay` PaymentMethod, this hash contains details about the Alipay payment method.

The Stripe API docs does not document any hash properties. There is some L<information about possible attributes here|https://stripe.com/docs/payments/alipay>

=head2 au_becs_debit

If this is an au_becs_debit PaymentMethod, this hash contains details about the bank account.

=over 4

=item I<bsb_number> string

Six-digit number identifying bank and branch associated with this bank account.

=item I<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item I<last4> string

Last four digits of the bank account number.

=back

=head2 bacs_debit hash

If this is a `bacs_debit` PaymentMethod, this hash contains details about the Bacs Direct Debit bank account.

It has the following properties:

=over 4

=item I<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item I<last4> string

Last four digits of the bank account number.

=item I<network_status> string

The status of the mandate on the Bacs network. Can be one of `pending`, `revoked`, `refused`, or `accepted`.

=item I<reference> string

The unique reference identifying the mandate on the Bacs network.

=item I<sort_code> string

Sort code of the bank account. (e.g., `10-20-30`)

=item I<url> string

The URL that will contain the mandate that the customer has signed.

=back

=head2 bancontact hash

If this is a `bancontact` PaymentMethod, this hash contains details about the Bancontact payment method.

The Stripe API docs does not document any hash properties.

=head2 billing_details hash

Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.

This is a L<Net::API::Stripe::Billing::Details> object.

=head2 boleto hash

If this is a C<boleto> PaymentMethod, this hash contains details about the Boleto payment method.

It has the following properties:

=over 4

=item C<fingerprint> string

=item C<tax_id> string

Uniquely identifies the customer tax id (CNPJ or CPF)

=back

=head2 card hash

If this is a card PaymentMethod, this hash contains details about the card.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object.

=head2 card_present hash

If this is an card_present PaymentMethod, this hash contains details about the Card Present payment method.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 customer string (expandable)

The ID of the Customer to which this PaymentMethod is saved. This will not be set when the PaymentMethod has not been saved to a Customer.

=head2 eps hash

If this is an `eps` PaymentMethod, this hash contains details about the EPS payment method.

The Stripe API docs does not document any hash properties.

=head2 fpx hash

If this is an fpx PaymentMethod, this hash contains details about the FPX payment method.

=over 4

=item I<bank> string

The customer’s bank, if provided. Can be one of affin_bank, alliance_bank, ambank, bank_islam, bank_muamalat, bank_rakyat, bsn, cimb, hong_leong_bank, hsbc, kfh, maybank2u, ocbc, public_bank, rhb, standard_chartered, uob, deutsche_bank, maybank2e, or pb_enterprise.

=back

=head2 giropay hash

If this is a C<giropay> PaymentMethod, this hash contains details about the Giropay payment method.

The Stripe API docs does not document any hash properties.

=head2 grabpay

If this is a C<grabpay> PaymentMethod, this hash contains details about the GrabPay payment method.

This is just a property with an empty hash. There are a few instances of this on Stripe api documentation.

=head2 ideal hash

If this is an ideal PaymentMethod, this hash contains details about the iDEAL payment method.

=over 4

=item I<bank> string

The customer’s bank, if provided. Can be one of abn_amro, asn_bank, bunq, handelsbanken, ing, knab, moneyou, rabobank, regiobank, sns_bank, triodos_bank, or van_lanschot.

=item I<bic> string

The Bank Identifier Code of the customer’s bank, if the bank was provided.

=back

=head2 interac_present hash

If this is an C<interac_present> PaymentMethod, this hash contains details about the Interac Present payment method.

The Stripe API docs does not document any hash properties.

=head2 klarna object

If this is a C<klarna> PaymentMethod, this hash contains details about the Klarna payment method.

This is a L<Net::API::Stripe::Connect::Person> object.

=head2 link hash

If this is an C<Link> PaymentMethod, this hash contains details about the Link payment method.

It has the following properties:

=over 4

=item C<email> string

Account owner's email address.

=item C<persistent_token> string

Token used for persistent Link logins.

=back

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 oxxo hash

If this is an C<oxxo> PaymentMethod, this hash contains details about the OXXO payment method.

The Stripe API docs now has the following properties:

=over 4

=item I<expires_after_days>

he number of calendar days before an OXXO voucher expires. For example, if you create an OXXO voucher on Monday and you set expires_after_days to 2, the OXXO invoice will expire on Wednesday at 23:59 America/Mexico_City time.

=back

=head2 p24 hash

If this is a C<p24> PaymentMethod, this hash contains details about the P24 payment method.

It has the following properties:

=over 4

=item I<bank> string

The customer's bank, if provided.

=back

=head2 paynow

If this is a C<paynow> PaymentMethod, this hash contains details about the PayNow payment method.

This is just a property with an empty hash. There are a few instances of this on Stripe api documentation.

=head2 promptpay

If this is a C<promptpay> PaymentMethod, this hash contains details about the PromptPay payment method.

This is just a property with an empty hash. There are a few instances of this on Stripe api documentation.

=head2 radar_options object

Options to configure Radar. See L<Radar Session|https://stripe.com/docs/radar/radar-session> for more information.

This is a L<Net::API::Stripe::Fraud::Review> object.

=head2 sepa_debit hash

If this is a sepa_debit PaymentMethod, this hash contains details about the SEPA debit bank account.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Card> object which uses the following properties:

=over 4

=item I<bank_code> string

Bank code of bank associated with the bank account.

=item I<branch_code> string

Branch code of bank associated with the bank account.

=item I<country> string

Two-letter ISO code representing the country the bank account is located in.

=item I<fingerprint> string

Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.

=item I<generated_from>

Information about the object that generated this PaymentMethod.

=over 8

=item I<charge>

The ID of the Charge that generated this PaymentMethod, if any.

=item I<setup_attempt>

The ID of the SetupAttempt that generated this PaymentMethod, if any.

=back

=item I<last4> string

Last four characters of the IBAN.

=back

=head2 sofort hash

If this is a C<sofort> PaymentMethod, this hash contains details about the SOFORT payment method.

It has the following properties:

=over 4

=item I<country> string

Two-letter ISO code representing the country the bank account is located in.

=item I<preferred_language>

Preferred language of the Bancontact authorization page that the customer is redirected to.

=back

=head2 type string

The type of the PaymentMethod. An additional hash is included on the PaymentMethod with a name matching this value. It contains additional information specific to the PaymentMethod type.

Possible enum values: card, fpx, ideal, sepa_debit

=head2 us_bank_account object

If this is an C<us_bank_account> PaymentMethod, this hash contains details about the US bank account payment method.

This is a L<Net::API::Stripe::Connect::ExternalAccount::Bank> object.

=head2 wechat_pay

If this is an C<wechat_pay> PaymentMethod, this hash contains details about the wechat_pay payment method.

This is just a property with an empty hash. There are a few instances of this on Stripe api documentation.

=head1 API SAMPLE

    {
      "id": "pm_123456789",
      "object": "payment_method",
      "billing_details": {
        "address": {
          "city": "Anytown",
          "country": "US",
          "line1": "1234 Main street",
          "line2": null,
          "postal_code": "123456",
          "state": null
        },
        "email": "jenny@example.com",
        "name": null,
        "phone": "+15555555555"
      },
      "card": {
        "brand": "visa",
        "checks": {
          "address_line1_check": null,
          "address_postal_code_check": null,
          "cvc_check": null
        },
        "country": "US",
        "exp_month": 8,
        "exp_year": 2020,
        "fingerprint": "kabvjbjcnbmbcmn",
        "funding": "credit",
        "generated_from": null,
        "last4": "4242",
        "three_d_secure_usage": {
          "supported": true
        },
        "wallet": null
      },
      "created": 123456789,
      "customer": null,
      "livemode": false,
      "metadata": {
        "order_id": "123456789"
      },
      "type": "card"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-24

Added properties B<ideal> and B<sepa_debit>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_methods>, L<https://stripe.com/docs/payments/payment-methods>, L<https://stripe.com/docs/payments/cards/reusing-cards>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
