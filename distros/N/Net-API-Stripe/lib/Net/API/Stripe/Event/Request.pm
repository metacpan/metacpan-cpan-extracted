##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Event/Request.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Event::Request;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub idempotency_key { return( shift->_set_get_scalar( 'idempotency_key', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Event::Request - A Stripe Event Request object

=head1 SYNOPSIS

    my $req = $stripe->event->request({
        id => 'req_HwlkQJshckjIsj',
        idempotency_key => '677A3112-FBAD-4804-BA61-CEF1CC13D155',
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is a Stripe Event Request object.

This is instantiated by the method B<request> in module L<Net::API::Stripe::Event>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Event::Request> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

ID of the API request that caused the event. If null, the event was automatic (e.g., Stripe’s automatic subscription handling). Request logs are available in the dashboard, but currently not in the API.

=head2 idempotency_key string

The idempotency key transmitted during the request, if any. Note: This property is populated only for events on or after May 23, 2017.

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

L<https://stripe.com/docs/api/events/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
