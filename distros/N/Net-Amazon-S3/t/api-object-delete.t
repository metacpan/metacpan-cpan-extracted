
use strict;
use warnings;

use Test::More tests => 1 + 4; # Test::Warnings + our tests
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::API (
    qw[ expect_api_object_delete ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
    qw[ fixture_error_no_such_key ],
);

expect_api_object_delete 'delete object' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => bool (1),
);

expect_api_object_delete 'error access denied' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    fixture_error_access_denied,
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_object_delete 'error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    fixture_error_no_such_bucket,
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchBucket',
    expect_s3_errstr        => 'No such bucket error message',
);

expect_api_object_delete 'error no such key' => (
    with_bucket             => 'some-bucket',
    with_key                => 'some-key',
    fixture_error_no_such_key,
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/some-key' },
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchKey',
    expect_s3_errstr        => 'No such key error message',
);

