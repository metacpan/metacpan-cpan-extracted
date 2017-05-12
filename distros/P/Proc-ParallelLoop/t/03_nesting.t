#!/usr/bin/perl -w
#
# Test ParallelLoop
#
# See how well we do when we running pardo nested loops.

use strict;
use Proc::ParallelLoop;

sub test($);
my @parms = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j');
open STDERR, ">/dev/null";
$|++;

print "1..3025\n";
{my $i=0; pardo sub{$i<55}, sub{$i++}, sub{
   {my $j=1; pardo sub{$j<=55}, sub{$j++}, sub{
      sleep 1;
      print "ok " . ($i*55+$j) . "\n";
   }, {"Max_Workers"=>10};}
}, {"Max_Workers"=>10};}

# EOF: 03_nesting.t
