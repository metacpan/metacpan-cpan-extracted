#!perl
# Test::Kwalitee cannot run in taint mode for whatever reason

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Only authors test the Kwalitee (except for CPANTS, of course :)
plan skip_all => 'Set TEST_AUTHOR to test the Kwalitee'
	unless $ENV{'TEST_AUTHOR'} || -e 'inc/.author';

# Required modules for this test
test_requires 'Test::Kwalitee';

# The test is automatically done on the import
# of the module. Test::Requires already imports
# the module into our namespace. We want to make
# sure this happens instead of relying on the
# side effect of Test::Requires and make sure
# we have a plan
if (Test::Builder->new->current_test == 0) {
	# No tests have been run, so assume we still need to import
	# Test::Kwalitee
	Test::Kwalitee->import;
}
