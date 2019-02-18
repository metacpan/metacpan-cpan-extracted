#!/usr/bin/perl

# Tests for Statistics::Descriptive::Discrete
# See descr.t for tests from Statistics::Descriptive which are also run

use strict;
use warnings;

use Test::More tests => 52;
use Statistics::Descriptive::Discrete;
use lib 't/lib';
use Utils qw/array_cmp/;

{
    #check calling methonds before adding data
    my $stats = Statistics::Descriptive::Discrete->new();

    #TEST
    is($stats->mean,undef,"mean should be undef");

    #TEST
    is($stats->count,0,"count should be 0");
}

{
    my $stats = Statistics::Descriptive::Discrete->new();
    #now add some data and compute the statistics
    $stats->add_data(1,2,3,4,5,4,3,2,1,2);

    #TEST
    is($stats->count,10,"Count = 10");

    #TEST
    my @d = $stats->get_data();
    my @sorted_data = (1,1,2,2,2,3,3,4,4,5);
    is(array_cmp(@d,@sorted_data),1,"get_data matches");

    #TEST
    is($stats->min,1,"min = 1");

    #TEST
    is($stats->mindex,0,"mindex = 0");

    #TEST
    is($stats->max,5,"max = 5");

    #TEST
    is($stats->maxdex,4,"maxdex = 4");

    #TEST
    is($stats->uniq,5,"uniq = 5");

    #TEST
    is($stats->mean,2.7,"mean = 2.7");

    #TEST
    is($stats->sample_range,4,"sample range = 4");

    #TEST
    is($stats->mode,2, "mode = 2");

    #TEST
    is($stats->median,2.5,"median = 2.5");

    #TEST
    ok(abs($stats->standard_deviation-1.33749350984926) < 0.00001,"standard_deviation ok");

    #TEST
    ok(abs($stats->variance-1.78888888888) < 0.00001,"variance ok");

   #TEST
    $stats->clear();
    is($stats->min,undef,"min should be undef now");
    
    #TEST
    is($stats->count,0,"count should be 0 now");

    #add data then chec stats
    $stats->add_data(1,2,3,4,5,4,3,2,1,2);

    #TEST
    is($stats->count,10,"Count = 10");
 
    #TEST
    is($stats->min,1,"min = 1");

    #TEST
    is($stats->max,5,"max = 5");

    #TEST
    is($stats->uniq,5,"uniq = 5");

    #TEST
    is($stats->mean,2.7,"mean = 2.7");

    #TEST
    is($stats->sample_range,4,"sample range = 4");

    #TEST
    is($stats->mode,2, "mode = 2");

    #TEST
    is($stats->median,2.5,"median = 2.5");

    #TEST
    ok(abs($stats->standard_deviation-1.33749350984926) < 0.00001,"standard_deviation ok");

    #TEST
    ok(abs($stats->variance-1.78888888888) < 0.00001,"variance ok");

}

{
    #test uniq in scalar and array context
    my $stats = Statistics::Descriptive::Discrete->new;
    $stats->add_data(1,2,2,3,3,3);
    my $uniq = $stats->uniq();
    my @uniq = $stats->uniq();
    
    #TEST
    is($uniq,3,"uniq in scalar context");

    #TEST
    is_deeply(\@uniq,[1,2,3],"uniq in array context");

    $stats->clear();
    $uniq = $stats->uniq();
    @uniq = $stats->uniq();

    #TEST
    is($uniq,undef,"uniq in scalar context with no data");

    #TEST
    is_deeply(\@uniq,[undef],"uniq in array context with no data");
}

{
    #variance for small values
    #TEST
    my $stats = Statistics::Descriptive::Discrete->new;
    my @data;
    for (my $i=0;$i<45;$i++)
    {
        push @data,0.01113;
    }
    $stats->add_data(@data);
    ok($stats->variance > 0,"variance ok");
}

{
    #add_data_tuple
    my $stats = Statistics::Descriptive::Discrete->new;
    $stats->add_data_tuple(2,2);
    $stats->add_data_tuple(3,3,4,4);

    #TEST
    is($stats->uniq,3,"uniq = 3");
    
    #TEST
    is($stats->sum,29,"sum = 29");
    
    #TEST
    is($stats->count,9,"count = 9");
    
    #TEST
    is($stats->mindex,0,"mindex = 0");

    #TEST
    is($stats->maxdex,5,"maxdex = 5");

    #TEST
    $stats->add_data_tuple(0,1);
    is($stats->mindex,9,"mindex = 9");
}

