#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
require 't/object/SetSubClass.pm';


my $sd1  = SetSubClass::set( 1,2,3,4 );
my $sd2 = SetSubClass::set(3,4,5,6);

my $union = $sd1->union($sd2);
isa_ok( $union, 'SetSubClass', "union of SetSubClass with SetSubClass" );

my $intersection = $sd1->intersection($sd2);
isa_ok( $union, 'SetSubClass', "intersection of SetSubClass with SetSubClass" );

my $difference = $sd1->difference($sd2);
isa_ok( $difference, 'SetSubClass', "difference of SetSubClass with SetSubClass" );

my $invert = $sd1 / $sd2;
isa_ok( $invert, 'SetSubClass', "invert of SetSubClass with SetSubClass" );

