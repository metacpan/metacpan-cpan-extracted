# -*- perl -*-

# Test that multiplying the weights by a constant does not change results

use strict;

use Test::More tests => 25;

my $epsilon = 1.0e-10;
my (@x, @y, @weights);
my $n = 100;
for (my $i = 0; $i < $n; ++$i) {
    $x[$i] = $i + 1;
    $y[$i] = $i ** 0.75;
    if ($i % 3 == 0) { 
        $weights[$i] = $i;
    } elsif ($i % 2 == 0) {
        $weights[$i] = 50;
    } else {
        $weights[$i] = $n + 1 - $i;
    }
}

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();

# Test absolute value of results
    is($lineFit->setData(\@x, \@y, \@weights), 1, 
        'setData1(\@x, \@y, \@weights)');
    my $rSquared1 = $lineFit->rSquared();
    cmp_ok(abs($rSquared1 - 0.991788159320494), "<", $epsilon, 'rSquared1()');
    my $durbinWatson1 = $lineFit->durbinWatson();
    cmp_ok(abs($durbinWatson1 - 0.0192675216315352), "<", $epsilon,
        'durbinWatson1()');
    my @tStatistics1 = $lineFit->tStatistics();
    cmp_ok(abs($tStatistics1[0] - 18.7895097501605), "<", $epsilon, 
        'tStatistics1[0]');
    cmp_ok(abs($tStatistics1[1] - 108.793322452779), "<", $epsilon, 
        'tStatistics1[0]');
    my @varianceOfEstimates1 = $lineFit->varianceOfEstimates();
    cmp_ok(abs($varianceOfEstimates1[0] - 0.000758134044735196), "<", $epsilon, 
        'varianceOfEstimates1[0]');
    cmp_ok(abs($varianceOfEstimates1[1] - 1.78672521866159e-07), "<", $epsilon, 
        'varianceOfEstimates1[0]');
    my $meanSqError1 = $lineFit->meanSqError();
    cmp_ok(abs($meanSqError1 - 0.603149693112746), "<", $epsilon,
        'meanSqError1()');
    my $sigma1 = $lineFit->sigma();
    cmp_ok(abs($sigma1 - 0.784511867675187), "<", $epsilon, 'sigma1()');
    my @coefficients1 = $lineFit->coefficients();
    cmp_ok(abs($coefficients1[0] - 2.9923929074799), "<", $epsilon, 
        'coefficients1[0]');
    cmp_ok(abs($coefficients1[1] - 0.295653654441678), "<", $epsilon, 
        'coefficients1[1]');
    my $sumSqErrors1 = 0;
    my @residuals = $lineFit->residuals();
    for (my $i = 0; $i < @residuals; ++$i) {
        $sumSqErrors1 += $residuals[$i] ** 2 * $weights[$i];
    }
    cmp_ok(abs($sumSqErrors1 - $lineFit->sumSqErrors()), "<", $epsilon,
        'sumSqErrors1()');

# Rescale weights and verify the results are the same
    for (my $i = 0; $i < $n; ++$i) { $weights[$i] *= 1000 }
    is($lineFit->setData(\@x, \@y, \@weights), 1, 
        'setData2(\@x, \@y, \@weights)');
    cmp_ok(abs($lineFit->rSquared() - $rSquared1), "<", $epsilon, 'rSquared()');
    cmp_ok(abs($lineFit->durbinWatson() - $durbinWatson1), "<", $epsilon,
        'durbinWatson2()');
    my @tStatistics2 = $lineFit->tStatistics();
    cmp_ok(abs($tStatistics2[0] - $tStatistics1[0]), "<", $epsilon, 
        'tStatistics2[0]');
    cmp_ok(abs($tStatistics1[1] - 108.793322452779), "<", $epsilon, 
        'tStatistics2[0]');
    my @varianceOfEstimates2 = $lineFit->varianceOfEstimates();
    cmp_ok(abs($varianceOfEstimates2[0] - $varianceOfEstimates1[0]), "<", 
        $epsilon, 'varianceOfEstimates2[0]');
    cmp_ok(abs($varianceOfEstimates1[1] - 1.78672521866159e-07), "<", $epsilon, 
        'varianceOfEstimates2[0]');
    cmp_ok(abs($lineFit->meanSqError() - $meanSqError1), "<", $epsilon,
        'meanSqError2()');
    cmp_ok(abs($lineFit->sigma() - $sigma1), "<", $epsilon, 'sigma2()');
    my @coefficients2 = $lineFit->coefficients();
    cmp_ok(abs($coefficients2[0] - $coefficients1[0]), "<", $epsilon, 
        'coefficients2[0]');
    cmp_ok(abs($coefficients2[1] - $coefficients1[1]), "<", $epsilon, 
        'coefficients2[1]');
    my $sumSqErrors2 = 0;
    @residuals = $lineFit->residuals();
    for (my $i = 0; $i < @residuals; ++$i) {
        $sumSqErrors2 += $residuals[$i] ** 2 * $weights[$i];
    }
    cmp_ok(abs($sumSqErrors2 - $sumSqErrors1), "<", $epsilon, 'sumSqErrors2()');
};
is($@, '', 'eval error trap');
