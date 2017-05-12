#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pod::POM::View::Confluence' );
}

diag( "Testing Pod::POM::View::Confluence $Pod::POM::View::Confluence::VERSION, Perl $], $^X" );
