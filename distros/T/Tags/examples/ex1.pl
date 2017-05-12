#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output;

# Object.
my $tags = Tags::Output->new;

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
# Begin of tag
# Attribute
# Comment
# End of tag
# Instruction
# Begin of tag
# Data
# End of tag