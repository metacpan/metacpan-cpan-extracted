#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_acl_set (
	'API / legacy'                      => \& api_object_acl_set,
	'API / legacy with key'             => \& api_object_acl_set_key,
	'API / named arguments'             => \& api_object_acl_set_named,
	'API / named arguments with key'    => \& api_object_acl_set_named_key,
	'Client'                            => \& client_object_acl_set,
);

had_no_warnings;

done_testing;

sub api_object_acl_set {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (\ %args)
		;
}

sub api_object_acl_set_key {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (delete $args{key}, \ %args)
		;
}

sub api_object_acl_set_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (%args)
		;
}

sub api_object_acl_set_named_key {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (delete $args{key}, %args)
		;
}

sub client_object_acl_set {
	my (%args) = @_;

	build_default_client_object (%args)
		->set_acl (%args)
		;
}

sub expect_operation_object_acl_set {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Acl::Set',
		plan => {
			"set object acl" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl         => 'private',
					acl_short   => 'public',
					acl_xml     => 'some xml placeholder',
				],
			},
		}
}
