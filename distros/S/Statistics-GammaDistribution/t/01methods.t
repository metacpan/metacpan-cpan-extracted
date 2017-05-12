# *-*-perl-*-*
use strict;
use warnings;
use Test::More tests => 2;

use Statistics::GammaDistribution;
my $g = Statistics::GammaDistribution->new();
$g->set_order(1);
$g->rand(1);
$g->set_order(0.1);
$g->rand(1);
$g->set_order(23.4);
$g->rand(1);
$g->set_order(65535);
$g->rand(1);
pass("rand() doesn't crash!");

my @alpha = (0.5,0.5,4.5,20,20.5,6.5,1.5,0.5);
my @theta = $g->dirichlet_dist(@alpha);
pass("dirichlet doesn't crash!");
