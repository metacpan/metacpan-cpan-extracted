#!/usr/bin/perl -w

use Proc::Simple;
use Test::More;
plan tests => 80;

###
### Multiple Processes Test
###
#Proc::Simple->debug(1);

foreach $i (0..19) {
    $psh[$i] = Proc::Simple->new();  
}

foreach $i (@psh) {
    ok($i->start("sleep 60"));        # 1-20
}

foreach $i (@psh) {
    while(!$i->poll) { 
        sleep 1; }
    ok($i->poll());                   # Check each process, kill it
    ok($i->kill());                   # and check again: 21-80
    while($i->poll) { 
        sleep 1; }
    ok(!$i->poll());                  
}

Proc::Simple->cleanup();

1;

