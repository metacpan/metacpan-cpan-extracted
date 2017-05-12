#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::PYX;

# Object.
my $tags = Tags::Output::PYX->new;

# Put all tag types.
$tags->put(
        ['b', 'tag'],
        ['a', 'par', 'val'],
        ['c', 'data', \'data'],
        ['e', 'tag'],
        ['i', 'target', 'data'],
        ['b', 'tag'],
        ['d', 'data', 'data'],
        ['e', 'tag'],
);

# Print out.
print $tags->flush."\n";

# Output:
# (tag
# Apar val
# -<!--data--><!--SCALAR(0x1570740)-->
# )tag
# ?target data
# (tag
# -datadata
# )tag