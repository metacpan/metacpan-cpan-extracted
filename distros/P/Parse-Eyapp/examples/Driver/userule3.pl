#!/usr/bin/perl -w
use strict;
use Rule3;

my $parser = new Rule3();

# Parameters: object or class, filename, prompt messagge, mode (interactive or not: undef or "\n")
$parser->slurp_file('', "\n");
$parser->YYParse();
