# NAME

Statistics::Cook - Statistics::Cook - calculate cook distance of Least squares line fit

# VERSION

version 0.0.6

# SYNOPSIS

    use Statistics::Cook;
    my @x = qw/1 2 3 4 5 6/;
    my @y = qw/1 2.1 3.2 4 7 6/;
    my $sc = Statistics::Cook->new(x => \@x, y => \@y);
    ($intercept, $slope) = $sc->coefficients;
    my @predictedYs = $sc->fitted;
    my @residuals = $sc->residuals;
    my @cooks = $sc->cooks_distance;

# DESCRIPTION

The Statistics::Cook module is used to calculate cook distance of Least squares line fit to
two-dimensional data (y = a + b \* x). (This is also called linear regression.)
In addition to the slope and y-intercept, the module, the predicted y values and the
residuals of the y values. (See the METHODS section for a description of these statistics.)

The module accepts input data in separate x and y arrays. The optional weights are input in a separate array
The module is state-oriented and caches its results. you can call the other methods in any order
or call a method several times without invoking redundant calculations.

# LIMITATIONS

The purpose of I write this module is that I could not find a module to calculate cook distance in CPAN,
Therefore I just realized this module with  a minimized function consists of least squares and cook distance

# ATTRIBUTES

## x

x coordinate that used to linear regression and cook distance, is a ArrayRef

## y

y coordinate that used to linear regression and cook distance, is a ArrayRef

## weight

weights that used to linear regression and cook distance, is a ArrayRef

## slope

slope value of linear model

## intercept

intercept of y in linear model

## regress\_done

the status whether has done linear regress

# METHODS

The module is state-oriented and caches its results. Once you have done regress, you can call
the other methods in any order or call a method several times without invoking redundant calculations.

The regression fails if the x values are all the same. In this case, the module issues an error message

## regress

Do the least squares line fit, but you don't need to call this method because it is invoked by the
other methods as needed,  you can call regress() at any time to get the status of the regression
for the current data.

## computeSums

Computing some value that used by regress, that you usually need not use it.

## coefficients

Return the slope and y intercept

## fitted

Return the fitted y values

## residuals

Return residuals of y values

## cooks\_distance

Calculate cook distance of linear model

## N

default is get N50 of a ArrayRef
$self->N(\[1,2,3,4\], 90), you will get N90
$self->N(\[1,2,3,4\], 80), you will get N80

## mean

mean value of an array

## var

The variance of a set of samples

## sd

The standard deviation of a set of samples

# AUTHOR

Yan Xueqing <yanxueqing621@163.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
