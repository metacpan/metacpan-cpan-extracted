##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Charge.pm
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
package Net::API::Stripe::Charge;
## https://stripe.com/docs/api/charges/object
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub amount_refunded { shift->_set_get_number( 'amount_refunded', @_ ); }

sub application { shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ); }

sub application_fee { shift->_set_get_number_or_object( 'application_fee', 'Net::API::Stripe::Connect::ApplicationFee', @_ ); }

sub application_fee_amount { shift->_set_get_number( 'application_fee_amount', @_ ); }

sub balance_transaction { shift->_set_get_scalar_or_object( 'balance_transaction', 'Net::API::Stripe::Balance::Transaction', @_ ); }

sub billing_details { shift->_set_get_object( 'billing_details', 'Net::API::Stripe::Billing::Details', @_ ); }

sub captured { shift->_set_get_boolean( 'captured', @_ ); }

sub card { shift->_set_get_object( 'card', 'Net::API::Stripe::Payment::Card', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

## Expandable so either we get an id or we get the underlying object
sub customer { shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub destination { shift->_set_get_scalar_or_object( 'destination', 'Net::API::Stripe::Connect::Account', @_ ); }

sub dispute { shift->_set_get_scalar_or_object( 'dispute', 'Net::API::Stripe::Dispute', @_ ); }

sub failure_code { shift->_set_get_scalar( 'failure_code', @_ ); }

sub failure_message { shift->_set_get_scalar( 'failure_message', @_ ); }

sub fraud_details { shift->_set_get_hash( 'fraud_details', @_ ); }

sub invoice { shift->_set_get_scalar_or_object( 'invoice', 'Net::API::Stripe::Billing::Invoice', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub on_behalf_of { shift->_set_get_scalar_or_object( 'on_behalf_of', 'Net::API::Stripe::Connect::Account', @_ ); }

sub order { shift->_set_get_scalar_or_object( 'order', 'Net::API::Stripe::Order', @_ ); }

sub outcome { shift->_set_get_object( 'outcome', 'Net::API::Stripe::Charge::Outcome', @_ ); }

sub paid { shift->_set_get_boolean( 'paid', @_ ); }

sub payment_intent { shift->_set_get_scalar( 'payment_intent', @_ ); }

sub payment_method { shift->_set_get_scalar( 'payment_method', @_ ); }

sub payment_method_details { shift->_set_get_object( 'payment_method_details', 'Net::API::Stripe::Payment::Method::Details', @_ ); }

sub receipt_email { shift->_set_get_scalar( 'receipt_email', @_ ); }

sub receipt_number { shift->_set_get_scalar( 'receipt_number', @_ ); }

sub receipt_url { shift->_set_get_scalar( 'receipt_url', @_ ); }

sub refunded { shift->_set_get_boolean( 'refunded', @_ ); }

## A list of refunds that have been applied to the charge.
## Net::API::Stripe::Charge::Refunds
sub refunds { shift->_set_get_object( 'refunds', 'Net::API::Stripe::Charge::Refunds', @_ ); }

sub review { shift->_set_get_scalar_or_object( 'review', 'Net::API::Stripe::Fraud::Review', @_ ); }

sub shipping { shift->_set_get_object( 'shipping', 'Net::API::Stripe::Shipping', @_ ); }

sub source { shift->_set_get_object( 'source', 'Net::API::Stripe::Payment::Card', @_ ); }

sub source_transfer { shift->_set_get_scalar_or_object( 'source_transfer', 'Net::API::Stripe::Connect::Transfer', @_ ); }

sub statement_descriptor { shift->_set_get_scalar( 'statement_descriptor', @_ ); }

sub statement_description { shift->_set_get_scalar( 'statement_description', @_ ); }

sub statement_descriptor_suffix { shift->_set_get_scalar( 'statement_descriptor_suffix', @_ ); }

## 2019-10-16: gone?
sub status { shift->_set_get_scalar( 'status', @_ ); }

sub transfer { shift->_set_get_scalar_or_object( 'transfer', 'Net::API::Stripe::Connect::Transfer', @_ ); }

sub transfer_data { shift->_set_get_object( 'transfer_data', 'Net::API::Stripe::Connect::Transfer', @_ ); }

sub transfer_group { shift->_set_get_scalar( 'transfer_group', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Charge - The Charge object of Stripe API

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

To charge a credit or a debit card, you create a Charge object. You can retrieve and refund individual charges as well as list all charges. Charges are identified by a unique, random ID.

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

=item B<object> string, value is "charge"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> positive integer or zero

A positive integer representing how much to charge in the smallest currency unit (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or equivalent in charge currency. The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).

=item B<amount_refunded> positive integer or zero

Amount in JPY refunded (can be less than the amount attribute on the charge if a partial refund was issued).

=item B<application> string expandable "application"

ID of the Connect application that created the charge. This represents a C<Net::API::Stripe::Connect::Account> object

=item B<application_fee> string (expandable)

The application fee (if any) for the charge. See the Connect documentation for details. This is a C<Net::API::Stripe::Connect::ApplicationFee> object.

=item B<application_fee_amount> integer

The amount of the application fee (if any) for the charge. See the Connect documentation for details.

=item B<balance_transaction> string (expandable)

ID of the balance transaction that describes the impact of this charge on your account balance (not including refunds or disputes).

This is an C<Net::API::Stripe::Balance::Transaction> object.

=item B<billing_details> hash

Billing information associated with the payment method at the time of the transaction. This is a C<Net::API::Stripe::Billing::Details> object.

Show child attributes

=item B<captured> boolean

If the charge was created without capturing, this Boolean represents whether it is still uncaptured or has since been captured.

=item B<card>

This is a C<Net::API::Stripe::Payment::Card> object. It seems it is no documented, but from experience, Stripe has replied with data containing this property.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<currency> currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<customer> string (expandable)

ID of the customer this charge is for if one exists.

This is a C<Net::API::Stripe::Customer> object.

=item B<description> string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<destination>

This is a C<Net::API::Stripe::Connect::Account> object. But, as of 2019-10-16, it seems absent from Stripe API documentation, so maybe it was removed?

=item B<dispute> string (expandable)

Details about the dispute if the charge has been disputed.

When expanded, this is a C<Net::API::Stripe::Dispute> object.

=item B<failure_code> string

Error code explaining reason for charge failure if available (see the errors section for a list of codes).

=item B<failure_message> string

Message to user further explaining reason for charge failure if available.

=item B<fraud_details> hash

Information on fraud assessments for the charge.

=over 8

=item I<stripe_report> string

Assessments from Stripe. If set, the value is fraudulent.

=item I<user_report> string

Assessments reported by you. If set, possible values of are safe and fraudulent.

=back

=item B<invoice> string (expandable)

ID of the invoice this charge is for if one exists.

When expanded, this is a C<Net::API::Stripe::Billing::Invoice> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<on_behalf_of> string (expandable)

The account (if any) the charge was made on behalf of without triggering an automatic transfer. See the Connect documentation for details.

When expanded, this is a C<Net::API::Stripe::Connect::Account> object

=item B<order> string (expandable)

ID of the order this charge is for if one exists.

When expanded, this is a C<Net::API::Stripe::Order> object.

=item B<outcome> hash

Details about whether the payment was accepted, and why. See understanding declines for details.

This is a C<Net::API::Stripe::Charge::Outcome> object.

=item B<paid> boolean

true if the charge succeeded, or was successfully authorized for later capture.

=item B<payment_intent> string

ID of the PaymentIntent associated with this charge, if one exists.

This is a <Net::API::Stripe::Payment::Intent> object if any.

=item B<payment_method> string

ID of the payment method used in this charge.

=item B<payment_method_details> hash

Details about the payment method at the time of the transaction.
Show child attributes

=item B<receipt_email> string

This is the email address that the receipt for this charge was sent to.

=item B<receipt_number> string

This is the transaction number that appears on email receipts sent for this charge. This attribute will be null until a receipt has been sent.

=item B<receipt_url> string

This is the URL to view the receipt for this charge. The receipt is kept up-to-date to the latest state of the charge, including any refunds. If the charge is for an Invoice, the receipt will be stylized as an Invoice receipt.

=item B<refunded> boolean

Whether the charge has been fully refunded. If the charge is only partially refunded, this attribute will still be false.

=item B<refunds> list

A list of refunds that have been applied to the charge.

This is a C<Net::API::Stripe::Charge::Refunds> object.

=item B<review> string (expandable)

ID of the review associated with this charge if one exists.

When expanded, this is a C<Net::API::Stripe::Fraud::Review> object.

=item B<shipping> hash

Shipping information for the charge. This is a C<Net::API::Stripe::Shipping> object.

=item B<source>

This represents a C<Net::API::Stripe::Payment::Card> object.

It was present before, or at least used in Stripe response, but it is not anymore on the API documentation as of 2019-10-16.

=item B<source_transfer> string (expandable)

The transfer ID which created this charge. Only present if the charge came from another Stripe account. See the Connect documentation for details here: L<https://stripe.com/docs/connect/destination-charges>

When expanded, this is a C<Net::API::Stripe::Connect::Transfer> object.

=item B<statement_descriptor> string

For card charges, use statement_descriptor_suffix instead. Otherwise, you can use this value as the complete description of a charge on your customers’ statements. Must contain at least one letter, maximum 22 characters.

=item B<statement_description>

This is an alternative found in data returned by Stripe. Probably an old property deprecated?

=item B<statement_descriptor_suffix> string

Provides information about the charge that customers see on their statements. Concatenated with the prefix (shortened descriptor) or statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters for the concatenated descriptor.

=item B<status> string

The status of the payment is either succeeded, pending, or failed.

=item B<transfer> string (expandable)

ID of the transfer to the destination account (only applicable if the charge was created using the destination parameter).

When expanded, this is a C<Net::API::Stripe::Connect::Transfer> object.

=item B<transfer_data> hash

An optional dictionary including the account to automatically transfer to as part of a destination charge. See the Connect documentation for details.

This is a C<Net::API::Stripe::Connect::Transfer> object, although in the documentation only the following 2 properties are used:

=over 8

=item I<amount> integer

The amount transferred to the destination account, if specified. By default, the entire charge amount is transferred to the destination account.

=item I<destination> string (expandable)

ID of an existing, connected Stripe account to transfer funds to if transfer_data was specified in the charge request.

If expanded, this is a C<Net::API::Stripe::Connect::Account> object.

=back

=item B<transfer_group> string

A string that identifies this transaction as part of a group. See the Connect documentation for details.

=back

=head1 API SAMPLE

	{
	  "id": "ch_1FTxyCCeyNCl6fY2aYoHTBBF",
	  "object": "charge",
	  "amount": 100,
	  "amount_refunded": 0,
	  "application": null,
	  "application_fee": null,
	  "application_fee_amount": null,
	  "balance_transaction": "txn_1FTlZvCeyNCl6fY2qIteNrPe",
	  "billing_details": {
		"address": {
		  "city": null,
		  "country": null,
		  "line1": null,
		  "line2": null,
		  "postal_code": null,
		  "state": null
		},
		"email": null,
		"name": null,
		"phone": null
	  },
	  "captured": false,
	  "created": 1571176460,
	  "currency": "jpy",
	  "customer": null,
	  "description": "My First Test Charge (created for API docs)",
	  "dispute": null,
	  "failure_code": null,
	  "failure_message": null,
	  "fraud_details": {},
	  "invoice": null,
	  "livemode": false,
	  "metadata": {},
	  "on_behalf_of": null,
	  "order": null,
	  "outcome": null,
	  "paid": true,
	  "payment_intent": null,
	  "payment_method": "card_1DSiVdCeyNCl6fY2xvLI809J",
	  "payment_method_details": {
		"card": {
		  "brand": "visa",
		  "checks": {
			"address_line1_check": null,
			"address_postal_code_check": null,
			"cvc_check": null
		  },
		  "country": "US",
		  "exp_month": 4,
		  "exp_year": 2024,
		  "fingerprint": "x18XyLUPM6hub5xz",
		  "funding": "credit",
		  "installments": null,
		  "last4": "4242",
		  "network": "visa",
		  "three_d_secure": null,
		  "wallet": null
		},
		"type": "card"
	  },
	  "receipt_email": null,
	  "receipt_number": null,
	  "receipt_url": "https://pay.stripe.com/receipts/acct_19eGgRCeyNCl6fY2/ch_1FTxyCCeyNCl6fY2aYoHTBBF/rcpt_FzxuG1UR6Pj9Er68sVPgHRNMLeKZomf",
	  "refunded": false,
	  "refunds": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/charges/ch_1FTxyCCeyNCl6fY2aYoHTBBF/refunds"
	  },
	  "review": null,
	  "shipping": null,
	  "source_transfer": null,
	  "statement_descriptor": null,
	  "statement_descriptor_suffix": null,
	  "status": "succeeded",
	  "transfer_data": null,
	  "transfer_group": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/charges>, L<https://stripe.com/docs/charges>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
