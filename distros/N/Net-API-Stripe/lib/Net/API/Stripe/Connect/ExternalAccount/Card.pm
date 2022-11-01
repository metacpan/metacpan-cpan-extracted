##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/ExternalAccount/Card.pm
## Version v0.203.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/external_account_cards/object
package Net::API::Stripe::Connect::ExternalAccount::Card;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.203.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account { return( shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub address { return( shift->_address_populate( @_ ) ); }

sub address_city { return( shift->_set_get_scalar( 'address_city', @_ ) ); }

sub address_country { return( shift->_set_get_scalar( 'address_country', @_ ) ); }

sub address_line1 { return( shift->_set_get_scalar( 'address_line1', @_ ) ); }

sub address_line1_check { return( shift->_set_get_scalar( 'address_line1_check', @_ ) ); }

sub address_line2 { return( shift->_set_get_scalar( 'address_line2', @_ ) ); }

sub address_state { return( shift->_set_get_scalar( 'address_state', @_ ) ); }

sub address_zip { return( shift->_set_get_scalar( 'address_zip', @_ ) ); }

sub address_zip_check { return( shift->_set_get_scalar( 'address_zip_check', @_ ) ); }

sub amount_authorized { return( shift->_set_get_number( 'amount_authorized', @_ ) ); }

sub available_payout_methods { return( shift->_set_get_array( 'available_payout_methods', @_ ) ); }

sub bank_code { return( shift->_set_get_scalar( 'bank_code', @_ ) ); }

sub branch_code { return( shift->_set_get_scalar( 'branch_code', @_ ) ); }

# Card brand name, e.g. American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown

sub brand { return( shift->_set_get_scalar( 'brand', @_ ) ); }

sub capture_before { return( shift->_set_get_datetime( 'capture_before', @_ ) ); }

sub capture_method { return( shift->_set_get_scalar( 'capture_method', @_ ) ); }

sub cardholder_name { return( shift->_set_get_scalar( 'cardholder_name', @_ ) ); }

sub checks { return( shift->_set_get_hash( 'checks', @_ ) ) };

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub cvc { return( shift->_set_get_scalar( 'cvc', @_ ) ); }

sub cvc_check { return( shift->_set_get_scalar( 'cvc_check', @_ ) ); }

sub default_for_currency { return( shift->_set_get_scalar( 'default_for_currency', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub dynamic_last4 { return( shift->_set_get_scalar( 'dynamic_last4', @_ ) ); }

sub emv_auth_data { return( shift->_set_get_scalar( 'emv_auth_data', @_ ) ); }

sub exp_month { return( shift->_set_get_number( 'exp_month', @_ ) ); }

sub exp_year { return( shift->_set_get_number( 'exp_year', @_ ) ); }

sub fingerprint { return( shift->_set_get_scalar( 'fingerprint', @_ ) ); }

sub funding { return( shift->_set_get_scalar( 'funding', @_ ) ); }

sub generated_card { return( shift->_set_get_scalar( 'generated_card', @_ ) ); }

sub generated_from { return( shift->_set_get_object( 'generated_from', 'Net::API::Stripe::Payment::GeneratedFrom', @_ ) ); }

sub iin { return( shift->_set_get_scalar( 'iin', @_ ) ); }

sub incremental_authorization_supported { return( shift->_set_get_boolean( 'incremental_authorization_supported', @_ ) ); }

sub installments { return( shift->_set_get_object( 'installments', 'Net::API::Stripe::Payment::Installment', @_ ) ); }

sub issuer { return( shift->_set_get_scalar( 'issuer', @_ ) ); }

sub last4 { return( shift->_set_get_scalar( 'last4', @_ ) ); }

sub mandate { return( shift->_set_get_scalar( 'mandate', @_ ) ); }

sub mandate_options { return( shift->_set_get_object( 'mandate_options', 'Net::API::Stripe::Mandate::Options', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

# Cardholder name

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

# Preview features says Stripe API

sub network { return( shift->_set_get_scalar( 'network', @_ ) ); }

sub networks
{
    return( shift->_set_get_class( 'networks',
    {
    available => { type => 'array_as_object' },
    preferred => { type => 'scalar_as_object' },
    }, @_ ) );
}

sub overcapture_supported { return( shift->_set_get_boolean( 'overcapture_supported', @_ ) ); }

sub preferred_locales { return( shift->_set_get_array( 'preferred_locales', @_ ) ); }

sub read_method { return( shift->_set_get_scalar( 'read_method', @_ ) ); }

sub receipt { return( shift->_set_get_class( 'receipt', 
{
    account_type                    => { type => 'scalar' },
    application_cryptogram          => { type => 'scalar' },
    application_preferred_name      => { type => 'scalar' },
    authorization_code              => { type => 'scalar' },
    authorization_response_code     => { type => 'scalar' },
    cardholder_verification_method  => { type => 'scalar' },
    dedicated_file_name             => { type => 'scalar' },
    terminal_verification_results   => { type => 'scalar' },
    transaction_status_information  => { type => 'scalar' },
}, @_ ) ); }

sub recipient { return( shift->_set_get_scalar_or_object( 'recipient', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub reference { return( shift->_set_get_scalar( 'reference', @_ ) ); }

sub request_extended_authorization { return( shift->_set_get_boolean( 'request_extended_authorization', @_ ) ); }

sub request_incremental_authorization_support { return( shift->_set_get_boolean( 'request_incremental_authorization_support', @_ ) ); }

sub request_three_d_secure { return( shift->_set_get_scalar( 'request_three_d_secure', @_ ) ); }

sub setup_future_usage { return( shift->_set_get_scalar( 'setup_future_usage', @_ ) ); }

sub statement_descriptor_suffix_kana { return( shift->_set_get_scalar( 'statement_descriptor_suffix_kana', @_ ) ); }

sub statement_descriptor_suffix_kanji { return( shift->_set_get_scalar( 'statement_descriptor_suffix_kanji', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub three_d_secure { return( shift->_set_get_class( 'three_d_secure',
{
    authenticated       => { type => 'boolean' },
    authentication_flow => { type => 'scalar' },
    result              => { type => 'scalar' },
    result_reason       => { type => 'scalar' },
    succeeded           => { type => 'boolean' },
    version             => { type => 'scalar' },
}, @_ ) ); }

# sub three_d_secure_usage { return( shift->_set_get_hash_as_object( 'three_d_secure_usage', 'Net::API::Stripe::Payment::3DUsage', @_ ) ); }

sub three_d_secure_usage { return( shift->_set_get_class( 'three_d_secure_usage',
{ supported => { type => "boolean" } }, @_ ) ); }

sub tokenization_method { return( shift->_set_get_scalar( 'tokenization_method', @_ ) ); }

## sub wallet { return( shift->_set_get_hash_as_object( 'wallet', 'Net::API::Stripe::Payment::Wallet', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

sub wallet { return( shift->_set_get_class( 'wallet',
{
  amex_express_checkout => { type => "hash" },
  apple_pay             => { type => "hash" },
  dynamic_last4         => { type => "scalar" },
  google_pay            => { type => "hash" },
  masterpass            => {
                             definition => {
                               billing_address => { package => "Net::API::Stripe::Address", type => "object" },
                               email => { type => "scalar" },
                               name => { type => "scalar" },
                               shipping_address => { package => "Net::API::Stripe::Address", type => "object" },
                             },
                             type => "class",
                           },
  samsung_pay           => { type => "hash" },
  type                  => { type => "scalar" },
  visa_checkout         => {
                             definition => {
                               billing_address => { package => "Net::API::Stripe::Address", type => "object" },
                               email => { type => "scalar" },
                               name => { type => "scalar" },
                               shipping_address => { package => "Net::API::Stripe::Address", type => "object" },
                             },
                             type => "class",
                           },
}, @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::ExternalAccount::Card - A Stripe Card Account Object

=head1 SYNOPSIS

    my $card = $stripe->card({
        account => 'acct_fake123456789',
        # Or you can also simply pass a Net::API::Stripe::Address object
        # address => $address_object
        address_line1 => '1-2-3 Kudan-Minami, Chiyoda-ku',
        address_line2 => 'Big bldg. 12F',
        address_city => 'Tokyo',
        address_zip => '123-4567',
        address_country => 'jp',
        brand => 'visa',
        country => 'jp',
        currency => 'jpy',
        customer => $customer_object,
        cvc => 123,
        # Boolean
        default_for_currency => 1,
        exp_month => 12,
        exp_year => 2030,
        funding => 'debit',
        metadata => { transaction_id => 123, customer_id => 456 },
        name => 'John Doe',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects. For example:

    my $stripe = Net::API::Stripe->new( conf_file => 'settings.json' ) | die( Net::API::Stripe->error );
    my $stripe_card = $stripe->cards( create =>
    {
    account => 'acct_fake123456789',
    external_account =>
        {
        object => 'card',
        exp_month => 12,
        exp_year => 2030,
        number => '012345678',
        },
    default_for_currency => $stripe->true,
    metadata => { transaction_id => 123, customer_id => 456 },
    }) || die( $stripe->error );

=head1 VERSION

    v0.203.0

=head1 DESCRIPTION

These External Accounts are transfer destinations on Account objects for Custom accounts (L<https://stripe.com/docs/connect/custom-accounts>). They can be bank accounts or debit cards.

Bank accounts (L<https://stripe.com/docs/api#customer_bank_account_object>) and debit cards (L<https://stripe.com/docs/api#card_object>) can also be used as payment sources on regular charges, and are documented in the links above.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Connect::ExternalAccount::Card> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "card"

String representing the object’s type. Objects of the same type share the same value.

=head2 account custom only string (expandable)

The account this card belongs to. This attribute will not be in the card object if the card belongs to a customer or recipient instead.

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=head2 address L<Net::API::Stripe::Address> object or hash

This is a helper method. Provided with either a L<Net::API::Stripe::Address> object or a hash with same properties, this will assign all the address_* properties by calling its method.

=head2 address_city string

City/District/Suburb/Town/Village.

=head2 address_country string

Billing address country, if provided when creating card.

=head2 address_line1 string

Address line 1 (Street address/PO Box/Company name).

=head2 address_line1_check string

If address_line1 was provided, results of the check: pass, fail, unavailable, or unchecked.

=head2 address_line2 string

Address line 2 (Apartment/Suite/Unit/Building).

=head2 address_state string

State/County/Province/Region.

=head2 address_zip string

ZIP or postal code.

=head2 address_zip_check string

If address_zip was provided, results of the check: pass, fail, unavailable, or unchecked.

=head2 amount_authorized integer

The authorized amount

=head2 available_payout_methods array

A set of available payout methods for this card. Will be either ["standard"] or ["standard", "instant"]. Only values from this set should be passed as the method when creating a transfer.

=head2 brand string

Card brand. Can be American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown.

=head2 capture_before timestamp

When using manual capture, a future timestamp after which the charge will be automatically refunded if uncaptured.

=head2 cardholder_name string

The cardholder name as read from the card, in L<ISO 7813|https://en.wikipedia.org/wiki/ISO/IEC_7813> format. May include alphanumeric characters, special characters and first/last name separator (C</>).

=head2 checks

=over 4

=item I<address_line1_check> string

If a address line1 was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.

=item I<address_postal_code_check> string

If a address postal code was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.

=item I<cvc_check> string

If a CVC was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.

=back

=head2 country string

Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you’ve collected.

=head2 currency custom only currency

Three-letter ISO code for currency. Only applicable on accounts (not customers or recipients). The card can be used as a transfer destination for funds in this currency.

=head2 customer string (expandable)

The customer that this card belongs to. This attribute will not be in the card object if the card belongs to an account or recipient instead.

When expanded, this is a L<Net::API::Stripe::Customer> object.

=head2 cvc string

Card security code. Highly recommended to always include this value, but it's required only for accounts based in European countries.

This is used when creating a card object on Stripe API. See here: L<https://stripe.com/docs/api/cards/create>

=head2 cvc_check string

If a CVC was provided, results of the check: pass, fail, unavailable, or unchecked.

=head2 default_for_currency custom only boolean

Whether this card is the default external account for its currency.

=head2 description string

A high-level description of the type of cards issued in this range

=head2 dynamic_last4 string

(For tokenized numbers only.) The last four digits of the device account number.

=head2 emv_auth_data string

Authorization response cryptogram.

=head2 exp_month integer

Two-digit number representing the card’s expiration month.

=head2 exp_year integer

Four-digit number representing the card’s expiration year.

=head2 fingerprint string

Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example.

=head2 funding string

Card funding type. Can be credit, debit, prepaid, or unknown.

=head2 generated_card string

ID of a card PaymentMethod generated from the card_present PaymentMethod that may be attached to a Customer for future transactions. Only present if it was possible to generate a card PaymentMethod.

=head2 generated_from hash

Details of the original PaymentMethod that created this object.

=head2 iin string

Issuer identification number of the card

=head2 incremental_authorization_supported boolean

Whether this L<PaymentIntent|https://stripe.com/docs/api/payment_intents> is eligible for incremental authorizations. Request support using L<requestI<incremental>authorization_support|https://stripe.com/docs/api/payment_intents/create#create_payment_intent-payment_method_options-card_present-request_incremental_authorization_support>.

=head2 installments hash

If present, this is a L<Net::API::Stripe::Payment::Installment> object. As of 2019-02-19, this is only used in Mexico though. See here for more information: L<https://stripe.com/docs/payments/installments>

=head2 issuer string

The name of the card's issuing bank

=head2 last4 string

The last four digits of the card.

=head2 mandate string

ID of the mandate used to make this payment.

=head2 mandate_options

Additional fields for Mandate creation

This is just a property with an empty hash. There are a few instances of this on Stripe api documentation.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 name string

Cardholder name.

=head2 network string preview feature

Identifies which network this charge was processed on. Can be amex, diners, discover, interac, jcb, mastercard, unionpay, visa, or unknown.

=head2 networks hash

Contains information about card networks that can be used to process the payment.

=over 4

=item I<available> array containing strings

All available networks for the card.

=item I<preferred> string

The preferred network for the card.

=back

=head2 overcapture_supported boolean

Defines whether the authorized amount can be over-captured or not

=head2 preferred_locales string_array

EMV tag 5F2D. Preferred languages specified by the integrated circuit chip.

=head2 read_method string

How were card details read in this transaction. Can be contact_emv, contactless_emv, magnetic_stripe_fallback, magnetic_stripe_track2, or contactless_magstripe_mode

=head2 receipt hash

A collection of fields required to be displayed on receipts. Only required for EMV transactions.

=over 4

=item I<account_type> string

The type of account being debited or credited

=item I<application_cryptogram> string

EMV tag 9F26, cryptogram generated by the integrated circuit chip.

=item I<application_preferred_name> string

Mnenomic of the Application Identifier.

=item I<authorization_code> string

Identifier for this transaction.

=item I<authorization_response_code> string

EMV tag 8A. A code returned by the card issuer.

=item I<cardholder_verification_method> string

How the cardholder verified ownership of the card.

=item I<dedicated_file_name> string

EMV tag 84. Similar to the application identifier stored on the integrated circuit chip.

=item I<terminal_verification_results> string

The outcome of a series of EMV functions performed by the card reader.

=item I<transaction_status_information> string

An indication of various EMV functions performed during the transaction.

=back

=head2 recipient string (expandable)

The recipient that this card belongs to. This attribute will not be in the card object if the card belongs to a customer or account instead.

Since 2017, Stripe recipients have been replaced by Stripe accounts: L<https://stripe.com/docs/connect/recipient-account-migrations>

So this is a Stripe account id, or if expanded, a L<Net::API::Stripe::Connect::Account> object.

=head2 reference string

The unique reference of the mandate.

=head2 request_extended_authorization

Request ability to capture this payment beyond the standard L<authorization validity window|https://stripe.com/docs/terminal/features/extended-authorizations#authorization-validity>

=head2 request_incremental_authorization_support

Request ability to increment this PaymentIntent if the combination of MCC and card brand is eligible. Check L<incremental_authorization_supported|https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-incremental_authorization_supported> in the L<Confirm|https://stripe.com/docs/api/payment_intents/confirm> response to verify support.

=head2 request_three_d_secure string

We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and other requirements. However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. Permitted values include: C<automatic> or C<any>. If not provided, defaults to C<automatic>. Read our guide on manually requesting 3D Secure for more information on how this configuration interacts with Radar and our SCA Engine.

=head2 status string

For external accounts, possible values are C<new> and C<errored>. If a transfer fails, the status is set to C<errored> and transfers are stopped until account details are updated.

=head2 three_d_secure hash

Populated if this transaction used 3D Secure authentication.

This is an objectified hash reference, ie its key / value pairs can be accessed as virtual methods. It uses the virtal package L<Net::API::Stripe::Payment::3DSecure>

=over 4

=item I<authenticated> boolean

Whether or not authentication was performed. 3D Secure will succeed without authentication when the card is not enrolled.

=item I<authentication_flow> string

For authenticated transactions: how the customer was authenticated by the issuing bank.

=item I<result> string

Indicates the outcome of 3D Secure authentication.

=item I<result_reason> string

Additional information about why 3D Secure succeeded or failed based on the C<result>.

=item I<succeeded> boolean

Whether or not 3D Secure succeeded.

=item I<version> string

The version of 3D Secure that was used for this payment.

=back

=head2 three_d_secure_usage hash

Contains details on how this Card maybe be used for 3D Secure authentication.

This is a virtual L<Net::API::Stripe::Payment::3DUsage> object ie whereby each key can be accessed as methods.

=over 4

=item I<supported> boolean

Whether 3D Secure is supported on this card.

=back

=head2 tokenization_method string

If the card number is tokenized, this is the method that was used. Can be apple_pay or google_pay.

=head2 url string

The URL of the mandate. This URL generally contains sensitive information about the customer and should be shared with them exclusively.

=head2 wallet hash

If this Card is part of a card wallet, this contains the details of the card wallet.

It has the following properties:

=over 4

=item I<amex_express_checkout> hash

If this is a C<amex_express_checkout> card wallet, this hash contains details about the wallet.

=over 8

=item I<amex_express_checkout>

This is an empty hash.

=back

=item I<apple_pay> hash

If this is a C<apple_pay> card wallet, this hash contains details about the wallet.

=over 8

=item I<apple_pay>

This is an empty hash.

=back

=item I<dynamic_last4> string

(For tokenized numbers only.) The last four digits of the device account number.

=item I<google_pay> hash

If this is a C<google_pay> card wallet, this hash contains details about the wallet.

=over 8

=item I<google_pay>

This is an empty hash.

=back

=item I<masterpass> hash

If this is a C<masterpass> card wallet, this hash contains details about the wallet.

=over 8

=item I<billing_address> hash

Owner's verified billing address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

When expanded, this is a L<Net::API::Stripe::Address> object.

=item I<email> string

Owner's verified email. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item I<name> string

Owner's verified full name. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item I<shipping_address> hash

Owner's verified shipping address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

When expanded, this is a L<Net::API::Stripe::Address> object.

=back

=item I<samsung_pay> hash

If this is a C<samsung_pay> card wallet, this hash contains details about the wallet.

=over 8

=item I<samsung_pay>

This is an empty hash.

=back

=item I<type> string

The type of the card wallet, one of C<amex_express_checkout>, C<apple_pay>, C<google_pay>, C<masterpass>, C<samsung_pay>, or C<visa_checkout>. An additional hash is included on the Wallet subhash with a name matching this value. It contains additional information specific to the card wallet type.

=item I<visa_checkout> hash

If this is a C<visa_checkout> card wallet, this hash contains details about the wallet.

=over 8

=item I<billing_address> hash

Owner's verified billing address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

When expanded, this is a L<Net::API::Stripe::Address> object.

=item I<email> string

Owner's verified email. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item I<name> string

Owner's verified full name. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item I<shipping_address> hash

Owner's verified shipping address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

When expanded, this is a L<Net::API::Stripe::Address> object.

=back

=back

=head1 API SAMPLE

    {
      "id": "card_fake123456789",
      "object": "card",
      "address_city": null,
      "address_country": null,
      "address_line1": null,
      "address_line1_check": null,
      "address_line2": null,
      "address_state": null,
      "address_zip": null,
      "address_zip_check": null,
      "brand": "Visa",
      "country": "US",
      "customer": null,
      "cvc_check": null,
      "dynamic_last4": null,
      "exp_month": 8,
      "exp_year": 2020,
      "fingerprint": "lkavkajndvkdvnj",
      "funding": "credit",
      "last4": "4242",
      "metadata": {},
      "name": null,
      "tokenization_method": null
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head2 v0.2

Added the method B<address> to make it easy to pass a L<Net::API::Stripe::Address> object or an hash reference to populate automatically the properties I<address_line1>, I<address_line2>, I<address_city>, I<address_zip> and I<address_country>

=head1 STRIPE HISTORY

=head2 2018-01-23

When being viewed by a platform, cards and bank accounts created on behalf of connected accounts will have a fingerprint that is universal across all connected accounts. For accounts that are not connect platforms, there will be no change.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/external_account_cards/object>, L<https://stripe.com/docs/connect/payouts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
