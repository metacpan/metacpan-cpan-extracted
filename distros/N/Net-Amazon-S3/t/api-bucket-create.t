
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_bucket_create ];

plan tests => 11;

expect_api_bucket_create 'simple create bucket (default region us-east-1)' => (
    with_bucket             => 'some-bucket',
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => all (
        obj_isa ('Net::Amazon::S3::Bucket'),
        methods (bucket => 'some-bucket'),
    ),
);

expect_api_bucket_create 'create bucket in different region' => (
    with_bucket             => 'some-bucket',
    with_region             => 'ca-central-1',
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => fixture ('request::bucket_create_ca_central_1')->{content},
    expect_data             => all (
        obj_isa ('Net::Amazon::S3::Bucket'),
        methods (bucket => 'some-bucket'),
    ),
);

expect_api_bucket_create 'create bucket with deprecated acl_short' => (
    with_bucket             => 'some-bucket',
    with_acl_short          => 'private',
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_request_headers  => { x_amz_acl => 'private' },
    expect_data             => all (
        obj_isa ('Net::Amazon::S3::Bucket'),
        methods (bucket => 'some-bucket'),
    ),
);

expect_api_bucket_create 'create bucket with canned acl' => (
    with_bucket             => 'some-bucket',
    with_acl                => Net::Amazon::S3::ACL::Canned->PRIVATE,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_request_headers  => { x_amz_acl => 'private' },
    expect_data             => all (
        obj_isa ('Net::Amazon::S3::Bucket'),
        methods (bucket => 'some-bucket'),
    ),
);

expect_api_bucket_create 'create bucket with canned acl coercion' => (
    with_bucket             => 'some-bucket',
    with_acl                => 'private',
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_request_headers  => { x_amz_acl => 'private' },
    expect_data             => all (
        obj_isa ('Net::Amazon::S3::Bucket'),
        methods (bucket => 'some-bucket'),
    ),
);

expect_api_bucket_create 'create bucket with explicit acl' => (
    with_bucket             => 'some-bucket',
    with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,

    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_request_headers  => {
		x_amz_grant_read    => 'id="123", id="234"',
		x_amz_grant_write   => 'id="345"',
	},
    expect_data             => all (
        obj_isa ('Net::Amazon::S3::Bucket'),
        methods (bucket => 'some-bucket'),
    ),
);

expect_api_bucket_create 'S3 error - Access Denied' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::access_denied'),
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_create 'S3 error - Bucket Already Exists' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::bucket_already_exists'),
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'BucketAlreadyExists',
    expect_s3_errstr        => 'Bucket already exists error message',
);

expect_api_bucket_create 'S3 error - Invalid Bucket Name' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::invalid_bucket_name'),
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'InvalidBucketName',
    expect_s3_errstr        => 'Invalid bucket name error message',
);

expect_api_bucket_create 'HTTP error - 400 Bad Request' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::http_bad_request'),
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => bool (0),
    expect_s3_err           => '400',
    expect_s3_errstr        => 'Bad Request',
);

had_no_warnings;

done_testing;
