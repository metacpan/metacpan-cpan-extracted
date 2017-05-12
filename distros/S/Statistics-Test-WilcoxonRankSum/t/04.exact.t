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

my $lesser_W_count = $wilcox_test->smaller_rank_sums_count();
my $expected = 64;

ok( $lesser_W_count == $expected, 'Number of possible arrangements with lesser rank sum');

1;

