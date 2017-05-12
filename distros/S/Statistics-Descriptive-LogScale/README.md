# DESCRIPTION

**Statistics::Descriptive::LogScale** - Memory-efficient approximate
univariate statistical analysis module.

# FEATURES

* Efficiency - can handle very large samples without loading them into memory,
at the cost of predictable small relative error (see DATA MODEL below);

* Power - can report all kind of values - mean, variance, percentiles,
moments of any power, probability to hit specific interval,
even integrate arbitrary function over the sample;

* Persistence - can save, load, and combine data sets, as well as cut
part of the sample within given range;

* Visualization - can output data in form of a histogram array to draw
pictures;

* Compatibility - can be used in place of  _Statistics::Descriptive::Full_
whenever retaining exact initial data points isn't required.

# SINOPSIS

	use strict;
	use warnings;
    use Statistics::Descriptive::LogScale;

    my $stat = Statistics::Descriptive::LogScale->new (
        base => 1.01,
        linear_width => 0.001,
    );

	while (<>) {
		$stat->add_data($_) for /(-?\d+(?:\.\d*)?)/g;
	};
    # add more data....

	printf "   minimal value: %f\n", $stat->min;
    printf "%3uth percentile: %f\n", $_*10, $stat->percentile($_*10)
		for 1..10;

See more in the perldoc. See also example directory:

* example/summary.pl - short summary

* example/compare-full.pl - side-by-side comparison
with Statistics::Descriptive::Full

* example/histogram.pl - text-based histogram

* example/png-histogram.pl - png histogram, can load JSON-encoded sample

* example/save-load.pl - save/load sample to JSON files

* example/gen-sample.pl - not really an example,
but a clumsy random distributions generator.
Use it to fake random test data, in case you don't have some at hand.

# DATA MODEL

The data is divided into logarithmic intervals, or bins, i.e.
such that upper boundary/lower boundary ratio is constant across all bins.
This allows to store data spanning orders of magnitude
while maintaining a guaranteed relative precision.

For instance, the default bin ratio is `10^1/232`, which is approximately `1%`
and allows sorting numbers from `1` to `1000000` into like `1400` bins.

Additionally, linear approximation can be used around zero to save memory.
The incoming data is rarely absolutely precise anyway.
The threshold under which linear interpolation is used is roughly
(precision of data)/(bin ratio).
By default, data is assumed to be precise, so linear approximation is not used.

# INSTALLATION

Most likely, you need to install the latest stable version from CPAN:

    cpanm Statistics::Descriptive::LogScale

However, for installing this very package, the following can be used:

    perl Makefile.PL
    make
    make test
    make install

# WHY THIS MODULE

Initially it was started out as a quick and dirty performance analysis tool.
It turned out that in some cases average values do not tell that much,
as in "your service responds in 0.1 +- 10 seconds".

Another usage can be long-running and/or memory-limited applications.
It's possible to save data samples and/or send them over the network,
as well as gradually "forget" old data.

Ideally, it should become *the* tool for preliminary analysis and drawing
funny pictures until one realises they need serious stuff like R.

# BUGS AND LIMITATIONS

This software is still under development and has not experienced enough
usage, so there may be bugs.

Mode calculation algorithm only works well for discrete distributions,
and needs improvement.

Data inspection methods are wanted.

C and Javascript translations are wanted. XS would be a boon.

The error introduced by approximation have not been studied well
enough yet. It may turn out that tweaking the model could win some precision.

# SUPPORT AND DOCUMENTATION

The module itself is moderately well documented, so you can use

    perldoc Statistics::Descriptive::LogScale

As of May 2015, you can find the latest and greatest version of this package at
https://github.com/dallaylaen/perl-Statistics-Descriptive-LogScale

Please, report bugs there, if you can. Alternatively,
[CPAN RT](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Descriptive-LogScale)
is at your service.

# ACKNOLEDGEMENTS

This module was inspired by a talk that Andrew Aksyonoff, author of
[Sphinx search software](http://sphinxsearch.com/),
has given at HighLoad++ conference in Moscow, 2012.

[Statistics::Descriptive::Full](https://metacpan.org/pod/Statistics::Descriptive::Full) 
was and is used as reference when in doubt.
Several code snippets were shamelessly stolen from there.

`linear_width` and `linear_threshold` parameter names were suggested by
[CountZero](http://perlmonks.org/?node=countzero) from http://perlmonks.org

# COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 Konstantin S. Uvarin

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
