#!perl 

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::MediaWikiDump' );
}

diag( "Testing Parse::MediaWikiDump $Parse::MediaWikiDump::VERSION, Perl $], $^X" );
