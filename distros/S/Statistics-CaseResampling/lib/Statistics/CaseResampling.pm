package Statistics::CaseResampling;
use 5.008001;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.15';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  resample
  resample_medians
  resample_means
  select_kth
  median
  median_absolute_deviation
  first_quartile
  third_quartile
  mean
  simple_confidence_limits_from_samples
  median_simple_confidence_limits
  approx_erf
  approx_erf_inv
  nsigma_to_alpha
  alpha_to_nsigma
  sample_standard_deviation
  population_standard_deviation
);
our @EXPORT = qw();
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

require XSLoader;
XSLoader::load('Statistics::CaseResampling', $VERSION);

our $Rnd = Statistics::CaseResampling::RdGen::setup(rand());


1;
__END__

=head1 NAME

Statistics::CaseResampling - Efficient resampling and calculation of medians with confidence intervals

=head1 SYNOPSIS

  use Statistics::CaseResampling ':all';
  
  my $sample = [1,3,5,7,1,2,9]; # ... usually MUCH more data ...
  my $confidence = 0.95; # ~2*sigma or "90% within confidence limits"
  #my $confidence = 0.37; # ~1*sigma or "~66% within confidence limits"
  
  # calculate the median of the sample with lower and upper confidence
  # limits using resampling/bootstrapping:
  my ($lower_cl, $median, $upper_cl)
    = median_simple_confidence_limits($sample, $confidence);
  
  # There are many auxiliary functions:
  
  my $resampled = resample($sample);
  # $resampled is now a random set of measurements from $sample,
  # including potential duplicates
  
  my $medians = resample_medians($sample, $n_resamples);
  # $medians is now an array reference containing the medians
  # of $n_resamples resample runs
  # This is vastly more efficient that doing the same thing with
  # repeated resample() calls!
  # Analogously:
  my $means = resample_means($sample, $n_resamples);
  
  # you can get the cl's from a set of separately resampled medians, too:
  my ($lower_cl, $median, $upper_cl)
    = simple_confidence_limits_from_samples($median, $medians, $confidence);
  
  # utility functions:
  print median([1..5]), "\n"; # prints 3
  print mean([1..5]), "\n"; # prints 3, too, surprise!
  print select_kth([1..5], 1), "\n"; # inefficient way to calculate the minimum

=head1 DESCRIPTION

The purpose of this (XS) module is to calculate the median (or in principle
also other statistics) with confidence intervals on a sample. To do that,
it uses a technique called bootstrapping. In a nutshell, it resamples the
sample a lot of times and for each resample, it calculates the median.
From the distribution of medians, it then calculates the confidence limits.

In order to implement the confidence limit calculation, various other
functions had to be implemented efficiently (both algorithmically efficient
and done in C). These functions may be useful in their own right and are
thus exposed to Perl. Most notably, this exposes a median (and general selection)
algorithm that works in linear time as opposed to the trivial implementation
that requires C<O(n*log(n))>.

=head2 Random numbers

The resampling involves drawing B<many> random numbers. Therefore,
the module comes with an embedded Mersenne twister (taken from
C<Math::Random::MT>).

If you want to change the seed of the RNG, do this:

  $Statistics::CaseResampling::Rnd
    = Statistics::CaseResampling::RdGen::setup($seed);
 
or

  $Statistics::CaseResampling::Rnd
    = Statistics::CaseResampling::RdGen::setup(@seed);

Do not use the embedded random number generator for other purposes.
Use C<Math::Random::MT> instead! At this point, you cannot change
the type of RNG.

=head2 EXPORT

None by default.

Can export any of the functions that are documented below
using standard C<Exporter> semantics, including the
customary C<:all> group.

=head1 FUNCTIONS

This list of functions is loosely sorted from I<basic>
to I<comprehensive> because the more complicated functions
are usually (under the hood, in C) implemented using the
basic building blocks. Unfortunately, that means you may
want to read the documentation backwards. :)

Additionally, there is a whole set of general purpose, fast (XS)
functions for calculating statistical metrics. They're useful
without the bootstrapping related stuff, so they're listed in
the L</"OTHER FUNCTIONS"> section below.

All of these functions are written in C for speed.

=head2 resample(ARRAYREF)

Returns a reference to an array containing N random elements from the
input array, where N is the length of the original array.

This is different from shuffling in that it's random drawing without
removing the drawn elements from the sample.

=head2 resample_medians(ARRAYREF, NMEDIANS)

Returns a reference to an array containing the medians of
C<NMEDIANS> resamples of the original input sample.

=head2 resample_means(ARRAYREF, NMEANS)

Returns a reference to an array containing the means of
C<NMEANS> resamples of the original input sample.

=head2 simple_confidence_limits_from_median_samples(STATISTIC, STATISTIC_SAMPLES, CONFIDENCE)

