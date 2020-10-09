
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-errors.pl" }

sub expect_error {
	my ($code, $message) = @_;

	return +(
		expect_data      => bool (0),
		expect_s3_err    => $code,
		expect_s3_errstr => $message,
	);
}

1;
