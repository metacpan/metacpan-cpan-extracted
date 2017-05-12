#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use PYX qw(attribute char comment end_element instruction start_element);

# Example output.
my @data = (
        instruction('xml', 'foo'),
        start_element('element'),
        attribute('key', 'val'),
        comment('comment'),
        char('data'),
        end_element('element'),
);

# Print out.
map { print $_."\n" } @data;

# Output:
# ?xml foo
# (element
# Akey val
# _comment
# -data
# )element