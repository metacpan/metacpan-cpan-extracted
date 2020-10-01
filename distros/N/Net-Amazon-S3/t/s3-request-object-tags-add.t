#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-request.pl" }
BEGIN { require "$FindBin::Bin/test-helper-tags.pl" }

plan tests => 3;

behaves_like_net_amazon_s3_request 'add some tags to an object' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Tags::Add::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some-key',
    with_tags       => fixture_tags_foo_bar_hashref,

    expect_request_method   => 'PUT',
    expect_request_path     => 'some-bucket/some-key?tagging',
    expect_request_header   => {
        content_type => 'application/xml',
    },
    expect_request_content  => fixture_tags_foo_bar_xml,
);

behaves_like_net_amazon_s3_request 'add some tags to an object version' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Tags::Add::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some-key',
    with_tags       => fixture_tags_foo_bar_hashref,
	with_version_id => 42,

    expect_request_method   => 'PUT',
    expect_request_path     => 'some-bucket/some-key?tagging&versionId=42',
    expect_request_header   => {
        content_type => 'application/xml',
    },
    expect_request_content  => fixture_tags_foo_bar_xml,
);

had_no_warnings;

done_testing;
