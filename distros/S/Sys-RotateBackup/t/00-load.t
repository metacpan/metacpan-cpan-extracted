#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::RotateBackup' ) || print "Bail out!
";
}

diag( "Testing Sys::RotateBackup $Sys::RotateBackup::VERSION, Perl $], $^X" );
