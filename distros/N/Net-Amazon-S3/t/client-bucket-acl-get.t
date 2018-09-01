
use strict;
use warnings;

use Test::More tests => 1 + 3;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ expect_client_bucket_acl_get ],
);

use Shared::Examples::Net::Amazon::S3::ACL (
    qw[ acl_xml ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
);

expect_client_bucket_acl_get 'get bucket acl' => (
    with_bucket             => 'some-bucket',
    with_response_data      => acl_xml,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => acl_xml,
);

expect_client_bucket_acl_get 'get bucket acl with access denied error' => (
    with_bucket             => 'some-bucket',
    fixture_error_access_denied,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_bucket_acl_get 'get bucket acl with bucket not found error' => (
    with_bucket             => 'some-bucket',
    fixture_error_no_such_bucket,
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    throws                  => qr/^NoSuchBucket: No such bucket error message/,
);

