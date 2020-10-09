
use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-common.pl" }

use Test::MockTime qw[ set_fixed_time ];

use Sub::Override;

use Shared::Examples::Net::Amazon::S3 (
	qw[ s3_api_with_signature_4 ],
	qw[ expect_net_amazon_s3_feature ],
);

plan tests => 3;

set_fixed_time '2011-09-09T23:36:00Z';

my $orig = \& Net::Amazon::S3::Signature::V4Implementation::_canonical_request;
my $cannonical_request;
my $guard = Sub::Override->new ('Net::Amazon::S3::Signature::V4Implementation::_canonical_request' => sub {
	my ($self, @params) = @_;
	$cannonical_request = $self->$orig (@params);
});

expect_net_amazon_s3_feature "Signature V4 query_string_authentication_uri with non-standard port" => (
	feature         => 'signed_uri',
	with_s3         => s3_api_with_signature_4 (host => 'foo:9999'),
	with_bucket     => 'some-bucket',
	with_key        => 'some/key',
	with_expire_at  => time + 123_000,
	with_region     => 'eu-west-1',

	expect_uri      => 'https://some-bucket.foo:9999/some/key?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIDEXAMPLE%2F20110909%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20110909T233600Z&X-Amz-Expires=123000&X-Amz-SignedHeaders=host&X-Amz-Signature=96068503a7efe97b987532326fa52fc75c643c65dc605734450fe573b18155ea',
);

ok "Cannonical request should include non-standard port in host header",
	got => $cannonical_request =~ m/^host:some-bucket.foo:9999/m,
	;

had_no_warnings;

done_testing;
