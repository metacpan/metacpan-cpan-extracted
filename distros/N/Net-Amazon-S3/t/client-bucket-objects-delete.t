
use strict;
use warnings;

use Test::More tests => 1 + 3;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ expect_client_bucket_objects_delete ],
);

use Shared::Examples::Net::Amazon::S3::Error (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_no_such_bucket ],
);

use Shared::Examples::Net::Amazon::S3::Operation::Bucket::Objects::Delete (
    qw[ fixture_response_quiet_without_errors ],
);

expect_client_bucket_objects_delete 'delete multiple objects' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    fixture_response_quiet_without_errors,
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

expect_client_bucket_objects_delete 'with error access denied' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    fixture_error_access_denied,
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    throws                  => qr/^AccessDenied: Access denied error message/,
);

expect_client_bucket_objects_delete 'with error no such bucket' => (
    with_bucket             => 'some-bucket',
    with_keys               => [qw[ key-1 key-2 ]],
    fixture_error_no_such_bucket,
    expect_request          => { POST => 'https://some-bucket.s3.amazonaws.com/?delete' },
    throws                  => qr/^NoSuchBucket: No such bucket error message/,
);

