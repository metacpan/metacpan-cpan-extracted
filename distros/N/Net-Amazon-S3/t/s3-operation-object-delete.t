#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_delete (
	'API / Bucket->delete_key / legacy' => \& api_delete_object_via_bucket,
	'API / S3->delete_key / legacy'     => \& api_delete_object_via_s3,
	'API / Bucket->delete_key / named arguments' => \& api_delete_object_via_bucket_named,
	'API / S3->delete_key / named arguments'     => \& api_delete_object_via_s3_named,
	'Client'                   => \& client_delete_object,
);

had_no_warnings;

done_testing;

sub api_delete_object_via_bucket {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_key ($args{key})
		;
}

sub api_delete_object_via_bucket_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_key (%args)
		;
}

sub api_delete_object_via_s3 {
	my (%args) = @_;

	build_default_api
		->delete_key (\ %args)
		;
}

sub api_delete_object_via_s3_named {
	my (%args) = @_;

	build_default_api
		->delete_key (%args)
		;
}

sub client_delete_object {
	my (%args) = @_;

	build_default_client_object (%args)
		->delete
		;
}

sub expect_operation_object_delete {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Delete',
		plan => {
			"delete object" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
				],
			},
		}
}
