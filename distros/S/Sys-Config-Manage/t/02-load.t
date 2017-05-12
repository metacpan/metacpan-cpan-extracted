#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Config::Manage::Ownership' ) || print "Bail out!
";
}

diag( "Testing Sys::Config::Manage::Ownership $Sys::Config::Manage::Ownership::VERSION, Perl $], $^X" );
