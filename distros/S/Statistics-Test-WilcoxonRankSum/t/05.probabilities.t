use lib 'lib';

use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Math::BigFloat;
use Statistics::Test::WilcoxonRankSum;

my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();

my @dataset_1 = (4.6, 4.7, 4.9, 5.1, 5.2, 5.5, 5.8, 6.1, 6.5, 6.5, 7.2);
my @dataset_2 = (5.2, 5.3, 5.4, 5.6, 6.2, 6.3, 6.8, 7.7, 8.0, 8.1);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);
my $prob = Math::BigFloat->new($wilcox_test->probability());
my $pf = sprintf '%f', $prob;
my $expected = 0.091022;
ok(abs($expected-$prob) < 0.00001, "$pf, probability");

my $pstatus = $wilcox_test->probability_status();
ok($pstatus =~ m{normal approx}, "probability computed by normal approx");

diag("Summary method in void context -> prints to stdout\n");
$wilcox_test->summary();

@dataset_1 = (6.0, 4.8, 5.1, 5.5, 4.1, 5.3, 4.5, 5.1);
@dataset_2 = (6.5, 5.5, 6.3, 7.2, 6.8, 5.5, 5.9, 5.5);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

$prob = $wilcox_test->probability();
$pf = sprintf '%f', $prob;
$expected = 0.002797;
ok(abs($expected-$prob) < 0.00001, "$pf, probability");

$pstatus = $wilcox_test->probability_status();
ok($pstatus =~ m{exact}, "exact probability");

# summary method in string context:
my $summary = $wilcox_test->summary();

diag($summary);


# my @dataset_1 = qw(22 41 35 1 8 20 18 8 19 11 6 32 3 3);
# my @dataset_2 = qw(1 2 3 2 3 1 1 2 1 1 3 4 3 1 3 1 1 1 1 3 1 1 1 2 3 1 3 1 1 1 1 1 1 1 1 1 3 1 2 1 1 1 3 5 1 1 4 2 1 1 1 6);

# my $n1 = scalar(@dataset_1);
# my $n2 = scalar(@dataset_2);
# my $N = $n1+$n2;

# $wilcox_test->load_data(\@dataset_1, \@dataset_2);
# my $rank_sum_1 = $wilcox_test->rank_sum_for('dataset1');

# my $expected_rank_sum_1 = $n1*$N/2;

# my $rank_sum_2 = $wilcox_test->rank_sum_for('dataset2');
# my $expected_rank_sum_2 = $n2*$N/2;

# print STDERR "Rank sum 1: $rank_sum_1\n";
# print STDERR "Expected rank sum 1: $expected_rank_sum_1\n";
# print STDERR "Rank sum 2: $rank_sum_2\n";
# print STDERR "Expected rank sum 2: $expected_rank_sum_2\n";

# my @ranks_array = $wilcox_test->get_rank_array();
# print STDERR Dumper(\@ranks_array);

# my $prob = Math::BigFloat->new($wilcox_test->probability_normal_approx());
# printf STDERR "Probability with normal approximation: %f\n", $prob;


1;
