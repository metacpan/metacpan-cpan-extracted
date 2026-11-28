package Statistics::CaseResampling;
use 5.008001;
use strict;
use warnings;

require Exporter;

our $VERSION = '1.01';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  resample
  resample_medians
  resample_means
  resample_quantiles
  select_kth
  quantile
  median
  median_absolute_deviation
  first_quartile
  third_quartile
  mean
  simple_confidence_limits_from_samples
  median_simple_confidence_limits
  basic_confidence_limits_from_samples
  percentile_confidence_limits_from_samples
  bca_confidence_limits_from_samples
  median_percentile_confidence_limits
  median_exact_confidence_limits
  mean_percentile_confidence_limits
  mean_bca_confidence_limits
  mean_studentized_confidence_limits
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

our $Rnd;
my $_Seed_Counter = 0;

sub _fallback_seed {
  my $tid = defined(&threads::tid) ? threads->tid() : 0;
  return (
    int(rand(4294967296)),
    int(rand(4294967296)),
    $$ & 0xffffffff,
    time() & 0xffffffff,
    $tid & 0xffffffff,
    (++$_Seed_Counter) & 0xffffffff,
  );
}

sub _new_default_rng {
  local $!;
  my @seed = Statistics::CaseResampling::RdGen::_os_entropy(4);
  @seed = _fallback_seed() if @seed != 4;
  my $rng = Statistics::CaseResampling::RdGen::setup_array(@seed);
  $rng->_mark_auto_seeded($$);
  return $rng;
}

sub _reseed_default_rng {
  $Rnd = _new_default_rng();
}

$Rnd = _new_default_rng();

sub CLONE {
  $Rnd = _new_default_rng();
}


1;
__END__

=head1 NAME

Statistics::CaseResampling - Efficient resampling and calculation of medians with confidence intervals

=head1 SYNOPSIS

  use Statistics::CaseResampling ':all';
  
  my $sample = [1,3,5,7,1,2,9,4,6,8]; # ... usually MUCH more data ...
  my $confidence = 0.95; # 95% confidence limits (~1.96*sigma)
  #my $confidence = 1 - nsigma_to_alpha(1); # ~1*sigma (~68.27% confidence limits)
  
  # calculate the median of the sample with distribution-free exact
  # binomial confidence limits:
  my ($lower_cl, $median, $upper_cl)
    = median_exact_confidence_limits($sample, $confidence);
  
  # or using percentile bootstrapping (defaults to 1000 resamples; use
  # 5000-10000+ for reliable tail limits):
  my ($lower_cl_boot, $median_boot, $upper_cl_boot)
    = median_percentile_confidence_limits($sample, $confidence, 5000);
  
  # or all-in-C BCa bootstrap confidence limits for the mean:
  my ($lower_bca, $mean_bca, $upper_bca)
    = mean_bca_confidence_limits($sample, $confidence, 5000);
  
  # There are many auxiliary functions:
  
  my $resampled = resample($sample);
  # $resampled is now a random set of measurements from $sample,
  # including potential duplicates
  
  my $medians = resample_medians($sample, $n_resamples);
  # $medians is now an array reference containing the medians
  # of $n_resamples resample runs
  # This is vastly more efficient than doing the same thing with
  # repeated resample() calls!
  # Analogously:
  my $means = resample_means($sample, $n_resamples);
  
  # you can get two-sided percentile (or basic, or BCa) confidence limits
  # from a set of separately resampled statistics, too:
  my ($lower_m, $mean, $upper_m)
    = percentile_confidence_limits_from_samples(mean($sample), $means, $confidence);
  
  # utility functions:
  print median([1..5]), "\n"; # prints 3
  print mean([1..5]), "\n"; # prints 3, too, surprise!
  print quantile([1..4], 0.5), "\n"; # prints 2.5
  print sample_standard_deviation($sample), "\n";
  print select_kth([1..5], 1), "\n"; # inefficient way to calculate the minimum

=head1 DESCRIPTION

The purpose of this (XS) module is to calculate the median (or in principle
also other statistics) with confidence intervals on a sample. To do that,
it uses a technique called bootstrapping. In a nutshell, it resamples the
sample a lot of times and for each resample, it calculates the statistic.
From the distribution of resampled statistics, it then calculates the
confidence limits.

In order to implement the confidence limit calculation, various other
functions had to be implemented efficiently (both algorithmically efficient
and done in C). These functions may be useful in their own right and are
thus exposed to Perl. Most notably, this exposes a median (and general selection)
algorithm that works in linear time as opposed to the trivial implementation
that requires C<O(n*log(n))>.

