#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MultiThread' );
}

diag( "Testing MultiThread $MultiThread::VERSION, Perl $], $^X" );
