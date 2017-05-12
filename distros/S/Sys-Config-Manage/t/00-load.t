#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Config::Manage' ) || print "Bail out!
";
}

diag( "Testing Sys::Config::Manage $Sys::Config::Manage::VERSION, Perl $], $^X" );
