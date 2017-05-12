#!perl -T

use 5.008;
use strict;
use warnings;

use Test::More;
use Test::Requires 0.02;

# Only authors test POD
plan skip_all => 'Set TEST_AUTHOR to enable this test'
	unless $ENV{'TEST_AUTHOR'} || -e 'inc/.author';

# Required modules for this test
test_requires 'Test::Pod' => '1.22';

# Add this here to fool the Kwalitee for the time being
eval { require Test::Pod; };

# Test the POD files
all_pod_files_ok();

