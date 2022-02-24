#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSL::RNG;

our @EXPORT_OK = qw( );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core qw/ zeroes long barf  /;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::RNG ;






#line 9 "gsl_random.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSL::RNG - PDL interface to RNG and randist routines in GSL

=head1 DESCRIPTION

This is an interface to the rng and randist packages present
in the GNU Scientific Library.

=head1 SYNOPSIS

   use PDL;
   use PDL::GSL::RNG;

   $rng = PDL::GSL::RNG->new('taus');

   $rng->set_seed(time());

   $x=zeroes(5,5,5)

   $rng->get_uniform($x); # inplace

   $y=$rng->get_uniform(3,4,5); # creates new pdl

=head1 NOMENCLATURE

Throughout this documentation we strive to use the same variables that
are present in the original GSL documentation (see L<See
Also|"SEE-ALSO">). Oftentimes those variables are called C<a> and
C<b>. Since good Perl coding practices discourage the use of Perl
variables C<$a> and C<$b>, here we refer to Parameters C<a> and C<b>
as C<$pa> and C<$pb>, respectively, and Limits (of domain or
integration) as C<$la> and C<$lb>.

=head1 FUNCTIONS

=head2 new

=for ref

The new method initializes a new instance of the RNG.

The available RNGs are:

 coveyou cmrg fishman18 fishman20 fishman2x gfsr4 knuthran
 knuthran2 knuthran2002 lecuyer21 minstd mrg mt19937 mt19937_1999
 mt19937_1998 r250 ran0 ran1 ran2 ran3 rand rand48 random128_bsd
 random128_glibc2 random128_libc5 random256_bsd random256_glibc2
 random256_libc5 random32_bsd random32_glibc2 random32_libc5
 random64_bsd random64_glibc2 random64_libc5 random8_bsd
 random8_glibc2 random8_libc5 random_bsd random_glibc2
 random_libc5 randu ranf ranlux ranlux389 ranlxd1 ranlxd2 ranlxs0
 ranlxs1 ranlxs2 ranmar slatec taus taus2 taus113 transputer tt800
 uni uni32 vax waterman14 zuf default

The last one (default) uses the environment variable GSL_RNG_TYPE.

Note that only a few of these rngs are recommended for general
use. Please check the GSL documentation for more information.

=for usage

Usage:

   $blessed_ref = PDL::GSL::RNG->new($RNG_name);

Example:

=for example

   $rng = PDL::GSL::RNG->new('taus');

=head2 set_seed

=for ref

Sets the RNG seed.

Usage:

=for usage

   $rng->set_seed($integer);
   # or
   $rng = PDL::GSL::RNG->new('taus')->set_seed($integer);

Example:

=for example

   $rng->set_seed(666);

=head2 min

=for ref

Return the minimum value generable by this RNG.

Usage:

=for usage

   $integer = $rng->min();

Example:

=for example

   $min = $rng->min(); $max = $rng->max();

=head2 max

=for ref

Return the maximum value generable by the RNG.

Usage:

=for usage

   $integer = $rng->max();

Example:

=for example

   $min = $rng->min(); $max = $rng->max();

=head2 name

=for ref

Returns the name of the RNG.

Usage:

=for usage

   $string = $rng->name();

Example:

=for example

   $name = $rng->name();

=head2 get

=for ref

This function creates an ndarray with given dimensions or accepts an
existing ndarray and fills it. get() returns integer values
between a minimum and a maximum specific to every RNG.

Usage:

=for usage

   $ndarray = $rng->get($list_of_integers)
   $rng->get($ndarray);

Example:

=for example

   $x = zeroes 5,6;
   $o = $rng->get(10,10); $rng->get($x);

=head2 get_int

=for ref

This function creates an ndarray with given dimensions or accepts an
existing ndarray and fills it. get_int() returns integer values
between 0 and $max.

Usage:

=for usage

   $ndarray = $rng->get($max, $list_of_integers)
   $rng->get($max, $ndarray);

Example:

=for example

   $x = zeroes 5,6; $max=100;
   $o = $rng->get(10,10); $rng->get($x);

=head2 get_uniform

=for ref

This function creates an ndarray with given dimensions or accepts an
existing ndarray and fills it. get_uniform() returns values 0<=x<1,

Usage:

=for usage

   $ndarray = $rng->get_uniform($list_of_integers)
   $rng->get_uniform($ndarray);

Example:

=for example

   $x = zeroes 5,6; $max=100;
   $o = $rng->get_uniform(10,10); $rng->get_uniform($x);

=head2 get_uniform_pos

=for ref

This function creates an ndarray with given dimensions or accepts an
existing ndarray and fills it. get_uniform_pos() returns values 0<x<1,

Usage:

=for usage

   $ndarray = $rng->get_uniform_pos($list_of_integers)
   $rng->get_uniform_pos($ndarray);

Example:

=for example

   $x = zeroes 5,6;
   $o = $rng->get_uniform_pos(10,10); $rng->get_uniform_pos($x);

=head2 ran_shuffle

=for ref

Shuffles values in ndarray

Usage:

=for usage

   $rng->ran_shuffle($ndarray);

=head2 ran_shuffle_vec

=for ref

Shuffles values in ndarray

Usage:

=for usage

   $rng->ran_shuffle_vec(@vec);

=head2 ran_choose

=for ref

Chooses values from C<$inndarray> to C<$outndarray>.

