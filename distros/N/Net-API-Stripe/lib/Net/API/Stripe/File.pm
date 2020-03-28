##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/File.pm
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
## https://stripe.com/docs/api/files/object
package Net::API::Stripe::File;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub filename { shift->_set_get_scalar( 'filename', @_ ); }

sub links { shift->_set_get_object( 'links', 'Net::API::Stripe::File::Links', @_ ); }

sub purpose { shift->_set_get_scalar( 'purpose', @_ ); }

sub size { shift->_set_get_number( 'size', @_ ); }

sub title { shift->_set_get_scalar( 'title', @_ ); }

sub type { shift->_set_get_scalar( 'type', @_ ); }

sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::File - A file in Stripe API

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is an object representing a file hosted on Stripe's servers. The file may have been uploaded by yourself using the create file request (for example, when uploading dispute evidence) or it may have been created by Stripe (for example, the results of a Sigma scheduled query L<https://stripe.com/docs/api/files#scheduled_queries>).

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

=item B<object> string, value is "file"

String representing the object’s type. Objects of the same type share the same value.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<filename> string

A filename for the file, suitable for saving to a filesystem.

=item B<links> list

This is a C<Net::API::Stripe::File::Links> object.

=item B<purpose> string

The purpose of the file. Possible values are business_icon, business_logo, customer_signature, dispute_evidence, finance_report_run, identity_document, pci_document, sigma_scheduled_query, or tax_document_user_upload.

=item B<size> integer

The size in bytes of the file object.

=item B<title> string

A user friendly title for the document.

=item B<type> string

The type of the file returned (e.g., csv, pdf, jpg, or png).

=item B<url> string

The URL from which the file can be downloaded using your live secret API key.

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

L<https://stripe.com/docs/api/files>, L<https://stripe.com/docs/file-upload>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
