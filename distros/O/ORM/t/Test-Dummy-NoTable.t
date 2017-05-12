#!/usr/bin/perl

use lib "t";
use Test::More tests => 1;

eval { require Test::Dummy::NoTable; };

ok( $@ =~ /Table 'Dummy__NoTable' for class 'Test::Dummy::NoTable' not found./, 'no_table' );
