#!/usr/bin/perl

# Test the basic loading, initialisation, etc for SMS::Send.
# Don't actually send anything yet.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use SMS::Send;
use Params::Util ':ALL';





#####################################################################
# Driver Detection

# Check for available drivers
my @drivers = SMS::Send->installed_drivers;

# Should contain our two test drivers
ok( scalar(@drivers) >= 2, 'Found at least 2 drivers' );
ok( scalar(grep { $_ eq 'Test' } @drivers) == 1, 'Found "Test" driver' );
ok( scalar(grep { $_ eq 'AU::Test' } @drivers) == 1, 'Found "AU::Test" driver' );

# In detecting these drivers, they should NOT be loaded
ok( ! defined $SMS::Send::Test::VERSION,
	'Did not load drivers when locating them' );
