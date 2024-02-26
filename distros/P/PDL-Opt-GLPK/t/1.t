#!perl -T

use v5.26;
use warnings;
use Test2::V0 '!float';

use PDL;
use PDL::Opt::GLPK;

my $a = pdl('1, 1, 1, 1; 10, 4, 5, 1; 2, 2, 6, 1');
my $b = pdl(100, 600, 300);
my $c = pdl(10, 6, 4, -1);
my $lb = zeroes(4);
my $ub = inf(4);
my $ctype = GLP_UP * ones(3);
my $vtype = GLP_CV * ones(4);
#my $sense = pdl([GLP_MAX]);
my $sense = pdl(GLP_MAX);
my $xopt = null;
my $fopt = null;
my $status = null;
my %param = (msglev => 1, save_pb => 0);

glpk($c,  $a, $b, $lb, $ub, $ctype, $vtype, $sense,
    $xopt, $fopt, $status, null, null, \%param);

my $xexp = pdl(33.3333, 66.6667, 0, 0);
ok(all(approx $xopt, $xexp, 1e-4), 'xopt from GLPK example') ||
    diag "got $xopt";

my $fexp = 733.333;
ok(approx($fopt, $fexp, 1e-3), 'fopt from GLPK example') ||
    diag "got $fopt";

$a = identity(2);
$b = ones(2);
$c = -ones(2);
$ctype = GLP_DB * ones(2);
$vtype = GLP_CV * ones(2);
$lb = -inf(2);
$ub = ones(2);
#$sense = pdl([GLP_MAX]);
$sense = pdl(GLP_MAX);
$xopt = null;
$fopt = null;
$status = null;

glpk($c, $a, $b, $lb, $ub, $ctype, $vtype, $sense, $xopt, $fopt, $status);

ok(all(approx($xopt, pdl(-1, -1))), 'xopt GLP_DB') || diag "got $xopt";
ok(approx($fopt, 2), 'fopt GLP_DB') || diag "got $fopt";

done_testing;
