
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

plan tests => 7;

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_object_fetch ];

expect_api_object_fetch 'fetch existing object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_response_code      => HTTP_OK,
    with_response_data      => 'some-value',
    with_response_headers   => {
        content_length      => 10,
        content_type        => 'text/plain',
        etag                => 'some-key-etag',
        x_amz_metadata_foo  => 'foo-1',
        date                => 'Fri, 09 Sep 2011 23:36:00 GMT',
    },
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => {
        content_type            => 'text/plain',
        content_length          => 10,
        etag                    => 'some-key-etag',
        value                   => 'some-value',
        date                    => 'Fri, 09 Sep 2011 23:36:00 GMT',
        'x-amz-metadata-foo'    => 'foo-1',
        'content-type'          => 'text/plain',
        'content-length'        => 10,
        'client-date'           => ignore,
    },
);

expect_api_object_fetch 'S3 error - Access Denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::access_denied'),
    throws                  => qr/^Net::Amazon::S3: Amazon responded with 403 Forbidden/i,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '403 Forbidden',
);

expect_api_object_fetch 'S3 error - No Such Bucket' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::no_such_bucket'),
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

expect_api_object_fetch 'S3 error - No Such Object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::no_such_key'),
    expect_data             => undef,
    expect_s3_err           => undef,
    expect_s3_errstr        => undef,
);

expect_api_object_fetch 'S3 error - Invalid Object State (object archived in glacier)' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::invalid_object_state'),
	throws                  => qr/Net::Amazon::S3: Amazon responded with 403 Forbidden/,
    expect_data             => undef,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '403 Forbidden',
);

expect_api_object_fetch 'HTTP error - 400 Bad Request' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { GET => 'https://some-bucket.s3.amazonaws.com/some-key' },
    with_response_fixture ('error::http_bad_request'),
	throws                  => qr/Net::Amazon::S3: Amazon responded with 400 Bad Request/,
    expect_data             => undef,
    expect_s3_err           => 'network_error',
    expect_s3_errstr        => '400 Bad Request',
);


had_no_warnings;
