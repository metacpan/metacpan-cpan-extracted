#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RRDTool::Creator' );
}

diag( "Testing RRDTool::Creator $RRDTool::Creator::VERSION, Perl $], $^X" );
