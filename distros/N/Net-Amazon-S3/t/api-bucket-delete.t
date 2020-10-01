
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_bucket_delete ];

plan tests => 6;

expect_api_bucket_delete 'delete bucket' => (
    with_bucket             => 'some-bucket',
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => bool (1),
);

expect_api_bucket_delete 'S3 error - Access Denied' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::access_denied'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_delete 'S3 error - Bucket Not Empty' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::bucket_not_empty'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'BucketNotEmpty',
    expect_s3_errstr        => 'Bucket not empty error message',
);

expect_api_bucket_delete 'S3 error - No Such Bucket' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchBucket',
    expect_s3_errstr        => 'No such bucket error message',
);

expect_api_bucket_delete 'HTTP error - 400 Bad Request' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::http_bad_request'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => bool (0),
    expect_s3_err           => '400',
    expect_s3_errstr        => 'Bad Request',
);

had_no_warnings;

done_testing;