=head2 Statistical caveats

Case resampling (nonparametric bootstrap) assumes that the observations in
C<$sample> are independent and identically distributed (i.i.d.). If your data
exhibits autocorrelation, time trends, or clustering, standard case resampling
will underestimate uncertainty.

Additionally, bootstrap confidence intervals for the median have limited
coverage accuracy on very small samples (e.g. C<N E<lt> 15>) or when the data
contains many tied values; prefer L</"median_exact_confidence_limits(SAMPLE, CONFIDENCE)">
when a distribution-free confidence interval for the median is required.

=head2 Input validation and error handling

All functions reject C<undef> and non-numeric values, both inside sample
arrays and in scalar parameters (probabilities, confidence levels, run
counts, and C<erf>/C<alpha>/C<nsigma> arguments). Numeric strings, C<NaN>,
and C<Inf> are accepted; C<NaN> propagates deterministically through summary
statistics and order statistics regardless of element ordering.

All summary statistic and confidence-limit functions croak on empty
samples (C<[]>). The raw resampling helpers (C<resample()>,
C<resample_medians()>, C<resample_means()>, and C<resample_quantiles()>)
return C<[]> on an empty sample and require run counts in C<1..100000000>.

=head2 Upgrading from 0.x to 1.00

Version 1.00 fixes several long-standing statistical correctness bugs that
change outputs for some legacy calls:

=over 4

=item *

C<simple_confidence_limits_from_samples()> and
C<median_simple_confidence_limits()> now compute true two-sided
C<alpha/2> and C<1 - alpha/2> tails with Type 7 quantile interpolation
instead of one-sided C<alpha> tails and truncated 1-based indices.

=item *

C<median()>, C<median_absolute_deviation()>, C<resample_medians()>,
C<first_quartile()>, and C<third_quartile()> now use Hyndman-Fan Type 7
interpolation (averaging the two middle elements for even C<N>).

=item *

C<approx_erf_inv()> now accepts its full domain C<(-1, 1)>,
C<alpha_to_nsigma()> requires C<alpha> in C<(0, 1]>, and
C<nsigma_to_alpha()> requires C<nsigma E<gt>= 0>.

=item *

Empty samples and C<undef>/non-numeric inputs croak instead of silently
returning or coercing to C<0>.

=back

=head2 Random numbers

The resampling involves drawing B<many> random numbers. Therefore,
the module comes with an embedded Mersenne twister (taken from
C<Math::Random::MT>).

If you want to change the seed of the RNG, do this:

  $Statistics::CaseResampling::Rnd
    = Statistics::CaseResampling::RdGen::setup($seed);

or

  $Statistics::CaseResampling::Rnd
    = Statistics::CaseResampling::RdGen::setup_array(@seed);

The default module RNG is automatically seeded from native OS entropy
(C<BCryptGenRandom>/C<RtlGenRandom> on Windows, C</dev/urandom> on Unix,
or process/time/PRNG fallback state when unavailable) and is reseeded
across C<ithreads> cloning and C<fork()>. Explicitly seeded RNG objects
retain their exact deterministic sequence.

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

=head2 resample_quantiles(ARRAYREF, P, NQUANTILES)

Returns a reference to an array containing the Type 7 sample quantile
at probability I<P> in C<[0, 1]> of C<NQUANTILES> resamples of the
original input sample.

=head2 percentile_confidence_limits_from_samples(STATISTIC, STATISTIC_SAMPLES, CONFIDENCE)

Calculates two-sided percentile bootstrap confidence limits at level
I<CONFIDENCE> (in C<(0, 1)>) using linear quantile interpolation at
C<alpha/2> and C<1 - alpha/2>, where C<alpha = 1 - CONFIDENCE>. Returns
C<($lower_cl, $statistic, $upper_cl)>.

For example, to get a 95% confidence interval for the mean of your sample:

  my $sample = [<numbers>];
  my $means = resample_means($sample, 5000);
  my ($lower_cl, $mean, $upper_cl)
    = percentile_confidence_limits_from_samples(mean($sample), $means, 0.95);

For reliable tail limits at 95% or higher confidence, use at least
5000-10000 bootstrap samples.

=head2 basic_confidence_limits_from_samples(STATISTIC, STATISTIC_SAMPLES, CONFIDENCE)

Calculates two-sided basic (pivotal) bootstrap confidence limits at level
I<CONFIDENCE> (in C<(0, 1)>) as
C<2 * STATISTIC - quantile(STATISTIC_SAMPLES, 1 - alpha/2)> and
C<2 * STATISTIC - quantile(STATISTIC_SAMPLES, alpha/2)>, where
C<alpha = 1 - CONFIDENCE>. Returns C<($lower_cl, $statistic, $upper_cl)>.

