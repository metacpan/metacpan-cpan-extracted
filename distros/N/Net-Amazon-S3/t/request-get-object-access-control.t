
use strict;
use warnings;

use Test::More tests => 1 + 1;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'get object access control' => (
    request_class   => 'Net::Amazon::S3::Request::GetObjectAccessControl',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/some/key?acl',
    expect_request_headers  => { },
    expect_request_content  => '',
);

