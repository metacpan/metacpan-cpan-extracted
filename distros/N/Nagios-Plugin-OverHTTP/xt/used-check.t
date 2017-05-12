#!perl

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Required modules for this test
test_requires 'Test::Module::Used' => '0.1.9';

# Test that used in Makefile.PL, META.yml, and files all match
Test::Module::Used->new->ok;
