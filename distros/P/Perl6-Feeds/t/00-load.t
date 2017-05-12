#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Perl6::Feeds' );
}

diag( "Testing Perl6::Feeds $Perl6::Feeds::VERSION, Perl $], $^X" );