Usage:

=for usage

   $rng->ran_choose($inndarray,$outndarray);

=head2 ran_choose_vec

=for ref

Chooses C<$n> values from C<@vec>.

Usage:

=for usage

   @chosen = $rng->ran_choose_vec($n,@vec);

=head2 ran_gaussian

=for ref

Fills output ndarray with random values from Gaussian distribution with mean zero and standard deviation C<$sigma>.

Usage:

=for usage

 $ndarray = $rng->ran_gaussian($sigma,[list of integers = output ndarray dims]);
 $rng->ran_gaussian($sigma, $output_ndarray);

Example:

=for example

  $o = $rng->ran_gaussian($sigma,10,10);
  $rng->ran_gaussian($sigma,$o);

=head2 ran_gaussian_var

=for ref

This method is similar to L</ran_gaussian> except that it takes
the parameters of the distribution as an ndarray and returns an ndarray of equal
dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gaussian_var($sigma_ndarray);
   $rng->ran_gaussian_var($sigma_ndarray, $output_ndarray);

Example:

=for example

   $sigma_pdl = rvals zeroes 11,11;
   $o = $rng->ran_gaussian_var($sigma_pdl);

=head2 ran_additive_gaussian

=for ref

Add Gaussian noise of given sigma to an ndarray.

Usage:

=for usage

   $rng->ran_additive_gaussian($sigma,$ndarray);

Example:

=for example

   $rng->ran_additive_gaussian(1,$image);

=head2 ran_bivariate_gaussian

=for ref

Generates C<$n> bivariate gaussian random deviates.

Usage:

=for usage

   $ndarray = $rng->ran_bivariate_gaussian($sigma_x,$sigma_y,$rho,$n);

Example:

=for example

   $o = $rng->ran_bivariate_gaussian(1,2,0.5,1000);

=head2 ran_poisson

=for ref

Fills output ndarray by with random integer values from the Poisson distribution with mean C<$mu>.

Usage:

=for usage

   $ndarray = $rng->ran_poisson($mu,[list of integers = output ndarray dims]);
   $rng->ran_poisson($mu,$output_ndarray);

=head2 ran_poisson_var

=for ref

Similar to L</ran_poisson> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_poisson_var($mu_ndarray);

=head2 ran_additive_poisson

=for ref

Add Poisson noise of given C<$mu> to a C<$ndarray>.

Usage:

=for usage

   $rng->ran_additive_poisson($mu,$ndarray);

Example:

=for example

   $rng->ran_additive_poisson(1,$image);

=head2 ran_feed_poisson

=for ref

This method simulates shot noise, taking the values of ndarray as
values for C<$mu> to be fed in the poissonian RNG.

Usage:

=for usage

   $rng->ran_feed_poisson($ndarray);

Example:

=for example

   $rng->ran_feed_poisson($image);

=head2 ran_bernoulli

=for ref

Fills output ndarray with random values 0 or 1, the result of a Bernoulli trial with probability C<$p>.

Usage:

=for usage

   $ndarray = $rng->ran_bernoulli($p,[list of integers = output ndarray dims]);
   $rng->ran_bernoulli($p,$output_ndarray);

=head2 ran_bernoulli_var

=for ref

Similar to L</ran_bernoulli> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_bernoulli_var($p_ndarray);

=head2 ran_beta

=for ref

Fills output ndarray with random variates from the beta distribution with parameters C<$pa> and C<$pb>.

Usage:

=for usage

   $ndarray = $rng->ran_beta($pa,$pb,[list of integers = output ndarray dims]);
   $rng->ran_beta($pa,$pb,$output_ndarray);

=head2 ran_beta_var

=for ref

Similar to L</ran_beta> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_beta_var($a_ndarray, $b_ndarray);

=head2 ran_binomial

=for ref

Fills output ndarray with random integer values from the binomial distribution, the number of
successes in C<$n> independent trials with probability C<$p>.

Usage:

=for usage

   $ndarray = $rng->ran_binomial($p,$n,[list of integers = output ndarray dims]);
   $rng->ran_binomial($p,$n,$output_ndarray);

=head2 ran_binomial_var

=for ref

Similar to L</ran_binomial> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_binomial_var($p_ndarray, $n_ndarray);

=head2 ran_cauchy

=for ref

Fills output ndarray with random variates from the Cauchy distribution with scale parameter C<$pa>.

Usage:

=for usage

   $ndarray = $rng->ran_cauchy($pa,[list of integers = output ndarray dims]);
   $rng->ran_cauchy($pa,$output_ndarray);

=head2 ran_cauchy_var

=for ref

Similar to L</ran_cauchy> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_cauchy_var($a_ndarray);

=head2 ran_chisq

=for ref

Fills output ndarray with random variates from the chi-squared distribution with
C<$nu> degrees of freedom.

Usage:

=for usage

   $ndarray = $rng->ran_chisq($nu,[list of integers = output ndarray dims]);
   $rng->ran_chisq($nu,$output_ndarray);

=head2 ran_chisq_var

=for ref

Similar to L</ran_chisq> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_chisq_var($nu_ndarray);

=head2 ran_exponential

=for ref

Fills output ndarray with random variates from the exponential distribution with mean C<$mu>.

Usage:

=for usage

   $ndarray = $rng->ran_exponential($mu,[list of integers = output ndarray dims]);
   $rng->ran_exponential($mu,$output_ndarray);

