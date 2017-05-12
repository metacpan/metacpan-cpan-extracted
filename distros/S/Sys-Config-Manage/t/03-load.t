#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Config::Manage::Scripts' ) || print "Bail out!
";
}

diag( "Testing Sys::Config::Manage::Scripts $Sys::Config::Manage::Scripts::VERSION, Perl $], $^X" );