Note that for heavily skewed distributions or bounded statistics (e.g.
strictly positive measurements), the basic bootstrap reflection can produce
limits outside the parameter support; prefer
L</"percentile_confidence_limits_from_samples(STATISTIC, STATISTIC_SAMPLES, CONFIDENCE)">
or L</"bca_confidence_limits_from_samples(STATISTIC, STATISTIC_SAMPLES, JACKKNIFE_SAMPLES, CONFIDENCE)">
in those cases.

=head2 bca_confidence_limits_from_samples(STATISTIC, STATISTIC_SAMPLES, JACKKNIFE_SAMPLES, CONFIDENCE)

Calculates two-sided bias-corrected and accelerated (BCa) bootstrap
confidence limits at level I<CONFIDENCE> (in C<(0, 1)>).
I<JACKKNIFE_SAMPLES> must be an array reference of leave-one-out
jackknife estimates of the statistic on the original sample. Returns
C<($lower_cl, $statistic, $upper_cl)>.

BCa intervals correct for both median bias and skewness (via the
acceleration constant) and are transformation-respecting.

=head2 mean_percentile_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])

All-in-C two-sided percentile bootstrap confidence limits for the arithmetic
mean of I<SAMPLE> at level I<CONFIDENCE> in C<(0, 1)>. I<NSAMPLES> defaults
to C<1000> (use C<5000> or more for stable 95%+ limits). Returns
C<($lower_cl, $mean, $upper_cl)>.

=head2 mean_bca_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])

All-in-C two-sided bias-corrected and accelerated (BCa) bootstrap
confidence limits for the arithmetic mean of I<SAMPLE>, computing the
leave-one-out jackknife means in C<O(n)> time without Perl overhead.
I<NSAMPLES> defaults to C<1000>. Returns C<($lower_cl, $mean, $upper_cl)>.

=head2 mean_studentized_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])

All-in-C two-sided studentized (bootstrap-t) confidence limits for the
arithmetic mean of I<SAMPLE> (requiring at least 2 observations).
I<NSAMPLES> defaults to C<1000>. Returns C<($lower_cl, $mean, $upper_cl)>.
Offers second-order accuracy for location statistics, though individual
small-sample bootstrap replicates with zero sample variance can yield
infinite endpoints.

=head2 median_percentile_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])

Calculates two-sided percentile bootstrap confidence limits for the exact
median of I<SAMPLE>. I<NSAMPLES> defaults to C<1000> (use C<5000> or more
for stable 95%+ limits). Returns C<($lower_cl, $median, $upper_cl)>.

=head2 median_exact_confidence_limits(SAMPLE, CONFIDENCE)

Calculates exact distribution-free confidence limits for the median of
I<SAMPLE> using the symmetric binomial distribution C<Binomial(n, 0.5)> on
the order statistics, returning C<($lower_cl, $median, $upper_cl)> with
at least I<CONFIDENCE> coverage (assuming continuous i.i.d. observations).
Achieving guaranteed coverage at level I<CONFIDENCE> requires
C<1 - 2**(1 - N) E<gt>= CONFIDENCE> (for example, C<N E<gt>= 6> at 95%
confidence); smaller samples return C<[min, max]>. This requires no Monte
Carlo resampling and runs in C<O(n)> expected time.

=head2 simple_confidence_limits_from_samples(STATISTIC, STATISTIC_SAMPLES, CONFIDENCE)

Alias/equivalent to
L</"basic_confidence_limits_from_samples(STATISTIC, STATISTIC_SAMPLES, CONFIDENCE)">:
calculates two-sided basic (pivotal) bootstrap confidence limits at level
I<CONFIDENCE> using C<alpha/2> and C<1 - alpha/2> quantiles, returning
C<($lower_cl, $statistic, $upper_cl)>.

For example:

  my $sample = [<numbers>];
  my $means = resample_means($sample, 5000);
  my ($lower_cl, $mean, $upper_cl)
    = simple_confidence_limits_from_samples(mean($sample), $means, 0.95);

If you want to apply this logic to other statistics such as the first
or third quartile, you can use C<resample_quantiles()>:

  my $sample = [<numbers>];
  my $quartiles = resample_quantiles($sample, 0.25, 5000);
  my ($lower_cl, $firstq, $upper_cl)
    = percentile_confidence_limits_from_samples(
        first_quartile($sample), $quartiles, 0.95
      );

