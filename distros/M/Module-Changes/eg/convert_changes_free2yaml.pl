#!/usr/bin/env perl

# Simple program that takes a filename, (hopefully) parses the freeform
# Changes file and prints the YAML version to STDOUT.

use warnings;
use strict;

use Module::Changes;

my $filename = shift;

my $parser = Module::Changes->make_object_for_type('parser_free');
my $formatter = Module::Changes->make_object_for_type('formatter_yaml');

print $formatter->format($parser->parse_from_file($filename));

