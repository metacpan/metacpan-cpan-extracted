
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-client.pl" }

use Shared::Examples::Net::Amazon::S3::Client qw[ expect_client_object_fetch ];

plan tests => 7;

expect_client_object_fetch 'fetch existing object' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_code      => HTTP::Status::HTTP_OK,
	with_response_data      => 'some-value',
	with_response_headers   => {
		content_length      => 10,
		content_type        => 'text/plain',
		etag                => '8c561147ab3ce19bb8e73db4a47cc6ac',
		x_amz_metadata_foo  => 'foo-1',
		date                => 'Fri, 09 Sep 2011 23:36:00 GMT',
	},
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_data             => 'some-value',
);

expect_client_object_fetch 'fetch range of existing object' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_range              => 'bytes=1024-10240',
	with_response_code      => HTTP::Status::HTTP_OK,
	with_response_data      => 'some-value',
	with_response_headers   => {
		content_length      => 10,
		content_type        => 'text/plain',
		etag                => '8c561147ab3ce19bb8e73db4a47cc6ac',
		x_amz_metadata_foo  => 'foo-1',
		date                => 'Fri, 09 Sep 2011 23:36:00 GMT',
	},
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_headers  => {
		range               => 'bytes=1024-10240',
	},
	expect_data             => 'some-value',
);

expect_client_object_fetch 'S3 error - Access Denied' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::access_denied'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_access_denied,
);

expect_client_object_fetch 'S3 error - No Such Bucket' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::no_such_bucket'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_bucket_not_found,
);

expect_client_object_fetch 'S3 error - No Such Object' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::no_such_key'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_object_not_found,
);

expect_client_object_fetch 'HTTP error - 400 Bad Request' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_response_fixture ('error::http_bad_request'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_http_error_bad_request,
);

had_no_warnings;

done_testing;
