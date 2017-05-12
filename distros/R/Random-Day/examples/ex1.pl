#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Random::Day;

# Object.
my $obj = Random::Day->new;

# Get date.
my $dt = $obj->get;

# Print out.
print $dt->ymd."\n";

# Output like:
# \d\d\d\d-\d\d-\d\d