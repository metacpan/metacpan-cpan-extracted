
use strict;
use warnings;

use Test::More tests => 2;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'get bucket location constraint' => (
    request_class   => 'Net::Amazon::S3::Request::GetBucketLocationConstraint',
    with_bucket     => 'some-bucket',

    expect_request_method   => 'GET',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/?location',
    expect_request_headers  => { },
    expect_request_content  => '',
);

had_no_warnings;
