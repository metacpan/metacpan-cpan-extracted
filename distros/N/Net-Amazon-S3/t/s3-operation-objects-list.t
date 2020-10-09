#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

plan tests => 10;

expect_operation_objects_list_api (
	"API / S3->list_bucket legacy"     => \& api_objects_list_legacy,
	"API / S3->list_bucket_all legacy" => \& api_objects_list_all_legacy,
	"API / S3->list_bucket named"      => \& api_objects_list_named,
	"API / S3->list_bucket_all named"  => \& api_objects_list_all_named,
	"API / Bucket->list legacy"        => \& api_objects_bucket_list_legacy,
	"API / Bucket->list_all legacy"    => \& api_objects_bucket_list_all_legacy,
	"API / Bucket->list named"         => \& api_objects_bucket_list_named,
	"API / Bucket->list_all named"     => \& api_objects_bucket_list_all_named,
);

expect_operation_objects_list_client (
	"Client" => \& client_objects_list,
);

had_no_warnings;

done_testing;

sub api_objects_list_legacy {
	my (%args) = @_;

	build_default_api->list_bucket (\ %args);
}

sub api_objects_list_named {
	my (%args) = @_;

	build_default_api->list_bucket (%args);
}

sub api_objects_list_all_legacy {
	my (%args) = @_;

	build_default_api->list_bucket_all (\ %args);
}

sub api_objects_list_all_named {
	my (%args) = @_;

	build_default_api->list_bucket_all (%args);
}

sub api_objects_bucket_list_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->list (\ %args)
		;
}

sub api_objects_bucket_list_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->list (%args)
		;
}

sub api_objects_bucket_list_all_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->list_all (\ %args)
		;
}

sub api_objects_bucket_list_all_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->list_all (%args)
		;
}

sub client_objects_list {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->list (\ %args)
		->next
		;
}

sub expect_operation_objects_list_api {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Objects::List',
		plan => {
			"list buckets" => {
				act_arguments => [
					bucket      => 'bucket-name',
					delimiter   => 'd',
					max_keys    => 1_000,
					marker      => 'm',
					prefix      => 'p'
				],
			},
		}
}

sub expect_operation_objects_list_client {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Objects::List',
		plan => {
			"list buckets" => {
				act_arguments => [
					bucket      => 'bucket-name',
					delimiter   => 'd',
					marker      => 'm',
					prefix      => 'p'
				],
				expect_arguments => {
					bucket      => 'bucket-name',
					delimiter   => 'd',
					marker      => undef,
					prefix      => 'p'
				},
			},
		}
}
