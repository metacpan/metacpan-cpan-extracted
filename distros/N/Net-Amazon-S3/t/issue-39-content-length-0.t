
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-s3-api.pl" }

use Shared::Examples::Net::Amazon::S3::API qw[ expect_api_bucket_acl_set ];

plan tests => 2;

expect_api_bucket_acl_set 'request without content should set content-length => 0' => (
	with_bucket             => 'some-bucket',
	with_acl_short          => 'private',
	with_response_fixture ('response::acl'),
	expect_request_headers  => {
		content_length => 0,
	},
	expect_data             => bool (1),
);

had_no_warnings;

done_testing;
