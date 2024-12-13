#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Task::Map::Tube::Bundle') || print "Bail out!\n"; }

diag( "Testing Task::Map::Tube::Bundle $Task::Map::Tube::Bundle::VERSION, Perl $], $^X" );
