#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Orignal' ) || print "Bail out!
";
}

diag( "Testing Orignal $Orignal::VERSION, Perl $], $^X" );
