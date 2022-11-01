##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/WebHook/Object.pm
## Version v0.1.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::WebHook::Object;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

# Should be webhook_endpoint
sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub api_version { return( shift->_set_get_scalar( 'api_version', @_ ) ); }

sub application { return( shift->_set_get_scalar( 'application', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub description { return( shift->_set_get_scalar( 'description', @_ ) ); }

# * to enable all event, other array of event types
sub enabled_events { return( shift->_set_get_array( 'enabled_events', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub secret { return( shift->_set_get_scalar( 'secret', @_ ) ); }

## enabled or disabled
sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::WebHook::Object - An Stripe WebHook Object

=head1 SYNOPSIS

    my $hook = $stripe->webhook({
        api_version => '2020-03-02',
        application => undef,
        enabled_events => ['*'],
        livemode => $stripe->false,
        status => 'enabled',
        url => 'https://api.example.con/stripe/CAC29A87-991E-44AF-8636-888E03082DDF',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a Stripe webhook endpoint object.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::WebHook::Object> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "webhook_endpoint"

String representing the object’s type. Objects of the same type share the same value.

=head2 api_version string

The API version events are rendered as for this webhook endpoint.

=head2 application string

The ID of the associated Connect application.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 description string

An optional description of what the webhook is used for.

=head2 enabled_events array containing strings

The list of events to enable for this endpoint. You may specify ['*'] to enable all events.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of L<key-value pairs|https://stripe.com/docs/api/metadata> that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 secret string

The endpoint’s secret, used to generate webhook signatures. Only returned at creation.

=head2 status string

The status of the webhook. It can be enabled or disabled.

=head2 url string

The URL of the webhook endpoint.

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

L<https://stripe.com/docs/api/webhook_endpoints>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
