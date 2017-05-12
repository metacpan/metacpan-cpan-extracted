#!perl
# Test::CleanNamespaces cannot run in taint mode for whatever reason

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Only authors get to run this test
plan skip_all => 'Set TEST_AUTHOR to enable this test'
	unless $ENV{'TEST_AUTHOR'} || -e 'inc/.author';

# Required modules for this test
test_requires 'Test::CleanNamespaces';

# Run tests
all_namespaces_clean();

