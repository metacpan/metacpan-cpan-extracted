
use strict;
use warnings;

use Test::More tests => 1 + 1;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'abort multipart upload' => (
    request_class   => 'Net::Amazon::S3::Request::AbortMultipartUpload',
    with_bucket     => 'some-bucket',
    with_key        => 'some/key',
    with_upload_id  => '123&456',

    expect_request_method   => 'DELETE',
    expect_request_path     => 'some-bucket/some/key?uploadId=123%26456',
    expect_request_headers  => { },
    expect_request_content  => '',
);

