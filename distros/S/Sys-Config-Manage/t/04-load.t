#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Config::Manage::Remove' ) || print "Bail out!
";
}

diag( "Testing Sys::Config::Manage::Remove $Sys::Config::Manage::Remove::VERSION, Perl $], $^X" );
