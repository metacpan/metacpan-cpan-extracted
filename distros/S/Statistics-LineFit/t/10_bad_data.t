# -*- perl -*-

# Test calling setData() with invalid data

use strict;

use Test::More tests => 18;

eval {
    use Statistics::LineFit;
    my $lineFit = Statistics::LineFit->new(0, 1);

# Only one point
    my @x = (0);
    my @y = (-1);
    my @xy = ( [ (0, 1) ] );
    is($lineFit->setData(\@x, \@y), 0, 'setData(\@x, \@y)');
    is($lineFit->setData(\@xy), 0, 'setData(\@xy)');
    
# Data array lengths not equal
    @x = (0, 1, 2);
    @y = (-1, 0, 2, 3);
    is($lineFit->setData(\@x, \@y), 0, 'setData(\@x, \@y)');
    my ($intercept, $slope) = $lineFit->coefficients();
    ok(! defined $intercept, 'coefficients[0]');
    ok(! defined $slope, 'coefficients[1]');
    
# Weights arrray length is not equal to length of data arrays
    @x = (0, 1, 2);
    @y = (-1, 0, 2);
    @xy = ( [ (0, 1) ], [ (0, 1) ], [ (0, 1) ] );
    my @weights = (1, 2);
    is($lineFit->setData(\@x, \@y, \@weights), 0, 
        'setData(\@x, \@y, \@weights)');
    is($lineFit->setData(\@xy, \@weights), 0, 'setData(\@xy, \@weights)');
    
# Negative weights not allowed
    @weights = (-1, 2, 3);
    @x = (0, 1, 2);
    @y = (-1, 0, 2);
    @xy = ( [ (0, 1) ], [ (0, 1) ], [ (0, 1) ] );
    is($lineFit->setData(\@x, \@y, \@weights), 0, 
        'setData(\@x, \@y, \@weights)');
    is($lineFit->setData(\@xy, \@weights), 0, 'setData(\@xy, \@weights)');

# Weights must contain at least two nonzero values
    @weights = (1, 0, 0);
    is($lineFit->setData(\@x, \@y, \@weights), 0, 
        'setData(\@x, \@y, \@weights)');
    is($lineFit->setData(\@xy, \@weights), 0, 'setData(\@xy, \@weights)');
    
# Data arrays contain non-numeric data (validate = 1)
    $lineFit = Statistics::LineFit->new(1, 1);
    @x = (0, 1, 2);
    @y = (-1, 0, '1.0 e+3');
    is($lineFit->setData(\@x, \@y), 0, 'setData(\@x, \@y)');
    @x = ('- 1.0', 0, 1);
    @y = (-1, 0, 3);
    is($lineFit->setData(\@x, \@y), 0, 'setData(\@x, \@y)');
    @x = (undef, 0, 1);
    is($lineFit->setData(\@x, \@y), 0, 'setData(\@x, \@y)');
    @x = (0, 1, 2);
    @y = (-1, 0, undef);
    is($lineFit->setData(\@x, \@y), 0, 'setData(\@x, \@y)');

# Weight array contains non-numeric data (validate = 1)
    @weights = (1, '2.0,', 3);
    @x = (0, 1, 2);
    @y = (-1, 0, 4);
    is($lineFit->setData(\@x, \@y, \@weights), 0, 
        'setData(\@x, \@y, \@weights)');
    @weights = (1, 2, undef);
    is($lineFit->setData(\@x, \@y, \@weights), 0, 
        'setData(\@x, \@y, \@weights)');
};
is($@, '', 'eval error trap');
