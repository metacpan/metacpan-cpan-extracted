#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Signer::AWSv4::S3;

my $signer = Signer::AWSv4::S3->new(
  time => Time::Piece->strptime('20130524T000000Z', '%Y%m%dT%H%M%SZ'),
  access_key => 'AKIAIOSFODNN7EXAMPLE',
  secret_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
  method => 'GET',
  key => 'test.txt',
  bucket => 'examplebucket',
  region => 'us-east-1',
  expires => 86400,
);

my $expected_canon_request = 'GET
/examplebucket/test.txt
X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host
host:s3-us-east-1.amazonaws.com

host
UNSIGNED-PAYLOAD';

cmp_ok($signer->canonical_request, 'eq', $expected_canon_request);

my $expected_string_to_sign = 'AWS4-HMAC-SHA256
20130524T000000Z
20130524/us-east-1/s3/aws4_request
3c94fcc618a24e3ce28d4518e02d9354e89ae7ee250bcea196cd84436d010c3a';

cmp_ok($signer->string_to_sign, 'eq', $expected_string_to_sign);

my $signature = '1ad7aad5bf7206f2efaa69aa2b13ae860262b6ae5c3fb895548d235852a303c9';
cmp_ok($signer->signature, 'eq', $signature);


my $expected_signed_qstring = 'X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=1ad7aad5bf7206f2efaa69aa2b13ae860262b6ae5c3fb895548d235852a303c9';
cmp_ok($signer->signed_qstring, 'eq', $expected_signed_qstring);

done_testing;
