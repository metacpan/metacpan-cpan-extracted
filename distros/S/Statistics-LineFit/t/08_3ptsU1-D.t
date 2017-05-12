# -*- perl -*-

# Test unweighted line fit, three points (an equilateral triangle), 1-D arrays

use strict;

use Test::More tests => 19;

my $epsilon = 1.0e-12;
my @x = (1, 1.5, 2);
my @y = (1, 1.866025403784438, 1);

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();
    is($lineFit->setData(\@x, \@y), 1, 'setData(\@x, \@y)');
    my @coefficients = $lineFit->coefficients();
    cmp_ok(abs($coefficients[0] - 1.28867513459481), "<", $epsilon, 
        'coefficients[0]');
    is($coefficients[1], 0, 'coefficients[1]');
    is($lineFit->durbinWatson(), 3, 'durbinWatson()');
    cmp_ok(abs($lineFit->meanSqError() - 0.166666666666666), "<", $epsilon,
        'meanSqError()');
    my @predictedY = $lineFit->predictedYs();
    my @results = (1.28867513459481, 1.28867513459481, 1.28867513459481);
    for (my $i = 0; $i < @predictedY; ++$i) {
        cmp_ok(abs($predictedY[$i] - $results[$i]), "<", $epsilon, 
            'predictedY()');
    }
    my @residuals = $lineFit->residuals();
    @results = (-0.288675134594813, 0.577350269189625, -0.288675134594813);
    for (my $i = 0; $i < @residuals; ++$i) {
        cmp_ok(abs($residuals[$i] - $results[$i]), "<", $epsilon, 
            'residuals()');
    }
    is($lineFit->rSquared(), 0, 'rSquared()');
    cmp_ok(abs($lineFit->sigma() - 0.707106781186547), "<", $epsilon, 
        'sigma()');
    my @tStatistics = $lineFit->tStatistics();
    cmp_ok(abs($tStatistics[0] - 0.828962859079729), "<", $epsilon, 
        'tStatistics[0]');
    is($tStatistics[1], 0, 'tStatistics[1]');
    my @varianceOfEstimates = $lineFit->varianceOfEstimates();
    cmp_ok(abs($varianceOfEstimates[0] - 0.412037037037036), "<", $epsilon, 
        'varianceOfEstimates[0]');
    cmp_ok(abs($varianceOfEstimates[1] - 0.166666666666666), "<", $epsilon, 
        'varianceOfEstimates[1]');
    my $sumSqErrors = 0;
    foreach my $residual (@residuals) { $sumSqErrors += $residual ** 2 }
    cmp_ok(abs($sumSqErrors - $lineFit->sumSqErrors()), "<", $epsilon,
        'sumSqErrors()');
};
is($@, '', 'eval error trap');
