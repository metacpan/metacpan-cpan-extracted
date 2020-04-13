##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Payment/Intent/NextAction.pm
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
package Net::API::Stripe::Payment::Intent::NextAction;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

# sub redirect_to_url { shift->_set_get_hash( 'redirect_to_url', @_ ); }
sub redirect_to_url
{
    return( shift->_set_get_class(
    {
    return_url => { type => 'uri' },
    url => { type => 'uri' },
    }, @_ ) );
}

sub type { shift->_set_get_scalar( 'type', @_ ); }

sub use_stripe_sdk { shift->_set_get_hash( 'use_stripe_sdk', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Payment::Intent::NextAction - A Stripe Payment Next Action Object

=head1 SYNOPSIS

    my $next = $stripe->payment_intent->next_action({
        redirect_to_url => 
        {
        return_url => 'https://example.com/pay/return',
        url => 'https://example.com/pay/auth',
        },
        type => 'redirect_to_url',
    });

=head1 VERSION

    0.1

=head1 DESCRIPTION

If present, this property tells you what actions you need to take in order for your customer to fulfill a payment using the provided source.

It used to be NextSourceAction, but the naming changed in Stripe API as of 2019-02-11

This is instantiated by method B<next_action> in module L<Net::API::Stripe::Payment::Intent>

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Payment::Intent::NextAction> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<redirect_to_url> hash

Contains instructions for authenticating a payment by redirecting your customer to another page or application.

This is actually a dynamic class L<Net::API::Stripe::Payment::Intent::NextAction::RedirectToUrl> so the following property can be accessed as methods:

=over 8

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
	  "client_secret": "pi_fake123456789_secret_ksjfjfbsjbfsmbfmf",
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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/payment_intents/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
