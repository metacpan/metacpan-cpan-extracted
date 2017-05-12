#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Quote::Ref' );
}

diag( "Testing Quote::Ref $Quote::Ref::VERSION, Perl $], $^X" );
