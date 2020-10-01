
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-client.pl" }

plan tests => 5;

use Shared::Examples::Net::Amazon::S3::Client qw[ expect_client_bucket_objects_delete ];

expect_client_bucket_objects_delete 'delete multiple objects' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    with_response_fixture ('response::bucket_objects_delete_quiet_without_errors'),
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    expect_data             => all (
        obj_isa ('HTTP::Response'),
        methods (is_success => bool (1)),
    ),
    expect_request_content  => <<'XML',
<Delete>
  <Quiet>true</Quiet>
  <Object><Key>key-1</Key></Object>
  <Object><Key>key-2</Key></Object>
</Delete>
XML
);

expect_client_bucket_objects_delete 'S3 error - Access Denied' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    with_response_fixture ('error::access_denied'),
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_bucket_objects_delete 'S3 error - No Such Bucket' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    with_response_fixture ('error::no_such_bucket'),
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    throws                  => qr/^NoSuchBucket: No such bucket error message/,
);

expect_client_bucket_objects_delete 'HTTP error - 400 Bad Request' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    with_response_fixture ('error::http_bad_request'),
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    throws                  => qr/^400: Bad Request/,
);

had_no_warnings;

done_testing;
