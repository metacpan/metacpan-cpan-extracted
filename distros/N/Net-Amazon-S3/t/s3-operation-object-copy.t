#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_copy (
	'API / legacy'                      => \& api_object_copy_legacy,
	'API / legacy configuration hash'   => \& api_object_copy_legacy_config,
	'API / named arguments'             => \& api_object_copy_named,
	'API / named arguments with keys'   => \& api_object_copy_named_keys,
);

expect_operation_object_edit_metadata (
	'API / edit metadata legacy'        => \& api_object_edit_metadata_legacy,
	'API / edit metadata named'         => \& api_object_edit_metadata_named,
);

had_no_warnings;

done_testing;

sub api_object_copy_legacy {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			delete $args{key},
			delete $args{source},
			\ %args
		);
}

sub api_object_copy_legacy_config {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			\ %args
		);
}

sub api_object_copy_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			%args
		);
}

sub api_object_copy_named_keys {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			delete $args{key},
			delete $args{source},
			%args
		);
}

sub api_object_edit_metadata_legacy {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->edit_metadata (
			delete $args{key},
			\ %args
		);
}

sub api_object_edit_metadata_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->edit_metadata (
			%args
		);
}

sub expect_operation_object_copy {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		plan => {
			"copy key" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					source      => 'source-key',
					acl_short   => 'object-acl',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'storage-class',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_arguments => {
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => '',
					acl_short   => 'object-acl',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'storage-class',
						x_amz_website_redirect_location => 'location-value',
						x_amz_meta_foo => 'foo-value',
						'x-amz-metadata-directive' => 'REPLACE',
						'x-amz-copy-source'        => 'source-key',
					}
				},
			},
		}
}

sub expect_operation_object_edit_metadata {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		plan => {
			"copy key" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl_short   => 'object-acl',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'storage-class',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_arguments => {
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => '',
					acl_short   => 'object-acl',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'storage-class',
						x_amz_website_redirect_location => 'location-value',
						x_amz_meta_foo => 'foo-value',
						'x-amz-metadata-directive' => 'REPLACE',
						'x-amz-copy-source'        => '/bucket-name/some-key',
					}
				},
			},
		}
}

