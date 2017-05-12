#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sub::Frequency' ) || print "Bail out!
";
}

diag( "Testing Sub::Frequency $Sub::Frequency::VERSION, Perl $], $^X" );
