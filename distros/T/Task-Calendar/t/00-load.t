#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Task::Calendar') || print "Bail out!\n"; }

diag( "Testing Task::Calendar $Task::Calendar::VERSION, Perl $], $^X" );
