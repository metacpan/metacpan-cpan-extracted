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
$RU1->histogram_enable({
	'num-bins' => $NUMBINS,
	'bin-width' => 1,
	'left-boundary' => -2,
});
is($RU1->histogram()->{'num-bins'}, $NUMBINS, "histogram has $NUMBINS as asked."); $num_tests++;

for(1..100){
	$RU1->add(5 - 10*rand());
}

srand 123;
my $RU2 = Statistics::Running->new();
$RU2->histogram_enable({
	'num-bins' => $NUMBINS,
	'bin-width' => 1,
	'left-boundary' => -2,
});
is($RU2->histogram()->{'num-bins'}, $NUMBINS, "histogram has $NUMBINS as asked."); $num_tests++;

for(1..100){
	$RU2->add(5 - 10*rand());
}
ok($RU1->equals_histograms($RU2), "histograms are the same because created from same seed rand."); $num_tests++;

$RU2 = Statistics::Running->new();
$RU2->histogram_enable({
        'num-bins' => $NUMBINS,
        'bin-width' => 1,
        'left-boundary' => -2,
});
my $binshash = $RU1->histogram_bins_hash();
$RU2->histogram_bins_hash($binshash);
ok($RU2->equals_histograms($RU1), "histograms are the same because loaded from same binhash."); $num_tests++;

$RU1 = Statistics::Running->new();
$RU1->histogram_enable({
        'num-bins' => 10,
        'bin-width' => 1,
        'left-boundary' => 0,
});
$RU1->add($_) for (0..9);

$RU2 = Statistics::Running->new();
$RU2->histogram_enable({
        'num-bins' => 10,
        'bin-width' => 1,
        'left-boundary' => 0,
});
$RU2->add($_) for (0..9);

my $RU3 = $RU1 + $RU2;
my $correct=1;
my $binshash1 = $RU1->histogram_bins_hash();
my $binshash2 = $RU2->histogram_bins_hash();
my $binshash3 = $RU3->histogram_bins_hash();
for (keys %$binshash1){
	ok($binshash3->{$_} == ($binshash1->{$_}+$binshash2->{$_}), "bin $_, count correct."); $num_tests++;
}

my $RU4 = Statistics::Running->new();
$RU4->histogram_enable({
        'num-bins' => 11,
        'bin-width' => 1,
        'left-boundary' => 0,
});
$RU4->add($_) for (0..10);
my $RU5 = $RU1 + $RU4;
ok($RU5->{'histo'}->{'num-bins'}==-1, "adding objs with different-sized histograms ignores the histograms"); $num_tests++;

# test stringify hist
$RU2 = Statistics::Running->new();
$RU2->histogram_enable({
        'num-bins' => 10,
        'bin-width' => 1,
        'left-boundary' => 0,
});
$RU2->add($_) for (0..9);
my $str = $RU2."";
ok($str =~ /^\s*4\.000\s*\-\s*5\.000\:\s*1\s*#/m, "prints OK"); $num_tests++;
$RU2->add($_) for (0..9);
$str = $RU2."";
ok($str =~ /^\s*4\.000\s*\-\s*5\.000\:\s*2\s*#/m, "prints OK"); $num_tests++;

# END
done_testing($num_tests);
