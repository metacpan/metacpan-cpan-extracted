
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require "test-helper-common.pl" }
BEGIN { require "test-helper-errors.pl" }

use HTTP::Status qw[ HTTP_OK ];

use Shared::Examples::Net::Amazon::S3::Client (
	qw[ fixture ],
	qw[ with_response_fixture ],
);

use Shared::Examples::Net::Amazon::S3 (
	qw[ s3_api_with_signature_2 ],
);

sub expect_error {
	my ($code, $message) = @_;

	+( throws => qr/^${code}: $message/ );
}

1;
