#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-s3-response.pl" }

plan tests => 2;

behaves_like_s3_response 'list all my buckets with displayname' => (
	response_class      => 'Net::Amazon::S3::Operation::Object::Upload::Create::Response',

	with_response_fixture ('response::create_multipart_upload_with_success'),

	expect_success      => 1,
	expect_error        => 0,
	expect_response     => methods (
		upload_id => 'new-upload-id',
	),
);

had_no_warnings;

done_testing;
