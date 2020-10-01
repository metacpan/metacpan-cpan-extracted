
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-client.pl" }

plan tests => 6;

use Shared::Examples::Net::Amazon::S3::Client qw[ expect_client_object_delete ];

expect_client_object_delete 'delete object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => bool (1),
);

expect_client_object_delete 'S3 error - Access Denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::access_denied'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_object_delete 'S3 error - No Such Bucket' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    throws                  => qr/^NoSuchBucket: No such bucket error message/,
);

expect_client_object_delete 'S3 error - No Such Key' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::no_such_key'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    throws                  => qr/^NoSuchKey: No such key error message/,
);

expect_client_object_delete 'HTTP error - 400 Bad Request' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_fixture ('error::http_bad_request'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    throws                  => qr/^400: Bad Request/,
);

had_no_warnings;

done_testing;
