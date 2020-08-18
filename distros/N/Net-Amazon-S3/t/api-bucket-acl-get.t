
use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::API (
    qw[ fixture ],
    qw[ with_response_fixture ],
    qw[ expect_api_bucket_acl_get ],
);

expect_api_bucket_acl_get 'get bucket acl' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('response::acl'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => fixture ('response::acl')->{content},
);

expect_api_bucket_acl_get 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::access_denied'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    throws                  => qr/^Net::Amazon::S3: Amazon responded with 403 Forbidden/i,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '403 Forbidden',
);

expect_api_bucket_acl_get 'with error bucket not found' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

had_no_warnings;
