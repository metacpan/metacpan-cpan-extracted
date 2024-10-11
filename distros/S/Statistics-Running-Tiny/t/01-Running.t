#!perl -T
use 5.006;

use strict;
use warnings;

use Statistics::Running::Tiny;
use Test::More;

our $VERSION = '0.04';

my $num_tests = 0;

my $RU1 = Statistics::Running::Tiny->new();
for(1..100){
	$RU1->add(10);
}
is($RU1->mean(), 10.0, "mean must be 10");
$num_tests++;
is($RU1->standard_deviation(), 0.0, "standard deviation must be 0");
$num_tests++;

my $RU2 = $RU1->clone();
ok($RU1->equals($RU2), "cloned object must be the same as source");
$num_tests++;

my $RU4 = Statistics::Running::Tiny->new();
$RU4->copy_from($RU1);
ok($RU4->equals($RU1), "copied object must be the same as source");
$num_tests++;

print "RU4: $RU4\n";
print "RU1: $RU1\n";
my $RU5 = $RU4+$RU1;
print "RU5: $RU5\n";
ok($RU5->equals_statistics($RU1) && ! $RU5->equals($RU1), "result of adding same-stats objects must be the same as far as stats are concerned but not number of samples");
$num_tests++;

$RU4 = $RU4+$RU1;
ok($RU4->equals_statistics($RU1) && ! $RU4->equals($RU1), "appending with same objects must yield no change");
$num_tests++;

my @dat = map { rand } (1..100);
my $RU6 = Statistics::Running::Tiny->new();
$RU6->add(\@dat);
my $RU7 = Statistics::Running::Tiny->new();
foreach my $x (@dat){ $RU7->add($x) }
ok($RU6->equals_statistics($RU7), "using push in array and scalar modes should yield same results exactly.");
$num_tests++;

$RU6->add(\@dat);
$RU6->clear();
is($RU6->get_N(), 0, "number of samples after clear is zero");
$num_tests++;
is($RU6->kurtosis(), 0, "kurtosis after clear is zero");
$num_tests++;

@dat = map { $_ } (1..100);
push(@dat, -123, 10101);
$RU6->clear();
$RU6->add(\@dat);
is($RU6->min(), -123, "minimum value is -123");
$num_tests++;
is($RU6->max(), 10101, "maximum value is 10101");
$num_tests++;

done_testing($num_tests);
