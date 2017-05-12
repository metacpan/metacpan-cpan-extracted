#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'TSQL::Common::Regexp' ) || print "Bail out!\n";
}

diag( "Testing TSQL::Common::Regexp $TSQL::Common::Regexp::VERSION, Perl $], $^X" );
