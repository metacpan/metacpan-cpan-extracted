##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/PortalSession.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2022/07/10
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::PortalSession;
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

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub configuration { return( shift->_set_get_scalar_or_object( 'configuration', 'Net::API::Stripe::Billing::PortalConfiguration', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub customer { return( shift->_set_get_scalar_or_object( 'customer', 'Net::API::Stripe::Customer', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub locale { return( shift->_set_get_scalar( 'locale', @_ ) ); }

sub on_behalf_of { return( shift->_set_get_scalar_or_object( 'on_behalf_of', 'Net::API::Stripe::Connect::Account', @_ ) ); }

sub return_url { return( shift->_set_get_uri( 'return_url', @_ ) ); }

sub url { return( shift->_set_get_scalar( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::PortalSession - The session object

=head1 SYNOPSIS

    my $portal = $stripe->portal_session({
        created => 'now',
        customer => 'cust_fake123456789',
        livemode => $stripe->false,
        return_url => 'https://example.com/ec/df63685a-6cd2-4c5d-9d4c-81b417646a58',
        url => 'https://billing.stripe.com/session/{SESSION_SECRET}',
    });

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A session describes the instantiation of the customer portal for a particular customer. By visiting the session's URL, the customer can manage their subscriptions and billing details. For security reasons, sessions are short-lived and will expire if the customer does not visit the URL.
Create sessions on-demand when customers intend to manage their subscriptions and billing details.
 Integration guide: [Billing customer portal](/docs/billing/subscriptions/integrating-customer-portal).

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 configuration string

Expandable to L<Net::API::Stripe::Billing::PortalConfiguration>

The configuration used by this session, describing the features available.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 customer string

The ID of the customer for this session.

=head2 livemode boolean

Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.

=head2 locale enum

The IETF language tag of the locale Customer Portal is displayed in (e.g. C<ja> or C<en-GB>. If blank or set to C<auto>, the customer’s C<preferred_locales> or browser’s locale is used.

=head2 on_behalf_of string

Connect only

The L<account|Net::API::Stripe::Connect::Account> for which the session was created on behalf of. When specified, only subscriptions and invoices with this C<on_behalf_of> account appear in the portal. For more information, see the docs. Use the Accounts API to modify the C<on_behalf_of> account’s branding settings, which the portal displays.

=head2 return_url string

The URL to which Stripe should send customers when they click on the link to return to your website.

=head2 url string

The short-lived URL of the session giving customers access to the customer portal.

=head1 API SAMPLE

    {
      "id": "bps_1LK7CQCeyNCl6fY2zTGZOzQa",
      "object": "billing_portal.session",
      "configuration": "bpc_1LK7CQCeyNCl6fY2ESFdGr6O",
      "created": 1657486674,
      "customer": "cus_AODr7KhjWjH7Yk",
      "livemode": true,
      "locale": null,
      "on_behalf_of": null,
      "return_url": "https://example.com/account",
      "url": "https://billing.stripe.com/session/{SESSION_SECRET}"
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api#portal_session_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
