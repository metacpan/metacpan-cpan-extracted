#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_tags_delete (
	'API / legacy'  => \& api_bucket_tags_delete_legacy,
	'API / named'   => \& api_bucket_tags_delete_named,
	'Client'  => \& client_bucket_tags_delete,
);

had_no_warnings;

done_testing;

sub api_bucket_tags_delete_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_tags (\ %args)
		;
}

sub api_bucket_tags_delete_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_tags (%args)
		;
}

sub client_bucket_tags_delete {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->delete_tags (%args)
		;
}

sub expect_operation_bucket_tags_delete {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Tags::Delete',
		plan => {
			"delete tags from bucket" => {
				act_arguments => [
					bucket      => 'bucket-name',
				],
			},
		}
}
