#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-s3-request.pl' }

plan tests => 2;

behaves_like_net_amazon_s3_request 'get bucket access control' => (
    request_class   => 'Net::Amazon::S3::Operation::Bucket::Acl::Fetch::Request',
    with_bucket     => 'some-bucket',

    expect_request_method   => 'GET',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/?acl',
    expect_request_headers  => { },
    expect_request_content  => '',
);

had_no_warnings;

done_testing;
