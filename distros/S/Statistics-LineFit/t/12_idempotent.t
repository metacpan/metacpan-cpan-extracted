# -*- perl -*-

# Verify that the methods return the same results on repeated calls

use strict;

use Test::More tests => 11;

my @x = (1, 2, 3, 4);
my @y = (1.2, 2.9, 19.1, 15.2,);

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new();
    is($lineFit->setData(\@x, \@y), 1, 'setData(\@x, \@y)');
    my @coeff1 = $lineFit->coefficients();
    my @coeff2 = $lineFit->coefficients();
    is_deeply(\@coeff1, \@coeff2, 'coefficients[0]');
    is($lineFit->durbinWatson(), $lineFit->durbinWatson(), 'durbinWatson()');
    is($lineFit->meanSqError(), $lineFit->meanSqError(), 'meanSqError()');
    my @predictedY1 = $lineFit->predictedYs();
    my @predictedY2 = $lineFit->predictedYs();
    is_deeply(\@predictedY1, \@predictedY2, 'predictedYs()');
    my @residuals1 = $lineFit->residuals();
    my @residuals2 = $lineFit->residuals();
    is_deeply(\@residuals1, \@residuals2, 'residuals()');
    is($lineFit->rSquared(), $lineFit->rSquared(), 'rSquared()');
    is($lineFit->sigma(), $lineFit->sigma(), 'sigma()');
    my @tStatistics1 = $lineFit->tStatistics();
    my @tStatistics2 = $lineFit->tStatistics();
    is_deeply(\@tStatistics1, \@tStatistics2, 'tStatistics[0]');
    my @varianceOfEstimates1 = $lineFit->varianceOfEstimates();
    my @varianceOfEstimates2 = $lineFit->varianceOfEstimates();
    is_deeply(\@varianceOfEstimates1, \@varianceOfEstimates2, 
        'varianceOfEstimates[0]');
};
is($@, '', 'eval error trap');
