
use strict;
use warnings;

use Test::More tests => 1 + 2;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'list parts' => (
    request_class       => 'Net::Amazon::S3::Request::ListParts',
    with_bucket         => 'some-bucket',
    with_key            => 'some/key',
    with_upload_id      => '123',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/some/key?uploadId=123',
    expect_request_headers  => { },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'list parts with acl' => (
    request_class       => 'Net::Amazon::S3::Request::ListParts',
    with_bucket         => 'some-bucket',
    with_key            => 'some/key',
    with_upload_id      => '123',
    with_acl_short      => 'private',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/some/key?uploadId=123',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
    expect_request_content  => '',
);

