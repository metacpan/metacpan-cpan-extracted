
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

plan tests => 6;

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_object_acl_get ];

expect_api_object_acl_get 'get bucket acl' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('response::acl'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    expect_data             => fixture ('response::acl')->{content},
);

expect_api_object_acl_get 'S3 error - Access Denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::access_denied'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    throws                  => qr/^Net::Amazon::S3: Amazon responded with 403 Forbidden/i,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '403 Forbidden',
);

expect_api_object_acl_get 'S3 error - Bucket Not Found' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

expect_api_object_acl_get 'S3 error - Object Not Found' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::no_such_key'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

expect_api_object_acl_get 'HTTP error - 400 Bad Request' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::http_bad_request'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    throws                  => qr/^Net::Amazon::S3: Amazon responded with 400 Bad Request/i,
    expect_data             => bool (0),
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '400 Bad Request',
);

had_no_warnings;
