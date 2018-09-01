
use strict;
use warnings;

use Test::More tests => 1 + 4;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

use Shared::Examples::Net::Amazon::S3::Operation::Bucket::Create (
    qw[ create_bucket_in_ca_central_1_content_xml ],
);

behaves_like_net_amazon_s3_request 'create bucket' => (
    request_class   => 'Net::Amazon::S3::Request::CreateBucket',
    with_bucket     => 'some-bucket',

    expect_request_method   => 'PUT',
    expect_request_path     => 'some-bucket/',
    expect_request_headers  => { },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'create bucket with acl' => (
    request_class   => 'Net::Amazon::S3::Request::CreateBucket',
    with_bucket     => 'some-bucket',
    with_acl_short  => 'private',

    expect_request_method   => 'PUT',
    expect_request_path     => 'some-bucket/',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'create bucket in region' => (
    request_class   => 'Net::Amazon::S3::Request::CreateBucket',
    with_bucket     => 'some-bucket',
    with_location_constraint => 'ca-central-1',

    expect_request_method   => 'PUT',
    expect_request_path     => 'some-bucket/',
    expect_request_headers  => { },
    expect_request_content  => create_bucket_in_ca_central_1_content_xml,
);

behaves_like_net_amazon_s3_request 'create bucket in region with acl' => (
    request_class   => 'Net::Amazon::S3::Request::CreateBucket',
    with_bucket     => 'some-bucket',
    with_acl_short  => 'private',
    with_location_constraint => 'ca-central-1',

    expect_request_method   => 'PUT',
    expect_request_path     => 'some-bucket/',
    expect_request_headers  => { 'x-amz-acl' => 'private' },
    expect_request_content  => create_bucket_in_ca_central_1_content_xml,
);

