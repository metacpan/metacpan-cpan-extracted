#!/usr/bin/env perl
use warnings;
use strict;
use ListAndAction;
use Data::Dumper;
$Data::Dumper::Indent = 0;

unshift @ARGV, '--noslurp';
print Dumper(ListAndAction->new->main("Try inputs 'acb' and 'aacbb': "))."\n";
