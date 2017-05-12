use lib 'lib';

use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Math::BigFloat;
use Statistics::Test::WilcoxonRankSum;

my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();

my @dataset_1 = qw(45 50 61 63 75 85 93);
my @dataset_2 = qw(44 45 52 53 56 58 58 65 79);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

my $N = $wilcox_test->get_N();
my $MaxSum = $wilcox_test->get_max_rank_sum();

ok($N == 16, "Overall number of elements");
ok($MaxSum == 136, 'biggest possible rank sum');


my $prob = Math::BigFloat->new($wilcox_test->probability_exact());
my $expected = 0.2204;
ok(abs($prob - $expected) < 0.0001, 'exact probability');

$wilcox_test = Statistics::Test::WilcoxonRankSum->new();

@dataset_1 = (0.465, 0.453, 0.486);
@dataset_2 = (0.891, 0.888, 0.838, 0.783, 0.553, 0.766, 0.5, 0.493);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

$prob = $wilcox_test->probability();
$expected = 0.012121;

ok(abs($prob - $expected) < 0.0001, 'exact probability, Bug RT #65797');

@dataset_1 = map { 1-$_; } @dataset_1;
@dataset_2 = map { 1-$_; } @dataset_2;

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

$prob = $wilcox_test->probability();

## all values in datasets substracted by 1
## p-value should be the same

ok(abs($prob - $expected) < 0.0001, 'Bug RT #65797, prob for values in ds substracted by 1 should be the same');


1;

