#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_tags_set (
	'API / legacy'  => \& api_bucket_tags_set_legacy,
	'API / named'   => \& api_bucket_tags_set_named,
	'Client'  => \& client_bucket_tags_set,
);

had_no_warnings;

done_testing;

sub api_bucket_tags_set_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->add_tags (\ %args)
		;
}

sub api_bucket_tags_set_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->add_tags (%args)
		;
}

sub client_bucket_tags_set {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->add_tags (%args)
		;
}

sub expect_operation_bucket_tags_set {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Tags::Add',
		plan => {
			"set tags on bucket" => {
				act_arguments => [
					bucket      => 'bucket-name',
					tags        => { foo => 'bar' },
				],
			},
		}
}