=head2 ran_exponential_var

=for ref

Similar to L</ran_exponential> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_exponential_var($mu_ndarray);

=head2 ran_exppow

=for ref

Fills output ndarray with random variates from the exponential power distribution with scale
parameter C<$pa> and exponent C<$pb>.

Usage:

=for usage

   $ndarray = $rng->ran_exppow($pa,$pb,[list of integers = output ndarray dims]);
   $rng->ran_exppow($pa,$pb,$output_ndarray);

=head2 ran_exppow_var

=for ref

Similar to L</ran_exppow> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_exppow_var($a_ndarray, $b_ndarray);

=head2 ran_fdist

=for ref

Fills output ndarray with random variates from the F-distribution with degrees
of freedom C<$nu1> and C<$nu2>.

Usage:

=for usage

   $ndarray = $rng->ran_fdist($nu1, $nu2,[list of integers = output ndarray dims]);
   $rng->ran_fdist($nu1, $nu2,$output_ndarray);

=head2 ran_fdist_var

=for ref

Similar to L</ran_fdist> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_fdist_var($nu1_ndarray, $nu2_ndarray);

=head2 ran_flat

=for ref

Fills output ndarray with random variates from the flat (uniform) distribution from C<$la> to C<$lb>.

Usage:

=for usage

   $ndarray = $rng->ran_flat($la,$lb,[list of integers = output ndarray dims]);
   $rng->ran_flat($la,$lb,$output_ndarray);

=head2 ran_flat_var

=for ref

Similar to L</ran_flat> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_flat_var($a_ndarray, $b_ndarray);

=head2 ran_gamma

=for ref

Fills output ndarray with random variates from the gamma distribution.

Usage:

=for usage

   $ndarray = $rng->ran_gamma($pa,$pb,[list of integers = output ndarray dims]);
   $rng->ran_gamma($pa,$pb,$output_ndarray);

=head2 ran_gamma_var

=for ref

Similar to L</ran_gamma> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gamma_var($a_ndarray, $b_ndarray);

=head2 ran_geometric

=for ref

Fills output ndarray with random integer values from the geometric distribution,
the number of independent trials with probability C<$p> until the first success.

Usage:

=for usage

   $ndarray = $rng->ran_geometric($p,[list of integers = output ndarray dims]);
   $rng->ran_geometric($p,$output_ndarray);

=head2 ran_geometric_var

=for ref

Similar to L</ran_geometric> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_geometric_var($p_ndarray);

=head2 ran_gumbel1

=for ref

Fills output ndarray with random variates from the Type-1 Gumbel distribution.

Usage:

=for usage

   $ndarray = $rng->ran_gumbel1($pa,$pb,[list of integers = output ndarray dims]);
   $rng->ran_gumbel1($pa,$pb,$output_ndarray);

=head2 ran_gumbel1_var

=for ref

Similar to L</ran_gumbel1> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gumbel1_var($a_ndarray, $b_ndarray);

=head2 ran_gumbel2

=for ref

Fills output ndarray with random variates from the Type-2 Gumbel distribution.

Usage:

=for usage

   $ndarray = $rng->ran_gumbel2($pa,$pb,[list of integers = output ndarray dims]);
   $rng->ran_gumbel2($pa,$pb,$output_ndarray);

=head2 ran_gumbel2_var

=for ref

Similar to L</ran_gumbel2> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gumbel2_var($a_ndarray, $b_ndarray);

=head2 ran_hypergeometric

=for ref

Fills output ndarray with random integer values from the hypergeometric distribution.
If a population contains C<$n1> elements of type 1 and C<$n2> elements of
type 2 then the hypergeometric distribution gives the probability of obtaining
C<$x> elements of type 1 in C<$t> samples from the population without replacement.

Usage:

=for usage

   $ndarray = $rng->ran_hypergeometric($n1, $n2, $t,[list of integers = output ndarray dims]);
   $rng->ran_hypergeometric($n1, $n2, $t,$output_ndarray);

=head2 ran_hypergeometric_var

=for ref

Similar to L</ran_hypergeometric> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_hypergeometric_var($n1_ndarray, $n2_ndarray, $t_ndarray);

=head2 ran_laplace

=for ref

Fills output ndarray with random variates from the Laplace distribution with width C<$pa>.

Usage:

=for usage

   $ndarray = $rng->ran_laplace($pa,[list of integers = output ndarray dims]);
   $rng->ran_laplace($pa,$output_ndarray);

=head2 ran_laplace_var

=for ref

Similar to L</ran_laplace> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_laplace_var($a_ndarray);

=head2 ran_levy

=for ref

Fills output ndarray with random variates from the Levy symmetric stable
distribution with scale C<$c> and exponent C<$alpha>.

Usage:

=for usage

   $ndarray = $rng->ran_levy($mu,$x,[list of integers = output ndarray dims]);
   $rng->ran_levy($mu,$x,$output_ndarray);

=head2 ran_levy_var

=for ref

Similar to L</ran_levy> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_levy_var($mu_ndarray, $a_ndarray);

=head2 ran_logarithmic

=for ref

Fills output ndarray with random integer values from the logarithmic distribution.

Usage:

=for usage

   $ndarray = $rng->ran_logarithmic($p,[list of integers = output ndarray dims]);
   $rng->ran_logarithmic($p,$output_ndarray);

=head2 ran_logarithmic_var

=for ref

