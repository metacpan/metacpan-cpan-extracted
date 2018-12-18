#!perl -T
use 5.006;

use strict;
use warnings;

use Statistics::Running;
use Test::More;
use Data::Dumper;

my $num_tests = 0;

my $NUMBINS = 5;
srand 123;
my $RU1 = Statistics::Running->new();
$RU1->histogram_reset({
	'num-bins' => $NUMBINS,
	'bin-width' => 1,
	'left-boundary' => -2,
});
is($RU1->histogram()->{'num-bins'}, $NUMBINS, "histogram has $NUMBINS as asked.");
$num_tests++;

for(1..100){
	$RU1->add(5 - 10*rand());
}

srand 123;
my $RU2 = Statistics::Running->new();
$RU2->histogram_reset({
	'num-bins' => $NUMBINS,
	'bin-width' => 1,
	'left-boundary' => -2,
});
is($RU2->histogram()->{'num-bins'}, $NUMBINS, "histogram has $NUMBINS as asked.");
$num_tests++;

for(1..100){
	$RU2->add(5 - 10*rand());
}
ok($RU1->equals_histograms($RU2), "histograms are the same because created from same seed rand.");
$num_tests++;

$RU2 = Statistics::Running->new();
$RU2->histogram_reset({
        'num-bins' => $NUMBINS,
        'bin-width' => 1,
        'left-boundary' => -2,
});
my $binshash = $RU1->histogram_bins_hash();
$RU2->histogram_bins_hash($binshash);
ok($RU2->equals_histograms($RU1), "histograms are the same because loaded from same binhash.");
$num_tests++;

# END
done_testing($num_tests);
