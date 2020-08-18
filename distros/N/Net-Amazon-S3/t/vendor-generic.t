#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }

use Net::Amazon::S3;
use Net::Amazon::S3::Vendor::Generic;

plan tests => 3;

my $s3 = Net::Amazon::S3->new (
	vendor => Net::Amazon::S3::Vendor::Generic->new (
		host                 => 'my.service.local',
		use_https            => 1,
		use_virtual_host     => 1,
		authorization_method => 'Net::Amazon::S3::Signature::V4',
		default_region       => 'eu-west-42',
	),
	aws_access_key_id => 'access-key',
	aws_secret_access_key => 'secret-key',
);

it "should provide vendor data via compatible delegations",
	got    => $s3,
	expect => methods (
		host                 => 'my.service.local',
		secure               => bool (1),
		use_virtual_host     => bool (1),
		authorization_method => 'Net::Amazon::S3::Signature::V4',
	),
	;

my $bucket = $s3->bucket ('foo');

it "should return provided region as bucket's region",
	got    => $bucket,
	expect => methods (
		bucket => 'foo',
		region => 'eu-west-42',
	),
	;

had_no_warnings;