Similar to L</ran_logarithmic> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_logarithmic_var($p_ndarray);

=head2 ran_logistic

=for ref

Fills output ndarray with random random variates from the logistic distribution.

Usage:

=for usage

   $ndarray = $rng->ran_logistic($m,[list of integers = output ndarray dims]u)
   $rng->ran_logistic($m,$output_ndarray)

=head2 ran_logistic_var

=for ref

Similar to L</ran_logistic> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_logistic_var($m_ndarray);

=head2 ran_lognormal

=for ref

Fills output ndarray with random variates from the lognormal distribution with
parameters C<$mu> (location) and C<$sigma> (scale).

Usage:

=for usage

   $ndarray = $rng->ran_lognormal($mu,$sigma,[list of integers = output ndarray dims]);
   $rng->ran_lognormal($mu,$sigma,$output_ndarray);

=head2 ran_lognormal_var

=for ref

Similar to L</ran_lognormal> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_lognormal_var($mu_ndarray, $sigma_ndarray);

=head2 ran_negative_binomial

=for ref

Fills output ndarray with random integer values from the negative binomial
distribution, the number of failures occurring before C<$n> successes in
independent trials with probability C<$p> of success. Note that C<$n> is
not required to be an integer.

Usage:

=for usage

   $ndarray = $rng->ran_negative_binomial($p,$n,[list of integers = output ndarray dims]);
   $rng->ran_negative_binomial($p,$n,$output_ndarray);

=head2 ran_negative_binomial_var

=for ref

Similar to L</ran_negative_binomial> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_negative_binomial_var($p_ndarray, $n_ndarray);

=head2 ran_pareto

=for ref

Fills output ndarray with random variates from the Pareto distribution of
order C<$pa> and scale C<$lb>.

Usage:

=for usage

   $ndarray = $rng->ran_pareto($pa,$lb,[list of integers = output ndarray dims]);
   $rng->ran_pareto($pa,$lb,$output_ndarray);

=head2 ran_pareto_var

=for ref

Similar to L</ran_pareto> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_pareto_var($a_ndarray, $b_ndarray);

=head2 ran_pascal

=for ref

Fills output ndarray with random integer values from the Pascal distribution.
The Pascal distribution is simply a negative binomial distribution
(see L</ran_negative_binomial>) with an integer value of C<$n>.

Usage:

=for usage

   $ndarray = $rng->ran_pascal($p,$n,[list of integers = output ndarray dims]);
   $rng->ran_pascal($p,$n,$output_ndarray);

=head2 ran_pascal_var

=for ref

Similar to L</ran_pascal> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_pascal_var($p_ndarray, $n_ndarray);

=head2 ran_rayleigh

=for ref

Fills output ndarray with random variates from the Rayleigh distribution with scale parameter C<$sigma>.

Usage:

=for usage

   $ndarray = $rng->ran_rayleigh($sigma,[list of integers = output ndarray dims]);
   $rng->ran_rayleigh($sigma,$output_ndarray);

=head2 ran_rayleigh_var

=for ref

Similar to L</ran_rayleigh> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_rayleigh_var($sigma_ndarray);

=head2 ran_rayleigh_tail

=for ref

Fills output ndarray with random variates from the tail of the Rayleigh distribution
with scale parameter C<$sigma> and a lower limit of C<$la>.

Usage:

=for usage

   $ndarray = $rng->ran_rayleigh_tail($la,$sigma,[list of integers = output ndarray dims]);
   $rng->ran_rayleigh_tail($x,$sigma,$output_ndarray);

=head2 ran_rayleigh_tail_var

=for ref

Similar to L</ran_rayleigh_tail> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_rayleigh_tail_var($a_ndarray, $sigma_ndarray);

=head2 ran_tdist

=for ref

Fills output ndarray with random variates from the t-distribution (AKA Student's
t-distribution) with C<$nu> degrees of freedom.

Usage:

=for usage

   $ndarray = $rng->ran_tdist($nu,[list of integers = output ndarray dims]);
   $rng->ran_tdist($nu,$output_ndarray);

=head2 ran_tdist_var

=for ref

Similar to L</ran_tdist> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_tdist_var($nu_ndarray);

=head2 ran_ugaussian_tail

=for ref

Fills output ndarray with random variates from the upper tail of a Gaussian
distribution with C<standard deviation = 1> (AKA unit Gaussian distribution).

Usage:

=for usage

   $ndarray = $rng->ran_ugaussian_tail($tail,[list of integers = output ndarray dims]);
   $rng->ran_ugaussian_tail($tail,$output_ndarray);

=head2 ran_ugaussian_tail_var

=for ref

Similar to L</ran_ugaussian_tail> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_ugaussian_tail_var($tail_ndarray);

=head2 ran_weibull

=for ref

Fills output ndarray with random variates from the Weibull distribution with scale C<$pa> and exponent C<$pb>. (Some literature uses C<lambda> for C<$pa> and C<k> for C<$pb>.)

Usage:

=for usage

   $ndarray = $rng->ran_weibull($pa,$pb,[list of integers = output ndarray dims]);
   $rng->ran_weibull($pa,$pb,$output_ndarray);

=head2 ran_weibull_var

=for ref

Similar to L</ran_weibull> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_weibull_var($a_ndarray, $b_ndarray);

=head2 ran_dir

=for ref

Returns C<$n> random vectors in C<$ndim> dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_dir($ndim,$n);

