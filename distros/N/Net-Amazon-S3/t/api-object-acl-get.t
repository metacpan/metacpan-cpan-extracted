
use strict;
use warnings;

use Test::More tests => 1 + 4;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::API (
    qw[ expect_api_object_acl_get ],
);

use Shared::Examples::Net::Amazon::S3::ACL (
    qw[ acl_xml ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
    qw[ fixture_error_no_such_key ],
);

expect_api_object_acl_get 'get bucket acl' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_data      => acl_xml,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    expect_data             => acl_xml,
);

expect_api_object_acl_get 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    fixture_error_access_denied,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    throws                  => qr/^Net::Amazon::S3: Amazon responded with 403 Forbidden/i,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '403 Forbidden',
);

expect_api_object_acl_get 'with error bucket not found' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    fixture_error_no_such_bucket,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

expect_api_object_acl_get 'with error bucket not found' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    fixture_error_no_such_key,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key?acl' },
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

