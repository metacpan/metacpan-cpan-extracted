##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/WebHook.pm
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
package Net::API::Stripe::WebHook;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = '0.1';
};

## Creating a web hook

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::WebHook - An interface to manage and handle Stripe WebHooks

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

Create a webhook:

	curl https://api.stripe.com/v1/webhook_endpoints \
	  -u sk_test_de3cHLEOsYm4zjiWQZBlYXyU: \
	  -d url="https://example.com/my/webhook/endpoint" \
	  -d "enabled_events[]=charge.failed" \
	  -d "enabled_events[]=charge.succeeded"

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

=item

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

L<https://stripe.com/docs/api/webhook_endpoints>,
L<https://stripe.com/docs/webhooks/configure>,
L<https://stripe.com/docs/api/events/types>,
L<https://stripe.com/docs/api/webhook_endpoints/list?lang=curl>,
L<https://stripe.com/docs/webhooks/signatures>,
L<https://stripe.com/docs/webhooks/best-practices#event-handling>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
