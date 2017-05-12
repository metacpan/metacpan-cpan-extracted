#!/usr/bin/perl -w

# Load testing for Module::Mapper

use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 1;

# Load the modules
use_ok( 'Module::Mapper'           );
