#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Pod::Example qw(sections);

# Get and print code.
print join "\n", sections('Pod::Example');
print "\n";

# Output:
# EXAMPLE1
# EXAMPLE2