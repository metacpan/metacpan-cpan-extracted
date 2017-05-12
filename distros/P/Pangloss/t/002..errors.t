#!/usr/bin/perl

##
## Tests for Pangloss::Error
##

use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Error qw( :try );
BEGIN { use_ok("Pangloss::Error") }
isa_ok( new Pangloss::Error, 'Pangloss::Error', 'new' );
