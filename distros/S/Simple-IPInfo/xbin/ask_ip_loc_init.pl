#!/usr/bin/perl

my $dir = 'data';

mkdir($dir);
for my $i ( 1 .. 255){
    `touch $dir/$i.csv`;
}
