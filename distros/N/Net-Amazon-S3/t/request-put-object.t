
use strict;
use warnings;

use Test::More tests => 4;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'put object' => (
    request_class   => 'Net::Amazon::S3::Request::PutObject',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_value      => 'foo',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key',
    expect_request_headers  => { },
);

behaves_like_net_amazon_s3_request 'put object with acl' => (
    request_class   => 'Net::Amazon::S3::Request::PutObject',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl_short  => 'private',
    with_value      => 'foo',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

behaves_like_net_amazon_s3_request 'put object with service side encryption' => (
    request_class   => 'Net::Amazon::S3::Request::PutObject',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_encryption => 'AES256',
    with_value      => 'foo',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key',
    expect_request_headers  => { 'x-amz-server-side-encryption' => 'AES256' },
);

had_no_warnings;
