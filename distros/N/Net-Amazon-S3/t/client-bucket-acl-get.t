
use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ fixture ],
    qw[ with_response_fixture ],
    qw[ expect_client_bucket_acl_get ],
);

expect_client_bucket_acl_get 'get bucket acl' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('response::acl'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    expect_data             => fixture ('response::acl')->{content},
);

expect_client_bucket_acl_get 'get bucket acl with access denied error' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::access_denied'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_bucket_acl_get 'get bucket acl with bucket not found error' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/?acl' },
    throws                  => qr/^NoSuchBucket: No such bucket error message/,
);

had_no_warnings;
