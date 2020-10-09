
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-errors.pl" }

no warnings 'redefine';

sub expect_s3_error_access_denied {
	return +(
		throws           => qr/Net::Amazon::S3: Amazon responded with 403 Forbidden/,
		expect_s3_err    => 'network_error',
		expect_s3_errstr => '403 Forbidden',
	);
}

sub expect_s3_error_invalid_object_state {
	return +(
		throws           => qr/Net::Amazon::S3: Amazon responded with 403 Forbidden/,
		expect_s3_err    => 'network_error',
		expect_s3_errstr => '403 Forbidden',
	);
}

sub expect_s3_error_bucket_not_found {
	return +(
		expect_data      => undef,
		expect_s3_err    => undef,
		expect_s3_errstr => undef,
	);
}

sub expect_s3_error_object_not_found {
	return +(
		expect_data      => undef,
		expect_s3_err    => undef,
		expect_s3_errstr => undef,
	);
}

sub expect_http_error_bad_request {
	return +(
		throws           => qr/Net::Amazon::S3: Amazon responded with 400 Bad Request/,
		expect_s3_err    => 'network_error',
		expect_s3_errstr => '400 Bad Request',
	);
}

1;
