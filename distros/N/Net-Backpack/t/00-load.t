#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Net::Backpack') || print "Bail out!\n"; }

diag( "Testing Net::Backpack $Net::Backpack::VERSION, Perl $], $^X" );
