##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/WebHook.pm
## Version v0.100.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::WebHook;
BEGIN
{
	use strict;
	use parent qw( Net::API::Stripe::Generic );
	our( $VERSION ) = 'v0.100.0';
};

## Creating a web hook

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::WebHook - An interface to manage and handle Stripe WebHooks

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

Create a webhook:

	curl https://api.stripe.com/v1/webhook_endpoints \
	  -u sk_test_khaffUjkDalUfkLhWD: \
	  -d url="https://example.com/my/webhook/endpoint" \
	  -d "enabled_events[]=charge.failed" \
	  -d "enabled_events[]=charge.succeeded"

See L<Net::API::Stripe::WebHook::Apache> for detail of implementation using Apache with mod_perl and L<Net::API::Stripe::WebHook::Object> for the Stripe WebHook object.

=head1 API SAMPLE

	{
	  "id": "we_fake123456789",
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

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
