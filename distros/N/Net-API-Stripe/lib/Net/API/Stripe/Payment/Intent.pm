##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Intent.pm
## Version v0.102.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/10/29
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
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.102.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

## 2019-02-11
## Stripe: allowed_source_types has been renamed to payment_method_types.
## sub allowed_source_types { return( shift->_set_get_scalar( 'allowed_source_types', @_ ) ); }

sub allowed_source_types { return( shift->payment_method_types( @_ ) ); }

sub amount { return( shift->_set_get_number( 'amount', @_ ) ); }

sub amount_capturable { return( shift->_set_get_number( 'amount_capturable', @_ ) ); }

sub amount_details { return( shift->_set_get_class( 'amount_details',
{
  tip => {
           package => "Net::API::Stripe::Balance::ConnectReserved",
           type => "object",
         },
}, @_ ) ); }

sub amount_received { return( shift->_set_get_number( 'amount_received', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub application_fee_amount { return( shift->_set_get_number( 'application_fee_amount', @_ ) ); }

## 2019-02-11
## Stripe: authorize_with_url within has been renamed to redirect_to_url.

sub authorize_with_url { return( shift->redirect_to_url( @_ ) ); }

sub automatic_payment_methods { return( shift->_set_get_object( 'automatic_payment_methods', 'Net::API::Stripe::Payment::Installment', @_ ) ); }

sub canceled_at { return( shift->_set_get_datetime( 'canceled_at', @_ ) ); }

sub cancellation_reason { return( shift->_set_get_scalar( 'cancellation_reason', @_ ) ); }

sub capture_method { return( shift->_set_get_scalar( 'capture_method', @_ ) ); }

sub charges { return( shift->_set_get_object( 'charges', 'Net::API::Stripe::Payment::Intent::Charges', @_ ) ); }

sub client_secret { return( shift->_set_get_scalar( 'client_secret', @_ ) ); }

sub confirmation_method { return( shift->_set_get_scalar( 'confirmation_method', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub currency { return( shift->_set_get_scalar( 'currency', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub invoice { return( shift->_set_get_scalar_or_object( 'invoice', 'Net::API::Stripe::Billing::Invoice', @_ ) ); }

sub last_payment_error { return( shift->_set_get_object( 'last_payment_error', 'Net::API::Stripe::Error', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub next_action { return( shift->_set_get_object( 'next_action', 'Net::API::Stripe::Payment::Intent::NextAction', @_ ) ); }

# 2019-02-11
# Stripe: The next_source_action property on PaymentIntent has been renamed to next_action
# sub next_source_action { shift->_set_get_scalar( 'next_source_action', @_ ); }

sub next_source_action { return( shift->next_action( @_ ) ); }

sub on_behalf_of { return( shift->_set_get_scalar_or_object( 'on_behalf_of', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub payment_method { return( shift->_set_get_scalar_or_object( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_options { return( shift->_set_get_object( 'payment_method_options', 'Net::API::Stripe::Payment::Method::Options', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

sub processing { return( shift->_set_get_object( 'processing', 'Net::API::Stripe::Issuing::Authorization::Transaction', @_ ) ); }

sub receipt_email { return( shift->_set_get_scalar( 'receipt_email', @_ ) ); }

sub return_url { return( shift->_set_get_uri( 'return_url', @_ ) ); }

sub review { return( shift->_set_get_scalar_or_object( 'review', 'Net::API::Stripe::Fraud::Review', @_ ) ); }

sub setup_future_usage { return( shift->_set_get_scalar( 'setup_future_usage', @_ ) ); }

sub shipping { return( shift->_set_get_object( 'shipping', 'Net::API::Stripe::Shipping', @_ ) ); }

sub source { return( shift->_set_get_scalar_or_object( 'source', 'Net::API::Stripe::Payment::Source', @_ ) ); }

sub statement_descriptor { return( shift->_set_get_scalar( 'statement_descriptor', @_ ) ); }

sub statement_descriptor_suffix { return( shift->_set_get_scalar( 'statement_descriptor_suffix', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub transfer_data { return( shift->_set_get_object( 'transfer_data', 'Net::API::Stripe::Connect::Transfer', @_ ) ); }

sub transfer_group { return( shift->_set_get_scalar( 'transfer_group', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::PaymentIntent - The PaymentIntent object

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

    v0.102.0

=head1 DESCRIPTION

A PaymentIntent guides you through the process of collecting a payment from your customer.
We recommend that you create exactly one PaymentIntent for each order or customer session in your system. You can reference the PaymentIntent later to see the history of payment attempts for a particular session.
A PaymentIntent transitions through L<multiple statuses|https://stripe.com/docs/payments/intents#intent-statuses> throughout its lifetime as it interfaces with Stripe.js to perform authentication flows and ultimately creates at most one successful charge.

Related guide: L<Payment Intents API|https://stripe.com/docs/payments/payment-intents>.

Creating payments takes five steps:

=over 4

=item 1. Create a PaymentIntent on the server

=item 2. Pass the PaymentIntent’s client secret to the client

=item 3. Collect payment method details on the client

=item 4. Submit the payment to Stripe from the client

=item 5. Asynchronously fulfill the customer’s order

=back

More info here: L<https://stripe.com/docs/payments/payment-intents/web>

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 amount integer

Amount intended to be collected by this PaymentIntent. A positive integer representing how much to charge in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal> (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or L<equivalent in charge currency|https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts>. The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).

=head2 amount_capturable integer

Amount that can be captured from this PaymentIntent.

=head2 amount_details hash

Details about items included in the amount

It has the following properties:

=over 4

=item C<tip> hash

Details about the tip.

When expanded, this is a L<Net::API::Stripe::Balance::ConnectReserved> object.

=back

=head2 amount_received integer

Amount that was collected by this PaymentIntent.

=head2 application expandable

ID of the Connect application that created the PaymentIntent.

When expanded this is an L<Net::API::Stripe::Connect::Account> object.

=head2 application_fee_amount integer

The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account. The amount of the application fee collected will be capped at the total payment amount. For more information, see the PaymentIntents L<use case for connected accounts|https://stripe.com/docs/payments/connected-accounts>.

=head2 automatic_payment_methods object

Settings to configure compatible payment methods from the L<Stripe Dashboard|https://dashboard.stripe.com/settings/payment_methods>

This is a L<Net::API::Stripe::Payment::Installment> object.

=head2 canceled_at timestamp

Populated when C<status> is C<canceled>, this is the time at which the PaymentIntent was canceled. Measured in seconds since the Unix epoch.

=head2 cancellation_reason string

Reason for cancellation of this PaymentIntent, either user-provided (C<duplicate>, C<fraudulent>, C<requested_by_customer>, or C<abandoned>) or generated by Stripe internally (C<failed_invoice>, C<void_invoice>, or C<automatic>).

=head2 capture_method string

Controls when the funds will be captured from the customer's account.

=head2 charges object

Charges that were created by this PaymentIntent, if any.

This is a L<Net::API::Stripe::List> object.

=head2 client_secret string

The client secret of this PaymentIntent. Used for client-side retrieval using a publishable key. 

The client secret can be used to complete a payment from your frontend. It should not be stored, logged, embedded in URLs, or exposed to anyone other than the customer. Make sure that you have TLS enabled on any page that includes the client secret.

Refer to our docs to L<accept a payment|https://stripe.com/docs/payments/accept-a-payment?integration=elements> and learn about how C<client_secret> should be handled.

=head2 confirmation_method string

Possible enum values

=over 4

=item I<automatic>

(Default) PaymentIntent can be confirmed using a publishable key. After next_actions are handled, no additional confirmation is required to complete the payment.

=item I<manual>

All payment attempts must be made using a secret key. The PaymentIntent returns to the requires_confirmation state after handling next_actions, and requires your server to initiate each payment attempt with an explicit confirmation.

=back

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 currency currency

Three-letter L<ISO currency code|https://www.iso.org/iso-4217-currency-codes.html>, in lowercase. Must be a L<supported currency|https://stripe.com/docs/currencies>.

=head2 customer expandable

ID of the Customer this PaymentIntent belongs to, if one exists.

Payment methods attached to other Customers cannot be used with this PaymentIntent.

If present in combination with L<setup_future_usage|https://stripe.com#payment_intent_object-setup_future_usage>, this PaymentIntent's payment method will be attached to the Customer after the PaymentIntent has been confirmed and any required actions from the user are complete.

When expanded this is an L<Net::API::Stripe::Customer> object.

=head2 description string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 invoice expandable

ID of the invoice that created this PaymentIntent, if it exists.

When expanded this is an L<Net::API::Stripe::Billing::Invoice> object.

=head2 last_payment_error hash

The payment error encountered in the previous PaymentIntent confirmation. It will be cleared if the PaymentIntent is later updated for any reason.

This is a L<Net::API::Stripe::Error> object.

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format. For more information, see the L<documentation|https://stripe.com/docs/payments/payment-intents/creating-payment-intents#storing-information-in-metadata>.

=head2 next_action object

If present, this property tells you what actions you need to take in order for your customer to fulfill a payment using the provided source.

This is a L<Net::API::Stripe::Payment::Intent::NextAction> object.

=head2 on_behalf_of expandable

The account (if any) for which the funds of the PaymentIntent are intended. See the PaymentIntents L<use case for connected accounts|https://stripe.com/docs/payments/connected-accounts> for details.

When expanded this is an L<Net::API::Stripe::Connect::Account> object.

=head2 payment_method expandable

ID of the payment method used in this PaymentIntent.

When expanded this is an L<Net::API::Stripe::Payment::Method> object.

=head2 payment_method_options object

Payment-method-specific configuration for this PaymentIntent.

This is a L<Net::API::Stripe::Payment::Method> object.

=head2 payment_method_types array of string

The list of payment method types (e.g. card) that this PaymentIntent is allowed to use.

=head2 processing object

If present, this property tells you about the processing state of the payment.

This is a L<Net::API::Stripe::Issuing::Authorization::Transaction> object.

=head2 receipt_email string

Email address that the receipt for the resulting payment will be sent to. If C<receipt_email> is specified for a payment in live mode, a receipt will be sent regardless of your L<email settings|https://dashboard.stripe.com/account/emails>.

=head2 review expandable

ID of the review associated with this PaymentIntent, if any.

When expanded this is an L<Net::API::Stripe::Fraud::Review> object.

=head2 setup_future_usage string

Indicates that you intend to make future payments with this PaymentIntent's payment method.

Providing this parameter will L<attach the payment method|https://stripe.com/docs/payments/save-during-payment> to the PaymentIntent's Customer, if present, after the PaymentIntent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be L<attached|https://stripe.com/docs/api/payment_methods/attach> to a Customer after the transaction completes.

When processing card payments, Stripe also uses C<setup_future_usage> to dynamically optimize your payment flow and comply with regional legislation and network rules, such as L<SCA|https://stripe.com/docs/strong-customer-authentication>.

=head2 shipping object

Shipping information for this PaymentIntent.

This is a L<Net::API::Stripe::Shipping> object.

=head2 source

This is a L<Net::API::Stripe::Payment::Source>, but it seems it is not documented on the Stripe API although it is found in its response.

=head2 statement_descriptor string

For non-card charges, you can use this value as the complete description that appears on your customers’ statements. Must contain at least one letter, maximum 22 characters.

=head2 statement_descriptor_suffix string

Provides information about a card payment that customers see on their statements. Concatenated with the prefix (shortened descriptor) or statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters for the concatenated descriptor.

=head2 status string

Status of this PaymentIntent, one of C<requires_payment_method>, C<requires_confirmation>, C<requires_action>, C<processing>, C<requires_capture>, C<canceled>, or C<succeeded>. Read more about each PaymentIntent L<status|https://stripe.com/docs/payments/intents#intent-statuses>.

=head2 transfer_data object

The data with which to automatically create a Transfer when the payment is finalized. See the PaymentIntents L<use case for connected accounts|https://stripe.com/docs/payments/connected-accounts> for details.

This is a L<Net::API::Stripe::Connect::Transfer> object.

It uses the following methods:

=over 4

=item I<amount> integer

Amount intended to be collected by this PaymentIntent. A positive integer representing how much to charge in the L<smallest currency unit|https://stripe.com/docs/currencies#zero-decimal> (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or L<equivalent in charge currency|https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts>. The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).

=item I<destination> string expandable

The account (if any) the payment will be attributed to for tax reporting, and where funds from the payment will be transferred to upon
payment success.

When expanded this is an L<Net::API::Stripe::Connect::Account> object.

=back

=head2 transfer_group string

A string that identifies the resulting payment as part of a group. See the PaymentIntents L<use case for connected accounts|https://stripe.com/docs/payments/connected-accounts> for details.

=head1 API SAMPLE

    {
      "id": "pi_1Dik5W2eZvKYlo2CDeNJH1A5",
      "object": "payment_intent",
      "amount": 1999,
      "amount_capturable": 0,
      "amount_received": 0,
      "application": null,
      "application_fee_amount": null,
      "canceled_at": null,
      "cancellation_reason": null,
      "capture_method": "automatic",
      "charges": {
        "object": "list",
        "data": [
        ],
        "has_more": false,
        "url": "/v1/charges?payment_intent=pi_1Dik5W2eZvKYlo2CDeNJH1A5"
      },
      "client_secret": "pi_1Dik5W2eZvKYlo2CDeNJH1A5_secret_YsxmIGlVxOrzmONrMv6KzeqGS",
      "confirmation_method": "automatic",
      "created": 1545145346,
      "currency": "gbp",
      "customer": null,
      "description": null,
      "invoice": null,
      "last_payment_error": null,
      "livemode": false,
      "metadata": {
      },
      "next_action": null,
      "on_behalf_of": null,
      "payment_method": null,
      "payment_method_options": {
      },
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

=head2 v0.1.0

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
