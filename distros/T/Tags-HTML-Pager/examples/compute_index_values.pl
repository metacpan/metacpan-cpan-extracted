#!/usr/bin/env perl

use strict;
use warnings;

use Tags::HTML::Pager::Utils qw(compute_index_values);

# Input informations.
my $items = 55;
my $actual_page = 2;
my $items_on_page = 10;

# Compute.
my ($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);

# Print out.
print "Items: $items\n";
print "Actual page: $actual_page\n";
print "Items on page: $items_on_page\n";
print "Begin index: $begin_index\n";
print "End index: $end_index\n";

# Output:
# Items: 55
# Actual page: 2
# Items on page: 10
# Computed begin index: 10
# Computed end index: 19