
use strict;
use warnings;

use Test::More tests => 1 + 4;
use Test::Deep;
use Test::Warnings;

use HTTP::Status;

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ expect_client_object_fetch ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
    qw[ fixture_error_no_such_key ],
);

expect_client_object_fetch 'fetch existing object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_code      => HTTP::Status::HTTP_OK,
    with_response_data      => 'some-value',
    with_response_headers   => {
        content_length      => 10,
        content_type        => 'text/plain',
        etag                => '8c561147ab3ce19bb8e73db4a47cc6ac',
        x_amz_metadata_foo  => 'foo-1',
        date                => 'Fri, 09 Sep 2011 23:36:00 GMT',
    },
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => 'some-value',
);

expect_client_object_fetch 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    fixture_error_access_denied,
    throws                  => qr/^AccessDenied: Access denied error message/i,
);

expect_client_object_fetch 'with error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    fixture_error_no_such_bucket,
    throws                  => qr/^NoSuchBucket: No such bucket error message/i,
);

expect_client_object_fetch 'with error no such object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    fixture_error_no_such_key,
    throws                  => qr/^NoSuchKey: No such key error message/i,
);

