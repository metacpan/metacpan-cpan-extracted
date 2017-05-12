#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Google::PicasaWeb' );
}

diag( "Testing Net::Google::PicasaWeb $Net::Google::PicasaWeb::VERSION, Perl $], $^X" );
