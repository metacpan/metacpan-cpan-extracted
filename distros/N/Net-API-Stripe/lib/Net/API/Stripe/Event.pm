##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Event.pm
## Version v0.101.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/11/16
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
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.101.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub account { return( shift->_set_get_scalar( 'account', @_ ) ); }

sub api_version { return( shift->_set_get_scalar( 'api_version', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub data { return( shift->_set_get_object( 'data', 'Net::API::Stripe::Event::Data', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub pending_webhooks { return( shift->_set_get_scalar( 'pending_webhooks', @_ ) ); }

sub request { return( shift->_set_get_object( 'request', 'Net::API::Stripe::Event::Request', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Event - A Stripe Event Object

=head1 SYNOPSIS

    my $evt = $stripe->event({
        api_version => '2020-03-02',
        data => 
        {
            object => $invoice_object,
        },
        livemode => $stripe->false,
        pending_webhooks => 2,
        request =>
        {
            id => 'req_HwlkQJshckjIsj',
            idempotency_key => '677A3112-FBAD-4804-BA61-CEF1CC13D155',
        },
        type => 'invoice.created',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.101.0

=head1 DESCRIPTION

Events are Stripe's way of letting you know when something interesting happens in your account. When an interesting event occurs, Stripe creates a new Event object. For example, when a charge succeeds, Stripe creates a charge.succeeded event; and when an invoice payment attempt fails, Stripe creates an invoice.payment_failed event. Note that many API requests may cause multiple events to be created. For example, if you create a new subscription for a customer, you will receive both a customer.subscription.created event and a charge.succeeded event.

Events occur when the state of another API resource changes. The state of that resource at the time of the change is embedded in the event's data field. For example, a charge.succeeded event will contain a charge, and an invoice.payment_failed event will contain an invoice.

As with other API resources, you can use endpoints to L<retrieve an individual event|https://stripe.com/docs/api/events#retrieve_event> or a L<list of events|https://stripe.com/docs/api/events#list_events> from the API. Stripe also have a L<separate webhooks  system|http://en.wikipedia.org/wiki/Webhook> for sending the Event objects directly to an endpoint on your server. Webhooks are managed in your L<account settings|https://dashboard.stripe.com/account/webhooks>, and L<Stripe's Using Webhooks|https://stripe.com/docs/webhooks> guide will help you get set up.

When using Connect, you can also receive notifications of events that occur in connected accounts. For these events, there will be an additional account attribute in the received Event object.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Event> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "event"

String representing the object’s type. Objects of the same type share the same value.

=head2 account Connect only string

The connected account that originated the event.

=head2 api_version string

The Stripe API version used to render data. Note: This property is populated only for events on or after October 31, 2014.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 data hash

Object containing data associated with the event. This is an L<Net::API::Stripe::Event::Data> object

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 pending_webhooks positive integer or zero

Number of webhooks that have yet to be successfully delivered (i.e., to return a 20x response) to the URLs you’ve specified.

=head2 request hash

Information on the API request that instigated the event. This is a L<Net::API::Stripe::Event::Request> object.

=head2 type string

Description of the event (e.g., invoice.created or charge.refunded).

=head1 API SAMPLE

    {
      "id": "evt_fake123456789",
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
