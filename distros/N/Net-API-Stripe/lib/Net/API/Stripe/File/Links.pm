##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/File/Links.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::File::Links;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::List );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

# Inherited
# sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

## Array of Net::API::Stripe::File::Link
# sub data { return( shift->_set_get_object_array( 'data', 'Net::API::Stripe::File::Link', @_ ) ); }

# Inherited
# sub has_more { return( shift->_set_get_scalar( 'has_more', @_ ) ); }

# Inherited
# sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::File::Links - File Links for Stripe API

=head1 DESCRIPTION

This module inherits completely from L<Net::API::Stripe::List> and may be removed in the future.

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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/files/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

