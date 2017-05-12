# -*- perl -*-

# Test unweighted line fit using four points, 1-D arrays

use strict;

use Test::More tests => 18;

my $epsilon = 1.0e-12;
my @x = (1, 2, 3, 4);
my @y = (1.2, 1.9, 3.1, 4.2,);

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();
    is($lineFit->setData(\@x, \@y), 1, 'setData(\@x, \@y)');
    my @coefficients = $lineFit->coefficients();
    cmp_ok(abs($coefficients[0] - 0.0499999999999972), "<", $epsilon, 
        'coefficients[0]');
    cmp_ok(abs($coefficients[1] - 1.02), "<", $epsilon, 'coefficients[1]');
    cmp_ok(abs($lineFit->durbinWatson() - 2.43448275862085), "<", $epsilon,
        'durbinWatson()');
    cmp_ok(abs($lineFit->meanSqError() - 0.0144999999999991), "<", $epsilon,
        'meanSqError()');
    my @predictedY = $lineFit->predictedYs();
    is_deeply(\@predictedY, [ (1.07, 2.09, 3.11, 4.13) ], 'predictedYs()');
    my @residuals = $lineFit->residuals();
    my @results = (0.130000000000002, -0.189999999999999, -0.00999999999999979,
        0.0699999999999994);
    for (my $i = 0; $i < @residuals; ++$i) {
        cmp_ok(abs($residuals[$i] - $results[$i]), "<", $epsilon,
            'residuals()');
    }
    cmp_ok(abs($lineFit->rSquared() - 0.988973384030419), "<", $epsilon, 
        'rSquared()');
    cmp_ok(abs($lineFit->sigma() - 0.170293863659259), "<", $epsilon, 
        'sigma()');
    my @tStatistics = $lineFit->tStatistics();
    cmp_ok(abs($tStatistics[0] - 0.239731650742686), "<", $epsilon, 
        'tStatistics[0]');
    cmp_ok(abs($tStatistics[1] - 13.3932561516921), "<", $epsilon, 
        'tStatistics[0]');
    my @varianceOfEstimates = $lineFit->varianceOfEstimates();
    cmp_ok(abs($varianceOfEstimates[0] - 0.0193944771559506), "<", $epsilon, 
        'varianceOfEstimates[0]');
    cmp_ok(abs($varianceOfEstimates[1] - 0.00213610609637551), "<", $epsilon, 
        'varianceOfEstimates[0]');
    my $sumSqErrors = 0;
    foreach my $residual (@residuals) { $sumSqErrors += $residual ** 2 }
    cmp_ok(abs($sumSqErrors - $lineFit->sumSqErrors()), "<", $epsilon, 
        'sumSqErrors()');
};
is($@, '', 'eval error trap');
