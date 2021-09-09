#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Term::VTerm;

my $vt = Term::VTerm->new( cols => 80, rows => 25 );

isa_ok( $vt, "Term::VTerm", '$vt' );

is_deeply( [ $vt->get_size ], [ 25, 80 ],
   '$vt->get_size' );

$vt->set_size( 30, 100 );

is_deeply( [ $vt->get_size ], [ 30, 100 ],
   '$vt->get_size after ->set_size' );

done_testing;
