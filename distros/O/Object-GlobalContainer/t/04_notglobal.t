#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer;


use Test::More tests => 4;


my $OC1 = Object::GlobalContainer->new();
my $OC2 = Object::GlobalContainer->new( notglobal => 1 );


$OC1->set('abc','123');
$OC1->set('first/second/third','456');

$OC2->set('abc','222');
$OC2->set('first/second/third','221');




is( $OC1->get('abc') , '123' ,                 "data in at place, store 1" );
is( $OC1->get('first/second/third') , '456' ,  "data in at place, store 1" );

is( $OC2->get('abc') , '222' ,                 "data in at place, store 2" );
is( $OC2->get('first/second/third') , '221' ,  "data in at place, store 2" );




1;
