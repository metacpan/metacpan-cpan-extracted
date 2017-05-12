#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Run' ) || print "Bail out!
";
}

diag( "Testing Sys::Run $Sys::Run::VERSION, Perl $], $^X" );
