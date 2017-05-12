#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RRD::CGI::Image' );
}

diag( "Testing RRD::CGI::Image $RRD::CGI::Image::VERSION, Perl $], $^X" );
