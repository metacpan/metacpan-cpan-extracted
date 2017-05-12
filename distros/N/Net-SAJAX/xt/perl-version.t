#!perl
# This uses default File::Find, so chdir won't
# work in taint mode

use 5.008;
use strict;
use warnings;

use Test::More;
use Test::Requires 0.02;

# Only authors test this
plan skip_all => 'Set TEST_AUTHOR to enable this test'
	unless $ENV{'TEST_AUTHOR'} || -e 'inc/.author';

# Required modules for this test
test_requires 'Test::MinimumVersion' => '0.009';

# Test
all_minimum_version_from_metayml_ok();

