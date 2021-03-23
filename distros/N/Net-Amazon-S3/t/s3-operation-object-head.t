#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_head_api (
	'API / via Bucket' => \& api_object_head_key_via_bucket,
	'API / via S3'     => \& api_object_head_key_via_s3,
);

expect_operation_object_head_client (
	'Client' => \& client_object_exists,
);

had_no_warnings;

done_testing;

sub api_object_head_key_via_bucket {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->head_key (delete $args{key})
		;
}

sub api_object_head_key_via_s3 {
	my (%args) = @_;

	build_default_api
		->head_key (\ %args)
		;
}

sub client_object_exists {
	my (%args) = @_;

	build_default_client_object (%args)
		->exists
		;
}

sub expect_operation_object_head_api {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Fetch',
		plan => {
			"head object" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
				],
				expect_arguments => {
					bucket => 'bucket-name',
					key    => 'key-name',
					method => 'HEAD',
					filename => undef,
				},
			},
		}
}

sub expect_operation_object_head_client {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Head',
		plan => {
			"fetch object" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
				],
				expect_arguments => {
					bucket => 'bucket-name',
					key    => 'key-name',
				},
			},
		}
}