Example:

=for example

   $o = $rng->ran_dir($ndim,$n);

=head2 ran_discrete_preproc

=for ref

This method returns a handle that must be used when calling
L</ran_discrete>. You specify the probability of the integer number
that are returned by L</ran_discrete>.

Usage:

=for usage

   $discrete_dist_handle = $rng->ran_discrete_preproc($double_ndarray_prob);

Example:

=for example

   $prob = pdl [0.1,0.3,0.6];
   $ddh = $rng->ran_discrete_preproc($prob);
   $o = $rng->ran_discrete($discrete_dist_handle,100);

=head2 ran_discrete

=for ref

Is used to get the desired samples once a proper handle has been
enstablished (see ran_discrete_preproc()).

Usage:

=for usage

   $ndarray = $rng->ran_discrete($discrete_dist_handle,$num);

Example:

=for example

   $prob = pdl [0.1,0.3,0.6];
   $ddh = $rng->ran_discrete_preproc($prob);
   $o = $rng->ran_discrete($discrete_dist_handle,100);

=head2 ran_ver

=for ref

Returns an ndarray with C<$n> values generated by the Verhulst map from C<$x0> and
parameter C<$r>.

Usage:

=for usage

   $rng->ran_ver($x0, $r, $n);

=head2 ran_caos

=for ref

Returns values from Verhuls map with C<$r=4.0> and randomly chosen
C<$x0>. The values are scaled by C<$m>.

Usage:

=for usage

   $rng->ran_caos($m,$n);

=head1 BUGS

