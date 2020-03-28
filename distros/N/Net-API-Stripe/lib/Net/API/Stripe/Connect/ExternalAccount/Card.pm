##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/ExternalAccount/Card.pm
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
## https://stripe.com/docs/api/external_account_cards/object
package Net::API::Stripe::Connect::ExternalAccount::Card;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account { return( shift->_set_get_scalar_or_object( 'account', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub address_city { return( shift->_set_get_scalar( 'address_city', @_ ) ); }

sub address_country { return( shift->_set_get_scalar( 'address_country', @_ ) ); }

sub address_line1 { return( shift->_set_get_scalar( 'address_line1', @_ ) ); }

sub address_line1_check { return( shift->_set_get_scalar( 'address_line1_check', @_ ) ); }

sub address_line2 { return( shift->_set_get_scalar( 'address_line2', @_ ) ); }

sub address_state { return( shift->_set_get_scalar( 'address_state', @_ ) ); }

sub address_zip { return( shift->_set_get_scalar( 'address_zip', @_ ) ); }

sub address_zip_check { return( shift->_set_get_scalar( 'address_zip_check', @_ ) ); }

sub available_payout_methods { return( shift->_set_get_array( 'available_payout_methods', @_ ) ); }

## Card brand name, e.g. American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown
sub brand { return( shift->_set_get_scalar( 'brand', @_ ) ); }

sub checks { return( shift->_set_get_hash( 'checks', @_ ) ) };

sub country { return( shift->_set_get_scalar( 'country', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub cvc { return( shift->_set_get_scalar( 'cvc', @_ ) ); }

sub cvc_check { return( shift->_set_get_scalar( 'cvc_check', @_ ) ); }

sub default_for_currency { return( shift->_set_get_scalar( 'default_for_currency', @_ ) ); }

sub dynamic_last4 { return( shift->_set_get_scalar( 'dynamic_last4', @_ ) ); }

sub exp_month { return( shift->_set_get_number( 'exp_month', @_ ) ); }

sub exp_year { return( shift->_set_get_number( 'exp_year', @_ ) ); }

sub fingerprint { return( shift->_set_get_scalar( 'fingerprint', @_ ) ); }

sub funding { return( shift->_set_get_scalar( 'funding', @_ ) ); }

sub generated_from { return( shift->_set_get_object( 'generated_from', 'Net::API::Stripe::Payment::GeneratedFrom', @_ ) ); }

sub installments { return( shift->_set_get_object( 'installments', 'Net::API::Stripe::Payment::Installment', @_ ) ); }

sub last4 { return( shift->_set_get_scalar( 'last4', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

## Cardholder name
sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

## Preview features says Stripe API
sub network { return( shift->_set_get_scalar( 'network', @_ ) ); }

sub recipient { return( shift->_set_get_scalar_or_object( 'recipient', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub three_d_secure { return( shift->_set_get_hash_as_object( 'three_d_secure', 'Net::API::Stripe::Payment::3DSecure', @_ ) ); }

sub three_d_secure_usage { return( shift->_set_get_hash_as_object( 'three_d_secure_usage', 'Net::API::Strip::Payment::3DUsage', @_ ) ); }

sub tokenization_method { return( shift->_set_get_scalar( 'tokenization_method', @_ ) ); }

sub wallet { return( shift->_set_get_hash_as_object( 'wallet', 'Net::API::Stripe::Payment::Wallet', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::ExternalAccount::Card - A Stripe Card Account Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

These External Accounts are transfer destinations on Account objects for Custom accounts (L<https://stripe.com/docs/connect/custom-accounts>). They can be bank accounts or debit cards.

Bank accounts (L<https://stripe.com/docs/api#customer_bank_account_object>) and debit cards (L<https://stripe.com/docs/api#card_object>) can also be used as payment sources on regular charges, and are documented in the links above.

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

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "card"

String representing the object’s type. Objects of the same type share the same value.

=item B<account> custom only string (expandable)

The account this card belongs to. This attribute will not be in the card object if the card belongs to a customer or recipient instead.

When expanded, this is a C<Net::API::Stripe::Connect::Account> object.

=item B<address_city> string

City/District/Suburb/Town/Village.

=item B<address_country> string

Billing address country, if provided when creating card.

=item B<address_line1> string

Address line 1 (Street address/PO Box/Company name).

=item B<address_line1_check> string

If address_line1 was provided, results of the check: pass, fail, unavailable, or unchecked.

=item B<address_line2> string

Address line 2 (Apartment/Suite/Unit/Building).

=item B<address_state> string

State/County/Province/Region.

=item B<address_zip> string

ZIP or postal code.

=item B<address_zip_check> string

If address_zip was provided, results of the check: pass, fail, unavailable, or unchecked.

=item B<available_payout_methods> array

A set of available payout methods for this card. Will be either ["standard"] or ["standard", "instant"]. Only values from this set should be passed as the method when creating a transfer.

=item B<brand> string

Card brand. Can be American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown.

=item B<checks>

=over 8

=item I<address_line1_check> string

If a address line1 was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.

=item I<address_postal_code_check> string

If a address postal code was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.

=item I<cvc_check> string

If a CVC was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.

=back

=item B<country> string

Two-letter ISO code representing the country of the card. You could use this attribute to get a sense of the international breakdown of cards you’ve collected.

=item B<currency> custom only currency

Three-letter ISO code for currency. Only applicable on accounts (not customers or recipients). The card can be used as a transfer destination for funds in this currency.

=item B<customer> string (expandable)

The customer that this card belongs to. This attribute will not be in the card object if the card belongs to an account or recipient instead.

When expanded, this is a C<Net::API::Stripe::Customer> object.

=item B<cvc> string

Card security code. Highly recommended to always include this value, but it's required only for accounts based in European countries.

This is used when creating a card object on Stripe API. See here: L<https://stripe.com/docs/api/cards/create>

=item B<cvc_check> string

If a CVC was provided, results of the check: pass, fail, unavailable, or unchecked.

=item B<default_for_currency> custom only boolean

Whether this card is the default external account for its currency.

=item B<dynamic_last4> string

(For tokenized numbers only.) The last four digits of the device account number.

=item B<exp_month> integer

Two-digit number representing the card’s expiration month.

=item B<exp_year> integer

Four-digit number representing the card’s expiration year.

=item B<fingerprint> string

Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example.

=item B<funding> string

Card funding type. Can be credit, debit, prepaid, or unknown.

=item B<generated_from> hash

Details of the original PaymentMethod that created this object.

=item B<installments> hash

If present, this is a C<Net::API::Stripe::Payment::Installment> object. As of 2019-02-19, this is only used in Mexico though. See here for more information: L<https://stripe.com/docs/payments/installments>

=item B<last4> string

The last four digits of the card.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<name> string

Cardholder name.

=item B<network> string preview feature

Identifies which network this charge was processed on. Can be amex, diners, discover, interac, jcb, mastercard, unionpay, visa, or unknown.

=item B<recipient> string (expandable)

The recipient that this card belongs to. This attribute will not be in the card object if the card belongs to a customer or account instead.

Since 2017, Stripe recipients have been replaced by Stripe accounts: L<https://stripe.com/docs/connect/recipient-account-migrations>

So this is a Stripe account id, or if expanded, a C<Net::API::Stripe::Connect::Account> object.

=item B<three_d_secure> hash

Populated if this transaction used 3D Secure authentication.

This is an objectified hash reference, ie its key / value pairs can be accessed as virtual methods. It uses the virtal package C<Net::API::Stripe::Payment::3DSecure>

=over 8

=item I<authenticated> boolean

Whether or not authentication was performed. 3D Secure will succeed without authentication when the card is not enrolled.

=item I<succeeded> boolean

Whether or not 3D Secure succeeded.

=item I<version> string

The version of 3D Secure that was used for this payment.

=back

=item B<three_d_secure_usage> hash

Contains details on how this Card maybe be used for 3D Secure authentication.

This is a virtual C<Net::API::Strip::Payment::3DUsage> object ie whereby each key can be accessed as methods.

=over 8

=item B<supported> boolean

Whether 3D Secure is supported on this card.

=back

=item B<tokenization_method> string

If the card number is tokenized, this is the method that was used. Can be apple_pay or google_pay.

=item B<wallet> hash

If this Card is part of a card wallet, this contains the details of the card wallet.

If present, this is a virtual package C<Net::API::Stripe::Payment::Wallet> object. The following data structure that can be accessed as chain objects is:

=over 4

=item B<amex_express_checkout> hash

If this is a amex_express_checkout card wallet, this hash contains details about the wallet.

No properties set yet in Stripe documentation.

=item B<apple_pay> hash

If this is a apple_pay card wallet, this hash contains details about the wallet.

No properties set yet in Stripe documentation.

=item B<dynamic_last4> string

(For tokenized numbers only.) The last four digits of the device account number.

=item B<google_pay> hash

If this is a google_pay card wallet, this hash contains details about the wallet.

No properties set yet in Stripe documentation.

=item B<masterpass> hash

If this is a masterpass card wallet, this hash contains details about the wallet.

=over 8

=item B<billing_address> hash

Owner’s verified billing address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=over 12

=item B<city> string

City/District/Suburb/Town/Village.

=item B<country> string

2-letter country code.

=item B<line1> string

Address line 1 (Street address/PO Box/Company name).

=item B<line2> string

Address line 2 (Apartment/Suite/Unit/Building).

=item B<postal_code> string

ZIP or postal code.

=item B<state> string

State/County/Province/Region.

=back

=item B<email> string

Owner’s verified email. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item B<name> string

Owner’s verified full name. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item B<shipping_address> hash

Owner’s verified shipping address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=over 12

=item B<city> string

City/District/Suburb/Town/Village.

=item B<country> string

2-letter country code.

=item B<line1> string

Address line 1 (Street address/PO Box/Company name).

=item B<line2> string

Address line 2 (Apartment/Suite/Unit/Building).

=item B<postal_code> string

ZIP or postal code.

=item B<state> string

State/County/Province/Region.

=back

=back

=item B<samsung_pay> hash

If this is a samsung_pay card wallet, this hash contains details about the wallet.

No properties set yet in Stripe documentation.

=item B<type> string

The type of the card wallet, one of amex_express_checkout, apple_pay, google_pay, masterpass, samsung_pay, or visa_checkout. An additional hash is included on the Wallet subhash with a name matching this value. It contains additional information specific to the card wallet type.

=item B<visa_checkout> hash

If this is a visa_checkout card wallet, this hash contains details about the wallet.

=over 4

=item B<billing_address hash

Owner’s verified billing address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=over 8

=item B<city> string

City/District/Suburb/Town/Village.

=item B<country> string

2-letter country code.

=item B<line1> string

Address line 1 (Street address/PO Box/Company name).

=item B<line2> string

Address line 2 (Apartment/Suite/Unit/Building).

=item B<postal_code> string

ZIP or postal code.

=item B<state> string

State/County/Province/Region.

=back

=item B<email> string

Owner’s verified email. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item B<name> string

Owner’s verified full name. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=item B<shipping_address> hash

Owner’s verified shipping address. Values are verified or provided by the wallet directly (if supported) at the time of authorization or settlement. They cannot be set or mutated.

=over 8

=item B<city> string

City/District/Suburb/Town/Village.

=item B<country> string

2-letter country code.

=item B<line1> string

Address line 1 (Street address/PO Box/Company name).

=item B<line2> string

Address line 2 (Apartment/Suite/Unit/Building).

=item B<postal_code> string

ZIP or postal code.

=item B<state> string

State/County/Province/Region.

=back

=back

=back

=back

=head1 API SAMPLE

	{
	  "id": "card_1FVF3JCeyNCl6fY2zKx7HpoK",
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
	  "fingerprint": "x18XyLUPM6hub5xz",
	  "funding": "credit",
	  "last4": "4242",
	  "metadata": {},
	  "name": null,
	  "tokenization_method": null
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

L<https://stripe.com/docs/api/external_account_cards/object>, L<https://stripe.com/docs/connect/payouts>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
