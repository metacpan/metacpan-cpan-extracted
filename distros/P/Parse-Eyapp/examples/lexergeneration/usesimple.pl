#!/usr/bin/env perl
use warnings;
use strict;

use simple;

# build a parser object
my $parser = simple->new();

# take the input from the command line arguments
# or from STDIN
my $input = join ' ',@ARGV;
$input = <> unless $input;

# set the input
$parser->input($input);

# parse the input and get the AST
my $tree = $parser->YYParse();

print $tree->str()."\n";

