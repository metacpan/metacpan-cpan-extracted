#!/usr/bin/perl

# Test that our files are portable across systems.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Portability::Files 0.05',
);

# Load the testing modules
use Test::More;

plan( skip_all => "Test::Portability::Files is buggy at the moment." );
exit(0);

foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

options(
	test_one_dot => 0, # Will fail test_one_dot deliberately.
	test_amiga_length => 1,
	test_ansi_chars => 1,
	test_case => 1,
	test_dos_length => 0,
	test_mac_length => 1,
	test_space => 1,
	test_special_chars => 1,
	test_symlink => 1,
	test_vms_length => 1,
);
run_tests();