Feedback is welcome. Log bugs in the PDL bug database (the
database is always linked from L<http://pdl.perl.org/>).

=head1 SEE ALSO

L<PDL>

The GSL documentation for random number distributions is online at
L<https://www.gnu.org/software/gsl/doc/html/randist.html>

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
Docs mangled by C. Soeller. All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL RNG and randist modules were written by James Theiler.

=cut
#line 1283 "RNG.pm"







#line 1309 "gsl_random.pd"


use strict;

# PDL::GSL::RNG::nullcreate just creates a null PDL. Used
#  for the GSL functions that create PDLs
sub nullcreate{

	my ($type,$arg) = @_;

	PDL->nullcreate($arg);
}
#line 1304 "RNG.pm"



#line 1323 "gsl_random.pd"


sub get_uniform {
my ($obj,@var) = @_;if (ref($var[0]) eq 'PDL') {
    gsl_get_uniform_meat($var[0],$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    gsl_get_uniform_meat($p,$$obj);
    return $p;
}
}
#line 1324 "RNG.pm"



#line 1324 "gsl_random.pd"


sub get_uniform_pos {
my ($obj,@var) = @_;if (ref($var[0]) eq 'PDL') {
    gsl_get_uniform_pos_meat($var[0],$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    gsl_get_uniform_pos_meat($p,$$obj);
    return $p;
}
}
#line 1344 "RNG.pm"



#line 1325 "gsl_random.pd"


sub get {
my ($obj,@var) = @_;if (ref($var[0]) eq 'PDL') {
    gsl_get_meat($var[0],$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    gsl_get_meat($p,$$obj);
    return $p;
}
}
#line 1364 "RNG.pm"



#line 1326 "gsl_random.pd"


sub get_int {
my ($obj,$n,@var) = @_;if (!($n>0)) {barf("first parameter must be an int >0")};if (ref($var[0]) eq 'PDL') {
    gsl_get_int_meat($var[0],$n,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    gsl_get_int_meat($p,$n,$$obj);
    return $p;
}
}
#line 1384 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gsl_get_uniform_meat = \&PDL::GSL::RNG::gsl_get_uniform_meat;
#line 1391 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gsl_get_uniform_pos_meat = \&PDL::GSL::RNG::gsl_get_uniform_pos_meat;
#line 1398 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gsl_get_meat = \&PDL::GSL::RNG::gsl_get_meat;
#line 1405 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gsl_get_int_meat = \&PDL::GSL::RNG::gsl_get_int_meat;
#line 1412 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gaussian_meat = \&PDL::GSL::RNG::ran_gaussian_meat;
#line 1419 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_gaussian {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_gaussian_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_gaussian_meat($p,$a,$$obj);
    return $p;
}
}
#line 1440 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gaussian_var_meat = \&PDL::GSL::RNG::ran_gaussian_var_meat;
#line 1447 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_gaussian_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_gaussian_var_meat(@var,$$obj);
}
#line 1459 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_ugaussian_tail_meat = \&PDL::GSL::RNG::ran_ugaussian_tail_meat;
#line 1466 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_ugaussian_tail {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_ugaussian_tail_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_ugaussian_tail_meat($p,$a,$$obj);
    return $p;
}
}
#line 1487 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_ugaussian_tail_var_meat = \&PDL::GSL::RNG::ran_ugaussian_tail_var_meat;
#line 1494 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_ugaussian_tail_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_ugaussian_tail_var_meat(@var,$$obj);
}
#line 1506 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_exponential_meat = \&PDL::GSL::RNG::ran_exponential_meat;
#line 1513 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_exponential {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_exponential_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_exponential_meat($p,$a,$$obj);
    return $p;
}
}
#line 1534 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_exponential_var_meat = \&PDL::GSL::RNG::ran_exponential_var_meat;
#line 1541 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_exponential_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_exponential_var_meat(@var,$$obj);
}
#line 1553 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_laplace_meat = \&PDL::GSL::RNG::ran_laplace_meat;
#line 1560 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_laplace {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_laplace_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_laplace_meat($p,$a,$$obj);
    return $p;
}
}
#line 1581 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_laplace_var_meat = \&PDL::GSL::RNG::ran_laplace_var_meat;
#line 1588 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_laplace_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_laplace_var_meat(@var,$$obj);
}
#line 1600 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_exppow_meat = \&PDL::GSL::RNG::ran_exppow_meat;
#line 1607 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_exppow {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_exppow_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_exppow_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 1628 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_exppow_var_meat = \&PDL::GSL::RNG::ran_exppow_var_meat;
#line 1635 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_exppow_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_exppow_var_meat(@var,$$obj);
}
#line 1647 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_cauchy_meat = \&PDL::GSL::RNG::ran_cauchy_meat;
#line 1654 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_cauchy {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_cauchy_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_cauchy_meat($p,$a,$$obj);
    return $p;
}
}
#line 1675 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_cauchy_var_meat = \&PDL::GSL::RNG::ran_cauchy_var_meat;
#line 1682 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_cauchy_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_cauchy_var_meat(@var,$$obj);
}
#line 1694 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_rayleigh_meat = \&PDL::GSL::RNG::ran_rayleigh_meat;
#line 1701 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_rayleigh {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_rayleigh_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_rayleigh_meat($p,$a,$$obj);
    return $p;
}
}
#line 1722 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_rayleigh_var_meat = \&PDL::GSL::RNG::ran_rayleigh_var_meat;
#line 1729 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_rayleigh_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_rayleigh_var_meat(@var,$$obj);
}
#line 1741 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_rayleigh_tail_meat = \&PDL::GSL::RNG::ran_rayleigh_tail_meat;
#line 1748 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_rayleigh_tail {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_rayleigh_tail_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_rayleigh_tail_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 1769 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_rayleigh_tail_var_meat = \&PDL::GSL::RNG::ran_rayleigh_tail_var_meat;
#line 1776 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_rayleigh_tail_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_rayleigh_tail_var_meat(@var,$$obj);
}
#line 1788 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_levy_meat = \&PDL::GSL::RNG::ran_levy_meat;
#line 1795 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_levy {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_levy_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_levy_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 1816 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_levy_var_meat = \&PDL::GSL::RNG::ran_levy_var_meat;
#line 1823 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_levy_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_levy_var_meat(@var,$$obj);
}
#line 1835 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gamma_meat = \&PDL::GSL::RNG::ran_gamma_meat;
#line 1842 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_gamma {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_gamma_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_gamma_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 1863 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gamma_var_meat = \&PDL::GSL::RNG::ran_gamma_var_meat;
#line 1870 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_gamma_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_gamma_var_meat(@var,$$obj);
}
#line 1882 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_flat_meat = \&PDL::GSL::RNG::ran_flat_meat;
#line 1889 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_flat {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_flat_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_flat_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 1910 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_flat_var_meat = \&PDL::GSL::RNG::ran_flat_var_meat;
#line 1917 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_flat_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_flat_var_meat(@var,$$obj);
}
#line 1929 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_lognormal_meat = \&PDL::GSL::RNG::ran_lognormal_meat;
#line 1936 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_lognormal {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_lognormal_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_lognormal_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 1957 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_lognormal_var_meat = \&PDL::GSL::RNG::ran_lognormal_var_meat;
#line 1964 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_lognormal_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_lognormal_var_meat(@var,$$obj);
}
#line 1976 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_chisq_meat = \&PDL::GSL::RNG::ran_chisq_meat;
#line 1983 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_chisq {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_chisq_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_chisq_meat($p,$a,$$obj);
    return $p;
}
}
#line 2004 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_chisq_var_meat = \&PDL::GSL::RNG::ran_chisq_var_meat;
#line 2011 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_chisq_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_chisq_var_meat(@var,$$obj);
}
#line 2023 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_fdist_meat = \&PDL::GSL::RNG::ran_fdist_meat;
#line 2030 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_fdist {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_fdist_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_fdist_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2051 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_fdist_var_meat = \&PDL::GSL::RNG::ran_fdist_var_meat;
#line 2058 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_fdist_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_fdist_var_meat(@var,$$obj);
}
#line 2070 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_tdist_meat = \&PDL::GSL::RNG::ran_tdist_meat;
#line 2077 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_tdist {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_tdist_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_tdist_meat($p,$a,$$obj);
    return $p;
}
}
#line 2098 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_tdist_var_meat = \&PDL::GSL::RNG::ran_tdist_var_meat;
#line 2105 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_tdist_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_tdist_var_meat(@var,$$obj);
}
#line 2117 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_beta_meat = \&PDL::GSL::RNG::ran_beta_meat;
#line 2124 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_beta {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_beta_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_beta_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2145 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_beta_var_meat = \&PDL::GSL::RNG::ran_beta_var_meat;
#line 2152 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_beta_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_beta_var_meat(@var,$$obj);
}
#line 2164 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_logistic_meat = \&PDL::GSL::RNG::ran_logistic_meat;
#line 2171 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_logistic {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_logistic_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_logistic_meat($p,$a,$$obj);
    return $p;
}
}
#line 2192 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_logistic_var_meat = \&PDL::GSL::RNG::ran_logistic_var_meat;
#line 2199 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_logistic_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_logistic_var_meat(@var,$$obj);
}
#line 2211 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_pareto_meat = \&PDL::GSL::RNG::ran_pareto_meat;
#line 2218 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_pareto {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_pareto_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_pareto_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2239 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_pareto_var_meat = \&PDL::GSL::RNG::ran_pareto_var_meat;
#line 2246 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_pareto_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_pareto_var_meat(@var,$$obj);
}
#line 2258 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_weibull_meat = \&PDL::GSL::RNG::ran_weibull_meat;
#line 2265 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_weibull {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_weibull_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_weibull_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2286 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_weibull_var_meat = \&PDL::GSL::RNG::ran_weibull_var_meat;
#line 2293 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_weibull_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_weibull_var_meat(@var,$$obj);
}
#line 2305 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gumbel1_meat = \&PDL::GSL::RNG::ran_gumbel1_meat;
#line 2312 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_gumbel1 {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_gumbel1_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_gumbel1_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2333 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gumbel1_var_meat = \&PDL::GSL::RNG::ran_gumbel1_var_meat;
#line 2340 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_gumbel1_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_gumbel1_var_meat(@var,$$obj);
}
#line 2352 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gumbel2_meat = \&PDL::GSL::RNG::ran_gumbel2_meat;
#line 2359 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_gumbel2 {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_gumbel2_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_gumbel2_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2380 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_gumbel2_var_meat = \&PDL::GSL::RNG::ran_gumbel2_var_meat;
#line 2387 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_gumbel2_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_gumbel2_var_meat(@var,$$obj);
}
#line 2399 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_poisson_meat = \&PDL::GSL::RNG::ran_poisson_meat;
#line 2406 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_poisson {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_poisson_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_poisson_meat($p,$a,$$obj);
    return $p;
}
}
#line 2427 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_poisson_var_meat = \&PDL::GSL::RNG::ran_poisson_var_meat;
#line 2434 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_poisson_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_poisson_var_meat(@var,$$obj);
}
#line 2446 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_bernoulli_meat = \&PDL::GSL::RNG::ran_bernoulli_meat;
#line 2453 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_bernoulli {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_bernoulli_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_bernoulli_meat($p,$a,$$obj);
    return $p;
}
}
#line 2474 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_bernoulli_var_meat = \&PDL::GSL::RNG::ran_bernoulli_var_meat;
#line 2481 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_bernoulli_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_bernoulli_var_meat(@var,$$obj);
}
#line 2493 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_binomial_meat = \&PDL::GSL::RNG::ran_binomial_meat;
#line 2500 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_binomial {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_binomial_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_binomial_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2521 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_binomial_var_meat = \&PDL::GSL::RNG::ran_binomial_var_meat;
#line 2528 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_binomial_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_binomial_var_meat(@var,$$obj);
}
#line 2540 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_negative_binomial_meat = \&PDL::GSL::RNG::ran_negative_binomial_meat;
#line 2547 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_negative_binomial {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_negative_binomial_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_negative_binomial_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2568 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_negative_binomial_var_meat = \&PDL::GSL::RNG::ran_negative_binomial_var_meat;
#line 2575 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_negative_binomial_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_negative_binomial_var_meat(@var,$$obj);
}
#line 2587 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_pascal_meat = \&PDL::GSL::RNG::ran_pascal_meat;
#line 2594 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_pascal {
my ($obj,$a,$b,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_pascal_meat($var[0],$a,$b,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_pascal_meat($p,$a,$b,$$obj);
    return $p;
}
}
#line 2615 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_pascal_var_meat = \&PDL::GSL::RNG::ran_pascal_var_meat;
#line 2622 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_pascal_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    return ran_pascal_var_meat(@var,$$obj);
}
#line 2634 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_geometric_meat = \&PDL::GSL::RNG::ran_geometric_meat;
#line 2641 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_geometric {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_geometric_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_geometric_meat($p,$a,$$obj);
    return $p;
}
}
#line 2662 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_geometric_var_meat = \&PDL::GSL::RNG::ran_geometric_var_meat;
#line 2669 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_geometric_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_geometric_var_meat(@var,$$obj);
}
#line 2681 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_hypergeometric_meat = \&PDL::GSL::RNG::ran_hypergeometric_meat;
#line 2688 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_hypergeometric {
my ($obj,$a,$b,$c,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_hypergeometric_meat($var[0],$a,$b,$c,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_hypergeometric_meat($p,$a,$b,$c,$$obj);
    return $p;
}
}
#line 2709 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_hypergeometric_var_meat = \&PDL::GSL::RNG::ran_hypergeometric_var_meat;
#line 2716 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_hypergeometric_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 3) {barf("Bad number of parameters!");}
    return ran_hypergeometric_var_meat(@var,$$obj);
}
#line 2728 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_logarithmic_meat = \&PDL::GSL::RNG::ran_logarithmic_meat;
#line 2735 "RNG.pm"



