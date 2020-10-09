
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }
BEGIN { require "$FindBin::Bin/test-helper-s3-api-error-confess.pl" }

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_object_head ];

plan tests => 6;

expect_api_object_head 'head existing object' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_code      => HTTP_OK,
	with_response_data      => '',
	with_response_headers   => {
		content_length      => 10,
		content_type        => 'text/plain',
		etag                => 'some-key-etag',
		x_amz_metadata_foo  => 'foo-1',
		date                => 'Fri, 09 Sep 2011 23:36:00 GMT',
	},
	expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_data             => {
		content_type            => 'text/plain',
		content_length          => 10,
		etag                    => 'some-key-etag',
		value                   => '',
		date                    => 'Fri, 09 Sep 2011 23:36:00 GMT',
		'x-amz-metadata-foo'    => 'foo-1',
		'content-type'          => 'text/plain',
		'content-length'        => 10,
		'client-date'           => ignore,
	},
);

expect_api_object_head 'S3 error - Access Denied' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::access_denied'),
	expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_access_denied,
);

expect_api_object_head 'S3 error - Bucket Not Found' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::no_such_bucket'),
	expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_bucket_not_found,
);

expect_api_object_head 'S3 error - Object Not Found' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::no_such_key'),
	expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_object_not_found,
);

expect_api_object_head 'HTTP error - 400 Bad Request' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::http_bad_request'),
	expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_http_error_bad_request,
);

had_no_warnings;

done_testing;
