##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Intent/Setup.pm
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
package Net::API::Stripe::Payment::Intent::Setup;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.3.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

# setup_intent

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub application { return( shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub attach_to_self { return( shift->_set_get_boolean( 'attach_to_self', @_ ) ); }

sub cancellation_reason { return( shift->_set_get_scalar( 'cancellation_reason', @_ ) ); }

sub cardholder_name { return( shift->_set_get_scalar( 'cardholder_name', @_ ) ); }

sub client_secret { return( shift->_set_get_scalar( 'client_secret', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

sub flow_directions { return( shift->_set_get_array( 'flow_directions', @_ ) ); }

sub last_setup_error { return( shift->_set_get_object( 'last_setup_error', 'Net::API::Stripe::Error', @_ ) ); }

sub latest_attempt { return( shift->_set_get_scalar_or_object( 'latest_attempt', 'Net::API::Stripe::SetupAttempt', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub mandate { return( shift->_set_get_scalar_or_object( 'mandate', 'Net::API::Stripe::Mandate', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub next_action { return( shift->_set_get_hash( 'next_action', @_ ) ); }

sub on_behalf_of { return( shift->_set_get_object_variant( 'on_behalf_of', @_ ) ); }

sub payment_method { return( shift->_set_get_scalar_or_object( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_options { return( shift->_set_get_object( 'payment_method_options', 'Net::API::Stripe::Payment::Method::Options', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

sub read_method { return( shift->_set_get_scalar( 'read_method', @_ ) ); }

sub review { return( shift->_set_get_scalar_or_object( 'review', '', @_ ) ); }

sub single_use_mandate { return( shift->_set_get_scalar_or_object( 'single_use_mandate', 'Net::API::Stripe::Mandate', @_ ) ); }

## requires_payment_method, requires_confirmation, requires_action, processing, requires_capture, canceled, or succeeded

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub usage { return( shift->_set_get_scalar( 'usage', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Intent::Setup - A Stripe Charge Setup Intent

=head1 SYNOPSIS

    my $setup = $stripe->setup_intent({
        cancellation_reason => undef,
        customer => $customer_object,
        description => 'Preparing for payment',
        mandate => $mandate_object,
        metadata => { transaction_id => 123, customer_id => 456 },
        next_action =>
        {
            redirect_to_url => 
            {
            return_url => 'https://example.com/pay/return',
            url => 'https://example.com/pay/auth',
            },
            type => 'redirect_to_url',
        },
        payment_method => $payment_method_object,
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

A SetupIntent guides you through the process of setting up a customer's payment credentials for future payments. For example, you could use a SetupIntent to set up your customer's card without immediately collecting a payment. Later, you can use PaymentIntents (L<Net::API::Stripe::Payment::Intent> / L<https://stripe.com/docs/api/setup_intents#payment_intents>) to drive the payment flow.

Create a SetupIntent as soon as you're ready to collect your customer's payment credentials. Do not maintain long-lived, unconfirmed SetupIntents as they may no longer be valid. The SetupIntent then transitions through multiple statuses as it guides you through the setup process.

Successful SetupIntents result in payment credentials that are optimized for future payments. For example, cardholders in certain regions may need to be run through Strong Customer Authentication at the time of payment method collection in order to streamline later off-session payments.

By using SetupIntents, you ensure that your customers experience the minimum set of required friction, even as regulations change over time.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Payment::Intent::Setup> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id retrievable with publishable key string

Unique identifier for the object.

=head2 object retrievable with publishable key string, value is "setup_intent"

String representing the object’s type. Objects of the same type share the same value.

=head2 application string expandable "application"

ID of the Connect application that created the SetupIntent. This is a string of the account or a L<Net::API::Stripe::Connect::Account> object.

=head2 attach_to_self boolean

If present, the SetupIntent's payment method will be attached to the in-context Stripe Account.

It can only be used for this Stripe Account’s own money movement flows like InboundTransfer and OutboundTransfers. It cannot be set to true when setting up a PaymentMethod for a Customer, and defaults to false when attaching a PaymentMethod to a Customer.

=head2 cancellation_reason retrievable with publishable key string

Reason for cancellation of this SetupIntent, one of abandoned, requested_by_customer, or duplicate.

=head2 client_secret retrievable with publishable key string

The client secret of this SetupIntent. Used for client-side retrieval using a publishable key.

The client secret can be used to complete payment setup from your frontend. It should not be stored, logged, embedded in URLs, or exposed to anyone other than the customer. Make sure that you have TLS enabled on any page that includes the client secret.

=head2 created retrievable with publishable key timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 customer string (expandable)

ID of the Customer this SetupIntent belongs to, if one exists, or the corresponding L<Net::API::Stripe::Customer> object.

If present, payment methods used with this SetupIntent can only be attached to this Customer, and payment methods attached to other Customers cannot be used with this SetupIntent.

=head2 description retrievable with publishable key string

An arbitrary string attached to the object. Often useful for displaying to users.

=head2 flow_directions array

Indicates the directions of money movement for which this payment method is intended to be used.

Include C<inbound> if you intend to use the payment method as the origin to pull funds from. Include C<outbound> if you intend to use the payment method as the destination to send funds to. You can include both if you intend to use the payment method for both purposes.

=head2 last_setup_error retrievable with publishable key hash

The error encountered in the previous SetupIntent confirmation.

This is a L<Net::API::Stripe::Error> object.

=head2 latest_attempt expandable

The most recent SetupAttempt for this SetupIntent.

When expanded this is an L<Net::API::Stripe::SetupAttempt> object.

=head2 livemode retrievable with publishable key boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 mandate string expandable

ID of the multi use Mandate generated by the SetupIntent. When expanded, this is a L<Net::API::Stripe::Mandate> object.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 next_action retrievable with publishable key hash

If present, this property tells you what actions you need to take in order for your customer to continue payment setup.

This is a L<Net::API::Stripe::Payment::Intent::NextAction> object with the following properties:

=over 4

=item I<redirect_to_url> hash

Contains instructions for authenticating a payment by redirecting your customer to another page or application.

=over 8

=item I<return_url> string

If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.

=item I<url> string

The URL you must redirect your customer to in order to authenticate the payment.

=back

=item I<type> string

Type of the next action to perform, one of redirect_to_url or use_stripe_sdk.

=item I<use_stripe_sdk> hash

When confirming a PaymentIntent with Stripe.js, Stripe.js depends on the contents of this dictionary to invoke authentication flows. The shape of the contents is subject to change and is only intended to be used by Stripe.js.

=back

=head2 on_behalf_of string (expandable)

The account (if any) for which the setup is intended.

=head2 payment_method retrievable with publishable key string (expandable)

ID of the payment method used with this SetupIntent.

When expanded, this is a L<Net::API::Stripe::Payment::Method> object.

=head2 payment_method_options hash

Payment-method-specific configuration for this SetupIntent.

=over 4

=item I<card>

If the PaymentIntent’s payment_method_types includes card, this hash contains the configurations that will be applied to each payment attempt of that type.

=over 8

=item I<installments>

=over 12

=item I<available_plans>

Instalment plans that may be selected for this PaymentIntent.

=over 16

=item I<count>

For fixed_count installment plans, this is the number of installment payments your customer will make to their credit card.

=item I<interval>

For fixed_count installment plans, this is the interval between installment payments your customer will make to their credit card. One of month.

=item I<type>

Type of installment plan, one of fixed_count

=back

=item I<enabled>

Whether Installments are enabled for this PaymentIntent.

=item I<plan>

Instalment plan selected for this PaymentIntent.

=over 16

=item I<count>

For fixed_count installment plans, this is the number of installment payments your customer will make to their credit card.

=item I<interval>

For fixed_count installment plans, this is the interval between installment payments your customer will make to their credit card. One of month.

=item I<type>

Type of installment plan, one of fixed_count.

=back

=back

=item I<request_three_d_secure>

Stripe strongly recommend that you rely on their SCA Engine to automatically prompt your customers for L<authentication based on risk level and other requirements|https://stripe.com/docs/strong-customer-authentication>. However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. Permitted values include: automatic or any. If not provided, defaults to automatic. Read Stripe guide on manually requesting 3D Secure for more information on how this configuration interacts with Radar and Stripe SCA Engine

=back

=back

=head2 payment_method_types retrievable with publishable key array containing strings

The list of payment method types (e.g. card) that this SetupIntent is allowed to set up.

=head2 review scalar or object

ID of the review associated with this PaymentIntent, if any.

When expanded, this is a a L<Net::API::Stripe::Fraud::Review> object

=head2 single_use_mandate string expandable

ID of the single_use Mandate generated by the SetupIntent. When expanded, this is a L<Net::API::Stripe::Mandate> object.

=head2 status retrievable with publishable key string

Status of this SetupIntent, one of requires_payment_method, requires_confirmation, requires_action, processing, canceled, or succeeded.

=head2 usage retrievable with publishable key string

Indicates how the payment method is intended to be used in the future.

Use on_session if you intend to only reuse the payment method when the customer is in your checkout flow. Use off_session if your customer may or may not be in your checkout flow. If not provided, this value defaults to off_session.

=head1 API SAMPLE

    {
      "id": "seti_123456789",
      "object": "setup_intent",
      "application": null,
      "cancellation_reason": null,
      "client_secret": null,
      "created": 123456789,
      "customer": null,
      "description": null,
      "last_setup_error": null,
      "livemode": false,
      "metadata": {
        "user_id": "guest"
      },
      "next_action": null,
      "on_behalf_of": null,
      "payment_method": null,
      "payment_method_options": {},
      "payment_method_types": [
        "card"
      ],
      "status": "requires_payment_method",
      "usage": "off_session"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 STRIPE HISTORY

=head2 2019-12-24

Stripe has added 2 new properties: B<mandate> and B<single_use_mandate>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/setup_intents>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