#line 1407 "gsl_random.pd"


sub ran_logarithmic {
my ($obj,$a,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_logarithmic_meat($var[0],$a,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_logarithmic_meat($p,$a,$$obj);
    return $p;
}
}
#line 2756 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_logarithmic_var_meat = \&PDL::GSL::RNG::ran_logarithmic_var_meat;
#line 2763 "RNG.pm"



#line 1431 "gsl_random.pd"


sub ran_logarithmic_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    return ran_logarithmic_var_meat(@var,$$obj);
}
#line 2775 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_additive_gaussian_meat = \&PDL::GSL::RNG::ran_additive_gaussian_meat;
#line 2782 "RNG.pm"



#line 1521 "gsl_random.pd"


       sub ran_additive_gaussian {
	 my ($obj,$sigma,$var) = @_;
	 barf("In additive gaussian mode you must specify an ndarray!")
	   if ref($var) ne 'PDL';
	 ran_additive_gaussian_meat($var,$sigma,$$obj);
	 return $var;
       }
       
#line 2797 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_additive_poisson_meat = \&PDL::GSL::RNG::ran_additive_poisson_meat;
#line 2804 "RNG.pm"



#line 1537 "gsl_random.pd"


       sub ran_additive_poisson {
	 my ($obj,$sigma,$var) = @_;
	 barf("In additive poisson mode you must specify an ndarray!")
	   if ref($var) ne 'PDL';
	 ran_additive_poisson_meat($var,$sigma,$$obj);
	 return $var;
       }
       
