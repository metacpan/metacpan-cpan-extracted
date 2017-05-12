#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::Facter' ) || print "Bail out!
";
}

diag( "Testing Sys::Facter $Sys::Facter::VERSION, Perl $], $^X" );
