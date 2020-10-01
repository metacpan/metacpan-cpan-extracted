
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-client.pl" }

plan tests => 6;

use Shared::Examples::Net::Amazon::S3::Client qw[ expect_client_bucket_delete ];

expect_client_bucket_delete 'delete bucket' => (
    with_bucket             => 'some-bucket',
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_data             => bool (1),
);

expect_client_bucket_delete 'S3 error - Access Denied' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::access_denied'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_bucket_delete 'S3 error - Bucket Not Empty' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::bucket_not_empty'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    throws                  => qr/^BucketNotEmpty: Bucket not empty error message/,
);

expect_client_bucket_delete 's3 error - No Such Bucket' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    throws                  => qr/^NoSuchBucket: No such bucket error message/,
);

expect_client_bucket_delete 'HTTP error - 400 Bad Request' => (
    with_bucket             => 'some-bucket',
    with_response_fixture ('error::http_bad_request'),
    expect_request          => { DELETE => 'https://some-bucket.s3.amazonaws.com/' },
    throws                  => qr/^400: Bad Request/,
);

had_no_warnings;

done_testing;
