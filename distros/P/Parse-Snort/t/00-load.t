#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::Snort' );
}

diag( "Testing Parse::Snort $Parse::Snort::VERSION, Perl $], $^X" );
