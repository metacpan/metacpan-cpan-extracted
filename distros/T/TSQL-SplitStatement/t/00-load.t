#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'TSQL::SplitStatement' ) || print "Bail out!\n";
}

diag( "Testing TSQL::SplitStatement $TSQL::SplitStatement::VERSION, Perl $], $^X" );
