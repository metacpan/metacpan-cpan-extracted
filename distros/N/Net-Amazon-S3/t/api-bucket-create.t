
use strict;
use warnings;

use Test::More tests => 1 + 6;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::API (
    qw[ expect_api_bucket_create ],
);

use Shared::Examples::Net::Amazon::S3::Operation::Bucket::Create (
    qw[ create_bucket_in_ca_central_1_content_xml ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_bucket_already_exists ],
    qw[ fixture_error_invalid_bucket_name ],
);

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
    expect_request_content  => create_bucket_in_ca_central_1_content_xml,
    expect_data             => all (
        obj_isa ('Net::Amazon::S3::Bucket'),
        methods (bucket => 'some-bucket'),
    ),
);

expect_api_bucket_create 'create bucket with acl' => (
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

expect_api_bucket_create 'error access denied' => (
    with_bucket             => 'some-bucket',
    fixture_error_access_denied,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_create 'error bucket already exists' => (
    with_bucket             => 'some-bucket',
    fixture_error_bucket_already_exists,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'BucketAlreadyExists',
    expect_s3_errstr        => 'Bucket already exists error message',
);

expect_api_bucket_create 'error invalid bucket name' => (
    with_bucket             => 'some-bucket',
    fixture_error_invalid_bucket_name,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'InvalidBucketName',
    expect_s3_errstr        => 'Invalid bucket name error message',
);

