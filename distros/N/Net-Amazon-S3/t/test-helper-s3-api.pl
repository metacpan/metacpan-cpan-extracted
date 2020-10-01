
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }
BEGIN { require "test-helper-errors.pl" }

use HTTP::Status qw[ HTTP_OK ];

use Net::Amazon::S3::Constants;
use Net::Amazon::S3::ACL::Canned;

use Shared::Examples::Net::Amazon::S3::Client (
    qw[ fixture ],
    qw[ with_response_fixture ],
);

use Shared::Examples::Net::Amazon::S3 (
    qw[ s3_api_with_signature_2 ],
);

sub expect_error {
	my ($code, $message) = @_;

	return +(
		expect_data      => bool (0),
		expect_s3_err    => $code,
		expect_s3_errstr => $message,
	);
}

1;
