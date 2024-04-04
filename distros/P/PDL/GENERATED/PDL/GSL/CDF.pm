#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSL::CDF;

our @EXPORT_OK = qw(gsl_cdf_beta_P gsl_cdf_beta_Pinv gsl_cdf_beta_Q gsl_cdf_beta_Qinv gsl_cdf_binomial_P gsl_cdf_binomial_Q gsl_cdf_cauchy_P gsl_cdf_cauchy_Pinv gsl_cdf_cauchy_Q gsl_cdf_cauchy_Qinv gsl_cdf_chisq_P gsl_cdf_chisq_Pinv gsl_cdf_chisq_Q gsl_cdf_chisq_Qinv gsl_cdf_exponential_P gsl_cdf_exponential_Pinv gsl_cdf_exponential_Q gsl_cdf_exponential_Qinv gsl_cdf_exppow_P gsl_cdf_exppow_Q gsl_cdf_fdist_P gsl_cdf_fdist_Pinv gsl_cdf_fdist_Q gsl_cdf_fdist_Qinv gsl_cdf_flat_P gsl_cdf_flat_Pinv gsl_cdf_flat_Q gsl_cdf_flat_Qinv gsl_cdf_gamma_P gsl_cdf_gamma_Pinv gsl_cdf_gamma_Q gsl_cdf_gamma_Qinv gsl_cdf_gaussian_P gsl_cdf_gaussian_Pinv gsl_cdf_gaussian_Q gsl_cdf_gaussian_Qinv gsl_cdf_geometric_P gsl_cdf_geometric_Q gsl_cdf_gumbel1_P gsl_cdf_gumbel1_Pinv gsl_cdf_gumbel1_Q gsl_cdf_gumbel1_Qinv gsl_cdf_gumbel2_P gsl_cdf_gumbel2_Pinv gsl_cdf_gumbel2_Q gsl_cdf_gumbel2_Qinv gsl_cdf_hypergeometric_P gsl_cdf_hypergeometric_Q gsl_cdf_laplace_P gsl_cdf_laplace_Pinv gsl_cdf_laplace_Q gsl_cdf_laplace_Qinv gsl_cdf_logistic_P gsl_cdf_logistic_Pinv gsl_cdf_logistic_Q gsl_cdf_logistic_Qinv gsl_cdf_lognormal_P gsl_cdf_lognormal_Pinv gsl_cdf_lognormal_Q gsl_cdf_lognormal_Qinv gsl_cdf_negative_binomial_P gsl_cdf_negative_binomial_Q gsl_cdf_pareto_P gsl_cdf_pareto_Pinv gsl_cdf_pareto_Q gsl_cdf_pareto_Qinv gsl_cdf_pascal_P gsl_cdf_pascal_Q gsl_cdf_poisson_P gsl_cdf_poisson_Q gsl_cdf_rayleigh_P gsl_cdf_rayleigh_Pinv gsl_cdf_rayleigh_Q gsl_cdf_rayleigh_Qinv gsl_cdf_tdist_P gsl_cdf_tdist_Pinv gsl_cdf_tdist_Q gsl_cdf_tdist_Qinv gsl_cdf_ugaussian_P gsl_cdf_ugaussian_Pinv gsl_cdf_ugaussian_Q gsl_cdf_ugaussian_Qinv gsl_cdf_weibull_P gsl_cdf_weibull_Pinv gsl_cdf_weibull_Q gsl_cdf_weibull_Qinv );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::CDF ;







#line 4 "gsl_cdf.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSL::CDF - PDL interface to GSL Cumulative Distribution Functions

=head1 DESCRIPTION

This is an interface to the Cumulative Distribution Function package present in the GNU Scientific Library.

Let us have a continuous random number distributions are defined by a probability density function C<p(x)>.

The cumulative distribution function for the lower tail C<P(x)> is defined by the integral of C<p(x)>, and
gives the probability of a variate taking a value less than C<x>. These functions are named B<cdf_NNNNNNN_P()>.

The cumulative distribution function for the upper tail C<Q(x)> is defined by the integral of C<p(x)>, and
gives the probability of a variate taking a value greater than C<x>. These functions are named B<cdf_NNNNNNN_Q()>.

The upper and lower cumulative distribution functions are related by C<P(x) + Q(x) = 1> and
satisfy C<0 E<lt>= P(x) E<lt>= 1> and C<0 E<lt>= Q(x) E<lt>= 1>.

