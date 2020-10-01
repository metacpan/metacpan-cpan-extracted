#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-s3-request.pl' }

plan tests => 8;

behaves_like_net_amazon_s3_request 'set object access control with (deprecated) acl_short' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl_short  => 'private',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?acl',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

behaves_like_net_amazon_s3_request 'set object access control with canned acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl        => Net::Amazon::S3::ACL::Canned->PRIVATE,

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?acl',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

behaves_like_net_amazon_s3_request 'set object access control with canned acl coercion' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl        => 'private',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?acl',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

behaves_like_net_amazon_s3_request 'set object access control with explicit acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?acl',
    expect_request_headers  => {
		'x-amz-grant-read'  => 'id="123", id="234"',
		'x-amz-grant-write' => 'id="345"',
	},
);

behaves_like_net_amazon_s3_request 'set object access control with body acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl_xml    => 'private',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?acl',
    expect_request_headers  => { },
);

behaves_like_net_amazon_s3_request 'set object access control without body or header acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',

    throws          => re( qr/need either acl_xml or acl/ ),
);

behaves_like_net_amazon_s3_request 'set object access control with both body and header acl specified' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_acl        => 'private',
    with_acl_xml    => 'private',

    throws          => re( qr/can not provide both acl_xml and acl/ ),
);

had_no_warnings;

done_testing;
