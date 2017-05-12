#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

# Autoflush ON
local $| = 1;

# Test _use_
use_ok('String::Range::Expand')
  || BAIL_OUT('Failed to load String::Range::Expand');

# Done
done_testing();
exit 0;