The inverse cumulative distributions, C<x = Pinv(P)> and C<x = Qinv(Q)> give the values of C<x> which correspond
to a specific value of C<P> or C<Q>. They can be used to find confidence limits from probability values.
These functions are named B<cdf_NNNNNNN_Pinv()> and B<cdf_NNNNNNN_Qinv()>.

For discrete distributions the probability of sampling the integer value C<k> is given by C<p(k)>, where
C<sum_k p(k) = 1>. The cumulative distribution for the lower tail C<P(k)> of a discrete distribution is
defined as, where the sum is over the allowed range of the distribution less than or equal to C<k>.

The cumulative distribution for the upper tail of a discrete distribution C<Q(k)> is defined as giving the sum
of probabilities for all values greater than C<k>. These two definitions satisfy the identity C<P(k) + Q(k) = 1>.

If the range of the distribution is C<1> to C<n> inclusive then C<P(n) = 1>, C<Q(n) = 0>
while C<P(1) = p(1)>, C<Q(1) = 1 - p(1)>.

=head1 SYNOPSIS

    use PDL;
    use PDL::GSL::CDF;

    my $p = gsl_cdf_tdist_P( $t, $df );

    my $t = gsl_cdf_tdist_Pinv( $p, $df );

=cut
#line 74 "CDF.pm"


=head1 FUNCTIONS

=cut





#line 144 "gsl_cdf.pd"

