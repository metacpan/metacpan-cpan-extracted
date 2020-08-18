#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }

use Net::Amazon::S3;

plan tests => 3;

subtest "by default it should expect Amazon AWS" => sub {
	my $s3 = Net::Amazon::S3->new (
		aws_access_key_id => 'access-key',
		aws_secret_access_key => 'secret-key',
	);

	it "should point to Amazon AWS",
		got    => $s3->host,
		expect => 's3.amazonaws.com',
		;

	it "should use Signature 4 authentication",
		got    => $s3->authorization_method,
		expect => 'Net::Amazon::S3::Signature::V4',
		;

	it "should use secure communication",
		got    => $s3->secure,
		expect => bool (1),
		;

	it "should use virtual-host-style addressing model",
		got    => $s3->use_virtual_host,
		expect => bool (1),
		;

	it "should build vendor class instance",
		got    => $s3->vendor,
		expect => all (
			obj_isa ('Net::Amazon::S3::Vendor::Amazon'),
			methods (
				host => 's3.amazonaws.com',
				use_virtual_host => bool (1),
				use_https        => bool (1),
				authorization_method => 'Net::Amazon::S3::Signature::V4',
			),
		),
		;
};

subtest "except of Amazon AWS default signature method is still V2" => sub {
	my $s3 = Net::Amazon::S3->new (
		aws_access_key_id => 'access-key',
		aws_secret_access_key => 'secret-key',
		host => 'my.service.local',
	);

	it "should point user provided host",
		got    => $s3->host,
		expect => 'my.service.local',
		;

	it "should use Signature 2 authentication",
		got    => $s3->authorization_method,
		expect => 'Net::Amazon::S3::Signature::V2',
		;

	it "should use secure communication",
		got    => $s3->secure,
		expect => bool (1),
		;

	it "should use path-style addressing model",
		got    => $s3->use_virtual_host,
		expect => bool (0),
		;

	it "should build vendor class instance",
		got    => $s3->vendor,
		expect => all (
			obj_isa ('Net::Amazon::S3::Vendor'),
			methods (
				host => 'my.service.local',
				use_virtual_host => bool (0),
				use_https        => bool (1),
				authorization_method => 'Net::Amazon::S3::Signature::V2',
			),
		),
		;
};


had_no_warnings;
