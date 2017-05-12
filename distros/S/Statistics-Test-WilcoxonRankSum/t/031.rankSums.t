use lib 'lib';

use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Statistics::Test::WilcoxonRankSum;

my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();

my @dataset_1 = qw(12 15 18 24 88);
my @dataset_2 = qw(3 3 13 27 33);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

my $smaller_rank_sum = $wilcox_test->get_smaller_rank_sum();
ok( $smaller_rank_sum == 24, 'Smaller rank sum');

1;

