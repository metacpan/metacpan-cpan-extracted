#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-s3-request.pl" }

plan tests => 2;

behaves_like_net_amazon_s3_request 'restore object' => (
    request_class   => 'Net::Amazon::S3::Operation::Object::Restore::Request',
    with_bucket     => 'some-bucket',
    with_key        => 'some-key',
	with_days       => 21,
	with_tier       => 'Standard',

    expect_request_method   => 'POST',
    expect_request_uri      => 'https://some-bucket.s3.amazonaws.com/some-key?restore',
    expect_request_content  => <<EOXML
<RestoreRequest xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
   <Days>21</Days>
   <GlacierJobParameters>
      <Tier>Standard</Tier>
   </GlacierJobParameters>
</RestoreRequest>
EOXML
);

had_no_warnings;

done_testing;
