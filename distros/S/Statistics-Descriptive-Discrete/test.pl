# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 16 };
use Statistics::Descriptive::Discrete;

#1: did the module import ok?
ok(1); # If we made it this far, we're ok.

#2: can we create a new object?
my $stats = Statistics::Descriptive::Discrete->new;
ok($stats);

#now add some data and compute the statistics
$stats->add_data(1,2,3,4,5,4,3,2,1,2);

#3: 
ok($stats->count,10);

#4: min
ok($stats->min,1);

#5: max
ok($stats->max,5);

#6: uniq
ok($stats->uniq,5);

#7: mean
ok($stats->mean,2.7);

#8: sample_range
ok($stats->sample_range,4);

#9: mode
ok($stats->mode,2);

#10: median
ok($stats->median,2.5);

#11: standard_deviation
ok(abs($stats->standard_deviation-1.33749350984926) < 0.00001);

#12: variance
ok(abs($stats->variance-1.78888888888) < 0.00001);

#13: variance for small values
$stats = Statistics::Descriptive::Discrete->new;
my @data;
for ($i=0;$i<45;$i++)
{
	push @data,0.01113;
}
$stats->add_data(@data);
ok($stats->variance > 0);

#14 add_data_tuple
$stats = Statistics::Descriptive::Discrete->new;
$stats->add_data_tuple(2,2);
$stats->add_data_tuple(3,3,4,4);
ok($stats->uniq,3);

#15
ok($stats->sum,29);

#16 more add_data_tuple
ok($stats->count,9);


#TODO:
#14: frequency_distribution
#even/odd data sets for median