For medians, prefer L</"median_exact_confidence_limits(SAMPLE, CONFIDENCE)">
or L</"median_percentile_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])">.

=head2 median_simple_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])

Calculates two-sided basic (pivotal) bootstrap confidence limits for the
median of I<SAMPLE> at level I<CONFIDENCE> (using C<alpha/2> and
C<1 - alpha/2> tails). Returns C<($lower_cl, $median, $upper_cl)>.
I<NSAMPLES> defaults to C<1000>.

Note that basic (pivotal) bootstrap reflection can undercover on
discrete/small-sample medians due to order-statistic spacing asymmetry;
prefer L</"median_exact_confidence_limits(SAMPLE, CONFIDENCE)"> or
L</"median_percentile_confidence_limits(SAMPLE, CONFIDENCE, [NSAMPLES])">
for medians.

=head1 OTHER FUNCTIONS

=head2 approx_erf($x)

Calculates the error function of I<x> (using the C math library C<erf()>
where available, with a high-precision fallback otherwise).

=head2 approx_erf_inv($x)

Calculates the inverse of the error function of I<x> for I<x> in C<(-1, 1)>
to near machine precision.

=head2 nsigma_to_alpha($nsigma)

Calculates the two-sided probability C<erfc($nsigma / sqrt(2))> that a
measurement from a normal distribution is further away from the mean than
C<$nsigma> standard deviations, for C<$nsigma E<gt>= 0>.

The two-sided confidence level is C<1 - nsigma_to_alpha($nsigma)>.

=head2 alpha_to_nsigma($alpha)

Inverse of C<nsigma_to_alpha()> for C<$alpha> in C<(0, 1]>.

=head2 mean(ARRAYREF)

Calculates the arithmetic mean of a sample using compensated summation
(and overflow-safe scaling for extreme magnitudes).

=head2 quantile(ARRAYREF, P)

Calculates the sample quantile for probability I<P> in C<[0, 1]> in
C<O(n)> expected time (C<O(n log n)> worst case) using Hyndman-Fan
Type 7 linear interpolation (the default in R, NumPy, and Julia). At
C<P = 0.5>, this computes the exact median, averaging the two middle
elements when N is even.

=head2 median(ARRAYREF)

Calculates the median (second quartile) of a sample using C<quantile($sample, 0.5)>,
averaging the two middle elements when N is even. Runs in C<O(n)> expected
time (C<O(n log n)> worst case).

=head2 median_absolute_deviation(ARRAYREF)

Calculates the median absolute deviation (MAD) in C<O(n)> expected time.
Note that for consistency with a normal standard deviation, a normally
distributed sample requires rescaling by C<1 / (sqrt(2) * erfinv(0.5))>
(approximately C<1.4826>).

=head2 first_quartile(ARRAYREF)

Calculates the first quartile of the sample using Hyndman-Fan Type 7
interpolation (equivalent to C<quantile($sample, 0.25)>).

=head2 third_quartile(ARRAYREF)

Calculates the third quartile of the sample using Hyndman-Fan Type 7
interpolation (equivalent to C<quantile($sample, 0.75)>).

=head2 select_kth(ARRAYREF, K)

Selects the kth smallest element (1-based) from the sample in C<O(n)>
expected time (hardened with introselect heapsort fallback for C<O(n log n)>
worst-case time).

=head2 sample_standard_deviation([$mean,] ARRAYREF)

Calculates the sample standard deviation (with Bessel's C<N - 1>
correction). May be called with either C<(\@sample)> (computing the
sample mean automatically) or C<($mean, \@sample)>. Note that Bessel's
C<N - 1> denominator is only statistically appropriate when C<$mean> is
the sample mean of C<@sample>.

=head2 population_standard_deviation([$mean,] ARRAYREF)

Same as C<sample_standard_deviation>, but dividing by C<N> instead of C<N - 1>.
May be called as C<(\@sample)> or C<($mean, \@sample)>.

=head1 TODO

One could calculate more statistics in C for performance.

=head1 SEE ALSO

L<Math::Random::MT>

The selection implementation uses Hoare's quickselect with an introselect
heapsort fallback to guarantee C<O(n log n)> worst-case time while keeping
C<O(n)> expected runtime. See
L<http://en.wikipedia.org/wiki/Introselect>.

=head1 AUTHOR

Steffen Mueller, E<lt>cpan@steffen-mueller.netE<gt>

Daniel Dragan, E<lt>bulk88@hotmail.comE<gt>, who supplied MSVC compatibility
patches.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011, 2012, 2013, 2025, 2026 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
