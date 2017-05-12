use lib 'lib';

use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Math::BigFloat;
use Statistics::Test::WilcoxonRankSum;
use Statistics::Distributions;

my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();

my $u = Statistics::Distributions::udistr (.05);
diag( "u-crit (95th percentile = 0.05 level) = $u\n" );

# Example from http://www.stat.auckland.ac.nz/~wild/ChanceEnc/Ch10.wilcoxon.pdf
# their results:
# dataset 1: rank sum: 75, p = 0.114

diag("Example from http://www.stat.auckland.ac.nz/~wild/ChanceEnc/Ch10.wilcoxon.pdf\n");

my @dataset_1 = (8.50, 9.48, 8.65, 8.16, 8.83, 7.76, 8.63);
my @dataset_2 = (8.27, 8.20, 8.25, 8.14, 9.00, 8.10, 7.20, 8.32, 7.70);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

my $prob = Math::BigFloat->new($wilcox_test->probability_exact());
my $expected = 0.114161;
my $pf = sprintf '%f', $prob;
ok( abs($prob-$expected) < 0.00001, "Exact probability: $pf");

$prob = Math::BigFloat->new($wilcox_test->probability_normal_approx());
$expected = 0.112338;
$pf = sprintf '%f', $prob;
ok( abs($prob-$expected) < 0.00001, "Probability with normal approximation: $pf" );

# An example from http://www.statsdirect.com/help/nonparametric_methods/mwt.htm
# Their results:
# estimated median difference = 0.8
# two sided P = 0.529
# 95.1% confidence interval for difference between population means or medians = -2.3 to 4.4

diag("Example from http://www.statsdirect.com/help/nonparametric_methods/mwt.htm\n");


@dataset_1 = (14.8, 7.3, 5.6, 6.3, 9.0, 4.2, 10.6, 12.5, 12.9, 16.1, 11.4, 2.7);
@dataset_2 = (12.7, 14.2, 12.6, 2.1, 17.7, 11.8, 16.9, 7.9, 16.0, 10.6, 5.6, 5.6, 7.6, 11.3, 8.3, 6.7, 3.6, 1.0, 2.4, 6.4, 9.1, 6.7, 18.6, 3.2, 6.2, 6.1, 15.3, 10.6, 1.8, 5.9, 9.9, 10.6, 14.8, 5.0, 2.6, 4.0);


$wilcox_test->load_data(\@dataset_1, \@dataset_2);
$prob = Math::BigFloat->new($wilcox_test->probability_normal_approx());
$expected = 0.528080;
$pf = sprintf '%f', $prob;
ok(abs($prob-$expected) < 0.00001, "Example from http://www.statsdirect.com/help/nonparametric_methods/mwt.htm, normal approximation: $pf"); 

# $wilcox_test = Statistics::Test::WilcoxonRankSum->new( { exact_upto => 50 } );
# $wilcox_test->load_data(\@dataset_1, \@dataset_2);
# $prob = $wilcox_test->probability();
# print STDERR "\n";
# print STDERR $wilcox_test->summary();



# An example from http://faculty.vassar.edu/lowry/ch11a.html
# Results there:
# dataset 1: rank sum = 96.5, z=-1.69, p (one sided) = 0.455
# would be significant to the 0.05 level 

diag('Example from http://faculty.vassar.edu/lowry/ch11a.html');
  
@dataset_1 = (4.6, 4.7, 4.9, 5.1, 5.2, 5.5, 5.8, 6.1, 6.5, 6.5, 7.2);
@dataset_2 = (5.2, 5.3, 5.4, 5.6, 6.2, 6.3, 6.8, 7.7, 8.0, 8.1);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);
$prob = Math::BigFloat->new($wilcox_test->probability_normal_approx());
$expected = 0.091022;
$pf = sprintf '%f', $prob;
ok(abs($prob-$expected)<0.00001, "$pf, normal approximation");

$prob = Math::BigFloat->new($wilcox_test->probability_exact());
$expected = 0.087668;
$pf = sprintf '%f', $prob;
ok(abs($prob-$expected)<0.00001, "$pf, exact");

diag('An example from http://www.saburchill.com/IBbiology/stats/002.html');
# An example from http://www.saburchill.com/IBbiology/stats/002.html
# rank sum 1 = 41.5
# rank sum 2 = 94.5
# The null hypothesis: rank sum 1 (or 2) is close to the expected rank sum (one obtained by chance)
# Result: the null hypothesis can be rejected at a 0.05 confidence level.
# Interpretation: The outcome that elements from dataset 2 are ranked higher is not due to chance
#                 with a confidence of 0.05

@dataset_1 = (6.0, 4.8, 5.1, 5.5, 4.1, 5.3, 4.5, 5.1);
@dataset_2 = (6.5, 5.5, 6.3, 7.2, 6.8, 5.5, 5.9, 5.5);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);
$prob = Math::BigFloat->new($wilcox_test->probability_normal_approx());
$pf = sprintf '%f', $prob;
$expected = 0.006323;
ok(abs($expected-$prob) < 0.00001, "$pf, normal approximation");

$prob = Math::BigFloat->new($wilcox_test->probability_exact());
$pf = sprintf '%f', $prob;
$expected = 0.002797;
ok(abs($expected-$prob) < 0.00001, "$pf, exact");

1;
