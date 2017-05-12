#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer;


use Test::More tests => 5;


my $OC = Object::GlobalContainer->new();

my $storename = $OC->storename;

$OC->add('abc-arr','123');
$OC->add('abc-arr','89');
$OC->add('first/second/third-arr','456');


is( $OC->{'STORE'}->{$storename}->{'first'}->{'second'}->{'third-arr'}->[0] , '456' ,  "data in at place" );

is( $OC->{'STORE'}->{$storename}->{'abc-arr'}->[0] , '123' ,  "data in at place" );
is( $OC->{'STORE'}->{$storename}->{'abc-arr'}->[1] , '89' ,  "data in at place" );



is( $OC->get('abc-arr')->[0] , '123' ,  "data in at place" );
is( $OC->get('first/second/third-arr')->[0] , '456' ,  "data in at place" );
 



1;
