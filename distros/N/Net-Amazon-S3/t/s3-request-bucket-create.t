#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-s3-request.pl' }

plan tests => 11;

sub h ($) {
	+{ 'Content-Length' => ignore, 'Content-Type' => ignore, %{ $_[0] } };
}

behaves_like_net_amazon_s3_request 'create bucket' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { },
	expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'create bucket with deprecated acl_short' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl_short  => 'private',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { 'x-amz-acl' => 'private' },
	expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'create bucket with canned acl' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl        => Net::Amazon::S3::ACL::Canned->PRIVATE,

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { 'x-amz-acl' => 'private' },
	expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'create bucket with canned acl coercion' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl        => 'private',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { 'x-amz-acl' => 'private' },
	expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'create bucket with exact acl' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h {
		'x-amz-grant-read'  => 'id="123", id="234"',
		'x-amz-grant-write' => 'id="345"',
	},
	expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'create bucket in region' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_location_constraint => 'ca-central-1',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { },
	expect_request_content  => fixture ('request::bucket_create_ca_central_1')->{content},
);

behaves_like_net_amazon_s3_request 'create bucket in region with deprecated acl_short' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl_short  => 'private',
	with_location_constraint => 'ca-central-1',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { 'x-amz-acl' => 'private' },
	expect_request_content  => fixture ('request::bucket_create_ca_central_1')->{content},
);

behaves_like_net_amazon_s3_request 'create bucket in region with canned acl' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl        => Net::Amazon::S3::ACL::Canned->PRIVATE,
	with_location_constraint => 'ca-central-1',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { 'x-amz-acl' => 'private' },
	expect_request_content  => fixture ('request::bucket_create_ca_central_1')->{content},
);

behaves_like_net_amazon_s3_request 'create bucket in region with canned acl coercion' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl_short  => 'private',
	with_location_constraint => 'ca-central-1',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h { 'x-amz-acl' => 'private' },
	expect_request_content  => fixture ('request::bucket_create_ca_central_1')->{content},
);

behaves_like_net_amazon_s3_request 'create bucket in region with exact acl' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Create::Request',
	with_bucket     => 'some-bucket',
	with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,
	with_location_constraint => 'ca-central-1',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/',
	expect_request_headers  => h {
		'x-amz-grant-read'  => 'id="123", id="234"',
		'x-amz-grant-write' => 'id="345"',
	},
	expect_request_content  => fixture ('request::bucket_create_ca_central_1')->{content},
);

had_no_warnings;

done_testing;
