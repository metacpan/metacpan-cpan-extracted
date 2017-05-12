#!/usr/bin/perl

#example program showing use of Statistics::Descriptive::Discrete
#reads a list of numbers from STDIN and computes the statistics

use strict;
use warnings;

use Statistics::Descriptive::Discrete;

#create a new Statistics object
my $stats = Statistics::Descriptive::Discrete->new();

while(<>)
{
	chomp;
	$stats->add_data($_);
}

print "count = ",$stats->count(),"\n";
print "unique  = ",$stats->uniq(),"\n";
print "sum = ",$stats->sum(),"\n";
print "min = ",$stats->min(),"\n";
print "max = ",$stats->max(),"\n";
print "mean = ",$stats->mean(),"\n";
print "standard_deviation = ",$stats->standard_deviation(),"\n";
print "variance = ",$stats->variance(),"\n";
print "sample_range = ",$stats->sample_range(),"\n";
print "mode = ",$stats->mode(),"\n";
print "median = ",$stats->median(),"\n";

#compute frequency distribution
print "-"x80,"\n";
my %histogram = $stats->frequency_distribution(5);
print "$_\t\t$histogram{$_}\n" foreach (sort {$a <=> $b} keys %histogram);

#get a copy of the data -- sort of defeats the purpose if you have a lot of data points
#my @data = $stats->get_data();
#print "data = @data\n";

