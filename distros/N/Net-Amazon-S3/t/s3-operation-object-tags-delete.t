#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

plan tests => 7;

expect_operation_object_tags_delete (
	'API / legacy'  => \& api_object_tags_delete_legacy,
	'API / named'   => \& api_object_tags_delete_named,
	'Client'  => \& client_object_tags_delete,
);

had_no_warnings;

done_testing;

sub api_object_tags_delete_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_tags (\ %args)
		;
}

sub api_object_tags_delete_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_tags (%args)
		;
}

sub client_object_tags_delete {
	my (%args) = @_;

	build_default_client_object (%args)
		->delete_tags (%args)
		;
}

sub expect_operation_object_tags_delete {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Tags::Delete',
		plan => {
			"delete tags from object" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
				],
			},
			"delete tags from object version" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					version_id  => 'foo',
				],
			},
		}
}
