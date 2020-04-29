#!/usr/bin/env perl

use strict;
use warnings;

use Tags::Output::LibXML;

# Object.
my $tags = Tags::Output::LibXML->new;

# Put data.
$tags->put(
        ['b', 'text'],
 ['d', 'data'],
 ['e', 'text'],
);

# Print.
print $tags->flush."\n";

# Output:
# <?xml version="1.1" encoding="UTF-8"?>
# <text>data</text>