# -*- perl -*-

# Test weighted line fit using four points, 2-D array
# Test alternate calling sequence (compared to test 05_4ptsU2-D)

use strict;

use Test::More tests => 21;

my $epsilon = 1.0e-12;
my @x = (1, 2, 3, 4);
my @y = (1.2, 1.9, 3.1, 4.2,);
my @xy;
for (my $i = 0; $i < @x; ++$i) { $xy[$i] = [ ($x[$i], $y[$i]) ] }
my @weights = (0.1, 0.3, 0.2, 0.4);

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();
    is($lineFit->setData(\@xy, \@weights), 1, 'setData(\@xy, \@weights)');
    cmp_ok(abs($lineFit->sigma() - 0.149494561283058), "<", $epsilon, 
        'sigma()');
    my @coefficients = $lineFit->coefficients();
    cmp_ok(abs($coefficients[0] - -0.120183486238534), "<", $epsilon, 
        'coefficients[0]');
    cmp_ok(abs($coefficients[1] - 1.07247706422018), "<", $epsilon, 
        'coefficients[1]');
    my @residuals = $lineFit->residuals();
    my @results = (0.24770642201835, -0.124770642201834, 0.00275229357798157,
        0.0302752293577973);
    for (my $i = 0; $i < @residuals; ++$i) {
        cmp_ok(abs($residuals[$i] - $results[$i]), "<", $epsilon, 
            'residuals()');
    }
    cmp_ok(abs($lineFit->rSquared() - 0.991165853485171), "<", $epsilon, 
        'rSquared()');
    my @tStatistics = $lineFit->tStatistics();
    cmp_ok(abs($tStatistics[0] - -0.544629105447965), "<", $epsilon, 
        'tStatistics[0]');
    cmp_ok(abs($tStatistics[1] - 14.9797948208089), "<", $epsilon, 
        'tStatistics[0]');
    my @varianceOfEstimates = $lineFit->varianceOfEstimates();
    cmp_ok(abs($varianceOfEstimates[0] - 3.85435204917384e-05), "<", $epsilon, 
        'varianceOfEstimates[0]');
    cmp_ok(abs($varianceOfEstimates[1] - 5.24491637451941e-06), "<", $epsilon, 
        'varianceOfEstimates[0]');
    my $sumSqErrors = 0;
    for (my $i = 0; $i < @residuals; ++$i) {
        $sumSqErrors += $residuals[$i] ** 2 * $weights[$i];
    }
    cmp_ok(abs($sumSqErrors - $lineFit->sumSqErrors()), "<", $epsilon,
        'sumSqErrors()');
    cmp_ok(abs($lineFit->meanSqError() - 0.011174311926607), "<", $epsilon,
        'meanSqError()');
    cmp_ok(abs($lineFit->durbinWatson() - 3.48475090763877), "<", $epsilon,
        'durbinWatson()');
    my @predictedY = $lineFit->predictedYs();
    @results = (0.95229357798165, 2.02477064220183, 3.09724770642202,
        4.1697247706422);
    for (my $i = 0; $i < @predictedY; ++$i) {
        cmp_ok(abs($predictedY[$i] - $results[$i]), "<", $epsilon, 
            'predictedY()');
    }
};
is($@, '', 'eval error trap');
