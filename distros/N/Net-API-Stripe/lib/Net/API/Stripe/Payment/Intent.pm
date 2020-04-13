##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Intent.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/payment_intents
package Net::API::Stripe::Payment::Intent;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

## 2019-02-11
## Stripe: allowed_source_types has been renamed to payment_method_types.
## sub allowed_source_types { shift->_set_get_scalar( 'allowed_source_types', @_ ); }
sub allowed_source_types { return( shift->payment_method_types( @_ ) ); }

## 2019-02-11
## Stripe: authorize_with_url within has been renamed to redirect_to_url.
sub authorize_with_url { return( shift->redirect_to_url( @_ ) ); }

sub amount { shift->_set_get_number( 'amount', @_ ); }

sub amount_capturable { shift->_set_get_number( 'amount_capturable', @_ ); }

sub amount_received { shift->_set_get_number( 'amount_received', @_ ); }

sub application { shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ); }

sub application_fee_amount { shift->_set_get_number( 'application_fee_amount', @_ ); }

sub canceled_at { shift->_set_get_datetime( 'canceled_at', @_ ); }

sub cancellation_reason { shift->_set_get_scalar( 'cancellation_reason', @_ ); }

sub capture_method { shift->_set_get_scalar( 'capture_method', @_ ); }

sub charges { shift->_set_get_object( 'charges', 'Net::API::Stripe::Payment::Intent::Charges', @_ ); }

sub client_secret { shift->_set_get_scalar( 'client_secret', @_ ); }

