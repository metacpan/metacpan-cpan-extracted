#!/usr/bin/perl -w

# Load testing for PPI::HTML::CodeFolder

use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 2;

# Check their perl version
ok( $] >= 5.008, "Your perl is new enough" );

# Load the modules
use_ok( 'PPI::HTML::CodeFolder'           );

exit();
