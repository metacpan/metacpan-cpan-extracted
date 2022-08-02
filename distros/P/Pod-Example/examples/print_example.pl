#!/usr/bin/env perl

use strict;
use warnings;

use Pod::Example qw(get);

# Get and print code.
print get('Pod::Example')."\n";

# Output:
# This example.