#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'String::Escape' ) || print "Bail out!
";
}

diag( "Testing String::Escape $String::Escape::VERSION, Perl $], $^X" );
