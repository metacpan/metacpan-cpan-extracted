
use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use HTTP::Status;

use Shared::Examples::Net::Amazon::S3::API (
    qw[ with_response_fixture ],
    qw[ expect_api_object_head ],
);

expect_api_object_head 'head existing object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_code      => HTTP::Status::HTTP_OK,
    with_response_data      => '',
    with_response_headers   => {
        content_length      => 10,
        content_type        => 'text/plain',
        etag                => 'some-key-etag',
        x_amz_metadata_foo  => 'foo-1',
        date                => 'Fri, 09 Sep 2011 23:36:00 GMT',
    },
    expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => {
        content_type            => 'text/plain',
        content_length          => 10,
        etag                    => 'some-key-etag',
        value                   => '',
        date                    => 'Fri, 09 Sep 2011 23:36:00 GMT',
        'x-amz-metadata-foo'    => 'foo-1',
        'content-type'          => 'text/plain',
        'content-length'        => 10,
        'client-date'           => ignore,
    },
);

expect_api_object_head 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::access_denied'),
    throws                  => qr/^Net::Amazon::S3: Amazon responded with 403 Forbidden/i,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '403 Forbidden',
);

expect_api_object_head 'with error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::no_such_bucket'),
    expect_data             => bool (0),
    expect_s3_err           => undef,,
    expect_s3_errstr        => undef,,
);

expect_api_object_head 'with error no such object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { HEAD => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::no_such_key'),
    expect_data             => bool (0),
    expect_s3_err           => undef,,
    expect_s3_errstr        => undef,,
);

had_no_warnings;
