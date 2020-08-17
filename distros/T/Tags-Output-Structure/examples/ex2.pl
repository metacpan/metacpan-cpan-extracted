#!/usr/bin/env perl

use strict;
use warnings;

use Tags::Output::Structure;

# Object.
my $tags = Tags::Output::Structure->new(
        'output_handler' => \*STDOUT,
);

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
$tags->flush;

# Output:
# ['b', 'tag']
# ['a', 'par', 'val']
# ['c', 'data', 'SCALAR(0x143d9c0)']
# ['e', 'tag']
# ['i', 'target', 'data']
# ['b', 'tag']
# ['d', 'data', 'data']
# ['e', 'tag']