#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Tags::Output::Structure;

# Object.
my $tags = Tags::Output::Structure->new;

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
my $ret_ar = $tags->flush;

# Dump out.
p $ret_ar;

# Output:
# \ [
#     [0] [
#         [0] "b",
#         [1] "tag"
#     ],
#     [1] [
#         [0] "a",
#         [1] "par",
#         [2] "val"
#     ],
#     [2] [
#         [0] "c",
#         [1] "data",
#         [2] \ "data"
#     ],
#     [3] [
#         [0] "e",
#         [1] "tag"
#     ],
#     [4] [
#         [0] "i",
#         [1] "target",
#         [2] "data"
#     ],
#     [5] [
#         [0] "b",
#         [1] "tag"
#     ],
#     [6] [
#         [0] "d",
#         [1] "data",
#         [2] "data"
#     ],
#     [7] [
#         [0] "e",
#         [1] "tag"
#     ]
# ]