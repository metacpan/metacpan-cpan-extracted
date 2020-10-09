#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-s3-request.pl' }

plan tests => 2;

behaves_like_net_amazon_s3_request 'put object' => (
	request_class       => 'Net::Amazon::S3::Operation::Object::Upload::Part::Request',
	with_bucket         => 'some-bucket',
	with_key            => 'some/key',
	with_value          => 'foo',
	with_upload_id      => '123',
	with_part_number    => '1',

	expect_request_method   => 'PUT',
	expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?partNumber=1&uploadId=123',
	expect_request_headers  => { },
);

had_no_warnings;

done_testing;
