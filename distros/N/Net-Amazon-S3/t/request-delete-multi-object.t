
use strict;
use warnings;

use Test::More tests => 1 + 3;
use Test::Deep;
use Test::Warnings;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ behaves_like_net_amazon_s3_request ],
);

behaves_like_net_amazon_s3_request 'delete multi object with empty keys' => (
    request_class   => 'Net::Amazon::S3::Request::DeleteMultiObject',
    with_bucket     => 'some-bucket',
    with_keys       => [],

    expect_request_method   => 'POST',
    expect_request_path     => 'some-bucket/?delete',
    expect_request_headers  => {
        'Content-MD5' => 'hWgjGHog2fcu6stNeIAJsw==',
        'Content-Length' => 76,
        'Content-Type' => 'application/xml',
    },
    expect_request_content  => <<'EOXML',
<Delete>
  <Quiet>true</Quiet>
</Delete>
EOXML
);

behaves_like_net_amazon_s3_request 'delete multi object with some keys' => (
    request_class   => 'Net::Amazon::S3::Request::DeleteMultiObject',
    with_bucket     => 'some-bucket',
    with_keys       => [ 'some/key', '<another/key>' ],

    expect_request_method   => 'POST',
    expect_request_path     => 'some-bucket/?delete',
    expect_request_headers  => {
        'Content-MD5' => '+6onPaU8IPGxGhWh0ULBJg==',
        'Content-Length' => 159,
        'Content-Type' => 'application/xml',
    },
    expect_request_content  => <<'EOXML',
<Delete>
  <Quiet>true</Quiet>
  <Object><Key>some/key</Key></Object>
  <Object><Key>&lt;another/key&gt;</Key></Object>
</Delete>
EOXML
);

behaves_like_net_amazon_s3_request 'delete multi object with more than 1_000 keys' => (
    request_class   => 'Net::Amazon::S3::Request::DeleteMultiObject',
    with_bucket     => 'some-bucket',
    with_keys       => [ 0 .. 1_000 ],

    throws          => re( qr/The maximum number of keys is 1000/ ),
);
