use 5.024;
use warnings;
use rlib '../lib';

use Statistics::Sampler::Multinomial;
use Statistics::Sampler::Multinomial::Indexed;
use Math::Random::MT::Auto;
use List::Util qw /sum/;
use Data::Compare;

my @updates = (2 => 3, 5 => 10);
my $probs = [
    1, 5, 2, 6, 3, 8, 1, 4, 9,
    #1, 5, 3, 6, 3, 10, 1, 4, 9,
    #1, 5, 0, 0, 0, 2, 6, 1, 0, 1, 8, 9
];

my $prng1   = Math::Random::MT::Auto->new (seed => 2345);
my $object1 = Statistics::Sampler::Multinomial->new (
    prng => $prng1,
    data => [@$probs],
);
my $prng2   = Math::Random::MT::Auto->new (seed => 2345);
my $object2 = Statistics::Sampler::Multinomial->new (
    prng => $prng2,
    data => [@$probs],
);
my $prngi   = Math::Random::MT::Auto->new (seed => 2345);
my $objecti = Statistics::Sampler::Multinomial::Indexed->new (
    prng => $prngi,
    data => [@$probs],
);

my (%results1, %results_old, %results_idx);
my $n = 100000;
foreach my $i (0..$#$probs) {
    $results1{$i} = 0;
    $results_old{$i} = 0;
    $results_idx{$i} = 0;
}
foreach my $i (0..$n) {
    $results1{$object1->draw1}++;
    $results_old{$object2->draw}++;
    $results_idx{$objecti->draw}++;
}

my $objecti_orig = $objecti->clone;
$object1->update_values (@updates);
$object2->update_values (@updates);
$objecti->update_values (@updates);

foreach my $i (0..$n) {
    $results1{$object1->draw1}++;
    $results_old{$object2->draw}++;
    $results_idx{$objecti->draw}++;
}

#say 'Index contents before and after cloning are ', Compare ($objecti->{index}, $objecti_orig->{index}) ? '' : 'not ', 'identical';
#use Data::Dumper::Compact qw /ddc/;
#say 'Before';
#print ddc $objecti_orig->{index};
#say 'After';
#print ddc $objecti->{index};
#print ddc $objecti->{data};
#print ddc $objecti_orig->{data};


my $sum_probs = sum @$probs;
my $sum_old   = sum values %results_old;
my $sum1      = sum values %results1;
my $psum_probs = sum @$probs[0..4] / sum @$probs;
my $psum_old   = sum @results_old{0..4} / sum values %results_old;
my $psum1      = sum @results1{0..4} / sum values %results1;

my $fmt = '%.4f';
say '  ' . join ' ', map {sprintf "%6i", $_} sort {$a <=> $b} keys %results_old;
say 'd ' . join ' ', map {sprintf $fmt, $_ / $sum_probs} @$probs;
say 'o ' . join ' ', map {sprintf $fmt, $_ / $sum_old} @results_old{sort {$a <=> $b} keys %results_old};
say '1 ' . join ' ', map {sprintf $fmt, $_ / $sum1} @results1{sort {$a <=> $b} keys %results1};
say 'i ' . join ' ', map {sprintf $fmt, $_ / $sum1} @results_idx{sort {$a <=> $b} keys %results_idx};
say '--';
say scalar keys %results1;
say scalar keys %results_old;
say scalar keys %results_idx;

say "$sum_probs, $sum_old, $sum1";
say "$psum_probs, $psum_old, $psum1";
