#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }

use Scalar::Util;

plan tests => 6;

sub build_bucket;
sub test_method_bucket;

SKIP:
{
	require_ok ('Net::Amazon::S3') or skip "Cannot load module", 2;

	test_method_bucket
		"bucket (STRING) should return respective bucket object",
		build_bucket ('foo'),
		obj_isa ('Net::Amazon::S3::Bucket'),
		methods (bucket => 'foo'),
		;

	test_method_bucket
		"bucket (bucket => STRING) should return respective bucket object",
		build_bucket (bucket => 'foo'),
		obj_isa ('Net::Amazon::S3::Bucket'),
		methods (bucket => 'foo'),
		;

	test_method_bucket
		"bucket (STRING, region => STRING) should return respective bucket object",
		build_bucket ('foo', region => 'bar'),
		obj_isa ('Net::Amazon::S3::Bucket'),
		methods (bucket => 'foo', region =>'bar'),
		;

	my $bar = build_bucket ('bar');
	test_method_bucket
		"bucket (Instance) should return its argument",
		scalar build_bucket ($bar),
		obj_isa ('Net::Amazon::S3::Bucket'),
		methods (bucket => 'bar'),
		code (sub {
			return 1 if Scalar::Util::refaddr ($_[0]) == Scalar::Util::refaddr ($bar);
			return 0, "Object is has different address"
		}),
		;
}

had_no_warnings;

done_testing;

sub build_bucket {
	my $s3 = bless {}, 'Net::Amazon::S3';

	$s3->bucket (@_);
}

sub test_method_bucket {
	my ($title, $bucket, @plan) = @_;

	it $title, got => $bucket, expect => all (@plan);
}

