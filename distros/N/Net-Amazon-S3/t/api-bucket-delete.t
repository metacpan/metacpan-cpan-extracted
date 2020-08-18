
use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::API (
    qw[ with_response_fixture ],
    qw[ expect_api_bucket_delete ],
);

expect_api_bucket_delete 'delete bucket' => (
    with_bucket             => 'some-bucket',
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => bool (1),
);

expect_api_bucket_delete 'error access denied' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::access_denied'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_delete 'error bucket not empty' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::bucket_not_empty'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'BucketNotEmpty',
    expect_s3_errstr        => 'Bucket not empty error message',
);

expect_api_bucket_delete 'error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchBucket',
    expect_s3_errstr        => 'No such bucket error message',
);

had_no_warnings;
