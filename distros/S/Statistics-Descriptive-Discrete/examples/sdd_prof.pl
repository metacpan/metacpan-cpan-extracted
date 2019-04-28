#!/usr/bin/env perl

# Profile Statistics::Descriptive::Full and Statistics::Descriptive::Discrete
# for various data set sizes

use strict;
use warnings;

use Statistics::Descriptive::Discrete;
use Statistics::Descriptive;
use Time::HiRes qw(gettimeofday tv_interval);
use Math::Random qw(random_set_seed_from_phrase random_uniform_integer);
use vars qw($MAXELEMENTS $NUMRUNS);

$MAXELEMENTS = 1000000; #how big is the data set
$NUMRUNS = 1; #how many times to run
my $HIGH = 2**8; #sample range for data set. E.g. 2**8 = 256 possible values in data set

my ($t0, $elapsed);

my $stats_discrete = Statistics::Descriptive::Discrete->new();
my $stats_descr = Statistics::Descriptive::Full->new();

print "Statistics::Descriptive, runs = $NUMRUNS, elements=$MAXELEMENTS, sample range = $HIGH\n";
$t0 = [gettimeofday];
test_stats($stats_descr,1,$HIGH,$MAXELEMENTS,$NUMRUNS); #start at 1 so stats that divide by 0 will work
$elapsed = tv_interval ( $t0, [gettimeofday]);
print "Total time: $elapsed sec\n";

print "Statistics::Descriptive::Discrete, runs = $NUMRUNS, elements=$MAXELEMENTS, sample range = $HIGH\n";
$t0 = [gettimeofday];
test_stats($stats_discrete,1,$HIGH,$MAXELEMENTS,$NUMRUNS); #start at 1 so stats that divide by 0 will work
$elapsed = tv_interval ( $t0, [gettimeofday]);
print "Total time: $elapsed sec\n";

sub test_stats
{
    my ($stats, $low, $high, $maxelements, $numruns) = @_;

    foreach my $run (0..$numruns-1)
    {
        print "Run # $run\n";
        $stats->clear();
        random_set_seed_from_phrase("Test Statistics::Descriptive::Discrete");
        print "Adding data\n";
        foreach my $i (0..$maxelements-1)
        {
            my $randint = random_uniform_integer(1, $low, $high);
            $stats->add_data($randint);
        }
        #compute and print out the stats
        print "count = ",$stats->count(),"\n";
        #print "uniq  = ",$stats->uniq(),"\n";
        print "sum = ",$stats->sum(),"\n";
        print "min = ",$stats->min(),"\n";
        print "min index = ",$stats->mindex(),"\n";
        print "max = ",$stats->max(),"\n";
        print "max index = ",$stats->maxdex(),"\n";
        print "mean = ",$stats->mean(),"\n";
        print "geometric mean = ",$stats->geometric_mean(),"\n";
        print "harmonic mean = ",$stats->harmonic_mean(),"\n";
        print "standard_deviation = ",$stats->standard_deviation(),"\n";
        print "variance = ",$stats->variance(),"\n";
        print "sample_range = ",$stats->sample_range(),"\n";
        print "mode = ",$stats->mode(),"\n";
        print "median = ",$stats->median(),"\n";
         my $f = $stats->frequency_distribution_ref(10);
         foreach (sort {$a <=> $b} keys %$f) {
             print "key = $_, count = $f->{$_}\n";
         }
    }
}

