##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/WebHook/Object.pm
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
package Net::API::Stripe::WebHook::Object;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

## Should be webhook_endpoint
sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub api_version { return( shift->_set_get_scalar( 'api_version', @_ ) ); }

sub application { return( shift->_set_get_scalar( 'application', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

## * to enable all event, other array of event types
sub enabled_events { return( shift->_set_get_array( 'enabled_events', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub secret { return( shift->_set_get_scalar( 'secret', @_ ) ); }

## enabled or disabled
sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::WebHook::Object - An Stripe WebHook Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

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

=item B<object> string, value is "webhook_endpoint"

String representing the object’s type. Objects of the same type share the same value.

=item B<api_version> string

The API version events are rendered as for this webhook endpoint.

=item B<application> string

The ID of the associated Connect application.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<enabled_events> array containing strings

The list of events to enable for this endpoint. You may specify ['*'] to enable all events.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<secret> string

The endpoint’s secret, used to generate webhook signatures. Only returned at creation.

=item B<status> string

The status of the webhook. It can be enabled or disabled.

=item B<url> string

The URL of the webhook endpoint.

=back

=head1 API SAMPLE

	{
	  "id": "we_1DVZbtCeyNCl6fY25k54GtOS",
	  "object": "webhook_endpoint",
	  "api_version": "2017-02-14",
	  "application": null,
	  "created": 1542006805,
	  "enabled_events": [
		"invoice.created",
		"invoice.payment_failed",
		"invoice.payment_succeeded"
	  ],
	  "livemode": false,
	  "status": "enabled",
	  "url": "http://expugno.serveo.net/stripe/invoice"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/webhook_endpoints>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
