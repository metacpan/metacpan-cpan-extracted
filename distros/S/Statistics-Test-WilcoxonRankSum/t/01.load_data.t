use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Statistics::Test::WilcoxonRankSum;
my @dataset_1 = qw(12 15 18 24 88);
my @dataset_2 = qw(3 3 13 27 33);

my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();
$wilcox_test->load_data(\@dataset_1, \@dataset_2);

my $ret_dataset1 = $wilcox_test->get_dataset1();
my $ret_dataset2 = $wilcox_test->get_dataset2();

is_deeply($ret_dataset1, \@dataset_1);
is_deeply($ret_dataset2, \@dataset_2);

my @zero_dataset = qw(0 0 0 0 0 0 0);

my $expected_exception = q(dataset has no element greater 0);

eval {
  $wilcox_test->set_dataset2(\@zero_dataset);
};

ok ($EVAL_ERROR =~ m{$expected_exception}ms, "Exception: $EVAL_ERROR\n when trying to set a dataset of zeroes");


1;

