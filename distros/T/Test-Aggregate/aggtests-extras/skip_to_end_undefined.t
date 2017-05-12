#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

SKIP: {
    {
        # Do this just to get $! set.
        open(my $fh, '<', 'a-file-that-almost-certainly-does.not.exist');
    }
    skip 'to end', 1;
}

# Don't return a value, the 'last skip' should jump out
# so the file returns undef.
