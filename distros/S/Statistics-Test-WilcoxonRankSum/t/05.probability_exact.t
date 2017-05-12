use lib 'lib';

use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Math::BigFloat;
use Statistics::Test::WilcoxonRankSum;

my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();

my @dataset_1 = qw(12 15 18 24 88);
my @dataset_2 = qw(3 3 13 27 33);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

my $prob = Math::BigFloat->new($wilcox_test->probability());
my $expected = Math::BigFloat->new(0.507937);

my $diff = abs($prob-$expected);
ok($diff < 0.0001, "Exact probability");

1;

