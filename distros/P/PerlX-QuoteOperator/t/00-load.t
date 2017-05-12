#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PerlX::QuoteOperator' );
}

diag( "Testing PerlX::QuoteOperator $PerlX::QuoteOperator::VERSION, Perl $], $^X" );
