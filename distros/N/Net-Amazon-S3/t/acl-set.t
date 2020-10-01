#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }

subtest "Canned ACL" => sub {
	use Net::Amazon::S3::ACL::Canned;

	my %plan = (
		AUTHENTICATED_READ          => 'authenticated-read',
		PRIVATE                     => 'private',
		AWS_EXEC_READ               => 'aws-exec-read',
		BUCKET_OWNER_FULL_CONTROL   => 'bucket-owner-full-control',
		BUCKET_OWNER_READ           => 'bucket-owner-read',
		LOG_DELIVERY_WRITE          => 'log-delivery-write',
		PUBLIC_READ                 => 'public-read',
		PUBLIC_READ_WRITE           => 'public-read-write',
	);

	plan tests => 8 * 2;

	for my $key (sort keys %plan) {
		cmp_deeply "Canned ACL builder $key should return instance of Net::Amazon::S3::ACL::Canned" => (
			got    => Net::Amazon::S3::ACL::Canned->$key,
			expect => obj_isa ('Net::Amazon::S3::ACL::Canned'),
		);

		cmp_deeply "Canned ACL builder $key should provide HTTP headers" => (
			got    => { Net::Amazon::S3::ACL::Canned->$key->build_headers },
			expect => { 'x-amz-acl' => $plan{$key} },
		);
	}

	done_testing;
};

subtest "Explicit ACL" => sub {
	use Net::Amazon::S3::ACL::Set;

	my $acl = Net::Amazon::S3::ACL::Set->new
		->grant_full_control (id => 123)
		->grant_read         (id => 234, Net::Amazon::S3::ACL::Grantee::Group->ALL_USERS)
		->grant_write        (email => 'foo@bar.baz', Net::Amazon::S3::ACL::Grantee::Group->LOG_DELIVERY)
		->grant_write        (id => 345, id => 456),
		;

	cmp_deeply "ACL set should format as HTTP headers",
		got => { $acl->build_headers },
		expect => {
			'x-amz-grant-full-control' => q[id="123"],
			'x-amz-grant-read'         => q[id="234", uri="http://acs.amazonaws.com/groups/global/AllUsers"],
			'x-amz-grant-write'        => q[emailAddress="foo@bar.baz", uri="http://acs.amazonaws.com/groups/s3/LogDelivery", id="345", id="456"],
		},
		;

	done_testing;
};


had_no_warnings;

done_testing;
