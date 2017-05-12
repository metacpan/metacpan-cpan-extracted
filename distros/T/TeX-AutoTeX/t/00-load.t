#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'TeX::AutoTeX' ) || print "Bail out!
";
}

diag( "Testing TeX::AutoTeX $TeX::AutoTeX::VERSION, Perl $], $^X" );
