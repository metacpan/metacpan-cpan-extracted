#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;

my $pxs=PortageXS->new();
my $repo=$pxs->portdir();
exit(0) if !$ARGV[0];
$repo=$ARGV[1] if $ARGV[1];
print "List of available packages in category $ARGV[0] in repo $repo:\n";
print join("\n",$pxs->getPackagesFromCategory($ARGV[0],$repo))."\n";
