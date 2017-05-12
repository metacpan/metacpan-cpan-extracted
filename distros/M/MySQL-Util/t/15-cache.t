#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

use lib '..';

BEGIN { use_ok('MySQL::Util::Data::Cache'); }

# Create some variables with which to test the MySQL::Util::Data::Cache objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)

# And now to test the methods/subroutines.

