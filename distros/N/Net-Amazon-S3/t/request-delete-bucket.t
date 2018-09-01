
use strict;
use warnings;

use Test::More tests => 1 + 1;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'delete bucket' => (
    request_class   => 'Net::Amazon::S3::Request::DeleteBucket',
    with_bucket     => 'some-bucket',

    expect_request_method   => 'DELETE',
    expect_request_path     => 'some-bucket/',
    expect_request_headers  => { },
    expect_request_content  => '',
);

