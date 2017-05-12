# -*- perl -*-

# Test unweighted line fit using five points, 1-D arrays
# Test multiple calls using the same object and different data

use strict;

use Test::More tests => 26;

my $epsilon = 1.0e-12;
my @x = (1, 2, 3, 4, 5);
my @y = (1, 2, 3, 4, 5);

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();
    is($lineFit->setData(\@x, \@y), 1, 'setData(\@x, \@y)');
    my @coefficients = $lineFit->coefficients();
    is_deeply(\@coefficients, [ (0, 1) ], 'coefficients()');
    is($lineFit->durbinWatson(), 0, 'durbinWatson()');
    is($lineFit->meanSqError(), 0, 'meanSqError()');
    my @predictedY = $lineFit->predictedYs();
    is_deeply(\@predictedY, [ (1, 2, 3, 4, 5) ], 'predictedYs()');
    my @residuals = $lineFit->residuals();
    is_deeply(\@residuals, [ (0, 0, 0, 0, 0) ], 'residuals()');
    is($lineFit->rSquared(), 1, 'rSquared()');
    is($lineFit->sigma(), 0, 'sigma()');
    my @tStatistics = $lineFit->tStatistics();
    is_deeply(\@tStatistics, [ (0, 0) ], 'tStatistics()');
    my @varianceOfEstimates = $lineFit->varianceOfEstimates();
    is(@varianceOfEstimates, 0, 'varianceOfEstimates()');
    my $sumSqErrors = 0;
    foreach my $residual (@residuals) { $sumSqErrors += $residual ** 2 }
    cmp_ok(abs($sumSqErrors - $lineFit->sumSqErrors()), "<", $epsilon,
        'sumSqErrors()');

    @x = (-1, -2, 3, 4);
    @y = (-1.02, 1.9, -3.2, 5);
    is($lineFit->setData(\@x, \@y), 1, 'setData(\@x, \@y)');
    @coefficients = $lineFit->coefficients();
    cmp_ok(abs($coefficients[0] - 0.48), "<", $epsilon, 'coefficients[0]');
    cmp_ok(abs($coefficients[1] - 0.19), "<", $epsilon, 'coefficients[1]');
    cmp_ok(abs($lineFit->durbinWatson() - 2.9721742266432), "<", $epsilon,
        'durbinWatson()');
    cmp_ok(abs($lineFit->meanSqError() - 9.28905), "<", $epsilon,
        'meanSqError()');
    @predictedY = $lineFit->predictedYs();
    is_deeply(\@predictedY, [ (0.29, 0.1, 1.05, 1.24) ], 'predictedYs()');
    @residuals = $lineFit->residuals();
    is_deeply(\@residuals, [ (-1.31, 1.8, -4.25, 3.76) ], 'predictedYs()');
    cmp_ok(abs($lineFit->rSquared() - 0.0246385333431334), "<", $epsilon, 
        'rSquared()');
    cmp_ok(abs($lineFit->sigma() - 4.31023201231674), "<", $epsilon, 
        'sigma()');
    @tStatistics = $lineFit->tStatistics();
    cmp_ok(abs($tStatistics[0] - 0.20734646307841), "<", $epsilon, 
        'tStatistics[0]');
    cmp_ok(abs($tStatistics[1] - 0.224770663113769), "<", $epsilon, 
        'tStatistics[0]');
    @varianceOfEstimates = $lineFit->varianceOfEstimates();
    cmp_ok(abs($varianceOfEstimates[0] - 1.17115479964839), "<", $epsilon, 
        'varianceOfEstimates[0]');
    cmp_ok(abs($varianceOfEstimates[1] - 0.345662317339679), "<", $epsilon, 
        'varianceOfEstimates[0]');
    $sumSqErrors = 0;
    foreach my $residual (@residuals) { $sumSqErrors += $residual ** 2 }
    cmp_ok(abs($sumSqErrors - $lineFit->sumSqErrors()), "<", $epsilon, 
        'sumSqErrors()');
};
is($@, '', 'eval error trap');
