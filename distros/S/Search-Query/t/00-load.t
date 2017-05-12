#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::Query' );
}

diag( "Testing Search::Query $Search::Query::VERSION, Perl $], $^X" );
