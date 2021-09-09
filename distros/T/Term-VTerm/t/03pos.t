#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Term::VTerm::Pos;

my $pos = Term::VTerm::Pos->new( row => 10, col => 20 );

isa_ok( $pos, "Term::VTerm::Pos", '$pos' );

is( $pos->row, 10, '$pos->row' );
is( $pos->col, 20, '$pos->col' );

done_testing;
