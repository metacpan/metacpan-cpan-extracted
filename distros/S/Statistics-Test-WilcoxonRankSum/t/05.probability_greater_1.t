use lib 'lib';

use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Math::BigFloat;
use Statistics::Test::WilcoxonRankSum;

my $w_test = Statistics::Test::WilcoxonRankSum->new();

my @d1 = qw(0.735 0.745 0.828 0.826); 
my @d2 = qw(0.847 0.837 0.719 0.668);

$w_test->load_data(\@d1, \@d2);

my $prob_exact = $w_test->probability();

ok($prob_exact>=1, "Probability must be at most 1");


1;

