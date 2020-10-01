#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-s3-request.pl' }

plan tests => 8;

behaves_like_net_amazon_s3_request 'set bucket access control using (deprecated) acl_short' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_acl_short  => 'private',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/?acl',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

behaves_like_net_amazon_s3_request 'set bucket access control using canned acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_acl        => Net::Amazon::S3::ACL::Canned->PRIVATE,

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/?acl',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

behaves_like_net_amazon_s3_request 'set bucket access control using canned acl coercion' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_acl        => 'private',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/?acl',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
);

behaves_like_net_amazon_s3_request 'set bucket access control using explicit acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/?acl',
    expect_request_headers  => {
		'x-amz-grant-read'  => 'id="123", id="234"',
		'x-amz-grant-write' => 'id="345"',
	},
);

behaves_like_net_amazon_s3_request 'set bucket access control with body acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_acl_xml    => 'private',

    expect_request_method   => 'PUT',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/?acl',
    expect_request_headers  => { },
);

behaves_like_net_amazon_s3_request 'set bucket access control without body or header acl' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Set::Request',
    with_bucket     => 'some-bucket',

    throws          => re( qr/need either acl_xml or acl/ ),
);

behaves_like_net_amazon_s3_request 'set bucket access control with both body and header acl specified' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Set::Request',
    with_bucket     => 'some-bucket',
    with_acl        => 'private',
    with_acl_xml    => 'private',

    throws          => re( qr/can not provide both acl_xml and acl/ ),
);


had_no_warnings;

done_testing;