{
    #frequency distribution
    #TEST
    my $stats = Statistics::Descriptive::Discrete->new();
    $stats->add_data(1,1.5,2,2.5,3,3.5,4);
    my $f = $stats->frequency_distribution_ref(2);
    my %freq = (2.5 => 4, 4=>3);
    is_deeply($f,\%freq,"frequency_distribution_ref 2 partitions");

    #cached results
    #TEST
    my $f2 = $stats->frequency_distribution_ref();
    is_deeply($f2,\%freq,"cached frequency_distribution_ref");

    #manual bin sizes
    #TEST
    $stats->clear();
    $stats->add_data_tuple(1,1,2,2,3,3,4,4,5,5,6,6,7,7);
    %freq = (1=>1, 2=>2, 3=>3, 4=>4, 5=>5, 6=>6, 7=>7);
    my @bins = (1,2,3,4,5,6,7);
    $f = $stats->frequency_distribution_ref(\@bins);
    is_deeply($f,\%freq,"manual bin sizes");

    #manual bin sizes less than max
    #TEST
    @bins = (2,4,6);
    $f = $stats->frequency_distribution_ref(\@bins);
    %freq = (2=>3,4=>7,6=>11);
    is_deeply($f,\%freq,"manual bin sizes less than max");

    #only 1 data element
    #TEST
    $stats->clear();
    $stats->add_data(1);
    $f = $stats->frequency_distribution_ref(2);
    is($f,undef,"can't compute frequency_distribution with a single data element");

    #only 1 partition
    #TEST
    $stats->clear();
    $stats->add_data(1,2,3);
    $f = $stats->frequency_distribution_ref(1);
    is_deeply($f,{3=>3},"single partition");

    #calling with no params returns last distribution calculated
    #TEST
    $f = $stats->frequency_distribution_ref();
    is_deeply($f,{3=>3},"no parameters returns last distribution");

    #adding data then calling with no partions returns undef
    #this is how Statistics::Descriptive behaves
    #TEST
    $stats->add_data(4);
    $f = $stats->frequency_distribution_ref();
    is($f,undef,"no parameters after adding data returns undef");

}

{
    # geometric mean
    #TEST
    my $stats = Statistics::Descriptive::Discrete->new();
    $stats->add_data(1,2,3,4);
    my $gm = $stats->geometric_mean;
    cmp_ok(abs($gm-2.213), "<", 0.001,"geometric mean approx 2.213");

    #TEST
    $stats->clear();
    $stats->add_data(4,1,1.0/32.0);
    $gm = $stats->geometric_mean;
    cmp_ok(abs($gm-.5),"<",0.0001,"geometric mean = 0.5");

    # negative value should make mean undefined
    #TEST
    $stats->clear();
    $stats->add_data(-1,2,3,4);
    $gm = $stats->geometric_mean;
    is($gm,undef,"negative values make geometric mean undefined");

    # any zero values make mean 0
    #TEST
    $stats->clear();
    $stats->add_data(0,1,2,3,4);
    $gm = $stats->geometric_mean;
    is($gm,0,"zero values make geometric mean zero");
}

{
    # test normal function of harmonic mean
    #TEST
    my $stat = Statistics::Descriptive::Discrete->new();
    $stat->add_data( 60, 20 );
    my $single_result = $stat->harmonic_mean();
    # TEST
    ok (scalar(abs( $single_result - 30.0 ) < 0.001),
        "test normal function of harmonic mean",
    );
}

{
    #frequency distribution by unique values
    #TEST
    my $stats = Statistics::Descriptive::Discrete->new();
    $stats->add_data_tuple(1,1,2,2,3,3,4,4,5,5,6,6,7,7);
    my %freq = (1=>1, 2=>2, 3=>3, 4=>4, 5=>5, 6=>6, 7=>7);
    my @uniq = $stats->uniq();
    my $f = $stats->frequency_distribution_ref(\@uniq);
    is_deeply($f,\%freq,"frequency_distribution_ref by uniq");
}