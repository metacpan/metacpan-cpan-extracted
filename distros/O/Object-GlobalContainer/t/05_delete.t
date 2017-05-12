#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer;


use Test::More tests => 4;


my $OC1 = Object::GlobalContainer->new();




$OC1->set('abc','123');
$OC1->set('first/second/third','456');

is(  $OC1->{'STORE'}->{'default'}->{'first'}->{'second'}->{'third'}, 456, "data exists, store 1" );
is(  $OC1->{'STORE'}->{'default'}->{'abc'}, 123, "data exists, store 1" );

$OC1->delete('abc');
$OC1->delete('first/second/third');



ok( ! exists $OC1->{'STORE'}->{'default'}->{'first'}->{'second'}->{'third'}, "data deleted, store 1" );
ok( ! exists $OC1->{'STORE'}->{'default'}->{'abc'}, "data deleted, store 1" );





1;
