#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_acl_fetch (
	'API / legacy'      => \& api_object_acl_fetch_legacy,
	'API / config hash' => \& api_object_acl_fetch_config_hash,
	'API / named'       => \& api_object_acl_fetch_named,
);

had_no_warnings;

done_testing;

sub api_object_acl_fetch_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl ($args{key})
		;
}

sub api_object_acl_fetch_config_hash {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl ( \%args)
		;
}

sub api_object_acl_fetch_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl (%args)
		;
}

sub expect_operation_object_acl_fetch {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Acl::Fetch',
		plan => {
			"fetch object acl" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
				],
			},
		}
}
