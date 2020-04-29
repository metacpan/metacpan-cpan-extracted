#!/usr/bin/env perl

use strict;
use warnings;

use Tags::Output::Indent;

# Object.
my $tags = Tags::Output::Indent->new;

# Put data.
$tags->put(
        ['b', 'text'],
 ['d', 'data'],
 ['e', 'text'],
);

# Print.
print $tags->flush."\n";

# Output:
# <text>
#   data
# </text>