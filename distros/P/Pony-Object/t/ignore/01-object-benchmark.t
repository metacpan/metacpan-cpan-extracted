#!/usr/bin/perl

use strict;
use warnings;

use lib './t';

use Benchmark;
use Object::Benchmark::BlessedRef;
use Object::Benchmark::Pony;

#
#  Init
#

print "Compare create time\n";

# Pony::Object
my $t1  = new Benchmark;
my $obj = new Object::Benchmark::Pony for 0 .. 100_000;
my $t2  = new Benchmark;

my $time = timediff($t2, $t1);

printf "Pony::Object:\t%s\n", timestr($time);

# Raw bless
$t1  = new Benchmark;
$obj = new Object::Benchmark::BlessedRef for 0 .. 100_000;
$t2  = new Benchmark;

$time = timediff($t2, $t1);

printf "Blessed Ref:\t%s\n", timestr($time);

#
#  Properties access
#

print "Compare properties access time\n";

my $pony = new Object::Benchmark::Pony;
my $bless= new Object::Benchmark::BlessedRef;

# Pony::Object
$t1  = new Benchmark;

for my $i ( 0 .. 10_000 )
{
    $pony->title = "Title $i";
    $pony->authors = [ 0 .. $i ];
    $pony->text = "Text $i";
}

$t2  = new Benchmark;

$time = timediff($t2, $t1);

printf "Pony::Object:\t%s\n", timestr($time);

# Raw bless
$t1  = new Benchmark;

for my $i ( 0 .. 10_000 )
{
    $bless->{title} = "Title $i";
    $bless->{authors} = [ 0 .. $i ];
    $bless->{text} = "Text $i";
}

$t2  = new Benchmark;

$time = timediff($t2, $t1);

printf "Blessed Ref:\t%s\n", timestr($time);


print "\nEND\n"
