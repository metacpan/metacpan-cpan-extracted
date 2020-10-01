#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-s3-request.pl" }

plan tests => 8;

behaves_like_net_amazon_s3_request 'initiate multipart upload' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Upload::Create::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',

    expect_request_method   => 'POST',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploads',
    expect_request_headers  => { },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'initiate multipart upload with deprecated acl_short' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Upload::Create::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl_short  => 'private',

    expect_request_method   => 'POST',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploads',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'initiate multipart upload with canned ACL' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Upload::Create::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl        => Net::Amazon::S3::ACL::Canned->PRIVATE,

    expect_request_method   => 'POST',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploads',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'initiate multipart upload with canned ACL coercion' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Upload::Create::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl        => 'private',

    expect_request_method   => 'POST',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploads',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'initiate multipart upload with explicit ACL' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Upload::Create::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,

    expect_request_method   => 'POST',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploads',
    expect_request_headers  => {
		'x-amz-grant-read'  => 'id="123", id="234"',
		'x-amz-grant-write' => 'id="345"',
	},
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'initiate multipart upload with service side encryption' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Upload::Create::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_encryption => 'AES256',

    expect_request_method   => 'POST',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?uploads',
    expect_request_headers  => { 'x-amz-server-side-encryption' => 'AES256' },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'initiate multipart upload with headers' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Upload::Create::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_headers    => { 'x-amz-meta-test' => 99 },

    expect_request_method   => 'POST',
    expect_request_path     => 'some-bucket/some/key?uploads',
    expect_request_headers  => { 'x-amz-meta-test' => 99 },
    expect_request_content  => '',
);

had_no_warnings;

done_testing;

