#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_delete (
	'API / with bucket name'     => \& api_bucket_delete_identified_by_name,
	'API / with bucket instance' => \& api_bucket_delete_instance,
	'API / with named arguments' => \& api_bucket_delete_named,
	'API / via bucket'           => \& api_bucket_delete_via_bucket,
	'Client'                     => \& client_bucket_delete,
);

had_no_warnings;

done_testing;

sub api_bucket_delete_identified_by_name {
	my (%args) = @_;

	build_default_api->delete_bucket (\ %args);
}

sub api_bucket_delete_instance {
	my (%args) = @_;

	build_default_api->delete_bucket (build_default_api->bucket (delete $args{bucket}));
}

sub api_bucket_delete_named {
	my (%args) = @_;

	build_default_api->delete_bucket (%args);
}

sub api_bucket_delete_via_bucket {
	my (%args) = @_;

	build_default_api
		->bucket (delete $args{bucket})
		->delete_bucket (%args)
		;
}

sub client_bucket_delete {
	my (%args) = @_;

	build_default_client
		->bucket (name => delete $args{bucket})
		->delete (%args)
		;
}

sub expect_operation_bucket_delete {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Delete',
		plan => {
			"delete bucket" => {
				act_arguments => [
					bucket => 'bucket-name',
				],
			},
		}
}
