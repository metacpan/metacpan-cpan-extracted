#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sendmail::Queue' );
}

diag( "Testing Sendmail::Queue $Sendmail::Queue::VERSION, Perl $], $^X" );
