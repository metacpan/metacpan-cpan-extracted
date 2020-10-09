#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-s3-request.pl' }

plan tests => 4;

behaves_like_net_amazon_s3_request 'abort multipart upload with empty parts' => (
	request_class       => 'Net::Amazon::S3::Operation::Object::Upload::Complete::Request',
	with_bucket         => 'some-bucket',
	with_key            => 'some/key',
	with_upload_id      => '123&456',
	with_etags          => [ ],
	with_part_numbers   => [ ],

	expect_request_method   => 'POST',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploadId=123%26456',
	expect_request_headers  => {
		'Content-Length' => ignore,
		'Content-Type' => 'application/xml',
	},
	expect_request_content  => <<'EOXML',
<CompleteMultipartUpload xmlns="http://s3.amazonaws.com/doc/2006-03-01/"></CompleteMultipartUpload>
EOXML
);

behaves_like_net_amazon_s3_request 'abort multipart upload with some parts' => (
	request_class       => 'Net::Amazon::S3::Operation::Object::Upload::Complete::Request',
	with_bucket         => 'some-bucket',
	with_key            => 'some/key',
	with_upload_id      => '123&456',
	with_etags          => [ 'etag01', 'etag02' ],
	with_part_numbers   => [ 1, 2 ],

	expect_request_method   => 'POST',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploadId=123%26456',
	expect_request_headers  => {
		'Content-Length' => ignore,
		'Content-Type' => 'application/xml',
	},
	expect_request_content  => <<'EOXML',
<CompleteMultipartUpload xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<Part>
		<PartNumber>1</PartNumber>
		<ETag>etag01</ETag>
	</Part>
	<Part>
		<PartNumber>2</PartNumber>
		<ETag>etag02</ETag>
	</Part>
</CompleteMultipartUpload>
EOXML
);

behaves_like_net_amazon_s3_request 'abort multipart upload with uneven argument arrays' => (
	request_class       => 'Net::Amazon::S3::Operation::Object::Upload::Complete::Request',
	with_bucket         => 'some-bucket',
	with_key            => 'some/ %/key',
	with_upload_id      => '123&456',
	with_etags          => [ 'etag01', 'etag02' ],
	with_part_numbers   => [ 1, 2, 3 ],

	throws              => re( qr/must have an equally sized list of etags and part numbers/ ),
);

had_no_warnings;

done_testing;
