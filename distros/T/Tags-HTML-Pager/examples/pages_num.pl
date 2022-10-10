#!/usr/bin/env perl

use strict;
use warnings;

use Tags::HTML::Pager::Utils qw(pages_num);

# Input informations.
my $items = 123;
my $items_on_page = 20;

# Compute.
my $pages = pages_num($items, $items_on_page);

# Print out.
print "Items count: $items\n";
print "Items on page: $items_on_page\n";
print "Number of pages: $pages\n";

# Output:
# Items count: 123
# Items on page: 20
# Number of pages: 7 