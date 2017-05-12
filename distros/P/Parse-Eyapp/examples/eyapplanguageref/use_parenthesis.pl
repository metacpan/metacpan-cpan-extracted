#!/usr/bin/env perl
use warnings;
use strict;
use Parenthesis;
use Data::Dumper;
$Data::Dumper::Indent = 0;

unshift @ARGV, '--noslurp';
print Dumper(Parenthesis->new->main("Try inputs 'acb' and 'aacbb': "))."\n";
