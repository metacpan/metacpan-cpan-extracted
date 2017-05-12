#!/usr/bin/perl -w
use strict;

# Prints a simple greeting.
# Exits with the argument provided, or 0 by default.

print STDERR "Hello\nGoodbye\n";

exit($ARGV[0] || 0);
