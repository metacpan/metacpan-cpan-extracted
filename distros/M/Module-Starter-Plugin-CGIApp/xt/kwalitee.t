#!/usr/bin/perl

# Check distribution for Kwalitee
use Test::More;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Test::Kwalitee tests => [ qw( -has_test_pod -has_test_pod_coverage ) ]',
);


# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		plan( skip_all => "$MODULE not available for testing" );
	}
}

END {
    if ( -f 'Debian_CPANTS.txt') {
        unlink 'Debian_CPANTS.txt' or die "$!\n";
    }
}

1;

