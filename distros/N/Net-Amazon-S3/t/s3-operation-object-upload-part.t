#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_upload_part (
	'Client / named arguments'    => \& client_object_upload_part_named_arguments,
	'Client / configuration hash' => \& client_object_upload_part_configuration_hash,
);

had_no_warnings;

done_testing;

sub client_object_upload_part_named_arguments {
	my (%args) = @_;

	build_default_client_object (%args)
		->put_part (%args);
}

sub client_object_upload_part_configuration_hash {
	my (%args) = @_;

	build_default_client_object (%args)
		->put_part (\ %args);
}

sub expect_operation_object_upload_part {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Upload::Part',
		plan => {
			"upload object part" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => 'foo-bar-baz',
					upload_id   => 42,
					part_number => 1,
					headers     => {
						x_amz_meta_additional => 'additional-header',
					},
				],
				expect_arguments => {
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => 'foo-bar-baz',
					upload_id   => 42,
					part_number => 1,
					headers     => {
						x_amz_meta_additional => 'additional-header',
						'Content-Length' => 11,
					},
				},
			},
		}
}

