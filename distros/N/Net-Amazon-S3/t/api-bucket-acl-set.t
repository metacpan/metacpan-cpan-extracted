
use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::API (
    qw[ with_response_fixture ],
    qw[ expect_api_bucket_acl_set ],
);

expect_api_bucket_acl_set 'set bucket acl via canned acl header' => (
    with_bucket             => 'some-bucket',
    with_acl_short          => 'private',
    with_response_fixture ('response::acl'),
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_request_content  => '',
    expect_request_headers  => {
        x_amz_acl => 'private',
    },
    expect_data             => bool (1),
);

expect_api_bucket_acl_set 'set bucket acl via xml acl' => (
    with_bucket             => 'some-bucket',
    with_acl_xml            => 'PASSTHROUGH',
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_request_content  => 'PASSTHROUGH',
    expect_request_headers  => {
        x_amz_acl => undef,
    },
    expect_data             => bool (1),
);

expect_api_bucket_acl_set 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_acl_short          => 'private',
    with_response_fixture ('error::access_denied'),
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_acl_set 'with error bucket not found' => (
    with_bucket             => 'some-bucket',
    with_acl_short          => 'private',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchBucket',
    expect_s3_errstr        => 'No such bucket error message',
);

had_no_warnings;
