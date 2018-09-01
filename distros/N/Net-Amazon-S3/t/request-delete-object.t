
use strict;
use warnings;

use Test::More tests => 1 + 1;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'delete object' => (
    request_class   => 'Net::Amazon::S3::Request::DeleteObject',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',

    expect_request_method   => 'DELETE',
    expect_request_path     => 'some-bucket/some/key',
    expect_request_headers  => { },
    expect_request_content  => '',
);

