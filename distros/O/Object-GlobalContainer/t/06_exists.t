#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer;


use Test::More tests => 7;


my $OC1 = Object::GlobalContainer->new();




$OC1->set('abc','123');
$OC1->set('first/second/third','456');

is(  $OC1->{'STORE'}->{'default'}->{'first'}->{'second'}->{'third'}, 456, "data exists, store 1" );
is(  $OC1->{'STORE'}->{'default'}->{'abc'}, 123, "data exists, store 1" );

ok( $OC1->exists('first/second/third'), "data exists, store 1" );

ok( !$OC1->exists('first/second/third-foo'), "foo data does not exist, store 1" );
ok( !$OC1->exists('abc-foo'), "foo data does not exist, store 1" );


$OC1->delete('abc');
$OC1->delete('first/second/third');



ok( !$OC1->exists('first/second/third'), "data does not exist, store 1" );
ok( !$OC1->exists('abc'), "data does not exist, store 1" );




1;
