#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer;


use Test::More tests => 4;


my $OC = Object::GlobalContainer->new();

my $storename = $OC->storename;

$OC->set('abc','123');
$OC->set('first/second/third','456');

is( $OC->{'STORE'}->{$storename}->{'first'}->{'second'}->{'third'} , '456' ,  "data in at place" );

is( $OC->{'STORE'}->{$storename}->{'abc'} , '123' ,  "data in at place" );



is( $OC->get('abc') , '123' ,  "data in at place" );
is( $OC->get('first/second/third') , '456' ,  "data in at place" );




1;
