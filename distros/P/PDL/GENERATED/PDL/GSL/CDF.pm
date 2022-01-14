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






#line 5 "gsl_cdf.pd"

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
#line 73 "CDF.pm"






=head1 FUNCTIONS

=cut




#line 145 "gsl_cdf.pd"

=head2 The Beta Distribution (gsl_cdf_beta_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the beta distribution with parameters I<a> and I<b>.

=cut
#line 94 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_beta_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_beta_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 118 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_beta_P = \&PDL::gsl_cdf_beta_P;
#line 124 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_beta_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_beta_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 148 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_beta_Pinv = \&PDL::gsl_cdf_beta_Pinv;
#line 154 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_beta_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_beta_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 178 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_beta_Q = \&PDL::gsl_cdf_beta_Q;
#line 184 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_beta_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_beta_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 208 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_beta_Qinv = \&PDL::gsl_cdf_beta_Qinv;
#line 214 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Binomial Distribution (gsl_cdf_binomial_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the binomial distribution with parameters I<p> and I<n>.

=cut
#line 225 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_binomial_P

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref



=for bad

gsl_cdf_binomial_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 249 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_binomial_P = \&PDL::gsl_cdf_binomial_P;
#line 255 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_binomial_Q

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref



=for bad

gsl_cdf_binomial_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 279 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_binomial_Q = \&PDL::gsl_cdf_binomial_Q;
#line 285 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Cauchy Distribution (gsl_cdf_cauchy_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Cauchy distribution with scale parameter I<a>.

=cut
#line 296 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_cauchy_P

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_cauchy_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 320 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_cauchy_P = \&PDL::gsl_cdf_cauchy_P;
#line 326 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_cauchy_Pinv

=for sig

  Signature: (double p(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_cauchy_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 350 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_cauchy_Pinv = \&PDL::gsl_cdf_cauchy_Pinv;
#line 356 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_cauchy_Q

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_cauchy_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 380 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_cauchy_Q = \&PDL::gsl_cdf_cauchy_Q;
#line 386 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_cauchy_Qinv

=for sig

  Signature: (double q(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_cauchy_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 410 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_cauchy_Qinv = \&PDL::gsl_cdf_cauchy_Qinv;
#line 416 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Chi-squared Distribution (gsl_cdf_chisq_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the chi-squared distribution with I<nu> degrees of freedom.

=cut
#line 427 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_chisq_P

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_chisq_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 451 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_chisq_P = \&PDL::gsl_cdf_chisq_P;
#line 457 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_chisq_Pinv

=for sig

  Signature: (double p(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_chisq_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 481 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_chisq_Pinv = \&PDL::gsl_cdf_chisq_Pinv;
#line 487 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_chisq_Q

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_chisq_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 511 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_chisq_Q = \&PDL::gsl_cdf_chisq_Q;
#line 517 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_chisq_Qinv

=for sig

  Signature: (double q(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_chisq_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 541 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_chisq_Qinv = \&PDL::gsl_cdf_chisq_Qinv;
#line 547 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Exponential Distribution (gsl_cdf_exponential_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the exponential distribution with mean I<mu>.

=cut
#line 558 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_exponential_P

=for sig

  Signature: (double x(); double mu(); double [o]out())

=for ref



=for bad

gsl_cdf_exponential_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 582 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_exponential_P = \&PDL::gsl_cdf_exponential_P;
#line 588 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_exponential_Pinv

=for sig

  Signature: (double p(); double mu(); double [o]out())

=for ref



=for bad

gsl_cdf_exponential_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 612 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_exponential_Pinv = \&PDL::gsl_cdf_exponential_Pinv;
#line 618 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_exponential_Q

=for sig

  Signature: (double x(); double mu(); double [o]out())

=for ref



=for bad

gsl_cdf_exponential_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 642 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_exponential_Q = \&PDL::gsl_cdf_exponential_Q;
#line 648 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_exponential_Qinv

=for sig

  Signature: (double q(); double mu(); double [o]out())

=for ref



=for bad

gsl_cdf_exponential_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 672 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_exponential_Qinv = \&PDL::gsl_cdf_exponential_Qinv;
#line 678 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Exponential Power Distribution (gsl_cdf_exppow_*)

These functions compute the cumulative distribution functions P(x), Q(x) for the exponential power distribution with parameters I<a> and I<b>.

=cut
#line 689 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_exppow_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_exppow_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 713 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_exppow_P = \&PDL::gsl_cdf_exppow_P;
#line 719 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_exppow_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_exppow_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 743 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_exppow_Q = \&PDL::gsl_cdf_exppow_Q;
#line 749 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The F-distribution (gsl_cdf_fdist_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the F-distribution with I<nu1> and I<nu2> degrees of freedom.

=cut
#line 760 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_fdist_P

=for sig

  Signature: (double x(); double nua(); double nub(); double [o]out())

=for ref



=for bad

gsl_cdf_fdist_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 784 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_fdist_P = \&PDL::gsl_cdf_fdist_P;
#line 790 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_fdist_Pinv

=for sig

  Signature: (double p(); double nua(); double nub(); double [o]out())

=for ref



=for bad

gsl_cdf_fdist_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 814 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_fdist_Pinv = \&PDL::gsl_cdf_fdist_Pinv;
#line 820 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_fdist_Q

=for sig

  Signature: (double x(); double nua(); double nub(); double [o]out())

=for ref



=for bad

gsl_cdf_fdist_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 844 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_fdist_Q = \&PDL::gsl_cdf_fdist_Q;
#line 850 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_fdist_Qinv

=for sig

  Signature: (double q(); double nua(); double nub(); double [o]out())

=for ref



=for bad

gsl_cdf_fdist_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 874 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_fdist_Qinv = \&PDL::gsl_cdf_fdist_Qinv;
#line 880 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Flat (Uniform) Distribution (gsl_cdf_flat_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for a uniform distribution from I<a> to I<b>.

=cut
#line 891 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_flat_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_flat_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 915 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_flat_P = \&PDL::gsl_cdf_flat_P;
#line 921 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_flat_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_flat_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 945 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_flat_Pinv = \&PDL::gsl_cdf_flat_Pinv;
#line 951 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_flat_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_flat_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 975 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_flat_Q = \&PDL::gsl_cdf_flat_Q;
#line 981 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_flat_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_flat_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1005 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_flat_Qinv = \&PDL::gsl_cdf_flat_Qinv;
#line 1011 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Gamma Distribution (gsl_cdf_gamma_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the gamma distribution with parameters I<a> and I<b>.

=cut
#line 1022 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gamma_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gamma_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1046 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gamma_P = \&PDL::gsl_cdf_gamma_P;
#line 1052 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gamma_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gamma_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1076 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gamma_Pinv = \&PDL::gsl_cdf_gamma_Pinv;
#line 1082 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gamma_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gamma_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1106 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gamma_Q = \&PDL::gsl_cdf_gamma_Q;
#line 1112 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gamma_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gamma_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1136 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gamma_Qinv = \&PDL::gsl_cdf_gamma_Qinv;
#line 1142 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Gaussian Distribution (gsl_cdf_gaussian_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Gaussian distribution with standard deviation I<sigma>.

=cut
#line 1153 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gaussian_P

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_gaussian_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1177 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gaussian_P = \&PDL::gsl_cdf_gaussian_P;
#line 1183 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gaussian_Pinv

=for sig

  Signature: (double p(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_gaussian_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1207 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gaussian_Pinv = \&PDL::gsl_cdf_gaussian_Pinv;
#line 1213 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gaussian_Q

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_gaussian_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1237 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gaussian_Q = \&PDL::gsl_cdf_gaussian_Q;
#line 1243 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gaussian_Qinv

=for sig

  Signature: (double q(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_gaussian_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1267 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gaussian_Qinv = \&PDL::gsl_cdf_gaussian_Qinv;
#line 1273 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Geometric Distribution (gsl_cdf_geometric_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the geometric distribution with parameter I<p>.

=cut
#line 1284 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_geometric_P

=for sig

  Signature: (ushort k(); double p(); double [o]out())

=for ref



=for bad

gsl_cdf_geometric_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1308 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_geometric_P = \&PDL::gsl_cdf_geometric_P;
#line 1314 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_geometric_Q

=for sig

  Signature: (ushort k(); double p(); double [o]out())

=for ref



=for bad

gsl_cdf_geometric_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1338 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_geometric_Q = \&PDL::gsl_cdf_geometric_Q;
#line 1344 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Type-1 Gumbel Distribution (gsl_cdf_gumbel1_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Type-1 Gumbel distribution with parameters I<a> and I<b>.

=cut
#line 1355 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel1_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel1_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1379 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel1_P = \&PDL::gsl_cdf_gumbel1_P;
#line 1385 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel1_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel1_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1409 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel1_Pinv = \&PDL::gsl_cdf_gumbel1_Pinv;
#line 1415 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel1_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel1_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1439 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel1_Q = \&PDL::gsl_cdf_gumbel1_Q;
#line 1445 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel1_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel1_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1469 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel1_Qinv = \&PDL::gsl_cdf_gumbel1_Qinv;
#line 1475 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Type-2 Gumbel Distribution (gsl_cdf_gumbel2_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Type-2 Gumbel distribution with parameters I<a> and I<b>.

=cut
#line 1486 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel2_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel2_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1510 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel2_P = \&PDL::gsl_cdf_gumbel2_P;
#line 1516 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel2_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel2_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1540 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel2_Pinv = \&PDL::gsl_cdf_gumbel2_Pinv;
#line 1546 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel2_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel2_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1570 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel2_Q = \&PDL::gsl_cdf_gumbel2_Q;
#line 1576 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_gumbel2_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_gumbel2_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1600 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_gumbel2_Qinv = \&PDL::gsl_cdf_gumbel2_Qinv;
#line 1606 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Hypergeometric Distribution (gsl_cdf_hypergeometric_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the hypergeometric distribution with parameters I<n1>, I<n2> and I<t>.

=cut
#line 1617 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_hypergeometric_P

=for sig

  Signature: (ushort k(); ushort na(); ushort nb(); ushort t(); double [o]out())

=for ref



=for bad

gsl_cdf_hypergeometric_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1641 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_hypergeometric_P = \&PDL::gsl_cdf_hypergeometric_P;
#line 1647 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_hypergeometric_Q

=for sig

  Signature: (ushort k(); ushort na(); ushort nb(); ushort t(); double [o]out())

=for ref



=for bad

gsl_cdf_hypergeometric_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1671 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_hypergeometric_Q = \&PDL::gsl_cdf_hypergeometric_Q;
#line 1677 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Laplace Distribution (gsl_cdf_laplace_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Laplace distribution with width I<a>.

=cut
#line 1688 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_laplace_P

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_laplace_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1712 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_laplace_P = \&PDL::gsl_cdf_laplace_P;
#line 1718 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_laplace_Pinv

=for sig

  Signature: (double p(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_laplace_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1742 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_laplace_Pinv = \&PDL::gsl_cdf_laplace_Pinv;
#line 1748 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_laplace_Q

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_laplace_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1772 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_laplace_Q = \&PDL::gsl_cdf_laplace_Q;
#line 1778 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_laplace_Qinv

=for sig

  Signature: (double q(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_laplace_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1802 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_laplace_Qinv = \&PDL::gsl_cdf_laplace_Qinv;
#line 1808 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Logistic Distribution (gsl_cdf_logistic_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the logistic distribution with scale parameter I<a>.

=cut
#line 1819 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_logistic_P

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_logistic_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1843 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_logistic_P = \&PDL::gsl_cdf_logistic_P;
#line 1849 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_logistic_Pinv

=for sig

  Signature: (double p(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_logistic_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1873 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_logistic_Pinv = \&PDL::gsl_cdf_logistic_Pinv;
#line 1879 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_logistic_Q

=for sig

  Signature: (double x(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_logistic_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1903 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_logistic_Q = \&PDL::gsl_cdf_logistic_Q;
#line 1909 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_logistic_Qinv

=for sig

  Signature: (double q(); double a(); double [o]out())

=for ref



=for bad

gsl_cdf_logistic_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1933 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_logistic_Qinv = \&PDL::gsl_cdf_logistic_Qinv;
#line 1939 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Lognormal Distribution (gsl_cdf_lognormal_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the lognormal distribution with parameters I<zeta> and I<sigma>.

=cut
#line 1950 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_lognormal_P

=for sig

  Signature: (double x(); double zeta(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_lognormal_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1974 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_lognormal_P = \&PDL::gsl_cdf_lognormal_P;
#line 1980 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_lognormal_Pinv

=for sig

  Signature: (double p(); double zeta(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_lognormal_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2004 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_lognormal_Pinv = \&PDL::gsl_cdf_lognormal_Pinv;
#line 2010 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_lognormal_Q

=for sig

  Signature: (double x(); double zeta(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_lognormal_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2034 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_lognormal_Q = \&PDL::gsl_cdf_lognormal_Q;
#line 2040 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_lognormal_Qinv

=for sig

  Signature: (double q(); double zeta(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_lognormal_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2064 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_lognormal_Qinv = \&PDL::gsl_cdf_lognormal_Qinv;
#line 2070 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_negative_binomial_P

=for sig

  Signature: (ushort k(); double p(); double n(); double [o]out())

=for ref



=for bad

gsl_cdf_negative_binomial_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2094 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_negative_binomial_P = \&PDL::gsl_cdf_negative_binomial_P;
#line 2100 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_negative_binomial_Q

=for sig

  Signature: (ushort k(); double p(); double n(); double [o]out())

=for ref



=for bad

gsl_cdf_negative_binomial_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2124 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_negative_binomial_Q = \&PDL::gsl_cdf_negative_binomial_Q;
#line 2130 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Pareto Distribution (gsl_cdf_pareto_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Pareto distribution with exponent I<a> and scale I<b>.

=cut
#line 2141 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_pareto_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_pareto_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2165 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_pareto_P = \&PDL::gsl_cdf_pareto_P;
#line 2171 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_pareto_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_pareto_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2195 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_pareto_Pinv = \&PDL::gsl_cdf_pareto_Pinv;
#line 2201 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_pareto_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_pareto_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2225 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_pareto_Q = \&PDL::gsl_cdf_pareto_Q;
#line 2231 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_pareto_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_pareto_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2255 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_pareto_Qinv = \&PDL::gsl_cdf_pareto_Qinv;
#line 2261 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Pascal Distribution (gsl_cdf_pascal_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the Pascal distribution with parameters I<p> and I<n>.

=cut
#line 2272 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_pascal_P

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref



=for bad

gsl_cdf_pascal_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2296 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_pascal_P = \&PDL::gsl_cdf_pascal_P;
#line 2302 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_pascal_Q

=for sig

  Signature: (ushort k(); double p(); ushort n(); double [o]out())

=for ref



=for bad

gsl_cdf_pascal_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2326 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_pascal_Q = \&PDL::gsl_cdf_pascal_Q;
#line 2332 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Poisson Distribution (gsl_cdf_poisson_*)

These functions compute the cumulative distribution functions P(k), Q(k) for the Poisson distribution with parameter I<mu>.

=cut
#line 2343 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_poisson_P

=for sig

  Signature: (ushort k(); double mu(); double [o]out())

=for ref



=for bad

gsl_cdf_poisson_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2367 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_poisson_P = \&PDL::gsl_cdf_poisson_P;
#line 2373 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_poisson_Q

=for sig

  Signature: (ushort k(); double mu(); double [o]out())

=for ref



=for bad

gsl_cdf_poisson_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2397 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_poisson_Q = \&PDL::gsl_cdf_poisson_Q;
#line 2403 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Rayleigh Distribution (gsl_cdf_rayleigh_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Rayleigh distribution with scale parameter I<sigma>.

=cut
#line 2414 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_rayleigh_P

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_rayleigh_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2438 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_rayleigh_P = \&PDL::gsl_cdf_rayleigh_P;
#line 2444 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_rayleigh_Pinv

=for sig

  Signature: (double p(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_rayleigh_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2468 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_rayleigh_Pinv = \&PDL::gsl_cdf_rayleigh_Pinv;
#line 2474 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_rayleigh_Q

=for sig

  Signature: (double x(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_rayleigh_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2498 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_rayleigh_Q = \&PDL::gsl_cdf_rayleigh_Q;
#line 2504 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_rayleigh_Qinv

=for sig

  Signature: (double q(); double sigma(); double [o]out())

=for ref



=for bad

gsl_cdf_rayleigh_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2528 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_rayleigh_Qinv = \&PDL::gsl_cdf_rayleigh_Qinv;
#line 2534 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The t-distribution (gsl_cdf_tdist_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the t-distribution with I<nu> degrees of freedom.

=cut
#line 2545 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_tdist_P

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_tdist_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2569 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_tdist_P = \&PDL::gsl_cdf_tdist_P;
#line 2575 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_tdist_Pinv

=for sig

  Signature: (double p(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_tdist_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2599 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_tdist_Pinv = \&PDL::gsl_cdf_tdist_Pinv;
#line 2605 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_tdist_Q

=for sig

  Signature: (double x(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_tdist_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2629 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_tdist_Q = \&PDL::gsl_cdf_tdist_Q;
#line 2635 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_tdist_Qinv

=for sig

  Signature: (double q(); double nu(); double [o]out())

=for ref



=for bad

gsl_cdf_tdist_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2659 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_tdist_Qinv = \&PDL::gsl_cdf_tdist_Qinv;
#line 2665 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Unit Gaussian Distribution (gsl_cdf_ugaussian_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the unit Gaussian distribution.

=cut
#line 2676 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_ugaussian_P

=for sig

  Signature: (double x(); double [o]out())

=for ref



=for bad

gsl_cdf_ugaussian_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2700 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_ugaussian_P = \&PDL::gsl_cdf_ugaussian_P;
#line 2706 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_ugaussian_Pinv

=for sig

  Signature: (double p(); double [o]out())

=for ref



=for bad

gsl_cdf_ugaussian_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2730 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_ugaussian_Pinv = \&PDL::gsl_cdf_ugaussian_Pinv;
#line 2736 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_ugaussian_Q

=for sig

  Signature: (double x(); double [o]out())

=for ref



=for bad

gsl_cdf_ugaussian_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2760 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_ugaussian_Q = \&PDL::gsl_cdf_ugaussian_Q;
#line 2766 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_ugaussian_Qinv

=for sig

  Signature: (double q(); double [o]out())

=for ref



=for bad

gsl_cdf_ugaussian_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2790 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_ugaussian_Qinv = \&PDL::gsl_cdf_ugaussian_Qinv;
#line 2796 "CDF.pm"



#line 145 "gsl_cdf.pd"

=head2 The Weibull Distribution (gsl_cdf_weibull_*)

These functions compute the cumulative distribution functions P(x), Q(x) and their inverses for the Weibull distribution with scale I<a> and exponent I<b>.

=cut
#line 2807 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_weibull_P

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_weibull_P processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2831 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_weibull_P = \&PDL::gsl_cdf_weibull_P;
#line 2837 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_weibull_Pinv

=for sig

  Signature: (double p(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_weibull_Pinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2861 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_weibull_Pinv = \&PDL::gsl_cdf_weibull_Pinv;
#line 2867 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_weibull_Q

=for sig

  Signature: (double x(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_weibull_Q processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2891 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_weibull_Q = \&PDL::gsl_cdf_weibull_Q;
#line 2897 "CDF.pm"



#line 1059 "../../../blib/lib/PDL/PP.pm"


=head2 gsl_cdf_weibull_Qinv

=for sig

  Signature: (double q(); double a(); double b(); double [o]out())

=for ref



=for bad

gsl_cdf_weibull_Qinv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2921 "CDF.pm"



#line 1061 "../../../blib/lib/PDL/PP.pm"
*gsl_cdf_weibull_Qinv = \&PDL::gsl_cdf_weibull_Qinv;
#line 2927 "CDF.pm"





#line 195 "gsl_cdf.pd"

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

The GSL CDF module was written by J. Stover.

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 2944 "CDF.pm"




# Exit with OK status

1;
