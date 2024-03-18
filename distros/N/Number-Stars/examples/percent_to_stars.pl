#!/usr/bin/env perl

use strict;
use warnings;

use Number::Stars;
use Data::Printer;

if (@ARGV < 1) {
       print STDERR "Usage: $0 percent\n";
       exit 1;
}
my $percent = $ARGV[0];

# Object.
my $obj = Number::Stars->new;

# Get structure.
my $stars_hr = $obj->percent_stars($percent);

# Print out.
print "Percent: $percent\n";
print "Output structure:\n";
p $stars_hr;

# Output for run without arguments:
# Usage: __SCRIPT__ percent

# Output for value '55':
# Percent: 55
# Output structure:
# \ {
#     1    "full",
#     2    "full",
#     3    "full",
#     4    "full",
#     5    "full",
#     6    "half",
#     7    "nothing",
#     8    "nothing",
#     9    "nothing",
#     10   "nothing"
# }