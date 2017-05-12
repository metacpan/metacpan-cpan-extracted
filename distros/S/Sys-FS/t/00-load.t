#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::FS' ) || print "Bail out!
";
}

diag( "Testing Sys::FS $Sys::FS::VERSION, Perl $], $^X" );
