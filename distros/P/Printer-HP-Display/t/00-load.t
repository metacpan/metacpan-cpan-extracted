#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Printer::HP::Display' ) || print "Bail out!
";
}

diag( "Testing Printer::HP::Display $Printer::HP::Display::VERSION, Perl $], $^X" );
