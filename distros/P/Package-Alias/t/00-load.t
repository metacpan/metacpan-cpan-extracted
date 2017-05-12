#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Package::Alias' ) || print "Bail out!
";
}

diag( "Testing Package::Alias $Package::Alias::VERSION, Perl $], $^X" );
