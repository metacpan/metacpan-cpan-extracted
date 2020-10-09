#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_acl_fetch (
	'API / legacy'  => \& api_bucket_acl_fetch_legacy,
	'API / named'   => \& api_bucket_acl_fetch_named,
	'Client'        => \& client_bucket_acl_fetch,
);

had_no_warnings;

done_testing;

sub api_bucket_acl_fetch_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl (%args)
		;
}

sub api_bucket_acl_fetch_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl (%args)
		;
}

sub client_bucket_acl_fetch {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->acl (%args)
		;
}

sub expect_operation_bucket_acl_fetch {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Acl::Fetch',
		plan => {
			"fetch bucket acl" => {
				act_arguments => [
					bucket => 'bucket-name',
				],
			},
		}
}
