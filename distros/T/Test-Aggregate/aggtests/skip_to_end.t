#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

SKIP: {
    {
        # Do this just to get $! set.
        open(my $fh, '<', 'a-file-that-almost-certainly-does.not.exist');
    }
    skip 'to end', 1;
}

# Return a defined value.
0;
