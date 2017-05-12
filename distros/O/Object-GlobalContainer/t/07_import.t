#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer 'objcon';


use Test::More tests => 6;


my $OC = Object::GlobalContainer->new();

my $storename = $OC->storename;


$OC->set('abc','123a');
$OC->set('first/second/third','456a');

objcon->set('abc','123');
objcon->set('first/second/third','456');

is( objcon->{'STORE'}->{$storename}->{'first'}->{'second'}->{'third'} , '456' ,  "data at place" );

is( objcon->{'STORE'}->{$storename}->{'abc'} , '123' ,  "data at place" );

is( $OC->{'STORE'}->{$storename}->{'first'}->{'second'}->{'third'} , '456' ,  "data at place" );

is( $OC->{'STORE'}->{$storename}->{'abc'} , '123' ,  "data at place" );



is( objcon->get('abc') , '123' ,  "data at place" );
is( objcon->get('first/second/third') , '456' ,  "data at place" );



1;
