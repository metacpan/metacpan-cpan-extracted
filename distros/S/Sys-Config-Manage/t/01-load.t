#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Config::Manage::Perms' ) || print "Bail out!
";
}

diag( "Testing Sys::Config::Manage::Perms $Sys::Config::Manage::Perms::VERSION, Perl $], $^X" );
