
use strict;
use warnings;

use Test::More tests => 1 + 4;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ expect_client_object_create ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
);

expect_client_object_create 'create object from scalar value' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_value              => 'some value',
    with_response_headers   => { etag => '5946210c9e93ae37891dfe96c3e39614' },
    expect_data             => '',
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_request_content  => 'some value',
    expect_request_headers  => {
        content_length => 10,
        content_md5 => 'WUYhDJ6TrjeJHf6Ww+OWFA==',
        expires => undef,
    },
);

expect_client_object_create 'create object with headers recognized by Client::Bucket' => (
    with_bucket                 => 'some-bucket',
    with_key                    => 'some-key',
    with_value                  => 'some value',
    with_response_headers       => { etag => '5946210c9e93ae37891dfe96c3e39614' },
    with_cache_control          => 'private',
    with_content_disposition    => 'inline',
    with_content_encoding       => 'identity',
    with_content_type           => 'text/plain',
    with_expires                => DateTime->new(
        year        => 2011,
        month       => 9,
        day         => 9,
        hour        => 23,
        minute      => 36,
        time_zone   => 'UTC',
    ),
    with_storage_class          => 'reduced_redundancy',
    with_user_metadata          => { Foo => 1, Bar => 2 },
    expect_data                 => '',
    expect_request              => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_request_content      => 'some value',
    expect_request_headers      => {
        cache_control       => 'private',
        content_disposition => 'inline',
        content_encoding    => 'identity',
        content_length      => 10,
        content_type        => 'text/plain',
        content_md5         => 'WUYhDJ6TrjeJHf6Ww+OWFA==',
        expires             => 'Fri, 09 Sep 2011 23:36:00 GMT',
        x_amz_meta_bar      => 2,
        x_amz_meta_foo      => 1,
        x_amz_storage_class => 'REDUCED_REDUNDANCY',
    },
);

expect_client_object_create 'error access denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_value              => 'some value',
    fixture_error_access_denied,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
    throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_object_create 'error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    with_value              => 'some value',
    fixture_error_no_such_bucket,
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => bool (0),
    throws                  => qr/^NoSuchBucket: No such bucket error message/,
);
