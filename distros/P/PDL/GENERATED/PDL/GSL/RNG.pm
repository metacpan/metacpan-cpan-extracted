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

=cut
#line 66 "RNG.pm"


=head1 FUNCTIONS

=cut





#line 50 "gsl_random.pd"

=head2 new

=for ref

The new method initializes a new instance of the RNG.

The available RNGs are:

=over

=item coveyou

=item cmrg

=item fishman18

=item fishman20

=item fishman2x

=item gfsr4

=item knuthran

=item knuthran2

=item knuthran2002

=item lecuyer21

=item minstd

=item mrg

=item mt19937

=item mt19937_1999

=item mt19937_1998

=item r250

=item ran0

=item ran1

=item ran2

=item ran3

=item rand

=item rand48

=item random128_bsd

=item random128_glibc2

=item random128_libc5

=item random256_bsd

=item random256_glibc2

=item random256_libc5

=item random32_bsd

=item random32_glibc2

=item random32_libc5

=item random64_bsd

=item random64_glibc2

=item random64_libc5

=item random8_bsd

=item random8_glibc2

=item random8_libc5

=item random_bsd

=item random_glibc2

=item random_libc5

=item randu

=item ranf

=item ranlux

=item ranlux389

=item ranlxd1

=item ranlxd2

=item ranlxs0

=item ranlxs1

=item ranlxs2

=item ranmar

=item slatec

=item taus

=item taus2

=item taus113

=item transputer

=item tt800

=item uni

=item uni32

=item vax

=item waterman14

=item zuf

=item default

=back

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

=cut
#line 395 "RNG.pm"


=head2 get_uniform

=for sig

  Signature: ([o]a(); IV rng)

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

=for bad

