use strict;

package Salvation::_t01_00::System;

use Moose;

extends 'Salvation::System';

no Moose;

package main;

use Test::More tests => 2;

my $o = new_ok( 'Salvation::_t01_00::System' );

isa_ok( $o, 'Salvation::System' );

