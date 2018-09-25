#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Signer::AWSv4::RDS;

my $signer = Signer::AWSv4::RDS->new(
  time => Time::Piece->strptime('20180722T202236Z', '%Y%m%dT%H%M%SZ'),
  access_key => 'AKIAKIAKIAKIAKIAKIAK',
  secret_key => '1111111111111111111111111111111111111111',

  host => 'mydb.c1fycpveg7nf.us-west-2.rds.amazonaws.com',
  user => 'mysqluser',

  region => 'eu-west-1',
);

my $expected_canon_request = 'GET
/
Action=connect&DBUser=mysqluser&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAKIAKIAKIAKIAKIAK%2F20180722%2Feu-west-1%2Frds-db%2Faws4_request&X-Amz-Date=20180722T202236Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host
host:mydb.c1fycpveg7nf.us-west-2.rds.amazonaws.com:3306

host
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

cmp_ok($signer->canonical_request, 'eq', $expected_canon_request);

my $expected_string_to_sign = 'AWS4-HMAC-SHA256
20180722T202236Z
20180722/eu-west-1/rds-db/aws4_request
3cc087a8945870ff5cb2a6b0ab4c5b7436e02d794b0cca9deab86a7fc76d5e52';

cmp_ok($signer->string_to_sign, 'eq', $expected_string_to_sign);

my $signature = 'b77c366f1379046852039d21f733035fa73696275c03dd2908ef267c3049d831';
cmp_ok($signer->signature, 'eq', $signature);

my $expected_signed_qstring = 'Action=connect&DBUser=mysqluser&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAKIAKIAKIAKIAKIAK%2F20180722%2Feu-west-1%2Frds-db%2Faws4_request&X-Amz-Date=20180722T202236Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=b77c366f1379046852039d21f733035fa73696275c03dd2908ef267c3049d831';
cmp_ok($signer->signed_qstring, 'eq', $expected_signed_qstring);

done_testing;