Calculates the confidence limits for I<STATISTIC>. Returns
the lower confidence limit, the statistic, and the upper confidence
limit. I<STATISTIC_SAMPLES> is the output of, for example, C<resample_means(\@sample)>.
I<CONFIDENCE> indicates the fraction of data within the confidence limits
(assuming a normal, symmetric distribution of the statistic =E<gt> I<simple confidence
limits>).

For example, to get the 90% confidence (~2 sigma) interval for the mean of your sample,
you can do the following:

  my $sample = [<numbers>];
  my $means = resample_means($sample, $n_resamples);
  my ($lower_cl, $mean, $upper_cl)
    = simple_confidence_limits_from_samples(mean($sample), $means, 0.90);

If you want to apply this logic to other statistics such as the first
or third quartile, you have to manually resample and lose the advantage of
doing it in C:

  my $sample = [<numbers>];
  my $quartiles = [];
  foreach (1..1000) {
    push @$quartiles, first_quartile(resample($sample));
  }
  my ($lower_cl, $firstq, $upper_cl)
    = simple_confidence_limits_from_samples(
        first_quartile($sample), $quartiles, 0.90
      );

For a reliable calculation of the confidence limits, you should use at least
1000 samples if not more. Yes. This whole procedure is B<expensive>.

For medians, however, use the following function:

=head2 median_simple_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])

Calculates the confidence limits for the C<CONFIDENCE> level
for the median of I<SAMPLE>. Returns the lower confidence limit,
the median, and the upper confidence limit.

In order to calculate the limits, a lot of resampling has to be done.
I<NSAMPLES> defaults to C<1000>. Try running this a couple of times
on your data interactively to see how the limits still vary a little
bit at this setting.

=head1 OTHER FUNCTIONS

=head2 approx_erf($x)

Calculates an approximatation of the error function of I<x>.
Implemented after

  Winitzki, Sergei (6 February 2008).
  "A handy approximation for the error function and its inverse" (PDF). 
  http://homepages.physik.uni-muenchen.de/~Winitzki/erf-approx.pdf

Quoting: Relative precision better than C<1.3e-4>.

=head2 approx_erf_inv($x)

Calculates an approximation of the inverse of the
error function of I<x>.

Algorithm from the same source as C<approx_erf>.

Quoting: Relative precision better than C<2e-3>.

=head2 nsigma_to_alpha($nsigma)

Calculates the probability that a measurement from a normal
distribution is further away from the mean than C<$nsigma>
standard deviations.

The confidence level (what you pass as the
C<CONFIDENCE> parameter to some functions in this module)
is C<1 - nsigma_to_alpha($nsigma)>.

=head2 alpha_to_nsigma($alpha)

Inverse of C<nsigma_to_alpha()>.

=head2 mean(ARRAYREF)

Calculates the mean of a sample.

=head2 median(ARRAYREF)

Calculates the median (second quartile)
of a sample. Works in linear time thanks
to using a selection instead of a sort.

Unfortunately, the way
this is implemented, the median of an even number of parameters
is, here, defined as the C<n/2-1>th largest number and not
the average of the C<n/2-1>th and the C<n/2>th number. This shouldn't
matter for nontrivial sample sizes!

=head2 median_absolute_deviation(ARRAYREF)

Calculates the median absolute deviation (MAD) in what I believe is O(n).
Take care to rescale the MAD before using it in place of a standard deviation.

=head2 first_quartile(ARRAYREF)

Calculates the first quartile of the sample.

=head2 third_quartile(ARRAYREF)

Calculates the third quartile of the sample.

=head2 select_kth(ARRAYREF, K)

Selects the kth smallest element from the sample.

This is the general function that implements the median/quartile
calculation. You get the median with this definition of K:

  my $k = int(@$sample/2) + (@$sample & 1);
  my $median = select_kth($sample, $k);

=head2 sample_standard_deviation

Given the sample mean and an anonymous array of numbers (the sample),
calculates the sample standard deviation.

=head2 population_standard_deviation

Same as sample_standard_deviation, but without the correction to C<N>.

=head1 TODO

One could calculate more statistics in C for performance.

=head1 SEE ALSO

L<Math::Random::MT>

On the approximation of the error function:

  Winitzki, Sergei (6 February 2008).
  "A handy approximation for the error function and its inverse" (PDF). 
  http://homepages.physik.uni-muenchen.de/~Winitzki/erf-approx.pdf

The ~O(n) median implementation is based on C.A.R. Hoare's quickselect
algorithm. See
L<http://en.wikipedia.org/wiki/Selection_algorithm#Partition-based_general_selection_algorithm>.
Right now, it does not implement the Median of Medians algorithm that would
guarantee linearity.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

Daniel Dragan, E<lt>bulk88@hotmail.comE<gt>, who supplied MSVC compatibility
patches.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011, 2012, 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

