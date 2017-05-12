#!/usr/local/bin/perl -sw

use strict ;
use Test::More tests => 2 ;

use Sort::Maker ;

my $sorter = make_sorter( name => 'sort_func', 'plain', number => 1 ) ;

#print "$@\n" unless $sorter ;

my @input = ( 10, 3, 40, 18 ) ;

my @sorted = sort_func( @input ) ;

ok( 1, 'sort name export' ) ;

my $ok = eq_array( \@input, \@sorted ) ;

ok( $ok, 'sort number' ) ;

exit ;
