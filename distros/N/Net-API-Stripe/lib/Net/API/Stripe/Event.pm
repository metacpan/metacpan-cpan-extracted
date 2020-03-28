##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Event.pm
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
## https://stripe.com/docs/api/events/object
package Net::API::Stripe::Event;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub api_version { shift->_set_get_scalar( 'api_version', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub data { shift->_set_get_object( 'data', 'Net::API::Stripe::Event::Data', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub pending_webhooks { shift->_set_get_scalar( 'pending_webhooks', @_ ); }

sub request { shift->_set_get_object( 'request', 'Net::API::Stripe::Event::Request', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Event - A Stripe Event Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Events are our way of letting you know when something interesting happens in your account. When an interesting event occurs, we create a new Event object. For example, when a charge succeeds, we create a charge.succeeded event; and when an invoice payment attempt fails, we create an invoice.payment_failed event. Note that many API requests may cause multiple events to be created. For example, if you create a new subscription for a customer, you will receive both a customer.subscription.created event and a charge.succeeded event.

Events occur when the state of another API resource changes. The state of that resource at the time of the change is embedded in the event's data field. For example, a charge.succeeded event will contain a charge, and an invoice.payment_failed event will contain an invoice.

As with other API resources, you can use endpoints to retrieve an individual event (L<https://stripe.com/docs/api/events#retrieve_event>) or a list of events (L<https://stripe.com/docs/api/events#list_events>) from the API. We also have a separate webhooks (L<http://en.wikipedia.org/wiki/Webhook>) system for sending the Event objects directly to an endpoint on your server. Webhooks are managed in your account settings (L<https://dashboard.stripe.com/account/webhooks>), and our Using Webhooks (L<https://stripe.com/docs/webhooks>) guide will help you get set up.

When using Connect, you can also receive notifications of events that occur in connected accounts. For these events, there will be an additional account attribute in the received Event object.

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

=item B<object> string, value is "event"

String representing the object’s type. Objects of the same type share the same value.

=item B<account> Connect only string

The connected account that originated the event.

=item B<api_version> string

The Stripe API version used to render data. Note: This property is populated only for events on or after October 31, 2014.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<data> hash

Object containing data associated with the event. This is an C<Net::API::Stripe::Event::Data> object

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<pending_webhooks> positive integer or zero

Number of webhooks that have yet to be successfully delivered (i.e., to return a 20x response) to the URLs you’ve specified.

=item B<request> hash

Information on the API request that instigated the event. This is a C<Net::API::Stripe::Event::Request> object.

=item B<type> string

Description of the event (e.g., invoice.created or charge.refunded).

=back

=head1 API SAMPLE

	{
	  "id": "evt_1Ccdk1CeyNCl6fY2mTXIaobI",
	  "object": "event",
	  "api_version": "2017-02-14",
	  "created": 1528914645,
	  "data": {
		"object": {
		  "object": "balance",
		  "available": [
			{
			  "currency": "jpy",
			  "amount": 1025751,
			  "source_types": {
				"card": 1025751
			  }
			}
		  ],
		  "connect_reserved": [
			{
			  "currency": "jpy",
			  "amount": 0
			}
		  ],
		  "livemode": false,
		  "pending": [
			{
			  "currency": "jpy",
			  "amount": 0,
			  "source_types": {
				"card": 0
			  }
			}
		  ]
		}
	  },
	  "livemode": false,
	  "pending_webhooks": 0,
	  "request": {
		"id": null,
		"idempotency_key": null
	  },
	  "type": "balance.available"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/events#events>, L<https://stripe.com/docs/api/events/types>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
