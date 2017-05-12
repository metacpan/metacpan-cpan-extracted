# -*- perl -*-

# Test unweighted line fit using two points, 1-D arrays

use strict;

use Test::More tests => 11;

my @x = (1000, 2000);
my @y = (-1000, -2000);

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();
    is($lineFit->setData(\@x, \@y), 1, 'setData(\@x, \@y)');
    my @coefficients = $lineFit->coefficients();
    is_deeply(\@coefficients, [ (0, -1) ], 'coefficients()');
    is($lineFit->durbinWatson(), 0, 'durbinWatson()');
    is($lineFit->meanSqError(), 0, 'meanSqError()');
    my @predictedY = $lineFit->predictedYs();
    is_deeply(\@predictedY, [ (-1000, -2000) ], 'predictedYs()');
    my @residuals = $lineFit->residuals();
    is_deeply(\@residuals, [ (0, 0) ], 'residuals()');
    is($lineFit->rSquared(), 1, 'rSquared()');
    is($lineFit->sigma(), 0, 'sigma()');
    my @tStatistics = $lineFit->tStatistics();
    is_deeply(\@tStatistics, [ (0, 0) ], 'tStatistics()');
    my @varianceOfEstimates = $lineFit->varianceOfEstimates();
    is(@varianceOfEstimates, 0, 'varianceOfEstimates()');
};
is($@, '', 'eval error trap');
