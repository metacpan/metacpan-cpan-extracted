
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

plan tests => 10;

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_object_acl_set ];

expect_api_object_acl_set 'set object acl using deprecated acl_short' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl_short          => 'private',
	with_response_fixture ('response::acl'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_request_content  => '',
	expect_request_headers  => {
		x_amz_acl => 'private',
	},
	expect_data             => bool (1),
);

expect_api_object_acl_set 'set object acl using canned acl' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl                => Net::Amazon::S3::ACL::Canned->PRIVATE,
	with_response_fixture ('response::acl'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_request_content  => '',
	expect_request_headers  => {
		x_amz_acl => 'private',
	},
	expect_data             => bool (1),
);

expect_api_object_acl_set 'set object acl using canned acl coerction' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl                => 'private',
	with_response_fixture ('response::acl'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_request_content  => '',
	expect_request_headers  => {
		x_amz_acl => 'private',
	},
	expect_data             => bool (1),
);

expect_api_object_acl_set 'set object acl using explicit acl' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
    with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,
	with_response_fixture ('response::acl'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_request_content  => '',
    expect_request_headers  => {
		x_amz_grant_read    => 'id="123", id="234"',
		x_amz_grant_write   => 'id="345"',
	},
	expect_data             => bool (1),
);

expect_api_object_acl_set 'set object acl using XML content' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl_xml            => 'PASSTHROUGH',
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_request_content  => 'PASSTHROUGH',
	expect_request_headers  => {
		x_amz_acl => undef,
	},
	expect_data             => bool (1),
);

expect_api_object_acl_set 'S3 error - Access Denied' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl                => 'private',
	with_response_fixture ('error::access_denied'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_data             => bool (0),
	expect_s3_err           => 'AccessDenied',
	expect_s3_errstr        => 'Access denied error message',
);

expect_api_object_acl_set 'S3 error - Bucket Not Found' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl                => 'private',
	with_response_fixture ('error::no_such_bucket'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_data             => bool (0),
	expect_s3_err           => 'NoSuchBucket',
	expect_s3_errstr        => 'No such bucket error message',
);

expect_api_object_acl_set 'S3 error - Object Not Found' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl                => 'private',
	with_response_fixture ('error::no_such_key'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_data             => bool (0),
	expect_s3_err           => 'NoSuchKey',
	expect_s3_errstr        => 'No such key error message',
);

expect_api_object_acl_set 'HTTP error - 400 Bad Request' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_acl                => 'private',
	with_response_fixture ('error::http_bad_request'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
	expect_data             => bool (0),
	expect_s3_err           => '400',
	expect_s3_errstr        => 'Bad Request',
);

had_no_warnings;

done_testing;

