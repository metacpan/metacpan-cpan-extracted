#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Object::GlobalContainer;


use Test::More tests => 3;


my $OC = Object::GlobalContainer->new();

my $storename = $OC->storename;

$OC->set('abc/def','123');
$OC->set('abc/bar','66');


my $h = { 'def' => '456',
          'foo' => '777',
        };

 $OC->merge('abc',$h);


 is( $OC->get('abc')->{'def'} , '456' ,  "data at place" );
 is( $OC->get('abc')->{'foo'} , '777' ,  "data at place" );
 is( $OC->get('abc')->{'bar'} , '66' ,  "data at place" );
 



1;