get_uniform does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub get_uniform {
my ($obj,@var) = @_;if (ref($var[0]) eq 'PDL') {
    _get_uniform_int($var[0],$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    _get_uniform_int($p,$$obj);
    return $p;
}
}



*get_uniform = \&PDL::GSL::RNG::get_uniform;






=head2 get_uniform_pos

=for sig

  Signature: ([o]a(); IV rng)

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

=for bad

get_uniform_pos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub get_uniform_pos {
my ($obj,@var) = @_;if (ref($var[0]) eq 'PDL') {
    _get_uniform_pos_int($var[0],$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    _get_uniform_pos_int($p,$$obj);
    return $p;
}
}



*get_uniform_pos = \&PDL::GSL::RNG::get_uniform_pos;






=head2 get

=for sig

  Signature: ([o]a(); IV rng)

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

=for bad

get does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub get {
my ($obj,@var) = @_;if (ref($var[0]) eq 'PDL') {
    _get_int($var[0],$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    _get_int($p,$$obj);
    return $p;
}
}



*get = \&PDL::GSL::RNG::get;






=head2 get_int

=for sig

  Signature: ([o]a(); int n; IV rng)

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

=for bad

get_int does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub get_int {
my ($obj,$n,@var) = @_;if (!($n>0)) {barf("first parameter must be an int >0")};if (ref($var[0]) eq 'PDL') {
    _get_int_int($var[0],$n,$$obj);
    return $var[0];
}
else {
    my $p;

    $p = zeroes @var;
    _get_int_int($p,$n,$$obj);
    return $p;
}
}



*get_int = \&PDL::GSL::RNG::get_int;






=head2 ran_gaussian

=for sig

  Signature: ([o]output(); double sigma; IV rng)

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

=for bad

ran_gaussian does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gaussian {
my ($obj,$sigma,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_gaussian_int($var[0],$sigma,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_gaussian_int($p,$sigma,$$obj);
    return $p;
}
}



*ran_gaussian = \&PDL::GSL::RNG::ran_gaussian;






=head2 ran_gaussian_var

=for sig

  Signature: (sigma();[o]output(); IV rng)

=for ref

Similar to L</ran_gaussian> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gaussian_var($sigma_ndarray);

=for bad

ran_gaussian_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gaussian_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_gaussian_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_gaussian_var = \&PDL::GSL::RNG::ran_gaussian_var;






=head2 ran_ugaussian_tail

=for sig

  Signature: ([o]output(); double tail; IV rng)

=for ref

Fills output ndarray with random variates from the upper tail of a Gaussian distribution with C<standard deviation = 1> (AKA unit Gaussian distribution).

Usage:

=for usage

 $ndarray = $rng->ran_ugaussian_tail($tail,[list of integers = output ndarray dims]);
 $rng->ran_ugaussian_tail($tail, $output_ndarray);

Example:

=for example

  $o = $rng->ran_ugaussian_tail($tail,10,10);
  $rng->ran_ugaussian_tail($tail,$o);

=for bad

ran_ugaussian_tail does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_ugaussian_tail {
my ($obj,$tail,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_ugaussian_tail_int($var[0],$tail,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_ugaussian_tail_int($p,$tail,$$obj);
    return $p;
}
}



*ran_ugaussian_tail = \&PDL::GSL::RNG::ran_ugaussian_tail;






=head2 ran_ugaussian_tail_var

=for sig

  Signature: (tail();[o]output(); IV rng)

=for ref

Similar to L</ran_ugaussian_tail> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_ugaussian_tail_var($tail_ndarray);

=for bad

ran_ugaussian_tail_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_ugaussian_tail_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_ugaussian_tail_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_ugaussian_tail_var = \&PDL::GSL::RNG::ran_ugaussian_tail_var;






=head2 ran_exponential

=for sig

  Signature: ([o]output(); double mu; IV rng)

=for ref

Fills output ndarray with random variates from the exponential distribution with mean C<$mu>.

Usage:

=for usage

 $ndarray = $rng->ran_exponential($mu,[list of integers = output ndarray dims]);
 $rng->ran_exponential($mu, $output_ndarray);

Example:

=for example

  $o = $rng->ran_exponential($mu,10,10);
  $rng->ran_exponential($mu,$o);

=for bad

ran_exponential does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_exponential {
my ($obj,$mu,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_exponential_int($var[0],$mu,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_exponential_int($p,$mu,$$obj);
    return $p;
}
}



*ran_exponential = \&PDL::GSL::RNG::ran_exponential;






=head2 ran_exponential_var

=for sig

  Signature: (mu();[o]output(); IV rng)

=for ref

Similar to L</ran_exponential> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_exponential_var($mu_ndarray);

=for bad

ran_exponential_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_exponential_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_exponential_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_exponential_var = \&PDL::GSL::RNG::ran_exponential_var;






=head2 ran_laplace

=for sig

  Signature: ([o]output(); double pa; IV rng)

=for ref

Fills output ndarray with random variates from the Laplace distribution with width C<$pa>.

Usage:

=for usage

 $ndarray = $rng->ran_laplace($pa,[list of integers = output ndarray dims]);
 $rng->ran_laplace($pa, $output_ndarray);

Example:

=for example

  $o = $rng->ran_laplace($pa,10,10);
  $rng->ran_laplace($pa,$o);

=for bad

ran_laplace does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_laplace {
my ($obj,$pa,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_laplace_int($var[0],$pa,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_laplace_int($p,$pa,$$obj);
    return $p;
}
}



*ran_laplace = \&PDL::GSL::RNG::ran_laplace;






=head2 ran_laplace_var

=for sig

  Signature: (pa();[o]output(); IV rng)

=for ref

Similar to L</ran_laplace> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_laplace_var($pa_ndarray);

=for bad

ran_laplace_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_laplace_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_laplace_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_laplace_var = \&PDL::GSL::RNG::ran_laplace_var;






=head2 ran_exppow

=for sig

  Signature: ([o]output(); double pa; double pb; IV rng)

=for ref

Fills output ndarray with random variates from the exponential power distribution with scale parameter C<$pa> and exponent C<$pb>.

Usage:

=for usage

 $ndarray = $rng->ran_exppow($pa, $pb,[list of integers = output ndarray dims]);
 $rng->ran_exppow($pa, $pb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_exppow($pa, $pb,10,10);
  $rng->ran_exppow($pa, $pb,$o);

=for bad

ran_exppow does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_exppow {
my ($obj,$pa,$pb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_exppow_int($var[0],$pa,$pb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_exppow_int($p,$pa,$pb,$$obj);
    return $p;
}
}



*ran_exppow = \&PDL::GSL::RNG::ran_exppow;






=head2 ran_exppow_var

=for sig

  Signature: (pa();pb();[o]output(); IV rng)

=for ref

Similar to L</ran_exppow> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_exppow_var($pa_ndarray,$pb_ndarray);

=for bad

ran_exppow_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_exppow_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_exppow_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_exppow_var = \&PDL::GSL::RNG::ran_exppow_var;






=head2 ran_cauchy

=for sig

  Signature: ([o]output(); double pa; IV rng)

=for ref

Fills output ndarray with random variates from the Cauchy distribution with scale parameter C<$pa>.

Usage:

=for usage

 $ndarray = $rng->ran_cauchy($pa,[list of integers = output ndarray dims]);
 $rng->ran_cauchy($pa, $output_ndarray);

Example:

=for example

  $o = $rng->ran_cauchy($pa,10,10);
  $rng->ran_cauchy($pa,$o);

=for bad

ran_cauchy does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_cauchy {
my ($obj,$pa,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_cauchy_int($var[0],$pa,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_cauchy_int($p,$pa,$$obj);
    return $p;
}
}



*ran_cauchy = \&PDL::GSL::RNG::ran_cauchy;






=head2 ran_cauchy_var

=for sig

  Signature: (pa();[o]output(); IV rng)

=for ref

Similar to L</ran_cauchy> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_cauchy_var($pa_ndarray);

=for bad

ran_cauchy_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_cauchy_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_cauchy_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_cauchy_var = \&PDL::GSL::RNG::ran_cauchy_var;






=head2 ran_rayleigh

=for sig

  Signature: ([o]output(); double sigma; IV rng)

=for ref

Fills output ndarray with random variates from the Rayleigh distribution with scale parameter C<$sigma>.

Usage:

=for usage

 $ndarray = $rng->ran_rayleigh($sigma,[list of integers = output ndarray dims]);
 $rng->ran_rayleigh($sigma, $output_ndarray);

Example:

=for example

  $o = $rng->ran_rayleigh($sigma,10,10);
  $rng->ran_rayleigh($sigma,$o);

=for bad

ran_rayleigh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_rayleigh {
my ($obj,$sigma,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_rayleigh_int($var[0],$sigma,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_rayleigh_int($p,$sigma,$$obj);
    return $p;
}
}



*ran_rayleigh = \&PDL::GSL::RNG::ran_rayleigh;






=head2 ran_rayleigh_var

=for sig

  Signature: (sigma();[o]output(); IV rng)

=for ref

Similar to L</ran_rayleigh> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_rayleigh_var($sigma_ndarray);

=for bad

ran_rayleigh_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_rayleigh_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_rayleigh_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_rayleigh_var = \&PDL::GSL::RNG::ran_rayleigh_var;






=head2 ran_rayleigh_tail

=for sig

  Signature: ([o]output(); double x; double sigma; IV rng)

=for ref

Fills output ndarray with random variates from the tail of the Rayleigh distribution
with scale parameter C<$sigma> and a lower limit of C<$la>.

Usage:

=for usage

 $ndarray = $rng->ran_rayleigh_tail($x, $sigma,[list of integers = output ndarray dims]);
 $rng->ran_rayleigh_tail($x, $sigma, $output_ndarray);

Example:

=for example

  $o = $rng->ran_rayleigh_tail($x, $sigma,10,10);
  $rng->ran_rayleigh_tail($x, $sigma,$o);

=for bad

ran_rayleigh_tail does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_rayleigh_tail {
my ($obj,$x,$sigma,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_rayleigh_tail_int($var[0],$x,$sigma,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_rayleigh_tail_int($p,$x,$sigma,$$obj);
    return $p;
}
}



*ran_rayleigh_tail = \&PDL::GSL::RNG::ran_rayleigh_tail;






=head2 ran_rayleigh_tail_var

=for sig

  Signature: (x();sigma();[o]output(); IV rng)

=for ref

Similar to L</ran_rayleigh_tail> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_rayleigh_tail_var($x_ndarray,$sigma_ndarray);

=for bad

ran_rayleigh_tail_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_rayleigh_tail_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_rayleigh_tail_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_rayleigh_tail_var = \&PDL::GSL::RNG::ran_rayleigh_tail_var;






=head2 ran_levy

=for sig

  Signature: ([o]output(); double mu; double x; IV rng)

=for ref

Fills output ndarray with random variates from the Levy symmetric stable distribution with scale C<$c> and exponent C<$alpha>.

Usage:

=for usage

 $ndarray = $rng->ran_levy($mu, $x,[list of integers = output ndarray dims]);
 $rng->ran_levy($mu, $x, $output_ndarray);

Example:

=for example

  $o = $rng->ran_levy($mu, $x,10,10);
  $rng->ran_levy($mu, $x,$o);

=for bad

ran_levy does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_levy {
my ($obj,$mu,$x,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_levy_int($var[0],$mu,$x,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_levy_int($p,$mu,$x,$$obj);
    return $p;
}
}



*ran_levy = \&PDL::GSL::RNG::ran_levy;






=head2 ran_levy_var

=for sig

  Signature: (mu();x();[o]output(); IV rng)

=for ref

Similar to L</ran_levy> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_levy_var($mu_ndarray,$x_ndarray);

=for bad

ran_levy_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_levy_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_levy_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_levy_var = \&PDL::GSL::RNG::ran_levy_var;






=head2 ran_gamma

=for sig

  Signature: ([o]output(); double pa; double pb; IV rng)

=for ref

Fills output ndarray with random variates from the gamma distribution.

Usage:

=for usage

 $ndarray = $rng->ran_gamma($pa, $pb,[list of integers = output ndarray dims]);
 $rng->ran_gamma($pa, $pb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_gamma($pa, $pb,10,10);
  $rng->ran_gamma($pa, $pb,$o);

=for bad

ran_gamma does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gamma {
my ($obj,$pa,$pb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_gamma_int($var[0],$pa,$pb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_gamma_int($p,$pa,$pb,$$obj);
    return $p;
}
}



*ran_gamma = \&PDL::GSL::RNG::ran_gamma;






=head2 ran_gamma_var

=for sig

  Signature: (pa();pb();[o]output(); IV rng)

=for ref

Similar to L</ran_gamma> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gamma_var($pa_ndarray,$pb_ndarray);

=for bad

ran_gamma_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gamma_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_gamma_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_gamma_var = \&PDL::GSL::RNG::ran_gamma_var;






=head2 ran_flat

=for sig

  Signature: ([o]output(); double la; double lb; IV rng)

=for ref

Fills output ndarray with random variates from the flat (uniform) distribution from C<$la> to C<$lb>.

Usage:

=for usage

 $ndarray = $rng->ran_flat($la, $lb,[list of integers = output ndarray dims]);
 $rng->ran_flat($la, $lb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_flat($la, $lb,10,10);
  $rng->ran_flat($la, $lb,$o);

=for bad

ran_flat does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_flat {
my ($obj,$la,$lb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_flat_int($var[0],$la,$lb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_flat_int($p,$la,$lb,$$obj);
    return $p;
}
}



*ran_flat = \&PDL::GSL::RNG::ran_flat;






=head2 ran_flat_var

=for sig

  Signature: (la();lb();[o]output(); IV rng)

=for ref

Similar to L</ran_flat> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_flat_var($la_ndarray,$lb_ndarray);

=for bad

ran_flat_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_flat_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_flat_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_flat_var = \&PDL::GSL::RNG::ran_flat_var;






=head2 ran_lognormal

=for sig

  Signature: ([o]output(); double mu; double sigma; IV rng)

=for ref

Fills output ndarray with random variates from the lognormal distribution with parameters C<$mu> (location) and C<$sigma> (scale).

Usage:

=for usage

 $ndarray = $rng->ran_lognormal($mu, $sigma,[list of integers = output ndarray dims]);
 $rng->ran_lognormal($mu, $sigma, $output_ndarray);

Example:

=for example

  $o = $rng->ran_lognormal($mu, $sigma,10,10);
  $rng->ran_lognormal($mu, $sigma,$o);

=for bad

ran_lognormal does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_lognormal {
my ($obj,$mu,$sigma,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_lognormal_int($var[0],$mu,$sigma,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_lognormal_int($p,$mu,$sigma,$$obj);
    return $p;
}
}



*ran_lognormal = \&PDL::GSL::RNG::ran_lognormal;






=head2 ran_lognormal_var

=for sig

  Signature: (mu();sigma();[o]output(); IV rng)

=for ref

Similar to L</ran_lognormal> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_lognormal_var($mu_ndarray,$sigma_ndarray);

=for bad

ran_lognormal_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_lognormal_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_lognormal_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_lognormal_var = \&PDL::GSL::RNG::ran_lognormal_var;






=head2 ran_chisq

=for sig

  Signature: ([o]output(); double nu; IV rng)

=for ref

Fills output ndarray with random variates from the chi-squared distribution with C<$nu> degrees of freedom.

Usage:

=for usage

 $ndarray = $rng->ran_chisq($nu,[list of integers = output ndarray dims]);
 $rng->ran_chisq($nu, $output_ndarray);

Example:

=for example

  $o = $rng->ran_chisq($nu,10,10);
  $rng->ran_chisq($nu,$o);

=for bad

ran_chisq does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_chisq {
my ($obj,$nu,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_chisq_int($var[0],$nu,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_chisq_int($p,$nu,$$obj);
    return $p;
}
}



*ran_chisq = \&PDL::GSL::RNG::ran_chisq;






=head2 ran_chisq_var

=for sig

  Signature: (nu();[o]output(); IV rng)

=for ref

Similar to L</ran_chisq> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_chisq_var($nu_ndarray);

=for bad

ran_chisq_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_chisq_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_chisq_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_chisq_var = \&PDL::GSL::RNG::ran_chisq_var;






=head2 ran_fdist

=for sig

  Signature: ([o]output(); double nu1; double nu2; IV rng)

=for ref

Fills output ndarray with random variates from the F-distribution with degrees of freedom C<$nu1> and C<$nu2>.

Usage:

=for usage

 $ndarray = $rng->ran_fdist($nu1, $nu2,[list of integers = output ndarray dims]);
 $rng->ran_fdist($nu1, $nu2, $output_ndarray);

Example:

=for example

  $o = $rng->ran_fdist($nu1, $nu2,10,10);
  $rng->ran_fdist($nu1, $nu2,$o);

=for bad

ran_fdist does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_fdist {
my ($obj,$nu1,$nu2,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_fdist_int($var[0],$nu1,$nu2,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_fdist_int($p,$nu1,$nu2,$$obj);
    return $p;
}
}



*ran_fdist = \&PDL::GSL::RNG::ran_fdist;






=head2 ran_fdist_var

=for sig

  Signature: (nu1();nu2();[o]output(); IV rng)

=for ref

Similar to L</ran_fdist> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_fdist_var($nu1_ndarray,$nu2_ndarray);

=for bad

ran_fdist_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_fdist_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_fdist_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_fdist_var = \&PDL::GSL::RNG::ran_fdist_var;






=head2 ran_tdist

=for sig

  Signature: ([o]output(); double nu; IV rng)

=for ref

Fills output ndarray with random variates from the t-distribution (AKA Student's
t-distribution) with C<$nu> degrees of freedom.

Usage:

=for usage

 $ndarray = $rng->ran_tdist($nu,[list of integers = output ndarray dims]);
 $rng->ran_tdist($nu, $output_ndarray);

Example:

=for example

  $o = $rng->ran_tdist($nu,10,10);
  $rng->ran_tdist($nu,$o);

=for bad

ran_tdist does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_tdist {
my ($obj,$nu,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_tdist_int($var[0],$nu,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_tdist_int($p,$nu,$$obj);
    return $p;
}
}



*ran_tdist = \&PDL::GSL::RNG::ran_tdist;






=head2 ran_tdist_var

=for sig

  Signature: (nu();[o]output(); IV rng)

=for ref

Similar to L</ran_tdist> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_tdist_var($nu_ndarray);

=for bad

ran_tdist_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_tdist_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_tdist_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_tdist_var = \&PDL::GSL::RNG::ran_tdist_var;






=head2 ran_beta

=for sig

  Signature: ([o]output(); double pa; double pb; IV rng)

=for ref

Fills output ndarray with random variates from the beta distribution with parameters C<$pa> and C<$pb>.

Usage:

=for usage

 $ndarray = $rng->ran_beta($pa, $pb,[list of integers = output ndarray dims]);
 $rng->ran_beta($pa, $pb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_beta($pa, $pb,10,10);
  $rng->ran_beta($pa, $pb,$o);

=for bad

ran_beta does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_beta {
my ($obj,$pa,$pb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_beta_int($var[0],$pa,$pb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_beta_int($p,$pa,$pb,$$obj);
    return $p;
}
}



*ran_beta = \&PDL::GSL::RNG::ran_beta;






=head2 ran_beta_var

=for sig

  Signature: (pa();pb();[o]output(); IV rng)

=for ref

Similar to L</ran_beta> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_beta_var($pa_ndarray,$pb_ndarray);

=for bad

ran_beta_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_beta_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_beta_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_beta_var = \&PDL::GSL::RNG::ran_beta_var;






=head2 ran_logistic

=for sig

  Signature: ([o]output(); double m; IV rng)

=for ref

Fills output ndarray with random random variates from the logistic distribution.

Usage:

=for usage

 $ndarray = $rng->ran_logistic($m,[list of integers = output ndarray dims]);
 $rng->ran_logistic($m, $output_ndarray);

Example:

=for example

  $o = $rng->ran_logistic($m,10,10);
  $rng->ran_logistic($m,$o);

=for bad

ran_logistic does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_logistic {
my ($obj,$m,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_logistic_int($var[0],$m,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_logistic_int($p,$m,$$obj);
    return $p;
}
}



*ran_logistic = \&PDL::GSL::RNG::ran_logistic;






=head2 ran_logistic_var

=for sig

  Signature: (m();[o]output(); IV rng)

=for ref

Similar to L</ran_logistic> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_logistic_var($m_ndarray);

=for bad

ran_logistic_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_logistic_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_logistic_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_logistic_var = \&PDL::GSL::RNG::ran_logistic_var;






=head2 ran_pareto

=for sig

  Signature: ([o]output(); double pa; double lb; IV rng)

=for ref

Fills output ndarray with random variates from the Pareto distribution of order C<$pa> and scale C<$lb>.

Usage:

=for usage

 $ndarray = $rng->ran_pareto($pa, $lb,[list of integers = output ndarray dims]);
 $rng->ran_pareto($pa, $lb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_pareto($pa, $lb,10,10);
  $rng->ran_pareto($pa, $lb,$o);

=for bad

ran_pareto does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_pareto {
my ($obj,$pa,$lb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_pareto_int($var[0],$pa,$lb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_pareto_int($p,$pa,$lb,$$obj);
    return $p;
}
}



*ran_pareto = \&PDL::GSL::RNG::ran_pareto;






=head2 ran_pareto_var

=for sig

  Signature: (pa();lb();[o]output(); IV rng)

=for ref

Similar to L</ran_pareto> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_pareto_var($pa_ndarray,$lb_ndarray);

=for bad

ran_pareto_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_pareto_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_pareto_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_pareto_var = \&PDL::GSL::RNG::ran_pareto_var;






=head2 ran_weibull

=for sig

  Signature: ([o]output(); double pa; double pb; IV rng)

=for ref

Fills output ndarray with random variates from the Weibull distribution with scale C<$pa> and exponent C<$pb>. (Some literature uses C<lambda> for C<$pa> and C<k> for C<$pb>.)

Usage:

=for usage

 $ndarray = $rng->ran_weibull($pa, $pb,[list of integers = output ndarray dims]);
 $rng->ran_weibull($pa, $pb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_weibull($pa, $pb,10,10);
  $rng->ran_weibull($pa, $pb,$o);

=for bad

ran_weibull does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_weibull {
my ($obj,$pa,$pb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_weibull_int($var[0],$pa,$pb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_weibull_int($p,$pa,$pb,$$obj);
    return $p;
}
}



*ran_weibull = \&PDL::GSL::RNG::ran_weibull;






=head2 ran_weibull_var

=for sig

  Signature: (pa();pb();[o]output(); IV rng)

=for ref

Similar to L</ran_weibull> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_weibull_var($pa_ndarray,$pb_ndarray);

=for bad

ran_weibull_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_weibull_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_weibull_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_weibull_var = \&PDL::GSL::RNG::ran_weibull_var;






=head2 ran_gumbel1

=for sig

  Signature: ([o]output(); double pa; double pb; IV rng)

=for ref

Fills output ndarray with random variates from the Type-1 Gumbel distribution.

Usage:

=for usage

 $ndarray = $rng->ran_gumbel1($pa, $pb,[list of integers = output ndarray dims]);
 $rng->ran_gumbel1($pa, $pb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_gumbel1($pa, $pb,10,10);
  $rng->ran_gumbel1($pa, $pb,$o);

=for bad

ran_gumbel1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gumbel1 {
my ($obj,$pa,$pb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_gumbel1_int($var[0],$pa,$pb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_gumbel1_int($p,$pa,$pb,$$obj);
    return $p;
}
}



*ran_gumbel1 = \&PDL::GSL::RNG::ran_gumbel1;






=head2 ran_gumbel1_var

=for sig

  Signature: (pa();pb();[o]output(); IV rng)

=for ref

Similar to L</ran_gumbel1> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gumbel1_var($pa_ndarray,$pb_ndarray);

=for bad

ran_gumbel1_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gumbel1_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_gumbel1_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_gumbel1_var = \&PDL::GSL::RNG::ran_gumbel1_var;






=head2 ran_gumbel2

=for sig

  Signature: ([o]output(); double pa; double pb; IV rng)

=for ref

Fills output ndarray with random variates from the Type-2 Gumbel distribution.

Usage:

=for usage

 $ndarray = $rng->ran_gumbel2($pa, $pb,[list of integers = output ndarray dims]);
 $rng->ran_gumbel2($pa, $pb, $output_ndarray);

Example:

=for example

  $o = $rng->ran_gumbel2($pa, $pb,10,10);
  $rng->ran_gumbel2($pa, $pb,$o);

=for bad

ran_gumbel2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gumbel2 {
my ($obj,$pa,$pb,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_gumbel2_int($var[0],$pa,$pb,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_gumbel2_int($p,$pa,$pb,$$obj);
    return $p;
}
}



*ran_gumbel2 = \&PDL::GSL::RNG::ran_gumbel2;






=head2 ran_gumbel2_var

=for sig

  Signature: (pa();pb();[o]output(); IV rng)

=for ref

Similar to L</ran_gumbel2> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_gumbel2_var($pa_ndarray,$pb_ndarray);

=for bad

ran_gumbel2_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_gumbel2_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_gumbel2_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_gumbel2_var = \&PDL::GSL::RNG::ran_gumbel2_var;






=head2 ran_poisson

=for sig

  Signature: ([o]output(); double mu; IV rng)

=for ref

Fills output ndarray with random integer values from the Poisson distribution with mean C<$mu>.

Usage:

=for usage

 $ndarray = $rng->ran_poisson($mu,[list of integers = output ndarray dims]);
 $rng->ran_poisson($mu, $output_ndarray);

Example:

=for example

  $o = $rng->ran_poisson($mu,10,10);
  $rng->ran_poisson($mu,$o);

=for bad

ran_poisson does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_poisson {
my ($obj,$mu,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_poisson_int($var[0],$mu,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_poisson_int($p,$mu,$$obj);
    return $p;
}
}



*ran_poisson = \&PDL::GSL::RNG::ran_poisson;






=head2 ran_poisson_var

=for sig

  Signature: (mu();[o]output(); IV rng)

=for ref

Similar to L</ran_poisson> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_poisson_var($mu_ndarray);

=for bad

ran_poisson_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_poisson_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_poisson_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_poisson_var = \&PDL::GSL::RNG::ran_poisson_var;






=head2 ran_bernoulli

=for sig

  Signature: ([o]output(); double p; IV rng)

=for ref

Fills output ndarray with random values 0 or 1, the result of a Bernoulli trial with probability C<$p>.

Usage:

=for usage

 $ndarray = $rng->ran_bernoulli($p,[list of integers = output ndarray dims]);
 $rng->ran_bernoulli($p, $output_ndarray);

Example:

=for example

  $o = $rng->ran_bernoulli($p,10,10);
  $rng->ran_bernoulli($p,$o);

=for bad

ran_bernoulli does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_bernoulli {
my ($obj,$p,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_bernoulli_int($var[0],$p,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_bernoulli_int($p,$p,$$obj);
    return $p;
}
}



*ran_bernoulli = \&PDL::GSL::RNG::ran_bernoulli;






=head2 ran_bernoulli_var

=for sig

  Signature: (p();[o]output(); IV rng)

=for ref

Similar to L</ran_bernoulli> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_bernoulli_var($p_ndarray);

=for bad

ran_bernoulli_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_bernoulli_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_bernoulli_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_bernoulli_var = \&PDL::GSL::RNG::ran_bernoulli_var;






=head2 ran_binomial

=for sig

  Signature: ([o]output(); double p; double n; IV rng)

=for ref

Fills output ndarray with random integer values from the binomial distribution, the number of successes in C<$n> independent trials with probability C<$p>.

Usage:

=for usage

 $ndarray = $rng->ran_binomial($p, $n,[list of integers = output ndarray dims]);
 $rng->ran_binomial($p, $n, $output_ndarray);

Example:

=for example

  $o = $rng->ran_binomial($p, $n,10,10);
  $rng->ran_binomial($p, $n,$o);

=for bad

ran_binomial does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_binomial {
my ($obj,$p,$n,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_binomial_int($var[0],$p,$n,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_binomial_int($p,$p,$n,$$obj);
    return $p;
}
}



*ran_binomial = \&PDL::GSL::RNG::ran_binomial;






=head2 ran_binomial_var

=for sig

  Signature: (p();n();[o]output(); IV rng)

=for ref

Similar to L</ran_binomial> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_binomial_var($p_ndarray,$n_ndarray);

=for bad

ran_binomial_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_binomial_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_binomial_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_binomial_var = \&PDL::GSL::RNG::ran_binomial_var;






=head2 ran_negative_binomial

=for sig

  Signature: ([o]output(); double p; double n; IV rng)

=for ref

Fills output ndarray with random integer values from the negative binomial
distribution, the number of failures occurring before C<$n> successes in
independent trials with probability C<$p> of success. Note that C<$n> is
not required to be an integer.

Usage:

=for usage

 $ndarray = $rng->ran_negative_binomial($p, $n,[list of integers = output ndarray dims]);
 $rng->ran_negative_binomial($p, $n, $output_ndarray);

Example:

=for example

  $o = $rng->ran_negative_binomial($p, $n,10,10);
  $rng->ran_negative_binomial($p, $n,$o);

=for bad

ran_negative_binomial does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_negative_binomial {
my ($obj,$p,$n,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_negative_binomial_int($var[0],$p,$n,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_negative_binomial_int($p,$p,$n,$$obj);
    return $p;
}
}



*ran_negative_binomial = \&PDL::GSL::RNG::ran_negative_binomial;






=head2 ran_negative_binomial_var

=for sig

  Signature: (p();n();[o]output(); IV rng)

=for ref

Similar to L</ran_negative_binomial> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_negative_binomial_var($p_ndarray,$n_ndarray);

=for bad

ran_negative_binomial_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_negative_binomial_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_negative_binomial_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_negative_binomial_var = \&PDL::GSL::RNG::ran_negative_binomial_var;






=head2 ran_pascal

=for sig

  Signature: ([o]output(); double p; double n; IV rng)

=for ref

Fills output ndarray with random integer values from the Pascal distribution.
The Pascal distribution is simply a negative binomial distribution
(see L</ran_negative_binomial>) with an integer value of C<$n>.

Usage:

=for usage

 $ndarray = $rng->ran_pascal($p, $n,[list of integers = output ndarray dims]);
 $rng->ran_pascal($p, $n, $output_ndarray);

Example:

=for example

  $o = $rng->ran_pascal($p, $n,10,10);
  $rng->ran_pascal($p, $n,$o);

=for bad

ran_pascal does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_pascal {
my ($obj,$p,$n,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_pascal_int($var[0],$p,$n,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_pascal_int($p,$p,$n,$$obj);
    return $p;
}
}



*ran_pascal = \&PDL::GSL::RNG::ran_pascal;






=head2 ran_pascal_var

=for sig

  Signature: (p();n();[o]output(); IV rng)

=for ref

Similar to L</ran_pascal> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_pascal_var($p_ndarray,$n_ndarray);

=for bad

ran_pascal_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_pascal_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 2) {barf("Bad number of parameters!");}
    _ran_pascal_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_pascal_var = \&PDL::GSL::RNG::ran_pascal_var;






=head2 ran_geometric

=for sig

  Signature: ([o]output(); double p; IV rng)

=for ref

Fills output ndarray with random integer values from the geometric distribution, the number of independent trials with probability C<$p> until the first success.

Usage:

=for usage

 $ndarray = $rng->ran_geometric($p,[list of integers = output ndarray dims]);
 $rng->ran_geometric($p, $output_ndarray);

Example:

=for example

  $o = $rng->ran_geometric($p,10,10);
  $rng->ran_geometric($p,$o);

=for bad

ran_geometric does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_geometric {
my ($obj,$p,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_geometric_int($var[0],$p,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_geometric_int($p,$p,$$obj);
    return $p;
}
}



*ran_geometric = \&PDL::GSL::RNG::ran_geometric;






=head2 ran_geometric_var

=for sig

  Signature: (p();[o]output(); IV rng)

=for ref

Similar to L</ran_geometric> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_geometric_var($p_ndarray);

=for bad

ran_geometric_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_geometric_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_geometric_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_geometric_var = \&PDL::GSL::RNG::ran_geometric_var;






=head2 ran_hypergeometric

=for sig

  Signature: ([o]output(); double n1; double n2; double t; IV rng)

=for ref

Fills output ndarray with random integer values from the hypergeometric distribution.
If a population contains C<$n1> elements of type 1 and C<$n2> elements of
type 2 then the hypergeometric distribution gives the probability of obtaining
C<$x> elements of type 1 in C<$t> samples from the population without replacement.

Usage:

=for usage

 $ndarray = $rng->ran_hypergeometric($n1, $n2, $t,[list of integers = output ndarray dims]);
 $rng->ran_hypergeometric($n1, $n2, $t, $output_ndarray);

Example:

=for example

  $o = $rng->ran_hypergeometric($n1, $n2, $t,10,10);
  $rng->ran_hypergeometric($n1, $n2, $t,$o);

=for bad

ran_hypergeometric does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_hypergeometric {
my ($obj,$n1,$n2,$t,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_hypergeometric_int($var[0],$n1,$n2,$t,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_hypergeometric_int($p,$n1,$n2,$t,$$obj);
    return $p;
}
}



*ran_hypergeometric = \&PDL::GSL::RNG::ran_hypergeometric;






=head2 ran_hypergeometric_var

=for sig

  Signature: (n1();n2();t();[o]output(); IV rng)

=for ref

Similar to L</ran_hypergeometric> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_hypergeometric_var($n1_ndarray,$n2_ndarray,$t_ndarray);

=for bad

ran_hypergeometric_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_hypergeometric_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 3) {barf("Bad number of parameters!");}
    _ran_hypergeometric_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_hypergeometric_var = \&PDL::GSL::RNG::ran_hypergeometric_var;






=head2 ran_logarithmic

=for sig

  Signature: ([o]output(); double p; IV rng)

=for ref

Fills output ndarray with random integer values from the logarithmic distribution.

Usage:

=for usage

 $ndarray = $rng->ran_logarithmic($p,[list of integers = output ndarray dims]);
 $rng->ran_logarithmic($p, $output_ndarray);

Example:

=for example

  $o = $rng->ran_logarithmic($p,10,10);
  $rng->ran_logarithmic($p,$o);

=for bad

ran_logarithmic does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_logarithmic {
my ($obj,$p,@var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_logarithmic_int($var[0],$p,$$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_logarithmic_int($p,$p,$$obj);
    return $p;
}
}



*ran_logarithmic = \&PDL::GSL::RNG::ran_logarithmic;






=head2 ran_logarithmic_var

=for sig

  Signature: (p();[o]output(); IV rng)

=for ref

Similar to L</ran_logarithmic> except that it takes the distribution
parameters as an ndarray and returns an ndarray of equal dimensions.

Usage:

=for usage

   $ndarray = $rng->ran_logarithmic_var($p_ndarray);

=for bad

ran_logarithmic_var does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_logarithmic_var {
my ($obj,@var) = @_;
    if (scalar(@var) != 1) {barf("Bad number of parameters!");}
    _ran_logarithmic_var_int(@var,my $x=PDL->null,$$obj);
    return $x;
}



*ran_logarithmic_var = \&PDL::GSL::RNG::ran_logarithmic_var;






=head2 ran_additive_gaussian

=for sig

  Signature: ([o]x(); double sigma; IV rng)

=for ref

Add Gaussian noise of given sigma to an ndarray.

Usage:

=for usage

   $rng->ran_additive_gaussian($sigma,$ndarray);

Example:

=for example

   $rng->ran_additive_gaussian(1,$image);

=for bad

ran_additive_gaussian does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





       sub ran_additive_gaussian {
	 my ($obj,$sigma,$var) = @_;
	 barf("In additive gaussian mode you must specify an ndarray!")
	   if ref($var) ne 'PDL';
	 _ran_additive_gaussian_int($var,$sigma,$$obj);
	 return $var;
       }
       


*ran_additive_gaussian = \&PDL::GSL::RNG::ran_additive_gaussian;






=head2 ran_additive_poisson

=for sig

  Signature: ([o]x(); double sigma; IV rng)

=for ref

Add Poisson noise of given C<$mu> to a C<$ndarray>.

Usage:

=for usage

   $rng->ran_additive_poisson($mu,$ndarray);

Example:

=for example

   $rng->ran_additive_poisson(1,$image);

=for bad

ran_additive_poisson does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





       sub ran_additive_poisson {
	 my ($obj,$sigma,$var) = @_;
	 barf("In additive poisson mode you must specify an ndarray!")
	   if ref($var) ne 'PDL';
	 _ran_additive_poisson_int($var,$sigma,$$obj);
	 return $var;
       }
       


*ran_additive_poisson = \&PDL::GSL::RNG::ran_additive_poisson;






=head2 ran_feed_poisson

=for sig

  Signature: ([o]x(); IV rng)

=for ref

This method simulates shot noise, taking the values of ndarray as
values for C<$mu> to be fed in the poissonian RNG.

Usage:

=for usage

   $rng->ran_feed_poisson($ndarray);

Example:

=for example

   $rng->ran_feed_poisson($image);

=for bad

ran_feed_poisson does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





       sub ran_feed_poisson {
	 my ($obj,$var) = @_;
	 barf("In poisson mode you must specify an ndarray!")
	   if ref($var) ne 'PDL';
	 _ran_feed_poisson_int($var,$$obj);
	 return $var;
       }
       


*ran_feed_poisson = \&PDL::GSL::RNG::ran_feed_poisson;






=head2 ran_bivariate_gaussian

=for sig

  Signature: ([o]x(n); double sigma_x; double sigma_y; double rho; IV rng)

=for ref

Generates C<$n> bivariate gaussian random deviates.

Usage:

=for usage

   $ndarray = $rng->ran_bivariate_gaussian($sigma_x,$sigma_y,$rho,$n);

Example:

=for example

   $o = $rng->ran_bivariate_gaussian(1,2,0.5,1000);

=for bad

ran_bivariate_gaussian does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub ran_bivariate_gaussian {
 my ($obj,$sigma_x,$sigma_y,$rho,$n) = @_;
 barf("Not enough parameters for gaussian bivariate!") if $n<=0;
 my $p = zeroes(2,$n);
 _ran_bivariate_gaussian_int($p,$sigma_x,$sigma_y,$rho,$$obj);
 return $p;
}



*ran_bivariate_gaussian = \&PDL::GSL::RNG::ran_bivariate_gaussian;




*ran_dir_2d = \&PDL::GSL::RNG::ran_dir_2d;




*ran_dir_3d = \&PDL::GSL::RNG::ran_dir_3d;




*ran_dir_nd = \&PDL::GSL::RNG::ran_dir_nd;





#line 875 "gsl_random.pd"

       sub ran_dir {
	 my ($obj,$ndim,$n) = @_;
	 barf("Not enough parameters for random vectors!") if $n<=0;
	 my $p = zeroes($ndim,$n);
	 if ($ndim==2) { ran_dir_2d($p,$$obj); }
	 elsif ($ndim==3) { ran_dir_3d($p,$$obj); }
	 elsif ($ndim>=4 && $ndim<=100) { ran_dir_nd($p,$ndim,$$obj); }
	 else { barf("Bad number of dimensions!"); }
	 return $p;
       }
       
#line 3831 "RNG.pm"


=head2 ran_discrete

=for sig

  Signature: ([o]x(); IV rng_discrete; IV rng)

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

=for bad

ran_discrete does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub ran_discrete {
my ($obj, $rdt, @var) = @_;
if (ref($var[0]) eq 'PDL') {
    _ran_discrete_int($var[0], $$rdt, $$obj);
    return $var[0];
}
else {
    my $p;
    $p = zeroes @var;
    _ran_discrete_int($p, $$rdt, $$obj);
    return $p;
}
}



*ran_discrete = \&PDL::GSL::RNG::ran_discrete;





#line 932 "gsl_random.pd"

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

#line 946 "gsl_random.pd"
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
#line 3919 "RNG.pm"


=head2 ran_ver

=for sig

  Signature: ([o]x(n); double x0; double r;int ns => n; IV rng)

=for ref

Returns an ndarray with C<$n> values generated by the Verhulst map from C<$x0> and
parameter C<$r>.

Usage:

=for usage

   $rng->ran_ver($x0, $r, $n);

=for bad

ran_ver does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





       sub ran_ver {
	 my ($obj,$x0,$r,$n) = @_;
	 barf("Not enough parameters for ran_ver!") if $n<=0;
	 my $p = zeroes($n);
	 _ran_ver_int($p,$x0,$r,$n,$$obj);
	 return $p;
       }
       


*ran_ver = \&PDL::GSL::RNG::ran_ver;






=head2 ran_caos

=for sig

  Signature: ([o]x(n); double m; int ns => n; IV rng)

=for ref

Returns values from Verhuls map with C<$r=4.0> and randomly chosen
C<$x0>. The values are scaled by C<$m>.

Usage:

=for usage

   $rng->ran_caos($m,$n);

=for bad

ran_caos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





       sub ran_caos {
	 my ($obj,$m,$n) = @_;
	 barf("Not enough parameters for ran_caos!") if $n<=0;
	 my $p = zeroes($n);
	 _ran_caos_int($p,$m,$n,$$obj);
	 return $p;
       }
       


*ran_caos = \&PDL::GSL::RNG::ran_caos;







#line 369 "gsl_random.pd"

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
#line 4039 "RNG.pm"

# Exit with OK status

1;
