#!/usr/bin/env perl

use strict;
use warnings;

use PYX::Optimization;

if (@ARGV < 1) {
        print STDERR "Usage: $0 pyx_file\n";
        exit 1;
}
my $pyx_file = $ARGV[0];

PYX::Optimization->new->parse_file($pyx_file);

# Output:
# Usage: __SCRIPT__ pyx_file