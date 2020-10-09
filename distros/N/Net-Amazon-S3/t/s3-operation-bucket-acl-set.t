#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_acl_set (
	'API / legacy'          => \& api_bucket_acl_set_legacy,
	'API / named arguments' => \& api_bucket_acl_set_named,
	'Client'                => \& client_bucket_acl_set,
);

had_no_warnings;

done_testing;

sub api_bucket_acl_set_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (\ %args)
		;
}

sub api_bucket_acl_set_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (%args)
		;
}

sub client_bucket_acl_set {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->set_acl (%args)
		;
}

sub expect_operation_bucket_acl_set {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Acl::Set',
		plan => {
			"set bucket acl" => {
				act_arguments => [
					bucket      => 'bucket-name',
					acl         => 'private',
					acl_short   => 'public',
					acl_xml     => 'some xml placeholder',
				],
			},
		}
}
