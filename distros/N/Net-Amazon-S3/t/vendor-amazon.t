#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }

use Net::Amazon::S3;
use Net::Amazon::S3::Vendor;

use Test::LWP::UserAgent;

plan tests => 3;

my $s3 = Net::Amazon::S3->new (
	vendor => Net::Amazon::S3::Vendor::Amazon->new (
		default_region       => 'eu-west-42',
	),
	aws_access_key_id => 'access-key',
	aws_secret_access_key => 'secret-key',
);

it "should provide vendor data via compatible delegations",
	got    => $s3,
	expect => methods (
		host                 => 's3.amazonaws.com',
		secure               => bool (1),
		use_virtual_host     => bool (1),
		authorization_method => 'Net::Amazon::S3::Signature::V4',
	),
	;

my $bucket = $s3->bucket ('foo');

$s3->ua (Test::LWP::UserAgent->new (network_fallback => 0));
$s3->ua->map_response (
	sub { $_[0]->method eq 'HEAD' },
	HTTP::Response->new (200 => 'OK', ['x-amz-bucket-region' => 'us-east-7']),
);

it "should perform HEAD request on bucket to fetch its region",
	got    => $bucket,
	expect => methods (
		bucket => 'foo',
		region => 'us-east-7',
	),
	;

had_no_warnings;
