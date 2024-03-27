#!perl -T

use Test2::V0 '!float';
use Test2::Require::Module 'PDL::CCS';

use PDL;
use PDL::Opt::GLPK;
use PDL::CCS;

my $m = 11;
my $n = 10;
my $w1 = yvals(2, $n);
my $w2 = $w1->copy;
$w2->slice('0') += 1;
my $w = $w1->glue(1, $w2);
my $a = PDL::CCS::Nd->newFromWhich($w, ones($n)->append(-ones($n)));
my $b = ones $n;
my $c = ones double, $m;
my $lb = zeroes($m);
my $ub = $m * ones($m);
my $ctype = GLP_LO * ones($n);
my $vtype = GLP_CV * ones($m);
my $sense = GLP_MAX;
my $xopt = null;
my $fopt = null;
my $status = null;

glpk($c, $a, $b, $lb, $ub, $ctype, $vtype, $sense, $xopt, $fopt, $status);

#say "status: $status";
#say "xopt: $xopt";
#say "fopt: $fopt";
#say "lambda: $lambda";
#say "redcosts: $redcosts";

ok all(approx($xopt, $m - sequence($m))), 'CCS matrix';

done_testing;
