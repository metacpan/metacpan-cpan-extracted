
use strict;
use warnings;

use Test::More tests => 1 + 3;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::API (
    qw[ expect_api_bucket_acl_get ],
);

use Shared::Examples::Net::Amazon::S3::ACL (
    qw[ acl_xml ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
);

expect_api_bucket_acl_get 'get bucket acl' => (
    with_bucket             => 'some-bucket',
    with_response_data      => acl_xml,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => acl_xml,
);

expect_api_bucket_acl_get 'with error access denied' => (
    with_bucket             => 'some-bucket',
    fixture_error_access_denied,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    throws                  => qr/^Net::Amazon::S3: Amazon responded with 403 Forbidden/i,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '403 Forbidden',
);

expect_api_bucket_acl_get 'with error bucket not found' => (
    with_bucket             => 'some-bucket',
    fixture_error_no_such_bucket,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

