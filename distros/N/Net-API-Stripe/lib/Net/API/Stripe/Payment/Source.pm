##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Source.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/sources/object
package Net::API::Stripe::Payment::Source;
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

sub ach_credit_transfer { return( shift->_set_get_object( 'ach_credit_transfer', 'Net::API::Stripe::Payment::Source::ACHCreditTransfer', @_ ) ); }

sub ach_debit { return( shift->_set_get_object( 'ach_debit', 'Net::API::Stripe::Payment::Source::ACHDebit', @_ ) ); }

sub account { return( shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub account_holder_name { return( shift->_set_get_scalar( 'account_holder_name', @_ ) ); }

sub account_holder_type { return( shift->_set_get_scalar( 'account_holder_type', @_ ) ); }

sub active { return( shift->_set_get_scalar( 'active', @_ ) ); }

sub address { return( shift->_address_populate( @_ ) ); }

sub address_city { return( shift->_set_get_scalar( 'address_city', @_ ) ); }

sub address_country { return( shift->_set_get_scalar( 'address_country', @_ ) ); }

sub address_line1 { return( shift->_set_get_scalar( 'address_line1', @_ ) ); }

sub address_line1_check { return( shift->_set_get_scalar( 'address_line1_check', @_ ) ); }

sub address_line2 { return( shift->_set_get_scalar( 'address_line2', @_ ) ); }

sub address_state { return( shift->_set_get_scalar( 'address_state', @_ ) ); }

sub address_zip { return( shift->_set_get_scalar( 'address_zip', @_ ) ); }

sub address_zip_check { return( shift->_set_get_scalar( 'address_zip_check', @_ ) ); }

sub alipay { return( shift->_set_get_hash_as_object( 'alipay', 'Net::API::Stripe::Payment::Method::Details::Alipay', @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_received { return( shift->_set_get_number( 'amount_received', @_ ) ); }

sub available_payout_methods { return( shift->_set_get_array( 'available_payout_methods', @_ ) ); }

sub bancontact { return( shift->_set_get_hash_as_object( 'bancontact', 'Net::API::Stripe::Payment::Method::Details::BanContact', @_ ) ); }

sub bank_name { return( shift->_set_get_scalar( 'bank_name', @_ ) ); }

sub bitcoin_amount { return( shift->_set_get_number( 'bitcoin_amount', @_ ) ); }

sub bitcoin_amount_received { return( shift->_set_get_number( 'bitcoin_amount_received', @_ ) ); }

sub bitcoin_uri { return( shift->_set_get_uri( 'bitcoin_uri', @_ ) ); }

sub brand { return( shift->_set_get_scalar( 'brand', @_ ) ); }

## If type is set to "card"
sub card { return( shift->_set_get_object( 'card', 'Net::API::Stripe::Connect::ExternalAccount::Card', @_ ) ); }

sub card_present { return( shift->_set_get_hash_as_object( 'card_present', 'Net::API::Stripe::Payment::Method::Details::CardPresent', @_ ) ); }

sub client_secret { return( shift->_set_get_scalar( 'client_secret', @_ ) ); }

sub code_verification { return( shift->_set_get_object( 'code_verification', 'Net::API::Stripe::Payment::Source::CodeVerification', @_ ) ); }

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub cvc_check { return( shift->_set_get_scalar( 'cvc_check', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub dynamic_last4 { return( shift->_set_get_scalar( 'dynamic_last4', @_ ) ); }

sub email { return( shift->_set_get_scalar( 'email', @_ ) ); }

sub eps { return( shift->_set_get_hash_as_object( 'eps', 'Net::API::Stripe::Payment::Method::Details::EPS', @_ ) ); }

sub exp_month { return( shift->_set_get_number( 'exp_month', @_ ) ); }

sub exp_year { return( shift->_set_get_number( 'exp_year', @_ ) ); }

sub filled { return( shift->_set_get_scalar( 'filled', @_ ) ); }

sub fingerprint { return( shift->_set_get_scalar( 'fingerprint', @_ ) ); }

sub flow { return( shift->_set_get_scalar( 'flow', @_ ) ); }

sub funding { return( shift->_set_get_scalar( 'funding', @_ ) ); }

sub giropay { return( shift->_set_get_hash_as_object( 'giropay', 'Net::API::Stripe::Payment::Method::Details::Giropay', @_ ) ); }

sub ideal { return( shift->_set_get_hash_as_object( 'ideal', 'Net::API::Stripe::Payment::Method::Details::Ideal', @_ ) ); }

sub inbound_address { return( shift->_set_get_scalar( 'inbound_address', @_ ) ); }

sub klarna { return( shift->_set_get_hash_as_object( 'klarna', 'Net::API::Stripe::Payment::Method::Details::Klarna', @_ ) ); }

sub last4 { return( shift->_set_get_scalar( 'last4', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub multibanco { return( shift->_set_get_hash_as_object( 'multibanco', 'Net::API::Stripe::Payment::Method::Details::MultiBanco', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub owner { return( shift->_set_get_object( 'owner', 'Net::API::Stripe::Payment::Source::Owner', @_ ) ); }

sub p24 { return( shift->_set_get_hash_as_object( 'p24', 'Net::API::Stripe::Payment::Method::Details::P24', @_ ) ); }

sub payment { return( shift->_set_get_scalar( 'payment', @_ ) ); }

sub payment_amount { return( shift->_set_get_number( 'payment_amount', @_ ) ); }

sub payment_currency { return( shift->_set_get_scalar( 'payment_currency', @_ ) ); }

## "Information related to the receiver flow. Present if the source is a receiver (flow is receiver)."
sub receiver { return( shift->_set_get_object( 'receiver', 'Net::API::Stripe::Payment::Source::Receiver', @_ ) ); }

sub redirect { return( shift->_set_get_object( 'redirect', 'Net::API::Stripe::Payment::Source::Redirect', @_ ) ); }

sub refund_address { return( shift->_set_get_scalar( 'refund_address', @_ ) ); }

sub recipient { return( shift->_set_get_scalar_or_object( 'recipient', 'Net::API::Stripe::Customer', @_ ) ); }

sub routing_number { return( shift->_set_get_scalar( 'routing_number', @_ ) ); }

sub reusable { return( shift->_set_get_scalar( 'reusable', @_ ) ); }

sub sofort { return( shift->_set_get_hash_as_object( 'sofort', 'Net::API::Stripe::Payment::Method::Details::Sofort', @_ ) ); }

sub source_order { return( shift->_set_get_object( 'source_order', 'Net::API::Stripe::Order', @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub stripe_account { return( shift->_set_get_hash_as_object( 'stripe_account', 'Net::API::Stripe::Payment::Method::Details::StripeAccount', @_ ) ); }

sub tokenization_method { return( shift->_set_get_scalar( 'tokenization_method', @_ ) ); }

sub transactions { return( shift->_set_get_object( 'transactions', 'Net::API::Stripe::List', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub uncaptured_funds { return( shift->_set_get_scalar( 'uncaptured_funds', @_ ) ); }

sub usage { return( shift->_set_get_scalar( 'usage', @_ ) ); }

sub used { return( shift->_set_get_scalar( 'used', @_ ) ); }

sub used_for_payment { return( shift->_set_get_scalar( 'used_for_payment', @_ ) ); }

sub username { return( shift->_set_get_scalar( 'username', @_ ) ); }

sub wechat { return( shift->_set_get_hash_as_object( 'wechat', 'Net::API::Stripe::Payment::Method::Details::WeChat', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Source - A Stripe Payment Source Object

=head1 SYNOPSIS

    my $source = $stripe->source({
        account => $account_object,
        account_holder_name => 'John Doe',
        account_holder_type => 'individual',
        active => $stripe->true,
        # Or maybe more simply you pass a Net::API::Stripe::Address object
        # address => $address_object
        address_line1 => '1-2-3 Kudan-Minami, Chiyoda-ku',
        address_line2 => 'Big Bldg 12F',
        address_city => 'Tokyo',
        address_state => undef,
        address_zip => '123-4567',
        address_country => 'jp',
        amount => 2000,
        brand => 'Visa',
        card => $card_object,
        country => 'jp',
        currency => 'jpy',
        description => 'Primary source for customer',
        email => 'john.doe@example.com',
        exp_month => 4,
        exp_year => 2030,
        funding => 'debit',
        metadata => { transaction_id => 123, customer_id => 456 },
        name => 'John Doe',
        statement_descriptor => 'Big Corp Services',
        type => 'card',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Source objects allow you to accept a variety of payment methods. They represent a customer's payment instrument, and can be used with the Stripe API just like a Card object: once chargeable, they can be charged, or can be attached to customers.

Stripe states this approach for card is deprecated in favour or PaymentIntent: L<https://stripe.com/docs/sources/cards>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Source> object.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "source"

String representing the object’s type. Objects of the same type share the same value.

=head2 account custom only string (expandable)

The account this card belongs to. This attribute will not be in the card object if the card belongs to a customer or recipient instead.

When expanded, this is a L<Net::API::Stripe::Connect::Account>

=head2 account_holder_name string

The name of the person or business that owns the bank account.

=head2 account_holder_type string

The type of entity that holds the account. This can be either individual or company.

=head2 ach_credit_transfer

If B<type> is set to C<ach_credit_transfer>, this is a L<Net::API::Stripe::Payment::Source::ACHCreditTransfer> object.

It is not very clear in the Stripe API, but in the B<type> property, they mention "An additional hash is included on the source with a name matching this value. It contains additional information specific to the payment method (L<https://stripe.com/docs/sources>) used." :/

=head2 ach_debit

If B<type> is set to C<ach_debit>, this is a L<Net::API::Stripe::Payment::Source::ACHDebit> object.

It is not very clear in the Stripe API, but in the B<type> property, they mention "An additional hash is included on the source with a name matching this value. It contains additional information specific to the payment method (L<https://stripe.com/docs/sources>) used." :/

=head2 active boolean

True when this bitcoin receiver has received a non-zero amount of bitcoin.

=head2 address L<Net::API::Stripe::Address> object or hash

This is a helper method. Provided with either a L<Net::API::Stripe::Address> object or a hash with same properties, this will assign all the address_* properties by calling its method.

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

=head2 alipay

If B<type> is set to C<alipay>, this is a L<Net::API::Stripe::Payment::Method::Details::Alipay> object.

=head2 amount integer

A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount associated with the source. This is the amount for which the source will be chargeable once ready. Required for single_use sources.

=head2 amount_received positive integer or zero

The amount of currency to which bitcoin_amount_received has been converted.

=head2 available_payout_methods array

A set of available payout methods for this card. Will be either ["standard"] or ["standard", "instant"]. Only values from this set should be passed as the method when creating a transfer.

=head2 bancontact

If B<type> is set to C<bancontact>, this is a L<Net::API::Stripe::Payment::Method::Details::BanContact> object.

=head2 bank_name string

Name of the bank associated with the routing number (e.g., WELLS FARGO).

=head2 bitcoin_amount positive integer

The amount of bitcoin that the customer should send to fill the receiver. The bitcoin_amount is denominated in Satoshi: there are 10^8 Satoshi in one bitcoin.

=head2 bitcoin_amount_received positive integer or zero

The amount of bitcoin that has been sent by the customer to this receiver.

=head2 bitcoin_uri string

This URI can be displayed to the customer as a clickable link (to activate their bitcoin client) or as a QR code (for mobile wallets).

=head2 brand string

Card brand. Can be American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown.

=head2 card object

If B<type> is set to C<card>, this is a L<Net::API::Stripe::Payment::Card> object. See also L<https://stripe.com/docs/sources/cards>.

=head2 card_present

If B<type> is set to C<card_present>, this is a L<Net::API::Stripe::Payment::Method::Details::CardPresent> object.

=head2 client_secret string

The client secret of the source. Used for client-side retrieval using a publishable key.

=head2 code_verification hash

Information related to the code verification flow. Present if the source is authenticated by a verification code (flow is code_verification).

This is a L<Net::API::Stripe::Payment::Source::CodeVerification> object.

=head2 country string

Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you’ve collected.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter ISO code for the currency associated with the source. This is the currency for which the source will be chargeable once ready. Required for single_use sources.

=head2 customer string

The ID of the customer to which this source is attached. This will not be present when the source has not been attached to a customer. If it is expanded, this would be a L<Net::API::Stripe::Customer> object.

=head2 cvc_check string

If a CVC was provided, results of the check: pass, fail, unavailable, or unchecked.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 dynamic_last4 string

(For tokenized numbers only.) The last four digits of the device account number.

=head2 email string

The customer’s email address, set by the API call that creates the receiver.

=head2 eps

If B<type> is set to C<eps>, this is a L<Net::API::Stripe::Payment::Method::Details::EPS> object.

=head2 exp_month integer

Two-digit number representing the card’s expiration month.

=head2 exp_year integer

Four-digit number representing the card’s expiration year.

=head2 filled boolean

This flag is initially false and updates to true when the customer sends the bitcoin_amount to this receiver.

=head2 fingerprint string

Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example.

=head2 flow string

The authentication flow of the source. flow is one of redirect, receiver, code_verification, none.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 funding string

Card funding type. Can be credit, debit, prepaid, or unknown.

=head2 giropay

If B<type> is set to C<giropay>, this is a L<Net::API::Stripe::Payment::Method::Details::Giropay> object.

=head2 ideal

If B<type> is set to C<ideal>, this is a L<Net::API::Stripe::Payment::Method::Details::Ideal> object.

=head2 inbound_address string

A bitcoin address that is specific to this receiver. The customer can send bitcoin to this address to fill the receiver.

=head2 klarna

If B<type> is set to C<klarna>, this is a L<Net::API::Stripe::Payment::Method::Details::Klarna> object.

=head2 last4 string

The last four digits of the card.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 multibanco

If B<type> is set to C<multibanco>, this is a L<Net::API::Stripe::Payment::Method::Details::MultiBanco> object.

=head2 name string

Cardholder name.

=head2 p24

If B<type> is set to C<p24>, this is a L<Net::API::Stripe::Payment::Method::Details::P24> object.

=head2 payment string

The ID of the payment created from the receiver, if any. Hidden when viewing the receiver with a publishable key.

=head2 owner hash

Information about the owner of the payment instrument that may be used or required by particular source types.

This is a L<Net::API::Stripe::Payment::Source::Owner> object.

=head2 payment_amount positive integer

If the Alipay account object is not reusable, the exact amount that you can create a charge for.

=head2 payment_currency currency

If the Alipay account object is not reusable, the exact currency that you can create a charge for.

=head2 receiver hash

Information related to the receiver flow. Present if the source is a receiver (flow is receiver).

This is a L<Net::API::Stripe::Payment::Source::Receiver> object.

=head2 recipient string (expandable)

The recipient that this card belongs to. This attribute will not be in the card object if the card belongs to a customer or account instead.

When expanded, this is a L<Net::API::Stripe::Customer>.

=head2 redirect hash

Information related to the redirect flow. Present if the source is authenticated by a redirect (flow is redirect).

This is a L<Net::API::Stripe::Payment::Source::Redirect> object.

=head2 reusable boolean

True if you can create multiple payments using this account. If the account is reusable, then you can freely choose the amount of each payment.

=head2 refund_address string

The refund address of this bitcoin receiver.

=head2 routing_number string

The routing transit number for the bank account.

=head2 sofort hash

If B<type> is set to C<sofort>, this is a L<Net::API::Stripe::Payment::Details::Sofort> virtual object, ie it is created dynamically by L<Nodule::Generic/"set_get_hash_as_object">

=head2 source_order hash

Information about the items and shipping associated with the source. Required for transactional credit (for example Klarna) sources before you can charge it. This is a L<Net::API::Stripe::Order> object.

=over 4

=item I<amount> integer

A positive integer in the smallest currency unit (that is, 100 cents for $1.00, or 1 for ¥1, Japanese Yen being a zero-decimal currency) representing the total amount for the order.

=item I<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item I<email> string

The email address of the customer placing the order.

=item I<items> array of hashes

List of items constituting the order. This is an array of L<Net::API::Stripe::Order::Item> objects.

=item I<shipping> hash

The shipping address for the order. Present if the order is for goods to be shipped. This is a L<Net::API::Stripe::Shipping> object

=back

=head2 statement_descriptor string

Extra information about a source. This will appear on your customer’s statement every time you charge the source.

=head2 status string

The status of the source, one of canceled, chargeable, consumed, failed, or pending. Only chargeable sources can be used to create a charge.

=head2 stripe_account

If B<type> is set to C<stripe_account>, this is a L<Net::API::Stripe::Payment::Method::Details::StripeAccount> object.

=head2 tokenization_method string

If the card number is tokenized, this is the method that was used. Can be apple_pay or google_pay.

=head2 transactions

A list (L<Net::API::Stripe::List>) of L<Net::API::Stripe::Bitcoin::Transaction> object

=head2 type string

The type of the source. The type is a payment method, one of ach_credit_transfer, ach_debit, alipay, bancontact, card, card_present, eps, giropay, ideal, multibanco, klarna, p24, sepa_debit, sofort, three_d_secure, or wechat. An additional hash is included on the source with a name matching this value. It contains additional information specific to the payment method (L<https://stripe.com/docs/sources>) used.

=head2 uncaptured_funds boolean

This receiver contains uncaptured funds that can be used for a payment or refunded.

=head2 usage string

Either reusable or single_use. Whether this source should be reusable or not. Some source types may or may not be reusable by construction, while others may leave the option at creation. If an incompatible value is passed, an error will be returned.

=head2 used boolean

Whether this Alipay account object has ever been used for a payment.

=head2 used_for_payment boolean

Indicate if this source is used for payment.

=head2 username string

The username for the Alipay account.

=head2 wechat

If L</type> is set to C<wechat>, this is a L<Net::API::Stripe::Payment::Method::Details::WeChat> object.

=head1 API SAMPLE

    {
      "id": "src_fake123456789",
      "object": "source",
      "ach_credit_transfer": {
        "account_number": "test_52796e3294dc",
        "routing_number": "110000000",
        "fingerprint": "anvbmbvmnbvmab",
        "bank_name": "TEST BANK",
        "swift_code": "TSTEZ122"
      },
      "amount": null,
      "client_secret": "src_client_secret_fake123456789",
      "created": 1571314413,
      "currency": "jpy",
      "flow": "receiver",
      "livemode": false,
      "metadata": {},
      "owner": {
        "address": null,
        "email": "jenny.rosen@example.com",
        "name": null,
        "phone": null,
        "verified_address": null,
        "verified_email": null,
        "verified_name": null,
        "verified_phone": null
      },
      "receiver": {
        "address": "121042882-38381234567890123",
        "amount_charged": 0,
        "amount_received": 0,
        "amount_returned": 0,
        "refund_attributes_method": "email",
        "refund_attributes_status": "missing"
      },
      "statement_descriptor": null,
      "status": "pending",
      "type": "ach_credit_transfer",
      "usage": "reusable"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2018-01-23

When being viewed by a platform, cards and bank accounts created on behalf of connected accounts will have a fingerprint that is universal across all connected accounts. For accounts that are not connect platforms, there will be no change.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/sources>, L<https://stripe.com/docs/sources>, L<https://stripe.com/docs/sources/customers>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