sub confirmation_method { shift->_set_get_scalar( 'confirmation_method', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub currency { shift->_set_get_scalar( 'currency', @_ ); }

sub customer { shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub invoice { return( shift->_set_get_scalar_or_object( 'invoice', '::API::Stripe::Billing::Invoice', @_ ) ); }

sub last_payment_error { shift->_set_get_object( 'last_payment_error', 'Net::API::Stripe::Error', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub next_action { return( shift->_set_get_object( 'next_action', 'Net::API::Stripe::Payment::Intent::NextAction', @_ ) ); }

# 2019-02-11
# Stripe: The next_source_action property on PaymentIntent has been renamed to next_action
# sub next_source_action { shift->_set_get_scalar( 'next_source_action', @_ ); }
sub next_source_action { return( shift->next_action( @_ ) ); }

sub on_behalf_of { return( shift->_set_get_scalar_or_object( 'on_behalf_of', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub payment_method { return( shift->_set_get_scalar( 'payment_method', @_ ) ); }

sub payment_method_options { return( shift->_set_get_hash_as_object( 'payment_method_options', 'Net::API::Stripe::Payment::Method::Options', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

sub receipt_email { shift->_set_get_scalar( 'receipt_email', @_ ); }

sub return_url { shift->_set_get_uri( 'return_url', @_ ); }

sub review { shift->_set_get_scalar_or_object( 'review', 'Net::API::Stripe::Fraud::Review', @_ ); }

sub setup_future_usage { return( shift->_set_get_scalar( 'setup_future_usage', @_ ) ); }

sub shipping { shift->_set_get_object( 'shipping', 'Net::API::Stripe::Shipping', @_ ); }

sub source { shift->_set_get_scalar_or_object( 'source', 'Net::API::Stripe::Payment::Source', @_ ); }

sub statement_descriptor { shift->_set_get_scalar( 'statement_descriptor', @_ ); }

sub statement_descriptor_suffix { return( shift->_set_get_scalar( 'statement_descriptor_suffix', @_ ) ); }

## requires_payment_method, requires_confirmation, requires_action, processing, requires_capture, canceled, or succeeded
sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub transfer_data { shift->_set_get_object( 'transfer_data', 'Net::API::Stripe::Payment::Intent::TransferData', @_ ); }

sub transfer_group { shift->_set_get_scalar( 'transfer_group', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Intent - A Stripe Payment Intent Object

=head1 SYNOPSIS

    my $intent = $stripe->payment_intent({
        amount => 2000,
        amount_capturable => 2000,
        application => $connect_account_object,
        application_fee_amount => 20,
        capture_method => 'automatic',
        customer => $customer_object,
        description => 'Preparation for payment',
        invoice => $invoice_object,
        metadata => { transaction_id => 123, customer_id => 456 },
        receipt_email => 'john.doe@example.com',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

A PaymentIntent guides you through the process of collecting a payment from your customer. Stripe recommends that you create exactly one PaymentIntent for each order or customer session in your system. You can reference the PaymentIntent later to see the history of payment attempts for a particular session.

A PaymentIntent transitions through multiple statuses throughout its lifetime as it interfaces with Stripe.js to perform authentication flows and ultimately creates at most one successful charge.

Creating payments takes five steps:

=over 4

=item 1. Create a PaymentIntent on the server

=item 2. Pass the PaymentIntent’s client secret to the client

=item 3. Collect payment method details on the client

=item 4. Submit the payment to Stripe from the client

=item 5. Asynchronously fulfill the customer’s order

=back

More info here: L<https://stripe.com/docs/payments/payment-intents/web>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payment::Intent> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> retrievable with publishable key string

Unique identifier for the object.

=item B<object> retrievable with publishable key string, value is "payment_intent"

String representing the object’s type. Objects of the same type share the same value.

=item B<amount> retrievable with publishable key integer

Amount intended to be collected by this PaymentIntent.

=item B<amount_capturable> integer

Amount that can be captured from this PaymentIntent.

=item B<amount_received> integer

Amount that was collected by this PaymentIntent.

=item B<application> string expandable "application"

ID of the Connect application that created the PaymentIntent.

This is a L<Net::API::Stripe::Connect::Account> object.

=item B<application_fee_amount> integer

The amount of the application fee (if any) for the resulting payment. See the PaymentIntents use case for connected accounts for details.

=item B<canceled_at> retrievable with publishable key timestamp

Populated when status is canceled, this is the time at which the PaymentIntent was canceled. Measured in seconds since the Unix epoch.

=item B<cancellation_reason> retrievable with publishable key string

Reason for cancellation of this PaymentIntent, either user-provided (duplicate, fraudulent, requested_by_customer, or abandoned) or generated by Stripe internally (failed_invoice, void_invoice, or automatic).

=item B<capture_method> retrievable with publishable key string

One of automatic (default) or manual.

When the capture method is automatic, Stripe automatically captures funds when the customer authorizes the payment.

Change capture_method to manual if you wish to separate authorization and capture for payment methods that support this.

=item B<charges> list

Charges that were created by this PaymentIntent, if any.

This is a L<Net::API::Stripe::Payment::Intent::Charges> object.

=item B<client_secret> retrievable with publishable key string

The client secret of this PaymentIntent. Used for client-side retrieval using a publishable key.

The client secret can be used to complete a payment from your frontend. It should not be stored, logged, embedded in URLs, or exposed to anyone other than the customer. Make sure that you have TLS enabled on any page that includes the client secret.

Please refer to L<Stripe quickstart guide|https://stripe.com/docs/payments/accept-a-payment> to learn about how client_secret should be handled.
confirmation_method retrievable with publishable key string

One of automatic (default) or manual.

When the confirmation method is automatic, a PaymentIntent can be confirmed using a publishable key. After 
next_actions are handled, no additional confirmation is required to complete the payment.

When the confirmation method is manual, all payment attempts must be made using a secret key. The PaymentIntent returns to the requires_confirmation state after handling next_actions, and requires your server to initiate each payment attempt with an explicit confirmation.

Learn more about the different confirmation flows.

=item B<created> retrievable with publishable key timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.
currency retrievable with publishable key currency

Three-letter ISO currency code, in lowercase. Must be a supported currency.

=item B<customer> string (expandable)

ID of the Customer this PaymentIntent belongs to, if one exists.

If present, payment methods used with this PaymentIntent can only be attached to this Customer, and payment methods attached to other Customers cannot be used with this PaymentIntent.

This is a customer id or a L<Net::API::Stripe::Customer> object.

=item B<description> retrievable with publishable key string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<invoice> string (expandable)

ID of the invoice that created this PaymentIntent, if it exists.

When expanded, this is a C<::API::Stripe::Billing::Invoice> object.

=item B<last_payment_error> retrievable with publishable key hash

The payment error encountered in the previous PaymentIntent confirmation.

This is a L<Net::API::Stripe::Error> object.

=item B<livemode> retrievable with publishable key boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format. For more information, see the documentation.

=item B<next_action> retrievable with publishable key hash

If present, this property tells you what actions you need to take in order for your customer to fulfill a payment using the provided source.

This is a L<Net::API::Stripe::Payment::Intent::NextAction> object with the following properties:

=over 8

=item B<redirect_to_url> hash

Contains instructions for authenticating a payment by redirecting your customer to another page or application.

See module L<Net::API::Stripe::Payment::Intent::NextAction> for more information.

=over 12

=item I<return_url> string

If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.

=item I<url> string

The URL you must redirect your customer to in order to authenticate the payment.

=back

=item B<type> string

Type of the next action to perform, one of redirect_to_url or use_stripe_sdk.

=item B<use_stripe_sdk> hash

When confirming a PaymentIntent with Stripe.js, Stripe.js depends on the contents of this dictionary to invoke authentication flows. The shape of the contents is subject to change and is only intended to be used by Stripe.js.

=back

=item B<on_behalf_of> string (expandable)

The account (if any) for which the funds of the PaymentIntent are intended. See the PaymentIntents use case for connected accounts for details.

When expanded, this is a L<Net::API::Stripe::Connect::Account> object.

=item B<payment_method> retrievable with publishable key string (expandable)

ID of the payment method used in this PaymentIntent.

=item B<payment_method_options> hash

Payment-method-specific configuration for this PaymentIntent.

This is a virtual L<Net::API::Stripe::Payment::Method::Options> object, ie a package created on the fly to allow the hash keys to be accessed as methods.

=over 8

=item B<card> hash

If the PaymentIntent’s payment_method_types includes card, this hash contains the configurations that will be applied to each payment attempt of that type.

=back

=item B<payment_method_types> retrievable with publishable key array containing strings

The list of payment method types (e.g. card) that this PaymentIntent is allowed to use.

=item B<receipt_email> retrievable with publishable key string

Email address that the receipt for the resulting payment will be sent to.

=item B<review> string (expandable)

ID of the review associated with this PaymentIntent, if any.

This is a L<Net::API::Stripe::Fraud::Review> object.

=item B<setup_future_usage> retrievable with publishable key string

Indicates that you intend to make future payments with this PaymentIntent’s payment method.

If present, the payment method used with this PaymentIntent can be attached to a Customer, even after the transaction completes.

Use on_session if you intend to only reuse the payment method when your customer is present in your checkout flow. Use off_session if your customer may or may not be in your checkout flow. See Saving card details after a payment to learn more.

Stripe uses setup_future_usage to dynamically optimize your payment flow and comply with regional legislation and network rules. For example, if your customer is impacted by SCA, using off_session will ensure that they are authenticated while processing this PaymentIntent. You will then be able to collect off-session payments for this customer.

=item B<shipping> retrievable with publishable key hash

Shipping information for this PaymentIntent.

This is a L<Net::API::Stripe::Shipping> object.

=item B<source>

This is a L<Net::API::Stripe::Payment::Source>, but it seems it is not documented on the Stripe API although it is found in its response.

=item B<statement_descriptor> string

For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters.

=item B<statement_descriptor_suffix> string

Provides information about a card payment that customers see on their statements. Concatenated with the prefix (shortened descriptor) or statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters for the concatenated descriptor.

=item B<status> retrievable with publishable key string

Status of this PaymentIntent, one of requires_payment_method, requires_confirmation, requires_action, processing, requires_capture, canceled, or succeeded. Read more about each PaymentIntent status.

=item B<transfer_data> hash

The data with which to automatically create a Transfer when the payment is finalized. See the PaymentIntents use case for connected accounts for details.

This is a L<Net::API::Stripe::Payment::Intent::TransferData> object.

=item B<transfer_group> string

A string that identifies the resulting payment as part of a group. See the PaymentIntents use case for connected accounts for details.

=back

=head1 API SAMPLE

	{
	  "id": "pi_fake123456789",
	  "object": "payment_intent",
	  "amount": 1099,
	  "amount_capturable": 0,
	  "amount_received": 0,
	  "application": null,
	  "application_fee_amount": null,
	  "canceled_at": null,
	  "cancellation_reason": null,
	  "capture_method": "automatic",
	  "charges": {
		"object": "list",
		"data": [],
		"has_more": false,
		"url": "/v1/charges?payment_intent=pi_fake123456789"
	  },
	  "client_secret": "pi_fake123456789_secret_nvsnvmsbfmsbfmbfm",
	  "confirmation_method": "automatic",
	  "created": 1556596976,
	  "currency": "jpy",
	  "customer": null,
	  "description": null,
	  "invoice": null,
	  "last_payment_error": null,
	  "livemode": false,
	  "metadata": {},
	  "next_action": null,
	  "on_behalf_of": null,
	  "payment_method": null,
	  "payment_method_options": {},
	  "payment_method_types": [
		"card"
	  ],
	  "receipt_email": null,
	  "review": null,
	  "setup_future_usage": null,
	  "shipping": null,
	  "statement_descriptor": null,
	  "statement_descriptor_suffix": null,
	  "status": "requires_payment_method",
	  "transfer_data": null,
	  "transfer_group": null
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-02-11

allowed_source_types has been renamed to payment_method_types.

=head2 2019-02-11

The next_source_action property on PaymentIntent has been renamed to next_action, and the authorize_with_url within has been renamed to redirect_to_url.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_intents>, L<https://stripe.com/docs/payments/payment-intents/creating-payment-intents>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

