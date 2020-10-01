#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-common.pl' }

use Net::Amazon::S3;

it "can construct Client instance with list arguments",
	got => Net::Amazon::S3::Client->new (
		s3 => Net::Amazon::S3->new (
			aws_access_key_id => 'foo',
			aws_secret_access_key => 'bar',
		),
	),
	expect => all (
		obj_isa ('Net::Amazon::S3::Client'),
		methods (s3 => all (
			obj_isa ('Net::Amazon::S3'),
			methods (aws_access_key_id => 'foo'),
			methods (aws_secret_access_key => 'bar'),
		)),
	),
	;

it "can construct Client instance with hashref arguments",
	got => Net::Amazon::S3::Client->new ({
		s3 => Net::Amazon::S3->new (
			aws_access_key_id => 'foo',
			aws_secret_access_key => 'bar',
		),
	}),
	expect => all (
		obj_isa ('Net::Amazon::S3::Client'),
		methods (s3 => all (
			obj_isa ('Net::Amazon::S3'),
			methods (aws_access_key_id => 'foo'),
			methods (aws_secret_access_key => 'bar'),
		)),
	),
	;

it "can construct Client instance with Net::Amazon::S3's list arguments",
	got => Net::Amazon::S3::Client->new (
		aws_access_key_id => 'foo',
		aws_secret_access_key => 'bar',
	),
	expect => all (
		obj_isa ('Net::Amazon::S3::Client'),
		methods (s3 => all (
			obj_isa ('Net::Amazon::S3'),
			methods (aws_access_key_id => 'foo'),
			methods (aws_secret_access_key => 'bar'),
		)),
	),
	;

it "can construct Client instance with Net::Amazon::S3's hashref arguments",
	got => Net::Amazon::S3::Client->new ({
		aws_access_key_id => 'foo',
		aws_secret_access_key => 'bar',
	}),
	expect => all (
		obj_isa ('Net::Amazon::S3::Client'),
		methods (s3 => all (
			obj_isa ('Net::Amazon::S3'),
			methods (aws_access_key_id => 'foo'),
			methods (aws_secret_access_key => 'bar'),
		)),
	),
	;

had_no_warnings;

done_testing;
