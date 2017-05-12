# -*- perl -*-

# Verify that methods return undefined values if setData() was not called

use strict;

use Test::More tests => 13;

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new(0, 1);
    my ($intercept, $slope) = $lineFit->coefficients();
    ok(! defined $intercept, 'coefficients[0]');
    ok(! defined $slope, 'coefficients[1]');
    ok(! defined $lineFit->durbinWatson(), 'durbinWatson()');
    ok(! defined $lineFit->meanSqError(), 'meanSqError()');
    ok(! defined $lineFit->predictedYs(), 'predictedYs()');
    ok(! defined $lineFit->residuals(), 'residuals()');
    ok(! defined $lineFit->rSquared(), 'rSquared()');
    ok(! defined $lineFit->sigma(), 'sigma()');
    my ($tStatIntercept, $tStatSlope) = $lineFit->tStatistics();
    ok(! defined $tStatIntercept, 'tStatIntercept');
    ok(! defined $tStatSlope, 'tStatSlope');
    my ($varianceIntercept, $varianceSlope) = $lineFit->varianceOfEstimates();
    ok(! defined $varianceIntercept, 'varianceIntercept');
    ok(! defined $varianceSlope, 'varianceSlope');
};
is($@, '', 'eval error trap');
