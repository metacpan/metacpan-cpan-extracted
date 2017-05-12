#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Test::CSS') || print "Bail out!\n"; }

diag( "Testing Test::CSS $Test::CSS::VERSION, Perl $], $^X" );
