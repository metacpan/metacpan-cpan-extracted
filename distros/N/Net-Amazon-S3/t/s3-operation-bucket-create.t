#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_create (
	'API / legacy'                      => \& api_bucket_create_legacy,
	'API / named arguments'             => \& api_bucket_create_named,
	'API / trailing named arguments'    => \& api_bucket_create_trailing_named,
	'API / trailing configuration hash' => \& api_bucket_create_trailing_conf,
	'Client' => \& client_bucket_create,
);

had_no_warnings;

done_testing;

sub api_bucket_create_legacy {
	my (%args) = @_;

	build_default_api->add_bucket (\ %args);
}

sub api_bucket_create_named {
	my (%args) = @_;

	build_default_api->add_bucket (%args);
}

sub api_bucket_create_trailing_named {
	my (%args) = @_;

	build_default_api->add_bucket (delete $args{bucket}, %args);
}

sub api_bucket_create_trailing_conf {
	my (%args) = @_;

	build_default_api->add_bucket (delete $args{bucket}, \%args);
}

sub client_bucket_create {
	my (%args) = @_;

	build_default_client->create_bucket (name => delete $args{bucket}, %args);
}

sub expect_operation_bucket_create {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Create',
		plan => {
			"create bucket with name" => {
				act_arguments => [
					bucket => 'bucket-name',
				],
			},
			"create bucket with location constraint" => {
				act_arguments => [
					bucket => 'bucket-name',
					location_constraint => 'eu-west-1',
				],
			},
			"create bucket with acl" => {
				act_arguments => [
					bucket    => 'bucket-name',
					acl_short => 'private',
					acl       => 'public',
				],
			},
		}
}
