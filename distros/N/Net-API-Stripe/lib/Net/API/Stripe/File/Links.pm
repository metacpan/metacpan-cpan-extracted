##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/File/Links.pm
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
package Net::API::Stripe::File::Links;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::List );
    our( $VERSION ) = '0.1';
};

# Inherited
# sub object { shift->_set_get_scalar( 'object', @_ ); }

## Array of Net::API::Stripe::File::Link
# sub data { shift->_set_get_object_array( 'data', 'Net::API::Stripe::File::Link', @_ ); }

# Inherited
# sub has_more { shift->_set_get_scalar( 'has_more', @_ ); }

# Inherited
# sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::File::Links - File Links for Stripe API

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is an object of file links

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

=item B<object> string, value is "list"

String representing the object’s type. Objects of the same type share the same value. Always has the value list.

=item B<data> array of C<Net::API::Stripe::File::Link> objects

=item B<has_more> boolean

True if this list has another page of items after this one that can be fetched.

=item B<url> string

The URL where this list can be accessed.

=back

=head1 API SAMPLE

	{
	  "id": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
	  "object": "file",
	  "created": 1540111053,
	  "filename": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
	  "links": {
		"object": "list",
		"data": [
		  {
			"id": "link_1FUBkBCeyNCl6fY2qHYSz07c",
			"object": "file_link",
			"created": 1571229407,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_hz1kCVcA56eXrmtn7NefMLnz"
		  },
		  {
			"id": "link_1FUAcFCeyNCl6fY271oD9exG",
			"object": "file_link",
			"created": 1571225071,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_8NLJYB8cW3mTdt8HGI4qWyPY"
		  },
		  {
			"id": "link_1FUACkCeyNCl6fY2O4OY3lGf",
			"object": "file_link",
			"created": 1571223490,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_fw15hmJNq7mdGjVXDnCSGa1k"
		  },
		  {
			"id": "link_1FUA14CeyNCl6fY2s3gFUjmP",
			"object": "file_link",
			"created": 1571222766,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_CFGUdKzOySQmE7nnu90OJvFA"
		  },
		  {
			"id": "link_1FU3MDCeyNCl6fY2AO4G1dEB",
			"object": "file_link",
			"created": 1571197169,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_ihRJaSmdENz7UrUYj4n15sxD"
		  },
		  {
			"id": "link_1FTxyCCeyNCl6fY2r4TebpGF",
			"object": "file_link",
			"created": 1571176460,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_HoVMKjGfUBiMD2OS7aDZivWJ"
		  },
		  {
			"id": "link_1FTe4wCeyNCl6fY2aoPS0DOo",
			"object": "file_link",
			"created": 1571099998,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_mGNgt9DXqHEgDtB436aPMo0s"
		  },
		  {
			"id": "link_1E9RjaCeyNCl6fY2WTBMmC1P",
			"object": "file_link",
			"created": 1551509650,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_KjRaNp9SHHgHV1crZbmXNFPS"
		  },
		  {
			"id": "link_1E9RcVCeyNCl6fY2ENfBjqlt",
			"object": "file_link",
			"created": 1551509211,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_hYLTeLBZuBzWgpN9jCkltoMq"
		  },
		  {
			"id": "link_1Dss88CeyNCl6fY21fJ0EdbR",
			"object": "file_link",
			"created": 1547559540,
			"expired": false,
			"expires_at": null,
			"file": "file_1DNcRFCeyNCl6fY2DkDq3nUd",
			"livemode": false,
			"metadata": {},
			"url": "https://files.stripe.com/links/fl_test_EgTRoBg3u2NXbACJp3ZmJhQP"
		  }
		],
		"has_more": true,
		"url": "/v1/file_links?file=file_1DNcRFCeyNCl6fY2DkDq3nUd"
	  },
	  "purpose": "dispute_evidence",
	  "size": 9863,
	  "title": null,
	  "type": "png",
	  "url": "https://files.stripe.com/v1/files/file_1DNcRFCeyNCl6fY2DkDq3nUd/contents"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/files/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

