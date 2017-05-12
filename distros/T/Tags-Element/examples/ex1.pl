#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use Tags::Element qw(element);

# Get example element.
my @tags = element('div', {
        'id' => 'foo',
        'class' => 'bar',
}, 'Foo', 'Bar');

# Dump to stdout.
p @tags;

# Output.
# [
#     [0] [
#         [0] "b",
#         [1] "div"
#     ],
#     [1] [
#         [0] "a",
#         [1] "class",
#         [2] "bar"
#     ],
#     [2] [
#         [0] "a",
#         [1] "id",
#         [2] "foo"
#     ],
#     [3] [
#         [0] "d",
#         [1] "Foo"
#     ],
#     [4] [
#         [0] "d",
#         [1] "Bar"
#     ],
#     [5] [
#         [0] "e",
#         [1] "div"
#     ]
# ]