
use strict;
use warnings;

use Test::More tests => 1 + 4;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::API (
    qw[ expect_api_bucket_acl_set ],
);

use Shared::Examples::Net::Amazon::S3::ACL (
    qw[ acl_xml ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
);

expect_api_bucket_acl_set 'set bucket acl via canned acl header' => (
    with_bucket             => 'some-bucket',
    with_acl_short          => 'private',
    with_response_data      => acl_xml,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_request_content  => '',
    expect_request_headers  => {
        x_amz_acl => 'private',
    },
    expect_data             => bool (1),
);

expect_api_bucket_acl_set 'set bucket acl via xml acl' => (
    with_bucket             => 'some-bucket',
    with_acl_xml            => acl_xml,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_request_content  => acl_xml,
    expect_request_headers  => {
        x_amz_acl => undef,
    },
    expect_data             => bool (1),
);

expect_api_bucket_acl_set 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_acl_short          => 'private',
    fixture_error_access_denied,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_acl_set 'with error bucket not found' => (
    with_bucket             => 'some-bucket',
    with_acl_short          => 'private',
    fixture_error_no_such_bucket,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchBucket',
    expect_s3_errstr        => 'No such bucket error message',
);

