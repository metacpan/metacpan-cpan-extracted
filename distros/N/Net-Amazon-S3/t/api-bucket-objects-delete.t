
use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::API (
    qw[ with_response_fixture ],
    qw[ expect_api_bucket_objects_delete ],
);

expect_api_bucket_objects_delete 'delete multiple objects' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    with_response_fixture ('response::bucket_objects_delete_quiet_without_errors'),
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    expect_data             => bool (1),
    expect_request_content  => <<'XML',
<Delete>
  <Quiet>true</Quiet>
  <Object><Key>key-1</Key></Object>
  <Object><Key>key-2</Key></Object>
</Delete>
XML
);

expect_api_bucket_objects_delete 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    with_response_fixture ('error::access_denied'),
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    expect_data             => bool (0),
    expect_s3_err           => 'AccessDenied',
    expect_s3_errstr        => 'Access denied error message',
);

expect_api_bucket_objects_delete 'with error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    expect_data             => bool (0),
    expect_s3_err           => 'NoSuchBucket',
    expect_s3_errstr        => 'No such bucket error message',
);

had_no_warnings;
