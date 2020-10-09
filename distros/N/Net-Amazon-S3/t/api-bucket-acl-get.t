
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }
BEGIN { require "$FindBin::Bin/test-helper-s3-api-error-confess.pl" }

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_bucket_acl_get ];

plan tests => 5;

expect_api_bucket_acl_get 'get bucket acl' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('response::acl'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	expect_data             => fixture ('response::acl')->{content},
);

expect_api_bucket_acl_get 'S3 error - Access Denied' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('error::access_denied'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	expect_s3_error_access_denied,
);

expect_api_bucket_acl_get 'S3 error - Bucket Not Found' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('error::no_such_bucket'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	expect_s3_error_bucket_not_found,
);

expect_api_bucket_acl_get 'HTTP error - 400 Bad Request' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('error::http_bad_request'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	expect_http_error_bad_request,
);

had_no_warnings;

done_testing;
