
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_object_create ];

plan tests => 11;

expect_api_object_create 'create object from scalar value' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	expect_data             => bool (1),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_content  => 'some value',
	expect_request_headers  => {
		content_length => 10,
		content_md5 => undef,
		expires => undef,
	},
);

expect_api_object_create 'create object with deprecated acl_short' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_acl_short          => 'private',
	expect_data             => bool (1),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_content  => 'some value',
	expect_request_headers  => {
		content_length => 10,
		content_md5 => undef,
		expires => undef,
		x_amz_acl => 'private',
	},
);

expect_api_object_create 'create object with canned acl' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_acl                => Net::Amazon::S3::ACL::Canned->PRIVATE,
	expect_data             => bool (1),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_content  => 'some value',
	expect_request_headers  => {
		content_length => 10,
		content_md5 => undef,
		expires => undef,
		x_amz_acl => 'private',
	},
);

expect_api_object_create 'create object with canned acl coercion' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_acl                => 'private',
	expect_data             => bool (1),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_content  => 'some value',
	expect_request_headers  => {
		content_length => 10,
		content_md5 => undef,
		expires => undef,
		x_amz_acl => 'private',
	},
);

expect_api_object_create 'create object with explicit acl' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_acl        => Net::Amazon::S3::ACL::Set->new
		->grant_read (id => '123', id => '234')
		->grant_write (id => '345')
		,
	expect_data             => bool (1),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_content  => 'some value',
	expect_request_headers  => {
		content_length => 10,
		content_md5 => undef,
		expires => undef,
		x_amz_grant_read  => 'id="123", id="234"',
		x_amz_grant_write => 'id="345"',
	},
);

expect_api_object_create 'create object with server side encryption' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_encryption         => 'AES256',
	expect_data             => bool (1),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_content  => 'some value',
	expect_request_headers  => {
		content_length => 10,
		content_md5 => undef,
		expires => undef,
		x_amz_server_side_encryption => 'AES256',
	},
);

expect_api_object_create 'create object with headers recognized by Client::Bucket' => (
	with_bucket                 => 'some-bucket',
	with_key                    => 'some-key',
	with_value                  => 'some value',
	with_cache_control          => 'private',
	with_content_disposition    => 'inline',
	with_content_encoding       => 'identity',
	with_content_type           => 'text/plain',
	with_expires                => 'Fri, 09 Sep 2011 23:36:00 GMT',
	with_storage_class          => 'reduced_redundancy',
	with_user_metadata          => { Foo => 1, Bar => 2 },
	expect_data                 => bool (1),
	expect_request              => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_request_content      => 'some value',
	expect_request_headers      => {
		cache_control       => 'private',
		content_disposition => 'inline',
		content_encoding    => 'identity',
		content_length      => 10,
		content_type        => 'text/plain',
		content_md5         => undef,
		expires             => 'Fri, 09 Sep 2011 23:36:00 GMT',
		x_amz_meta_bar      => 2,
		x_amz_meta_foo      => 1,
		x_amz_storage_class => 'reduced_redundancy',
	},
);

expect_api_object_create 'S3 error - Access Denied' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_response_fixture ('error::access_denied'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_access_denied,
);

expect_api_object_create 'S3 error - Bucket Not Found' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_response_fixture ('error::no_such_bucket'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_s3_error_bucket_not_found,
);

expect_api_object_create 'HTTP error - 400 Bad Request' => (
	with_bucket             => 'some-bucket',
	with_key                => 'some-key',
	with_value              => 'some value',
	with_response_fixture ('error::http_bad_request'),
	expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/some-key' },
	expect_http_error_bad_request,
);

had_no_warnings;

done_testing;

