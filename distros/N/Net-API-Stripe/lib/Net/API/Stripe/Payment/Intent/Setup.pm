##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Intent/Setup.pm
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
package Net::API::Stripe::Payment::Intent::Setup;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

## setup_intent
sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub application { shift->_set_get_scalar_or_object( 'application', 'Net::API::Stripe::Connect::Account', @_ ); }

sub cancellation_reason { return( shift->_set_get_scalar( 'cancellation_reason', @_ ) ); }

sub client_secret { return( shift->_set_get_scalar( 'client_secret', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub customer { shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ); }

sub description { shift->_set_get_scalar( 'description', @_ ); }

sub last_setup_error { shift->_set_get_object( 'last_setup_error', 'Net::API::Stripe::Error', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub mandate { return( shift->_set_get_scalar_or_object( 'mandate', 'Net::API::Stripe::Mandate', @_ ) ); }

sub metadata { shift->_set_get_hash( 'metadata', @_ ); }

sub next_action { return( shift->_set_get_hash( 'next_action', @_ ) ); }

sub on_behalf_of { return( shift->_set_get_object_variant( 'on_behalf_of', @_ ) ); }

sub payment_method { return( shift->_set_get_scalar_or_object( 'payment_method', 'Net::API::Stripe::Payment::Method', @_ ) ); }

sub payment_method_options { return( shift->_set_get_hash( 'payment_method_options', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

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

=head1 VERSION

    0.1

=head1 DESCRIPTION

A SetupIntent guides you through the process of setting up a customer's payment credentials for future payments. For example, you could use a SetupIntent to set up your customer's card without immediately collecting a payment. Later, you can use PaymentIntents (C<Net::API::Stripe::Payment::Intent> / L<https://stripe.com/docs/api/setup_intents#payment_intents>) to drive the payment flow.

Create a SetupIntent as soon as you're ready to collect your customer's payment credentials. Do not maintain long-lived, unconfirmed SetupIntents as they may no longer be valid. The SetupIntent then transitions through multiple statuses as it guides you through the setup process.

Successful SetupIntents result in payment credentials that are optimized for future payments. For example, cardholders in certain regions may need to be run through Strong Customer Authentication at the time of payment method collection in order to streamline later off-session payments.

By using SetupIntents, you ensure that your customers experience the minimum set of required friction, even as regulations change over time.

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

=item B<id> retrievable with publishable key string

Unique identifier for the object.

=item B<object> retrievable with publishable key string, value is "setup_intent"

String representing the object’s type. Objects of the same type share the same value.

=item B<application> string expandable "application"

ID of the Connect application that created the SetupIntent. This is a string of the account or a C<Net::API::Stripe::Connect::Account> object.

=item B<cancellation_reason> retrievable with publishable key string

Reason for cancellation of this SetupIntent, one of abandoned, requested_by_customer, or duplicate.

=item B<client_secret> retrievable with publishable key string

The client secret of this SetupIntent. Used for client-side retrieval using a publishable key.

The client secret can be used to complete payment setup from your frontend. It should not be stored, logged, embedded in URLs, or exposed to anyone other than the customer. Make sure that you have TLS enabled on any page that includes the client secret.

=item B<created> retrievable with publishable key timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<customer> string (expandable)

ID of the Customer this SetupIntent belongs to, if one exists, or the corresponding C<Net::API::Stripe::Customer> object.

If present, payment methods used with this SetupIntent can only be attached to this Customer, and payment methods attached to other Customers cannot be used with this SetupIntent.

=item B<description> retrievable with publishable key string

An arbitrary string attached to the object. Often useful for displaying to users.

=item B<last_setup_error> retrievable with publishable key hash

The error encountered in the previous SetupIntent confirmation.

This is a C<Net::API::Stripe::Error> object.

=item B<livemode> retrievable with publishable key boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<mandate> string expandable

ID of the multi use Mandate generated by the SetupIntent. When expanded, this is a C<Net::API::Stripe::Mandate> object.

=item B<metadata> hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=item B<next_action> retrievable with publishable key hash

If present, this property tells you what actions you need to take in order for your customer to continue payment setup.

This is a C<Net::API::Stripe::Payment::Intent::NextAction> object with the following properties:

=over 8

=item B<redirect_to_url> hash

Contains instructions for authenticating a payment by redirecting your customer to another page or application.
Show child attributes

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

The account (if any) for which the setup is intended.

=item B<payment_method> retrievable with publishable key string (expandable)

ID of the payment method used with this SetupIntent.

When expanded, this is a C<Net::API::Stripe::Payment::Method> object.

=item B<payment_method_options> hash

Payment-method-specific configuration for this SetupIntent.
Show child attributes

=item B<payment_method_types> retrievable with publishable key array containing strings

The list of payment method types (e.g. card) that this SetupIntent is allowed to set up.

=item B<single_use_mandate> string expandable

ID of the single_use Mandate generated by the SetupIntent. When expanded, this is a C<Net::API::Stripe::Mandate> object.

=item B<status> retrievable with publishable key string

Status of this SetupIntent, one of requires_payment_method, requires_confirmation, requires_action, processing, canceled, or succeeded.

=item B<usage> retrievable with publishable key string

Indicates how the payment method is intended to be used in the future.

Use on_session if you intend to only reuse the payment method when the customer is in your checkout flow. Use off_session if your customer may or may not be in your checkout flow. If not provided, this value defaults to off_session.

=back

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

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
