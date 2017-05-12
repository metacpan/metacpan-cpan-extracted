#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Number::Phone::AU' ) || print "Bail out!
";
}

diag( "Testing Number::Phone::AU $Number::Phone::AU::VERSION, Perl $], $^X" );
