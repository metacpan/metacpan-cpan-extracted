#!/usr/bin/perl

use strict;
use warnings;
use Carp;

my $count=0;

print STDERR sprintf ("%u <%s>\n", $count++, $_) foreach @ARGV;



