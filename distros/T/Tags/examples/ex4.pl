#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Raw;

# Object.
my $tags = Tags::Output::Raw->new;

# Put data.
$tags->put(
        ['b', 'text'],
        ['d', 'data'],
        ['e', 'text'],
);

# Print.
print $tags->flush."\n";

# Output:
# <text>data</text>