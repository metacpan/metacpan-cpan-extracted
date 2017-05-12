# -*- perl -*-

# Test unweighted line fit using 100,000 points, 1-D arrays

use strict;

use Test::More tests => 12;

my $epsilon = 1.0e-10;
my (@x, @y);
for (my $i = 0; $i < 100000; ++$i) { 
    $x[$i] = $i;
    $y[$i] = sqrt($i);
}

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();
    is($lineFit->setData(\@x, \@y), 1, 'setData(\@x, \@y)');
    my @coefficients = $lineFit->coefficients();
    cmp_ok(abs($coefficients[0] - 84.3254986214062), "<", $epsilon, 
        'coefficients[0]');
    cmp_ok(abs($coefficients[1] - 0.00252985387534101), "<", $epsilon,
        'coefficients[1]');
    cmp_ok(abs($lineFit->durbinWatson() - 1.31194787800295e-07), "<", $epsilon,
        'durbinWatson()');
    cmp_ok(abs($lineFit->meanSqError() - 222.255904069674), "<", $epsilon,
        'meanSqError()');
    cmp_ok(abs($lineFit->rSquared() - 0.95999514370284), "<", $epsilon, 
        'rSquared()');
    cmp_ok(abs($lineFit->sigma() - 14.9083986154335), "<", $epsilon, 
        'sigma()');
    my @tStatistics = $lineFit->tStatistics();
    cmp_ok(abs($tStatistics[0] - 894.336968406119), "<", $epsilon, 
        'tStatistics[0]');
    cmp_ok(abs($tStatistics[1] - 1549.07989604865), "<", $epsilon, 
        'tStatistics[0]');
    my @varianceOfEstimates = $lineFit->varianceOfEstimates();
    cmp_ok(abs($varianceOfEstimates[0] - 8.96982691422364e-08), "<", $epsilon, 
        'varianceOfEstimates[0]');
    cmp_ok(abs($varianceOfEstimates[1] - 0.0), "<", $epsilon, 
        'varianceOfEstimates[0]');
};
is($@, '', 'eval error trap');
