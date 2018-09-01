
use strict;
use warnings;

use Test::More tests => 1 + 3;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'abort multipart upload with empty parts' => (
    request_class       => 'Net::Amazon::S3::Request::CompleteMultipartUpload',
    with_bucket         => 'some-bucket',
    with_key            => 'some/key',
    with_upload_id      => '123&456',
    with_etags          => [ ],
    with_part_numbers   => [ ],

    expect_request_method   => 'POST',
    expect_request_path     => 'some-bucket/some/key?uploadId=123%26456',
    expect_request_headers  => {
        'Content-MD5' => ignore,
        'Content-Length' => ignore,
        'Content-Type' => 'application/xml',
    },
    expect_request_content  => <<'EOXML',
<CompleteMultipartUpload></CompleteMultipartUpload>
EOXML
);

behaves_like_net_amazon_s3_request 'abort multipart upload with some parts' => (
    request_class       => 'Net::Amazon::S3::Request::CompleteMultipartUpload',
    with_bucket         => 'some-bucket',
    with_key            => 'some/key',
    with_upload_id      => '123&456',
    with_etags          => [ 'etag01', 'etag02' ],
    with_part_numbers   => [ 1, 2 ],

    expect_request_method   => 'POST',
    expect_request_path     => 'some-bucket/some/key?uploadId=123%26456',
    expect_request_headers  => {
        'Content-MD5' => ignore,
        'Content-Length' => ignore,
        'Content-Type' => 'application/xml',
    },
    expect_request_content  => <<'EOXML',
<CompleteMultipartUpload>
  <Part>
    <PartNumber>1</PartNumber>
    <ETag>etag01</ETag>
  </Part>
  <Part>
    <PartNumber>2</PartNumber>
    <ETag>etag02</ETag>
  </Part>
</CompleteMultipartUpload>
EOXML
);

behaves_like_net_amazon_s3_request 'abort multipart upload with uneven argument arrays' => (
    request_class       => 'Net::Amazon::S3::Request::CompleteMultipartUpload',
    with_bucket         => 'some-bucket',
    with_key            => 'some/ %/key',
    with_upload_id      => '123&456',
    with_etags          => [ 'etag01', 'etag02' ],
    with_part_numbers   => [ 1, 2, 3 ],

    throws              => re( qr/must have an equally sized list of etags and part numbers/ ),
);
