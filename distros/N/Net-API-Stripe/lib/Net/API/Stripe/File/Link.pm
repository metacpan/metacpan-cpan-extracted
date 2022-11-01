##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/File/Link.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/file_links/object
package Net::API::Stripe::File::Link;
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

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub expired { return( shift->_set_get_boolean( 'expired', @_ ) ); }

sub expires_at { return( shift->_set_get_datetime( 'expires_at', @_ ) ); }

sub file { return( shift->_set_get_scalar_or_object( 'file', 'Net::API::Stripe::File', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::File::Link - A Stripe File Link Object

=head1 SYNOPSIS

    my $link = $stripe->file_link({
        expires_at => '2020-04-12',
        file => $file_object,
        livemode => $stripe->false,
        metadata => { transaction_id => 123 },
        url => 'https://example.com/some/file.jpg',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is a Stripe File Link object.

To share the contents of a File object with non-Stripe users, you can create a FileLink. FileLinks contain a URL that can be used to retrieve the contents of the file without authentication.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::File::Link> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "file_link"

String representing the object’s type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 expired boolean

Whether this link is already expired.

=head2 expires_at timestamp

Time at which the link expires.

=head2 file string (expandable)

The file object this link points to.

When expanded, this is a L<Net::API::Stripe::File> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 metadata hash

Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.

=head2 url string

The publicly accessible URL to download the file.

=head1 API SAMPLE

    {
      "id": "file_fake123456789",
      "object": "file",
      "created": 1540111053,
      "filename": "file_fake123456789",
      "links": {
        "object": "list",
        "data": [
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1571229407,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1571225071,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1571223490,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_1FUA14CeyNCl6fY2s3gFUjmP",
            "object": "file_link",
            "created": 1571222766,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1571197169,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1571176460,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1571099998,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1551509650,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1551509211,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          },
          {
            "id": "link_fake123456789",
            "object": "file_link",
            "created": 1547559540,
            "expired": false,
            "expires_at": null,
            "file": "file_fake123456789",
            "livemode": false,
            "metadata": {},
            "url": "https://files.stripe.com/links/fl_test_fake123456789"
          }
        ],
        "has_more": true,
        "url": "/v1/file_links?file=file_fake123456789"
      },
      "purpose": "dispute_evidence",
      "size": 9863,
      "title": null,
      "type": "png",
      "url": "https://files.stripe.com/v1/files/file_fake123456789/contents"
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/files/object>, L<https://stripe.com/docs/api/file_links/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