#line 2819 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_feed_poisson_meat = \&PDL::GSL::RNG::ran_feed_poisson_meat;
#line 2826 "RNG.pm"



#line 1553 "gsl_random.pd"


       sub ran_feed_poisson {
	 my ($obj,$var) = @_;
	 barf("In poisson mode you must specify an ndarray!")
	   if ref($var) ne 'PDL';
	 ran_feed_poisson_meat($var,$$obj);
	 return $var;
       }
       
#line 2841 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_bivariate_gaussian_meat = \&PDL::GSL::RNG::ran_bivariate_gaussian_meat;
#line 2848 "RNG.pm"



#line 1574 "gsl_random.pd"


       sub ran_bivariate_gaussian {
	 my ($obj,$sigma_x,$sigma_y,$rho,$n) = @_;
	 barf("Not enough parameters for gaussian bivariate!") if $n<=0;
	 my $p = zeroes(2,$n);
	 ran_bivariate_gaussian_meat($p,$sigma_x,$sigma_y,$rho,$$obj);
	 return $p;
       }
       
#line 2863 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_dir_2d_meat = \&PDL::GSL::RNG::ran_dir_2d_meat;
#line 2870 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_dir_3d_meat = \&PDL::GSL::RNG::ran_dir_3d_meat;
#line 2877 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_dir_nd_meat = \&PDL::GSL::RNG::ran_dir_nd_meat;
#line 2884 "RNG.pm"



#line 1618 "gsl_random.pd"


       sub ran_dir {
	 my ($obj,$ndim,$n) = @_;
	 barf("Not enough parameters for random vectors!") if $n<=0;
	 my $p = zeroes($ndim,$n);
	 if ($ndim==2) { ran_dir_2d_meat($p,$$obj); }
	 elsif ($ndim==3) { ran_dir_3d_meat($p,$$obj); }
	 elsif ($ndim>=4 && $ndim<=100) { ran_dir_nd_meat($p,$ndim,$$obj); }
	 else { barf("Bad number of dimensions!"); }
	 return $p;
       }
       
#line 2902 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_discrete_meat = \&PDL::GSL::RNG::ran_discrete_meat;
#line 2909 "RNG.pm"



#line 1638 "gsl_random.pd"


sub ran_discrete {
my ($obj, $rdt, @var) = @_;
if (ref($var[0]) eq 'PDL') {
    ran_discrete_meat($var[0], $$rdt, $$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    ran_discrete_meat($p, $$rdt, $$obj);
    return $p;
}
}
#line 2930 "RNG.pm"



#line 1655 "gsl_random.pd"


sub ran_shuffle_vec {
my ($obj,@in) = @_;
my (@out,$i,$p);

$p = long [0..$#in];
$obj->ran_shuffle($p);
for($i=0;$i<scalar(@in);$i++) {
$out[$p->at($i)]=$in[$i];
}
return @out;
}
#line 2948 "RNG.pm"



#line 1669 "gsl_random.pd"


sub ran_choose_vec {
my ($obj,$nout,@in) = @_;
my (@out,$i,$pin,$pout);

$pin = long [0..$#in];
$pout = long [0..($nout-1)];
$obj->ran_choose($pin,$pout);
for($i=0;$i<$nout;$i++) {
$out[$i]=$in[$pout->at($i)];
}
return @out;
}
#line 2967 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_ver_meat = \&PDL::GSL::RNG::ran_ver_meat;
#line 2974 "RNG.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*ran_caos_meat = \&PDL::GSL::RNG::ran_caos_meat;
#line 2981 "RNG.pm"



#line 1703 "gsl_random.pd"


       sub ran_ver {
	 my ($obj,$x0,$r,$n) = @_;
	 barf("Not enough parameters for ran_ver!") if $n<=0;
	 my $p = zeroes($n);
	 ran_ver_meat($p,$x0,$r,$n,$$obj);
	 return $p;
       }
       
#line 2996 "RNG.pm"



#line 1713 "gsl_random.pd"


       sub ran_caos {
	 my ($obj,$m,$n) = @_;
	 barf("Not enough parameters for ran_caos!") if $n<=0;
	 my $p = zeroes($n);
	 ran_caos_meat($p,$m,$n,$$obj);
	 return $p;
       }
       
#line 3011 "RNG.pm"






# Exit with OK status

1;
