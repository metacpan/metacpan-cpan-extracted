#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

note "Client and API capabilities differs a lot";

expect_operation_object_add_scalar (
	'API / via Bucket' => \& api_object_add_scalar_via_bucket,
	'API / via S3'     => \& api_object_add_scalar_via_s3,
	'API / via Bucket / named arguments' => \& api_object_add_scalar_via_bucket_named,
	'API / via S3 / named arguments'     => \& api_object_add_scalar_via_s3_named,
);

expect_operation_object_add_file (
	'API / add key wrapper' => \& api_object_add_filename,
	'API / add key'         => \& api_object_add_file,
	'API / add key wrapper / named arguments' => \& api_object_add_filename_named,
);

expect_operation_object_client_add_scalar (
	'Client'  => \& client_object_add_scalar,
);

expect_operation_object_client_add_file (
	'Client / add key filename'  => \& client_object_add_filename,
);

had_no_warnings;

done_testing;

sub api_object_add_scalar_via_bucket {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key (
			delete $args{key},
			delete $args{value},
			\ %args
		);
}

sub api_object_add_scalar_via_s3 {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api
		->add_key (
			\ %args
		);
}

sub api_object_add_scalar_via_bucket_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key (%args)
		;
}

sub api_object_add_scalar_via_s3_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api
		->add_key (%args)
		;
}

sub api_object_add_file {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key (
			delete $args{key},
			\ delete $args{value},
			\ %args
		);
}

sub api_object_add_filename {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key_filename (
			delete $args{key},
			delete $args{value},
			\ %args
		);
}

sub api_object_add_filename_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key_filename (
			delete $args{key},
			delete $args{value},
			\ %args
		);
}

sub client_object_add_scalar {
	my (%args) = @_;
	my $headers = delete $args{headers};
	build_default_client_bucket (%args)
		->object (
			key => $args{key},
			expires => 2_345_567_890,
			storage_class => $headers->{x_amz_storage_class},
			website_redirect_location => $headers->{x_amz_website_redirect_location},
			user_metadata => $args{metadata},
			content_encoding => $headers->{content_encoding},
			acl => $args{acl},
			encryption => $args{encryption},
		)
		->put ($args{value})
		;
}

sub client_object_add_filename {
	my (%args) = @_;
	my $headers = delete $args{headers};
	build_default_client_bucket (%args)
		->object (
			key => $args{key},
			expires => 2_345_567_890,
			storage_class => $headers->{x_amz_storage_class},
			website_redirect_location => $headers->{x_amz_website_redirect_location},
			user_metadata => $args{metadata},
			content_encoding => $headers->{content_encoding},
			acl => $args{acl},
			encryption => $args{encryption},
		)
		->put_filename ($args{value})
		;
}

sub expect_operation_object_add_scalar {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		plan => {
			"add object with value from scalar" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => 'foo-bar-baz',
					acl         => 'object-acl',
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
					value       => 'foo-bar-baz',
					acl         => 'object-acl',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'storage-class',
						x_amz_website_redirect_location => 'location-value',
						x_amz_meta_foo => 'foo-value',
						'Content-Length' => 11,
					}
				},
			},
		}
}

sub expect_operation_object_add_file {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		plan => {
			"add object with value from file" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => "$FindBin::Bin/data/s3-operation-object-add.txt",
					acl         => 'private',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'standard',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_arguments => {
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => expect_coderef,
					acl         => 'private',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'standard',
						x_amz_website_redirect_location => 'location-value',
						x_amz_meta_foo => 'foo-value',
						'Content-Length' => 72,
						expect           => '100-continue',
					}
				},
			},
		}
}

sub expect_operation_object_client_add_scalar {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		plan => {
			"add object with value from scalar" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => 'foo-bar-baz',
					acl         => 'private',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 'expires-value',
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'standard',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_arguments => {
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => 'foo-bar-baz',
					acl         => obj_isa ('Net::Amazon::S3::ACL::Canned'),
					encryption  => 'object-encryption',
					headers     => {
						'Content-Length' => 11,
						'Content-Type' => 'binary/octet-stream',
						'Content-MD5'  => ignore,
						'Content-Encoding' => 'content-encoding',
						'Expires'            => 'Fri, 29 Apr 2044 18:38:10 GMT',
						'x-amz-meta-foo'     => 'foo-value',
						'x-amz-website-redirect-location' => 'location-value',
					}
				},
			},
		}
}

sub expect_operation_object_client_add_file {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		plan => {
			"add object with value from scalar" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => "$FindBin::Bin/data/s3-operation-object-add.txt",
					acl         => 'private',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 'expires-value',
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'standard',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_arguments => {
					bucket      => 'bucket-name',
					key         => 'some-key',
					value       => expect_coderef,
					acl         => obj_isa ('Net::Amazon::S3::ACL::Canned'),
					encryption  => 'object-encryption',
					headers     => {
						'Content-Length' => 72,
						'Content-Type' => 'binary/octet-stream',
						'Content-MD5'  => ignore,
						'Content-Encoding' => 'content-encoding',
						'Expires'            => 'Fri, 29 Apr 2044 18:38:10 GMT',
						'x-amz-meta-foo'     => 'foo-value',
						'x-amz-website-redirect-location' => 'location-value',
					}
				},
			},
		}
}

