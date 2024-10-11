# NAME

Statistics::Running::Tiny - Basic descriptive statistics (mean/stdev/min/max/skew/kurtosis) over data without the need to store data points ever. OOP style. The Tiny version.

# VERSION

Version 0.04

# SYNOPSIS

        use Statistics::Running::Tiny;
        my $ru = Statistics::Running::Tiny->new();
        for(1..100){
                $ru->add(rand());
        }
        print "mean: ".$ru->mean()."\n";
        $ru->add(12345);
        print "mean: ".$ru->mean()."\n";

        my $ru2 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru2->add(rand());
        }
        my $ru3 = $ru + $ru2;
        print "mean of concatenated data: ".$ru3->mean()."\n";

        $ru += $ru2;
        print "mean after appending data: ".$ru->mean()."\n";

        print "stats: ".$ru->stringify()."\n";

# DESCRIPTION

Calculate basic descriptive statistics (mean, variance, standard deviation, skewness, kurtosis)
without the need to store any data point/sample. Statistics are
updated each time a new data point/sample comes in.

There are three amazing things about B.P.Welford's algorithm implemented here:

- 1. It calculates and keeps updating mean/standard-deviation etc. on 
data without the need to store that data. As new data comes in, the
statistics are updated based on the state of a few variables (mean, number
of data points, etc.) but not the past data points. This includes the
calculation of standard deviation which most of us knew (wrongly) that
it requires a second pass on the data points, after the mean is calculated.
Well, B.P.Welford found a way to avoid this.
- 2. The standard formula for standard deviation requires to sum
the square of the difference of each sample from the mean.
If samples are large numbers then you are summing differences of large
numbers. If further there is little difference between samples, and the
discrepancy from the mean is small, then you are prone to
precision errors which accumulate to destructive effect if the number of
samples is large. In contrast,  B.P.Welford's algorithm does
not suffer from this, it is stable and accurate.
- 3. B.P.Welford's online statistics algorithm
is quite a revolutionary idea and why is not an obligatory subject
in first-year programming courses is beyond comprehension.
Here is a way to decrease those CO2 emissions.

The basis for the code in this module is from 
[John D. Cook's article and C++ implementation](https://www.johndcook.com/blog/skewness_kurtosis)

# EXPORT

Nothing, this is an Object Oriented module. Once you instantiate
an object all its methods are yours.

# SUBROUTINES/METHODS

## new

Constructor, initialises internal variables.

## add

Update our statistics after one more data point/sample (or an
array of them) is presented to us.

        my $ru1 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru1->add(rand());
                print $ru1."\n";
        }

Input can be a single data point (a scalar) or a reference
to an array of data points.

## copy\_from

Copy state of input object into current effectively making us like
them. Our previous state is forgotten. After that adding a new data point into
us will be with the new state copied.

        my $ru1 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru1->add(rand());
        }
        my $ru2 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru2->add(rand(1000000));
        }
        # copy the state of ru1 into ru2. state of ru1 is forgotten.
        $ru2->copy_from($ru1);

## clone

Clone state of our object into a newly created object which is returned.
Our object and returned object are identical at the time of cloning.

        my $ru1 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru1->add(rand(1000000));
        }
        my $ru2 = $ru1->clone();

## clear

Clear our internal state as if no data points have ever added into us.
As if we were just created. All state is forgotten and reset to zero.

## mean

Returns the mean of all the data pushed in us

## sum

Returns the sum of all the data pushed in us (algebraic sum, not absolute sum)

## abs\_sum

Returns the sum of the absolute value of all the data pushed in us (this is not algebraic sum)

## min

Returns the minimum data sample added in us

## max

Returns the maximum data sample added in us

## get\_N

Returns the number of data points/samples inserted, and had
their descriptive statistics calculated, so far.

## variance

Returns the variance of the data points/samples added onto us so far.

## standard\_deviation

Returns the standard deviation of the data points/samples added onto us so far. This is the square root of the variance.

## skewness

Returns the skewness of the data points/samples added onto us so far.

## kurtosis

Returns the kurtosis of the data points/samples added onto us so far.

## concatenate

Concatenates our state with the input object's state and returns
a newly created object with the combined state. Our object and
input object are not modified. The overloaded symbol '+' points
to this sub.

## append

Appends input object's state into ours.
Our state is modified. (input object's state is not modified)
The overloaded symbol '+=' points
to this sub.

## equals

Check if our state (number of samples and all internal state) is
the same with input object's state. Equality here implies that
ALL statistics are equal (within a small number Statistics::Running::Tiny::SMALL\_NUMBER\_FOR\_EQUALITY)

## equals\_statistics

Check if our statistics only (and not sample size)
are the same with input object. E.g. it checks mean, variance etc.
but not sample size (as with the real equals()).
It returns 0 on non-equality. 1 if equal.

## stringify

Returns a string description of descriptive statistics we know about
(mean, standard deviation, kurtosis, skewness) as well as the
number of data points/samples added onto us so far. Note that
this method is not necessary because stringification is overloaded
and the follow **print $stats\_obj."\\n"** is equivalent to
**print $stats\_obj->stringify()."\\n"**

# Overloaded functionality

- 1. Addition of two statistics objects: **my $ru3 = $ru1 + $ru2**
- 2. Test for equality: **if( $ru2 == $ru3 ){ ... }**
- 3. Stringification: **print $ru1."\\n"**

# Testing for Equality

In testing if two objects are the same, their means, standard deviations
etc. are compared. This is done using
**if( ($self->mean() - $other->mean()) < Statistics::Running::SMALL\_NUMBER\_FOR\_EQUALITY ){ ... }**

# BENCHMARKS

Run **make bench** for benchmarks which report the maximum number of data points inserted
per second (in your system).

# SEE ALSO

- 1. [Wikipedia](http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Online_algorithm)
- 2. [John D. Cook's article and C++ implementation](https://www.johndcook.com/blog/skewness_kurtosis)
was used both as inspiration and as the basis for the formulas for **kurtosis()** and **skewness()**
- 3. [Statistics::Welford](https://metacpan.org/pod/Statistics%3A%3AWelford) This module does not provide **kurtosis()** and **skewness()**
which current module does.
- 4. [Statistics::Running](https://metacpan.org/pod/Statistics%3A%3ARunning) This is the exact same module with the addition of
a histogram logging each inserted data point. The histogram is in effect
a discrete approximation of the Probability Distribution of the input data
points. The current module is the same as that bar the histogram. That
makes it a bit faster. Check **make bench** for benchmarks

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-statistics-running at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Running](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Running).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Running::Tiny

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Running](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Running)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Statistics-Running](http://annocpan.org/dist/Statistics-Running)

- Review this module at PerlMonks

    [https://www.perlmonks.org/?node\_id=21144](https://www.perlmonks.org/?node_id=21144)

- Search CPAN

    [http://search.cpan.org/dist/Statistics-Running/](http://search.cpan.org/dist/Statistics-Running/)

# DEDICATIONS

Almaz

# ACKNOWLEDGEMENTS

B.P.Welford, John Cook.

# LICENSE AND COPYRIGHT

Copyright 2018-2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
