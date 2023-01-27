#!/usr/bin/env perl

use strict;
use warnings;

use Random::Day::InThePast;

# Object.
my $obj = Random::Day::InThePast->new;

# Get date.
my $dt = $obj->get;

# Print out.
print $dt->ymd."\n";

# Output like:
# \d\d\d\d-\d\d-\d\d