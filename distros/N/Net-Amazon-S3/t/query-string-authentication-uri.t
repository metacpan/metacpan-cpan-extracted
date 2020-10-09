
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-common.pl" }

use Test::MockTime (
	qw[ set_fixed_time ],
);

plan tests => 4;

use Shared::Examples::Net::Amazon::S3 (
	qw[ s3_api_with_signature_4 ],
	qw[ s3_api_with_signature_2 ],
	qw[ expect_net_amazon_s3_feature ],
);

set_fixed_time '2011-09-09T23:36:00Z';

expect_net_amazon_s3_feature "Signature V4 query_string_authentication_uri" => (
	feature         => 'signed_uri',
	with_s3         => s3_api_with_signature_4,
	with_bucket     => 'some-bucket',
	with_key        => 'some/key',
	with_expire_at  => time + 123_000,
	with_region     => 'eu-west-1',

	expect_uri      => 'https://some-bucket.s3-eu-west-1.amazonaws.com/some/key?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIDEXAMPLE%2F20110909%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20110909T233600Z&X-Amz-Expires=123000&X-Amz-SignedHeaders=host&X-Amz-Signature=93da6eea1ab776752fbde0d235f04e1513207a88a3cf1ff45fe4ad05505e45a1',
);

expect_net_amazon_s3_feature "Signature V4 query_string_authentication_uri" => (
	feature         => 'signed_uri',
	with_s3         => s3_api_with_signature_4,
	with_bucket     => 'some-bucket',
	with_key        => 'some/key',
	with_expire_at  => time + 123_000,
	with_region     => 'eu-west-1',
	with_method     => 'PUT',

	expect_uri      => 'https://some-bucket.s3-eu-west-1.amazonaws.com/some/key?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIDEXAMPLE%2F20110909%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20110909T233600Z&X-Amz-Expires=123000&X-Amz-SignedHeaders=host&X-Amz-Signature=f21f29a595aefde844acbdf526e2c17887738a61464f381541c9dceb7310eed8',
);

expect_net_amazon_s3_feature "Signature V2 query_string_authentication_uri" => (
	feature         => 'signed_uri',
	with_s3         => s3_api_with_signature_2,
	with_bucket     => 'some-bucket',
	with_key        => 'some/key',
	with_expire_at  => time + 123_000,
	with_region     => 'eu-west-1',

	expect_uri      => 'https://some-bucket.s3.amazonaws.com/some/key?AWSAccessKeyId=AKIDEXAMPLE&Expires=1315734360&Signature=YtOFhJwsOcNKz5xW7dF6TlrqZT0%3D',
);

had_no_warnings;

done_testing;
