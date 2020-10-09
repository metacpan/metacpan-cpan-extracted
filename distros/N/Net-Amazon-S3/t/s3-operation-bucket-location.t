#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_location (
	'API / legacy'  => \& api_bucket_location_legacy,
	'API / named'   => \& api_bucket_location_named,
	'Client' => \& client_bucket_location,
);

had_no_warnings;

done_testing;

sub api_bucket_location_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_location_constraint (\ %args)
		;
}

sub api_bucket_location_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_location_constraint (%args)
		;
}

sub client_bucket_location {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->location_constraint (%args)
		;
}

sub expect_operation_bucket_location {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Location',
		plan => {
			"location bucket with name" => {
				act_arguments => [
					bucket => 'bucket-name',
				],
			},
		}
}
