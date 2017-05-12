#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::PJLink' ) || print "Bail out!
";
}

diag( "Testing Net::PJLink $Net::PJLink::VERSION, Perl $], $^X" );
