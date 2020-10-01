
use strict;
use warnings;

use FindBin;
BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

use Shared::Examples::Net::Amazon::S3 qw[ s3_api_with_signature_2 ];

use Net::Amazon::S3::X;

use Net::Amazon::S3::Error::Handler::X;
use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_bucket_create ];
use Shared::Examples::Net::Amazon::S3::Client qw[ expect_client_bucket_create ];

it "should build exception for S3 error",
	got => Net::Amazon::S3::X->build ('AuthorizationHeaderMalformed'),
	expect => obj_isa ('Net::Amazon::S3::X::AuthorizationHeaderMalformed'),
	;

it "should build exception for HTTP error",
	got => Net::Amazon::S3::X->build ('400'),
	expect => obj_isa ('Net::Amazon::S3::X::400'),
	;

subtest "S3 API should recognize custom error handler" => sub {
	my $s3_api = sub {
		s3_api_with_signature_2 (error_handler_class => 'Net::Amazon::S3::Error::Handler::X');
	};

	expect_api_bucket_create 'S3 error - Access Denied' => (
		with_s3                 => s3_api_with_signature_2 (error_handler_class => 'Net::Amazon::S3::Error::Handler::X'),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::access_denied'),
		throws                  => 'Net::Amazon::S3::X::AccessDenied',
		expect_s3_err           => undef,
		expect_s3_errstr        => undef,
	);

	expect_api_bucket_create 'S3 error - Bucket Already Exists' => (
		with_s3                 => s3_api_with_signature_2 (error_handler_class => 'Net::Amazon::S3::Error::Handler::X'),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::bucket_already_exists'),
		throws                  => 'Net::Amazon::S3::X::BucketAlreadyExists',
		expect_s3_err           => undef,
		expect_s3_errstr        => undef,
	);

	expect_api_bucket_create 'S3 error - Invalid Bucket Name' => (
		with_s3                 => s3_api_with_signature_2 (error_handler_class => 'Net::Amazon::S3::Error::Handler::X'),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::invalid_bucket_name'),
		throws                  => 'Net::Amazon::S3::X::InvalidBucketName',
		expect_s3_err           => undef,
		expect_s3_errstr        => undef,
	);

	expect_api_bucket_create 'HTTP error - 400 Bad Request' => (
		with_s3                 => $s3_api->(),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::http_bad_request'),
		throws                  => 'Net::Amazon::S3::X::400',
		expect_s3_err           => undef,
		expect_s3_errstr        => undef,
	);

};

subtest "S3 Client should recognize custom error handlerclass" => sub {
	my $s3_client = sub {
		Net::Amazon::S3::Client->new (
			s3 => s3_api_with_signature_2,
			error_handler_class => 'Net::Amazon::S3::Error::Handler::X',
		);
	};

	expect_client_bucket_create 'S3 error - Access Denied' => (
		with_client             => $s3_client->(),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::access_denied'),
		throws                  => 'Net::Amazon::S3::X::AccessDenied',
	);

	expect_client_bucket_create 'S3 error - Bucket Already Exists' => (
		with_client             => $s3_client->(),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::bucket_already_exists'),
		throws                  => 'Net::Amazon::S3::X::BucketAlreadyExists',
	);

	expect_client_bucket_create 'S3 error - Invalid Bucket Name' => (
		with_client             => $s3_client->(),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::invalid_bucket_name'),
		throws                  => 'Net::Amazon::S3::X::InvalidBucketName',
	);

	expect_client_bucket_create 'HTTP error - 400 Bad Request' => (
		with_client             => $s3_client->(),
		with_bucket             => 'some-bucket',
		with_response_fixture ('error::http_bad_request'),
		throws                  => 'Net::Amazon::S3::X::400',
	);
};

had_no_warnings;

done_testing;