=head2 The Beta Distribution (gsl_cdf_beta_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the beta distribution with parameters I<a> and I<b>.

=cut
#line 92 "CDF.pm"


=head2 gsl_cdf_beta_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_beta_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_beta_P = \&PDL::gsl_cdf_beta_P;






=head2 gsl_cdf_beta_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_beta_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_beta_Pinv = \&PDL::gsl_cdf_beta_Pinv;






=head2 gsl_cdf_beta_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_beta_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_beta_Q = \&PDL::gsl_cdf_beta_Q;






=head2 gsl_cdf_beta_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_beta_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_beta_Qinv = \&PDL::gsl_cdf_beta_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Binomial Distribution (gsl_cdf_binomial_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the binomial distribution with parameters I<p> and I<n>.

=cut
#line 201 "CDF.pm"


=head2 gsl_cdf_binomial_P

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref

=for bad

gsl_cdf_binomial_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_binomial_P = \&PDL::gsl_cdf_binomial_P;






=head2 gsl_cdf_binomial_Q

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref

=for bad

gsl_cdf_binomial_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_binomial_Q = \&PDL::gsl_cdf_binomial_Q;





#line 144 "gsl_cdf.pd"

=head2 The Cauchy Distribution (gsl_cdf_cauchy_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Cauchy distribution with scale parameter I<a>.

=cut
#line 260 "CDF.pm"


=head2 gsl_cdf_cauchy_P

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_cauchy_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_cauchy_P = \&PDL::gsl_cdf_cauchy_P;






=head2 gsl_cdf_cauchy_Pinv

=for sig

  Signature: (double p(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_cauchy_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_cauchy_Pinv = \&PDL::gsl_cdf_cauchy_Pinv;






=head2 gsl_cdf_cauchy_Q

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_cauchy_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_cauchy_Q = \&PDL::gsl_cdf_cauchy_Q;






=head2 gsl_cdf_cauchy_Qinv

=for sig

  Signature: (double q(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_cauchy_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_cauchy_Qinv = \&PDL::gsl_cdf_cauchy_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Chi-squared Distribution (gsl_cdf_chisq_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the chi-squared distribution with I<nu> degrees of freedom.

=cut
#line 369 "CDF.pm"


=head2 gsl_cdf_chisq_P

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_chisq_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_chisq_P = \&PDL::gsl_cdf_chisq_P;






=head2 gsl_cdf_chisq_Pinv

=for sig

  Signature: (double p(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_chisq_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_chisq_Pinv = \&PDL::gsl_cdf_chisq_Pinv;






=head2 gsl_cdf_chisq_Q

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_chisq_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_chisq_Q = \&PDL::gsl_cdf_chisq_Q;






=head2 gsl_cdf_chisq_Qinv

=for sig

  Signature: (double q(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_chisq_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_chisq_Qinv = \&PDL::gsl_cdf_chisq_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Exponential Distribution (gsl_cdf_exponential_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the exponential distribution with mean I<mu>.

=cut
#line 478 "CDF.pm"


=head2 gsl_cdf_exponential_P

=for sig

  Signature: (double x(); double mu(); double [o]out())

=for ref

=for bad

gsl_cdf_exponential_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_exponential_P = \&PDL::gsl_cdf_exponential_P;






=head2 gsl_cdf_exponential_Pinv

=for sig

  Signature: (double p(); double mu(); double [o]out())

=for ref

=for bad

gsl_cdf_exponential_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_exponential_Pinv = \&PDL::gsl_cdf_exponential_Pinv;






=head2 gsl_cdf_exponential_Q

=for sig

  Signature: (double x(); double mu(); double [o]out())

=for ref

=for bad

gsl_cdf_exponential_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_exponential_Q = \&PDL::gsl_cdf_exponential_Q;






=head2 gsl_cdf_exponential_Qinv

=for sig

  Signature: (double q(); double mu(); double [o]out())

=for ref

=for bad

gsl_cdf_exponential_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_exponential_Qinv = \&PDL::gsl_cdf_exponential_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Exponential Power Distribution (gsl_cdf_exppow_*)

These functions compute the cumulative distribution functions P(x), Q(x) for the exponential power distribution with parameters I<a> and I<b>.

=cut
#line 587 "CDF.pm"


=head2 gsl_cdf_exppow_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_exppow_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_exppow_P = \&PDL::gsl_cdf_exppow_P;






=head2 gsl_cdf_exppow_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_exppow_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_exppow_Q = \&PDL::gsl_cdf_exppow_Q;





#line 144 "gsl_cdf.pd"

=head2 The F-distribution (gsl_cdf_fdist_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the F-distribution with I<nu1> and I<nu2> degrees of freedom.

=cut
#line 646 "CDF.pm"


=head2 gsl_cdf_fdist_P

=for sig

  Signature: (double x(); double nua(); double nub(); double [o]out())

=for ref

=for bad

gsl_cdf_fdist_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_fdist_P = \&PDL::gsl_cdf_fdist_P;






=head2 gsl_cdf_fdist_Pinv

=for sig

  Signature: (double p(); double nua(); double nub(); double [o]out())

=for ref

=for bad

gsl_cdf_fdist_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_fdist_Pinv = \&PDL::gsl_cdf_fdist_Pinv;






=head2 gsl_cdf_fdist_Q

=for sig

  Signature: (double x(); double nua(); double nub(); double [o]out())

=for ref

=for bad

gsl_cdf_fdist_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_fdist_Q = \&PDL::gsl_cdf_fdist_Q;






=head2 gsl_cdf_fdist_Qinv

=for sig

  Signature: (double q(); double nua(); double nub(); double [o]out())

=for ref

=for bad

gsl_cdf_fdist_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_fdist_Qinv = \&PDL::gsl_cdf_fdist_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Flat (Uniform) Distribution (gsl_cdf_flat_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for a uniform distribution from I<a> to I<b>.

=cut
#line 755 "CDF.pm"


=head2 gsl_cdf_flat_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_flat_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_flat_P = \&PDL::gsl_cdf_flat_P;






=head2 gsl_cdf_flat_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_flat_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_flat_Pinv = \&PDL::gsl_cdf_flat_Pinv;






=head2 gsl_cdf_flat_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_flat_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_flat_Q = \&PDL::gsl_cdf_flat_Q;






=head2 gsl_cdf_flat_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_flat_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_flat_Qinv = \&PDL::gsl_cdf_flat_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Gamma Distribution (gsl_cdf_gamma_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the gamma distribution with parameters I<a> and I<b>.

=cut
#line 864 "CDF.pm"


=head2 gsl_cdf_gamma_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gamma_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gamma_P = \&PDL::gsl_cdf_gamma_P;






=head2 gsl_cdf_gamma_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gamma_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gamma_Pinv = \&PDL::gsl_cdf_gamma_Pinv;






=head2 gsl_cdf_gamma_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gamma_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gamma_Q = \&PDL::gsl_cdf_gamma_Q;






=head2 gsl_cdf_gamma_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gamma_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gamma_Qinv = \&PDL::gsl_cdf_gamma_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Gaussian Distribution (gsl_cdf_gaussian_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Gaussian distribution with standard deviation I<sigma>.

=cut
#line 973 "CDF.pm"


=head2 gsl_cdf_gaussian_P

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_gaussian_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gaussian_P = \&PDL::gsl_cdf_gaussian_P;






=head2 gsl_cdf_gaussian_Pinv

=for sig

  Signature: (double p(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_gaussian_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gaussian_Pinv = \&PDL::gsl_cdf_gaussian_Pinv;






=head2 gsl_cdf_gaussian_Q

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_gaussian_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gaussian_Q = \&PDL::gsl_cdf_gaussian_Q;






=head2 gsl_cdf_gaussian_Qinv

=for sig

  Signature: (double q(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_gaussian_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gaussian_Qinv = \&PDL::gsl_cdf_gaussian_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Geometric Distribution (gsl_cdf_geometric_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the geometric distribution with parameter I<p>.

=cut
#line 1082 "CDF.pm"


=head2 gsl_cdf_geometric_P

=for sig

  Signature: (ushort k(); double p(); double [o]out())

=for ref

=for bad

gsl_cdf_geometric_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_geometric_P = \&PDL::gsl_cdf_geometric_P;






=head2 gsl_cdf_geometric_Q

=for sig

  Signature: (ushort k(); double p(); double [o]out())

=for ref

=for bad

gsl_cdf_geometric_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_geometric_Q = \&PDL::gsl_cdf_geometric_Q;





#line 144 "gsl_cdf.pd"

=head2 The Type-1 Gumbel Distribution (gsl_cdf_gumbel1_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Type-1 Gumbel distribution with parameters I<a> and I<b>.

=cut
#line 1141 "CDF.pm"


=head2 gsl_cdf_gumbel1_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel1_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel1_P = \&PDL::gsl_cdf_gumbel1_P;






=head2 gsl_cdf_gumbel1_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel1_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel1_Pinv = \&PDL::gsl_cdf_gumbel1_Pinv;






=head2 gsl_cdf_gumbel1_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel1_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel1_Q = \&PDL::gsl_cdf_gumbel1_Q;






=head2 gsl_cdf_gumbel1_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel1_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel1_Qinv = \&PDL::gsl_cdf_gumbel1_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Type-2 Gumbel Distribution (gsl_cdf_gumbel2_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Type-2 Gumbel distribution with parameters I<a> and I<b>.

=cut
#line 1250 "CDF.pm"


=head2 gsl_cdf_gumbel2_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel2_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel2_P = \&PDL::gsl_cdf_gumbel2_P;






=head2 gsl_cdf_gumbel2_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel2_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel2_Pinv = \&PDL::gsl_cdf_gumbel2_Pinv;






=head2 gsl_cdf_gumbel2_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel2_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel2_Q = \&PDL::gsl_cdf_gumbel2_Q;






=head2 gsl_cdf_gumbel2_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_gumbel2_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_gumbel2_Qinv = \&PDL::gsl_cdf_gumbel2_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Hypergeometric Distribution (gsl_cdf_hypergeometric_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the hypergeometric distribution with parameters I<n1>, I<n2> and I<t>.

=cut
#line 1359 "CDF.pm"


=head2 gsl_cdf_hypergeometric_P

=for sig

  Signature: (ushort k(); ushort na(); ushort nb(); ushort t(); double [o]out())

=for ref

=for bad

gsl_cdf_hypergeometric_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_hypergeometric_P = \&PDL::gsl_cdf_hypergeometric_P;






=head2 gsl_cdf_hypergeometric_Q

=for sig

  Signature: (ushort k(); ushort na(); ushort nb(); ushort t(); double [o]out())

=for ref

=for bad

gsl_cdf_hypergeometric_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_hypergeometric_Q = \&PDL::gsl_cdf_hypergeometric_Q;





#line 144 "gsl_cdf.pd"

=head2 The Laplace Distribution (gsl_cdf_laplace_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Laplace distribution with width I<a>.

=cut
#line 1418 "CDF.pm"


=head2 gsl_cdf_laplace_P

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_laplace_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_laplace_P = \&PDL::gsl_cdf_laplace_P;






=head2 gsl_cdf_laplace_Pinv

=for sig

  Signature: (double p(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_laplace_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_laplace_Pinv = \&PDL::gsl_cdf_laplace_Pinv;






=head2 gsl_cdf_laplace_Q

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_laplace_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_laplace_Q = \&PDL::gsl_cdf_laplace_Q;






=head2 gsl_cdf_laplace_Qinv

=for sig

  Signature: (double q(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_laplace_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_laplace_Qinv = \&PDL::gsl_cdf_laplace_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Logistic Distribution (gsl_cdf_logistic_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the logistic distribution with scale parameter I<a>.

=cut
#line 1527 "CDF.pm"


=head2 gsl_cdf_logistic_P

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_logistic_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_logistic_P = \&PDL::gsl_cdf_logistic_P;






=head2 gsl_cdf_logistic_Pinv

=for sig

  Signature: (double p(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_logistic_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_logistic_Pinv = \&PDL::gsl_cdf_logistic_Pinv;






=head2 gsl_cdf_logistic_Q

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_logistic_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_logistic_Q = \&PDL::gsl_cdf_logistic_Q;






=head2 gsl_cdf_logistic_Qinv

=for sig

  Signature: (double q(); double a(); double [o]out())

=for ref

=for bad

gsl_cdf_logistic_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_logistic_Qinv = \&PDL::gsl_cdf_logistic_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Lognormal Distribution (gsl_cdf_lognormal_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the lognormal distribution with parameters I<zeta> and I<sigma>.

=cut
#line 1636 "CDF.pm"


=head2 gsl_cdf_lognormal_P

=for sig

  Signature: (double x(); double zeta(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_lognormal_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_lognormal_P = \&PDL::gsl_cdf_lognormal_P;






=head2 gsl_cdf_lognormal_Pinv

=for sig

  Signature: (double p(); double zeta(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_lognormal_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_lognormal_Pinv = \&PDL::gsl_cdf_lognormal_Pinv;






=head2 gsl_cdf_lognormal_Q

=for sig

  Signature: (double x(); double zeta(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_lognormal_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_lognormal_Q = \&PDL::gsl_cdf_lognormal_Q;






=head2 gsl_cdf_lognormal_Qinv

=for sig

  Signature: (double q(); double zeta(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_lognormal_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_lognormal_Qinv = \&PDL::gsl_cdf_lognormal_Qinv;






=head2 gsl_cdf_negative_binomial_P

=for sig

  Signature: (ushort k(); double p(); double n(); double [o]out())

=for ref

=for bad

gsl_cdf_negative_binomial_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_negative_binomial_P = \&PDL::gsl_cdf_negative_binomial_P;






=head2 gsl_cdf_negative_binomial_Q

=for sig

  Signature: (ushort k(); double p(); double n(); double [o]out())

=for ref

=for bad

gsl_cdf_negative_binomial_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_negative_binomial_Q = \&PDL::gsl_cdf_negative_binomial_Q;





#line 144 "gsl_cdf.pd"

=head2 The Pareto Distribution (gsl_cdf_pareto_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Pareto distribution with exponent I<a> and scale I<b>.

=cut
#line 1795 "CDF.pm"


=head2 gsl_cdf_pareto_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_pareto_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_pareto_P = \&PDL::gsl_cdf_pareto_P;






=head2 gsl_cdf_pareto_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_pareto_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_pareto_Pinv = \&PDL::gsl_cdf_pareto_Pinv;






=head2 gsl_cdf_pareto_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_pareto_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_pareto_Q = \&PDL::gsl_cdf_pareto_Q;






=head2 gsl_cdf_pareto_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_pareto_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_pareto_Qinv = \&PDL::gsl_cdf_pareto_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Pascal Distribution (gsl_cdf_pascal_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the Pascal distribution with parameters I<p> and I<n>.

=cut
#line 1904 "CDF.pm"


=head2 gsl_cdf_pascal_P

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref

=for bad

gsl_cdf_pascal_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_pascal_P = \&PDL::gsl_cdf_pascal_P;






=head2 gsl_cdf_pascal_Q

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref

=for bad

gsl_cdf_pascal_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_pascal_Q = \&PDL::gsl_cdf_pascal_Q;





#line 144 "gsl_cdf.pd"

=head2 The Poisson Distribution (gsl_cdf_poisson_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the Poisson distribution with parameter I<mu>.

=cut
#line 1963 "CDF.pm"


=head2 gsl_cdf_poisson_P

=for sig

  Signature: (ushort k(); double mu(); double [o]out())

=for ref

=for bad

gsl_cdf_poisson_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_poisson_P = \&PDL::gsl_cdf_poisson_P;






=head2 gsl_cdf_poisson_Q

=for sig

  Signature: (ushort k(); double mu(); double [o]out())

=for ref

=for bad

gsl_cdf_poisson_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_poisson_Q = \&PDL::gsl_cdf_poisson_Q;





#line 144 "gsl_cdf.pd"

=head2 The Rayleigh Distribution (gsl_cdf_rayleigh_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Rayleigh distribution with scale parameter I<sigma>.

=cut
#line 2022 "CDF.pm"


=head2 gsl_cdf_rayleigh_P

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_rayleigh_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_rayleigh_P = \&PDL::gsl_cdf_rayleigh_P;






=head2 gsl_cdf_rayleigh_Pinv

=for sig

  Signature: (double p(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_rayleigh_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_rayleigh_Pinv = \&PDL::gsl_cdf_rayleigh_Pinv;






=head2 gsl_cdf_rayleigh_Q

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_rayleigh_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_rayleigh_Q = \&PDL::gsl_cdf_rayleigh_Q;






=head2 gsl_cdf_rayleigh_Qinv

=for sig

  Signature: (double q(); double sigma(); double [o]out())

=for ref

=for bad

gsl_cdf_rayleigh_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_rayleigh_Qinv = \&PDL::gsl_cdf_rayleigh_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The t-distribution (gsl_cdf_tdist_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the t-distribution with I<nu> degrees of freedom.

=cut
#line 2131 "CDF.pm"


=head2 gsl_cdf_tdist_P

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_tdist_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_tdist_P = \&PDL::gsl_cdf_tdist_P;






=head2 gsl_cdf_tdist_Pinv

=for sig

  Signature: (double p(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_tdist_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_tdist_Pinv = \&PDL::gsl_cdf_tdist_Pinv;






=head2 gsl_cdf_tdist_Q

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_tdist_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_tdist_Q = \&PDL::gsl_cdf_tdist_Q;






=head2 gsl_cdf_tdist_Qinv

=for sig

  Signature: (double q(); double nu(); double [o]out())

=for ref

=for bad

gsl_cdf_tdist_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_tdist_Qinv = \&PDL::gsl_cdf_tdist_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Unit Gaussian Distribution (gsl_cdf_ugaussian_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the unit Gaussian distribution.

=cut
#line 2240 "CDF.pm"


=head2 gsl_cdf_ugaussian_P

=for sig

  Signature: (double x(); double [o]out())

=for ref

=for bad

gsl_cdf_ugaussian_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_ugaussian_P = \&PDL::gsl_cdf_ugaussian_P;






=head2 gsl_cdf_ugaussian_Pinv

=for sig

  Signature: (double p(); double [o]out())

=for ref

=for bad

gsl_cdf_ugaussian_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_ugaussian_Pinv = \&PDL::gsl_cdf_ugaussian_Pinv;






=head2 gsl_cdf_ugaussian_Q

=for sig

  Signature: (double x(); double [o]out())

=for ref

=for bad

gsl_cdf_ugaussian_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_ugaussian_Q = \&PDL::gsl_cdf_ugaussian_Q;






=head2 gsl_cdf_ugaussian_Qinv

=for sig

  Signature: (double q(); double [o]out())

=for ref

=for bad

gsl_cdf_ugaussian_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_ugaussian_Qinv = \&PDL::gsl_cdf_ugaussian_Qinv;





#line 144 "gsl_cdf.pd"

=head2 The Weibull Distribution (gsl_cdf_weibull_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Weibull distribution with scale I<a> and exponent I<b>.

=cut
#line 2349 "CDF.pm"


=head2 gsl_cdf_weibull_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_weibull_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_weibull_P = \&PDL::gsl_cdf_weibull_P;






=head2 gsl_cdf_weibull_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_weibull_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_weibull_Pinv = \&PDL::gsl_cdf_weibull_Pinv;






=head2 gsl_cdf_weibull_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_weibull_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_weibull_Q = \&PDL::gsl_cdf_weibull_Q;






=head2 gsl_cdf_weibull_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref

=for bad

gsl_cdf_weibull_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_cdf_weibull_Qinv = \&PDL::gsl_cdf_weibull_Qinv;







#line 176 "gsl_cdf.pd"

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

The GSL CDF module was written by J. Stover.

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 2464 "CDF.pm"

# Exit with OK status

1;
