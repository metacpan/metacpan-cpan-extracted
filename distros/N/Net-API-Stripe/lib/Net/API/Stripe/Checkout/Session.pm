##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Checkout/Session.pm
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
## https://stripe.com/docs/api/checkout/sessions
package Net::API::Stripe::Checkout::Session;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub billing_address_collection { return( shift->_set_get_scalar( 'billing_address_collection', @_ ) ); }

sub cancel_url { return( shift->_set_get_uri( 'cancel_url', @_ ) ); }

sub client_reference_id { return( shift->_set_get_scalar( 'client_reference_id', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub customer_email { return( shift->_set_get_scalar( 'customer_email', @_ ) ); }

sub display_items { return( shift->_set_get_object_array( 'display_items', 'Net::API::Stripe::Checkout::Item', @_ ) ); }

sub line_items { return( shift->_set_get_object_array( 'line_items', 'Net::API::Stripe::Checkout::Item', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub locale { return( shift->_set_get_scalar( 'locale', @_ ) ); }

## payment, setup, or subscription
sub mode { return( shift->_set_get_scalar( 'mode', @_ ) ); }

sub payment_intent { return( shift->_set_get_scalar_or_object( 'payment_intent', 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_intent_data { return( shift->_set_get_object( 'payment_intent_data', 'Net::API::Stripe::Payment::Intent', @_ ) ); }

sub payment_method_types { return( shift->_set_get_array( 'payment_method_types', @_ ) ); }

sub setup_intent { return( shift->_set_get_scalar_or_object( 'setup_intent', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub setup_intent_data { return( shift->_set_get_object( 'setup_intent_data', 'Net::API::Stripe::Payment::Intent::Setup', @_ ) ); }

sub submit_type { return( shift->_set_get_scalar( 'submit_type', @_ ) ); }

sub subscription { return( shift->_set_get_scalar_or_object( 'subscription', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub subscription_data { return( shift->_set_get_object( 'subscription_data', 'Net::API::Stripe::Billing::Subscription', @_ ) ); }

sub success_url { return( shift->_set_get_uri( 'success_url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Checkout::Session - A Stripe Checkout Session Object

=head1 SYNOPSIS

    my $session = $stripe->session({
        # This easy to implement with Net::API::REST
        cancel_url => 'https://api.example.com/v1/stripe/cancel',
        success_url => 'https://api.example.com/v1/stripe/success',
        client_reference_id => '1F7F749C-D9C9-46EB-B692-986628BD7302',
        customer => $customer_object,
        customer_email => 'john.doe@example.com',
        # Japanese please
        locale => 'ja',
        mode => 'subscription',
        payment_intent => $payment_intent_object,
        submit_type => 'pay',
        subscription => $subscription_object,
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

A Checkout Session represents your customer's session as they pay for one-time purchases or subscriptions through Checkout (L<https://stripe.com/docs/payments/checkout>). Stripe recommends creating a new Session each time your customer attempts to pay.

Once payment is successful, the Checkout Session will contain a reference to the Customer (L<Net::API::Stripe::Customer> / L<https://stripe.com/docs/api/customers>), and either the successful PaymentIntent (L<Net::API::Stripe::Payment::Intent> / L<https://stripe.com/docs/api/payment_intents>) or an active Subscription (L<Net::API::Stripe::Billing::Subscription> / L<https://stripe.com/docs/api/subscriptions>).

You can create a Checkout Session on your server and pass its ID to the client to begin Checkout.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Checkout::Session> object.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object. Used to pass to redirectToCheckout in Stripe.js.

=item B<object> string, value is "checkout.session"

String representing the object’s type. Objects of the same type share the same value.

=item B<billing_address_collection> string

The value (auto or required) for whether Checkout collected the customer’s billing address.

=item B<cancel_url> string

The URL the customer will be directed to if they decide to cancel payment and return to your website.

This is a L<URI> object.

=item B<client_reference_id> string

A unique string to reference the Checkout Session. This can be a customer ID, a cart ID, or similar, and can be used to reconcile the session with your internal systems.

=item B<customer> string (expandable)

The ID of the customer for this session. For Checkout Sessions in payment or subscription mode, Checkout will create a new customer object based on information provided during the session unless an existing customer was provided when the session was created.

When expanded, this is a L<Net::API::Stripe::Customer> object.

=item B<customer_email> string

If provided, this value will be used when the Customer object is created. If not provided, customers will be asked to enter their email address. Use this parameter to prefill customer data if you already have an email on file. To access information about the customer once a session is complete, use the customer field.

=item B<display_items> array of hashes

The line items, plans, or SKUs purchased by the customer.

This is an array of L<Net::API::Stripe::Checkout::Item> objects.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<locale> string

The IETF language tag of the locale Checkout is displayed in. If blank or auto, the browser’s locale is used.

=item B<mode> string

The mode of the Checkout Session, one of payment, setup, or subscription.

=item B<payment_intent> string (expandable)

The ID of the PaymentIntent for Checkout Sessions in payment mode. If it is expanded, it contains a L<Net::API::Stripe::Payment::Intent> object.

=item B<payment_intent_data> object

A subset of parameters to be passed to PaymentIntent creation for Checkout Sessions in payment mode.

This is a L<Net::API::Stripe::Payment::Intent> object and used to create a checkout session.

=item B<payment_method_types> array containing strings

A list of the types of payment methods (e.g. card) this Checkout Session is allowed to accept.

=item B<setup_intent> string (expandable)

The ID of the SetupIntent for Checkout Sessions in setup mode.

When expanded, this is a L<Net::API::Stripe::Payment::Intent> object.

=item B<setup_intent_data> object

A subset of parameters to be passed to SetupIntent creation for Checkout Sessions in setup mode.

This is a L<Net::API::Stripe::Payment::Intent> object and used to create a checkout session.

=item B<submit_type> string

Describes the type of transaction being performed by Checkout in order to customize relevant text on the page, such as the submit button. submit_type can only be specified on Checkout Sessions in payment mode, but not Checkout Sessions in subscription or setup mode. Supported values are auto, book, donate, or pay.

=item B<subscription> string (expandable)

The ID of the subscription for Checkout Sessions in subscription mode. If it is expanded, this is the L<Net::API::Stripe::Billing::Subscription> object.

=item B<subscription_data> object

A subset of parameters to be passed to subscription creation for Checkout Sessions in subscription mode.

This is a L<Net::API::Stripe::Billing::Subscription> object and used to create a checkout session.

=item B<success_url> string

The URL the customer will be directed to after the payment or subscription creation is successful.

=back

=head1 API SAMPLE

	{
	  "id": "cs_test_ksjfkjfkljslfkjlfkflsfklskflskflskfs",
	  "object": "checkout.session",
	  "billing_address_collection": null,
	  "cancel_url": "https://example.com/cancel",
	  "client_reference_id": null,
	  "customer": null,
	  "customer_email": null,
	  "display_items": [
		{
		  "amount": 1500,
		  "currency": "usd",
		  "custom": {
			"description": "Comfortable cotton t-shirt",
			"images": null,
			"name": "T-shirt"
		  },
		  "quantity": 2,
		  "type": "custom"
		}
	  ],
	  "livemode": false,
	  "locale": null,
	  "mode": null,
	  "payment_intent": "pi_fake123456789",
	  "payment_method_types": [
		"card"
	  ],
	  "setup_intent": null,
	  "submit_type": null,
	  "subscription": null,
	  "success_url": "https://example.com/success"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/checkout/sessions>, L<https://stripe.com/docs/payments/checkout/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

