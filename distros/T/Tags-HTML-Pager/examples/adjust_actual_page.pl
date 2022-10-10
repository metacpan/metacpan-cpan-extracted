#!/usr/bin/env perl

use strict;
use warnings;

use Tags::HTML::Pager::Utils qw(adjust_actual_page);

# Input informations.
my $input_actual_page = 10;
my $pages = 5;

# Compute;
my $actual_page = adjust_actual_page($input_actual_page, $pages);

# Print out.
print "Input actual page: $input_actual_page\n";
print "Number of pages: $pages\n";
print "Adjusted actual page: $actual_page\n";

# Output:
# Input actual page: 10
# Number of pages: 5
# Adjusted actual page: 5