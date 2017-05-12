#!/usr/bin/perl -w

use strict;
use Perl::Visualize qw/paint/;
my $program = "fibo";
#`perl -d:GraphVizProf $program.pl | dot -Tgif -o $program.gif`;
open CODE, "<$program.pl" or die "Could not open $program.pl: $@";
my(@lines) = <CODE>;
close CODE;
paint "$program.gif", "v-$program.gif", join '',@lines;
