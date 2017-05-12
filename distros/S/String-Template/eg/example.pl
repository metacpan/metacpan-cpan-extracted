#!/usr/bin/env perl

use warnings;
use strict;
use String::Template;

my %fields = ( num => 2, str => 'this', date => 'Feb 27, 2008' );

my $template = "...<num%04d>...<str>...<date:%Y/%m/%d>...\n";

print expand_string($template, \%fields);
