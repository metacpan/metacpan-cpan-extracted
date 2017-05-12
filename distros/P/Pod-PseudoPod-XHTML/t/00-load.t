#!perl

use Test::More tests => 1;

BEGIN { use_ok( 'Pod::PseudoPod::XHTML' ) || print "Bail out!\n" }

diag( "Testing Pod::PseudoPod::XHTML $Pod::PseudoPod::XHTML::VERSION, Perl $], $^X" );
