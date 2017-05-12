#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Net::Route' );
    use_ok( 'Net::Route::Table' );
}

diag( "Testing Net::Route $Net::Route::VERSION, Perl $], $^X" );
