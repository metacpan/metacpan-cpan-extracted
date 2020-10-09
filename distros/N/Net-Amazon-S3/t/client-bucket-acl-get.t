
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-client.pl" }

use Shared::Examples::Net::Amazon::S3::Client qw[ expect_client_bucket_acl_get ];

plan tests => 5;

expect_client_bucket_acl_get 'get bucket acl' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('response::acl'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	expect_data             => fixture ('response::acl')->{content},
);

expect_client_bucket_acl_get 'S3 error - Access Denied' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('error::access_denied'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_bucket_acl_get 'S3 error - Bucket Not Found' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('error::no_such_bucket'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	throws                  => qr/^NoSuchBucket: No such bucket error message/,
);

expect_client_bucket_acl_get 'HTTP error - 400 Bad Request' => (
	with_bucket             => 'some-bucket',
	with_response_fixture ('error::http_bad_request'),
	expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
	throws                  => qr/^400: Bad Request/,
);

had_no_warnings;

done_testing;

