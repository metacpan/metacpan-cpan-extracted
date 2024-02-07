#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Tags::HTML::Element::Utils qw(tags_boolean);
use Test::MockObject;

my $self = {};
my $obj = Test::MockObject->new;
$obj->set_true('foo');

# Process $obj->foo.
my @tags = tags_boolean($self, $obj, 'foo');

# Print out.
p $tags[0];

# Output (like attribute <element foo="foo">):
# [
#     [0] "a",
#     [1] "foo",
#     [2] "foo"
# ]