#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PerlIO::via::Logger' );
}

#diag( "Testing PerlIO::via::Logger $PerlIO::via::Logger::VERSION, Perl $], $^X" );
