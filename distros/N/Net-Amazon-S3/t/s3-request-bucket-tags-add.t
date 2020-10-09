#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-request.pl" }
BEGIN { require "$FindBin::Bin/test-helper-tags.pl" }

plan tests => 2;

behaves_like_net_amazon_s3_request 'add some tags to a bucket' => (
	request_class   => 'Net::Amazon::S3::Operation::Bucket::Tags::Add::Request',
	with_bucket     => 'some-bucket',
	with_tags       => fixture_tags_foo_bar_hashref,

	expect_request_method   => 'PUT',
	expect_request_path     => 'some-bucket/?tagging',
	expect_request_header   => {
		content_type => 'application/xml',
	},
	expect_request_content  => fixture_tags_foo_bar_xml,
);

had_no_warnings;

done_testing;
