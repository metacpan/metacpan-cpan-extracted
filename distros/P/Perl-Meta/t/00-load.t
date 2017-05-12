#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Perl::Meta' ) || print "Bail out!
";
}

diag( "Testing Perl::Meta $Perl::Meta::VERSION, Perl $], $^X" );
