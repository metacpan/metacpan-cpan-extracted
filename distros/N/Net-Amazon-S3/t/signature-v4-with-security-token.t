
use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep;
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use Shared::Examples::Net::Amazon::S3::API (
    qw[ expect_api_bucket_create ],
);

use Shared::Examples::Net::Amazon::S3 (
    qw[ s3_api_with_signature_4 ],
);

expect_api_bucket_create 'create bucket using Signature 4 and session token' => (
    with_s3                 => s3_api_with_signature_4 (aws_session_token => 'security-token'),
    with_bucket             => 'some-bucket',
    expect_request          => { PUT => 'https://some-bucket.s3.amazonaws.com/' },
    expect_request_content  => '',
    expect_request_headers  => { 'x-amz-security-token' => 'security-token' },
    expect_data             => ignore,
);

had_no_warnings;
