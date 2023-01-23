#!/usr/bin/env perl

use strict;
use warnings;

use String::UpdateYears qw(update_years);

my $input = '1900';
my $output = update_years($input, {}, 2023);

# Print input and output.
print "Input: $input\n";
print "Output: $output\n";

# Output:
# Input: 1900
# Output: 1900-2023