#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tenjin' ) || print "Bail out!
";
}

diag( "Testing Tenjin $Tenjin::VERSION, Perl $], $^X" );
