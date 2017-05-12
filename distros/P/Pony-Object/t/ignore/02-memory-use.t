#!/usr/bin/perl -w

use lib './lib';
use lib './t/ignore';

use Benchmark;
use Object::Animal::Cattle;

my $t1  = new Benchmark;

for ( 1 .. 100 )
{
    my @cow;
    
    for ( 1 .. 10 )
    {
        push @cow, new Object::Animal::Cattle;
        $cow[$#cow]->big = 'a' x 100_000_000;
    }
    
    for my $i ( 1 .. 4 )
    {
        $cow[$i * 2]->getMilk() for 0 .. 1000;
        $cow[$i * 2 - 1]->getYieldOfMilk();
    }
    
    sleep 1;
}

my $t2  = new Benchmark;

my $time = timediff($t2, $t1);

printf "Pony::Object:\t%s\n", timestr($time);
