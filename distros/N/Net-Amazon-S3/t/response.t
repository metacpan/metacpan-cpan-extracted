#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-s3-response.pl" }

plan tests => 6;

use HTTP::Request;
use HTTP::Response;
use HTTP::Status qw[ status_message ];

use Net::Amazon::S3::Response;

sub with_fixture_http_error;
sub with_fixture_cant_connect_internal_response;
sub with_fixture_common_response_headers;

behaves_like_s3_response "S3 error response - NoSuchKey" => (
	response_class          => 'Net::Amazon::S3::Response',

	with_response_fixture ('error::no_such_key'),

	expect_success           => 0,
	expect_error             => 1,
	expect_redirect          => 0,
	expect_internal_response => 0,
	expect_xml_content       => 1,
	expect_error_code        => 'NoSuchKey',
	expect_error_message     => 'No such key error message',
	expect_error_resource    => '/some-resource',
	expect_error_request_id  => '4442587FB7D0A2F9',
);

behaves_like_s3_response "S3 error response - AccessDenied" => (
	response_class      => 'Net::Amazon::S3::Response',

	with_response_fixture ('error::access_denied'),

	expect_error         => 1,
	expect_success       => 0,
	expect_error_code    => 'AccessDenied',
	expect_error_message => 'Access denied error message',
);

behaves_like_s3_response "HTTP error - 403 Forbidden" => (
	response_class          => 'Net::Amazon::S3::Response',

	with_fixture_http_error,

	expect_error             => 1,
	expect_success           => 0,
	expect_redirect          => 0,
	expect_xml_content       => 0,
	expect_internal_response => 0,
	expect_error_code        => '403',
	expect_error_message     => 'Forbidden',
	expect_error_resource    => 'https://my-bucket.amazonaws.com/some-resource',
	expect_error_request_id  => undef,
);

behaves_like_s3_response "Internal response - Can't connect" => (
	response_class          => 'Net::Amazon::S3::Response',

	with_fixture_cant_connect_internal_response,

	expect_error             => 1,
	expect_success           => 0,
	expect_redirect          => 0,
	expect_xml_content       => 0,
	expect_internal_response => 1,
	expect_error_code        => '500',
	expect_error_message     => "Can't connect to my.bucket.name.s3.amazonaws.com:443",
);

behaves_like_s3_response "S3 response - Common Response Headers" => (
	response_class          => 'Net::Amazon::S3::Response',

	with_fixture_common_response_headers,

	expect_response         => all (
		methods (etag          => "2468"),
		methods (server        => "AmazonS3"),
		methods (delete_marker => "some-delete-marker"),
		methods (id_2          => 'some-id-2'),
		methods (request_id    => 'some-request-id'),
		methods (version_id    => 'some-version-id'),
	),
);

had_no_warnings;

done_testing;

sub with_fixture_http_error {
	+(
		with_response_code => 403,
		with_origin_request => HTTP::Request->new (GET => 'https://my-bucket.amazonaws.com/some-resource'),
	);
}

sub with_fixture_cant_connect_internal_response {
	+(
		with_response_code => 500,
		with_response_message => "Can't connect to my.bucket.name.s3.amazonaws.com:443",
		with_response_header_content_type => 'text/plain',
		with_response_header_client_warning => 'Internal response',
	);
}

sub with_fixture_common_response_headers {
	+(
		with_response_code => 403,
		with_response_header => {
			server              => 'AmazonS3',
			content_type        => 'application/xml',
			etag                => '"2468"',
			x_amz_delete_marker => 'some-delete-marker',
			x_amz_id_2          => 'some-id-2',
			x_amz_request_id    => 'some-request-id',
			x_amz_version_id    => 'some-version-id',
		},
	);
}
