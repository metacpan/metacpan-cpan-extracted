#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Pod::Section' ) || print "Bail out!
";
}

diag( "Testing Pod::Section $Pod::Section::VERSION, Perl $], $^X" );
