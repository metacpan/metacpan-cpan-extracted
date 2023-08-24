#!/usr/bin/env perl

use strict;
use warnings;

use Random::AcademicTitle::CZ;

# Object.
my $obj = Random::AcademicTitle::CZ->new;

# Get titles.
my $title_after = $obj->random_title_after;
my $title_before = $obj->random_title_before;

# Print out.
print "Title before: $title_before\n";
print "Title after: $title_after\n";

# Output like:
# TODO