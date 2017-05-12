#!/usr/bin/perl

# Load testing for Object::Destroyer

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 2;

use_ok( 'Object::Destroyer' );
use_ok( 'Object::Destroyer' => 2.01 );
