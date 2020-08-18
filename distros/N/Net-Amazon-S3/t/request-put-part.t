
use strict;
use warnings;

use Test::More tests => 3;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'put object' => (
    request_class       => 'Net::Amazon::S3::Request::PutPart',
    with_bucket         => 'some-bucket',
    with_key            => 'some/key',
    with_value          => 'foo',
    with_upload_id      => '123',
    with_part_number    => '1',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?partNumber=1&uploadId=123',
    expect_request_headers  => { },
);

behaves_like_net_amazon_s3_request 'put object with acl' => (
    request_class       => 'Net::Amazon::S3::Request::PutPart',
    with_bucket         => 'some-bucket',
    with_key            => 'some/key',
    with_value          => 'foo',
    with_upload_id      => '123',
    with_part_number    => '1',
    with_acl_short      => 'private',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?partNumber=1&uploadId=123',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

had_no_warnings;
