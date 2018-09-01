
use strict;
use warnings;

use Test::More tests => 1 + 5;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'list bucket' => (
    request_class   => 'Net::Amazon::S3::Request::ListBucket',
    with_bucket     => 'some-bucket',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/?max-keys=1000',
    expect_request_headers  => { },
);

behaves_like_net_amazon_s3_request 'list bucket with prefix' => (
    request_class   => 'Net::Amazon::S3::Request::ListBucket',
    with_bucket     => 'some-bucket',
    with_prefix     => 'some-prefix',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/?max-keys=1000&prefix=some-prefix',
    expect_request_headers  => { },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'list bucket with delimiter' => (
    request_class   => 'Net::Amazon::S3::Request::ListBucket',
    with_bucket     => 'some-bucket',
    with_delimiter  => '&',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/?delimiter=%26&max-keys=1000',
    expect_request_headers  => { },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'list bucket with max-keys' => (
    request_class   => 'Net::Amazon::S3::Request::ListBucket',
    with_bucket     => 'some-bucket',
    with_max_keys   => '200',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/?max-keys=200',
    expect_request_headers  => { },
    expect_request_content  => '',
);

behaves_like_net_amazon_s3_request 'list bucket with marker' => (
    request_class   => 'Net::Amazon::S3::Request::ListBucket',
    with_bucket     => 'some-bucket',
    with_marker     => 'x',

    expect_request_method   => 'GET',
    expect_request_path     => 'some-bucket/?marker=x&max-keys=1000',
    expect_request_headers  => { },
    expect_request_content  => '',
);

