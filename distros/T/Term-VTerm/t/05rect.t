#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Term::VTerm;

my $rect = Term::VTerm::Rect->new( start_row => 10, end_row => 15, start_col => 20, end_col => 40 );

isa_ok( $rect, "Term::VTerm::Rect", '$rect' );

is( $rect->start_row, 10, '$rect->start_row' );
is( $rect->end_row,   15, '$rect->end_row' );
is( $rect->start_col, 20, '$rect->start_col' );
is( $rect->end_col,   40, '$rect->end_col' );

done_testing;
