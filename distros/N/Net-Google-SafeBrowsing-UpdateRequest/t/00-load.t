#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Google::SafeBrowsing::UpdateRequest' );
}

diag( "Testing Net::Google::SafeBrowsing::UpdateRequest $Net::Google::SafeBrowsing::UpdateRequest::VERSION, Perl $], $^X" );
