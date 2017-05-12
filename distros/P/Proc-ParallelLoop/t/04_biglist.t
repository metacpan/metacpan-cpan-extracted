#!/usr/bin/perl -w
#
# Test ParallelLoop
#
# See how well we do when we run a few thousand iterations (3000), 
# with a high degree of parallelism (25).

use strict;
use Proc::ParallelLoop;

sub test($);
my @parms = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j');
open STDERR, ">/dev/null";
$|++;

print "1..3000\n";
{my $i=1; pardo sub{$i<=3000}, sub{$i++}, sub{

   sleep 1;
   print "ok $i\n";
}, {"Max_Workers"=>25};}

# EOF: 03_biglist.t
