#!/usr/bin/perl

use Test::More tests => 1;

use lib qw( lib ../lib );

BEGIN {
	use_ok( 'Pod::POM::View::TOC' );
}

diag( "Testing Pod::POM::View::TOC $Pod::POM::View::TOC::VERSION, Perl $], $^X" );
