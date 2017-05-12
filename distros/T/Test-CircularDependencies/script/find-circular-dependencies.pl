#!/usr/bin/env perl
use strict;
use warnings;

use Test::CircularDependencies qw(find_dependencies);

use Getopt::Long qw(GetOptions);

GetOptions('dir=s' => \my @dirs);

my @loops = find_dependencies(\@ARGV, \@dirs);
foreach my $l (@loops) {
	print "Found loop: @$l\n";
}

