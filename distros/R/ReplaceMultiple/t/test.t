#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use ReplaceMultiple;

my $source = "AAABBB";
my $result = replace_multiple({"AAA"=>"BBB", "BBB"=>"AAA"}, $source);

ok($result eq "BBBAAA", "double replacement");

