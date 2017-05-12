#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer;


use Test::More tests => 6;


my $OC1 = Object::GlobalContainer->new();
my $OC2 = Object::GlobalContainer->new();


$OC1->set('abc','123');
$OC2->set('first/second/third','456');


my $OC3 = Object::GlobalContainer->new();


is( $OC1->get('abc') , '123' ,                 "data in at place, store 1" );
is( $OC1->get('first/second/third') , '456' ,  "data in at place, store 1" );

is( $OC2->get('abc') , '123' ,                 "data in at place, store 2" );
is( $OC2->get('first/second/third') , '456' ,  "data in at place, store 2" );

is( $OC3->get('abc') , '123' ,                 "data in at place, store 3" );
is( $OC3->get('first/second/third') , '456' ,  "data in at place, store 3" );




1;
