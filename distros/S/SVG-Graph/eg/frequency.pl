#!/usr/bin/perl
use strict;

use Statistics::Descriptive;
use Getopt::Long;

my $bin;

GetOptions('binsize|b=i' => \$bin);
my $stat = Statistics::Descriptive::Full->new;

while(<>){
  chomp;
  $stat->add_data($_);
}

if(!$bin){
  my $max = $stat->max;
  my $min = $stat->min;
  $bin = int($max - $min);
}

my %f = $stat->frequency_distribution($bin);

print "#stat:mean\t".$stat->mean."\n";
print "#stat:quartile1\t".$stat->percentile(25)."\n";
print "#stat:median\t".$stat->median."\n";
print "#stat:quartile3\t".$stat->percentile(75)."\n";
print "#stat:standard_deviation\t".$stat->standard_deviation."\n";

foreach my $p (sort {$a <=> $b} keys %f){
  print $p, "\t", $f{$p} || 0, "\n";
}
