#!/usr/bin/env perl
use warnings;
use strict;

use simplewithwhites;

my $parser = simplewithwhites->new();

# take the input from the specified file
my $fn = shift;

$parser->YYSlurpFile($fn);

# parse the input and get the AST
my $tree = $parser->YYParse();

print $tree->str()."\n";

