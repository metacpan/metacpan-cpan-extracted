#
# GENERATED WITH PDL::PP from lib/PDL/GSL/SF.pd! Don't modify!
#
package PDL::GSL::SF;

our @EXPORT_OK = qw(gsl_sf_airy_Ai gsl_sf_airy_Bi gsl_sf_airy_Ai_scaled gsl_sf_airy_Bi_scaled gsl_sf_airy_Ai_deriv gsl_sf_airy_Bi_deriv gsl_sf_airy_Ai_deriv_scaled gsl_sf_airy_Bi_deriv_scaled gsl_sf_bessel_Jn gsl_sf_bessel_Jn_array gsl_sf_bessel_Yn gsl_sf_bessel_Yn_array gsl_sf_bessel_In gsl_sf_bessel_I_array gsl_sf_bessel_In_scaled gsl_sf_bessel_In_scaled_array gsl_sf_bessel_Kn gsl_sf_bessel_K_array gsl_sf_bessel_Kn_scaled gsl_sf_bessel_Kn_scaled_array gsl_sf_bessel_jl gsl_sf_bessel_jl_array gsl_sf_bessel_yl gsl_sf_bessel_yl_array gsl_sf_bessel_il_scaled gsl_sf_bessel_il_scaled_array gsl_sf_bessel_kl_scaled gsl_sf_bessel_kl_scaled_array gsl_sf_bessel_Jnu gsl_sf_bessel_Ynu gsl_sf_bessel_Inu_scaled gsl_sf_bessel_Inu gsl_sf_bessel_Knu_scaled gsl_sf_bessel_Knu gsl_sf_bessel_lnKnu gsl_sf_clausen gsl_sf_hydrogenicR gsl_sf_coulomb_wave_FGp_array gsl_sf_coulomb_wave_sphF_array gsl_sf_coulomb_CL_e gsl_sf_coupling_3j gsl_sf_coupling_6j gsl_sf_coupling_9j gsl_sf_dawson gsl_sf_debye_1 gsl_sf_debye_2 gsl_sf_debye_3 gsl_sf_debye_4 gsl_sf_dilog gsl_sf_complex_dilog gsl_sf_multiply gsl_sf_multiply_err gsl_sf_ellint_Kcomp gsl_sf_ellint_Ecomp gsl_sf_ellint_F gsl_sf_ellint_E gsl_sf_ellint_P gsl_sf_ellint_D gsl_sf_ellint_RC gsl_sf_ellint_RD gsl_sf_ellint_RF gsl_sf_ellint_RJ gsl_sf_elljac gsl_sf_erfc gsl_sf_log_erfc gsl_sf_erf gsl_sf_erf_Z gsl_sf_erf_Q gsl_sf_exp gsl_sf_exprel_n gsl_sf_exp_err gsl_sf_expint_E1 gsl_sf_expint_E2 gsl_sf_expint_Ei gsl_sf_Shi gsl_sf_Chi gsl_sf_expint_3 gsl_sf_Si gsl_sf_Ci gsl_sf_atanint gsl_sf_fermi_dirac_int gsl_sf_fermi_dirac_mhalf gsl_sf_fermi_dirac_half gsl_sf_fermi_dirac_3half gsl_sf_fermi_dirac_inc_0 gsl_sf_lngamma gsl_sf_gamma gsl_sf_gammastar gsl_sf_gammainv gsl_sf_lngamma_complex gsl_sf_taylorcoeff gsl_sf_fact gsl_sf_doublefact gsl_sf_lnfact gsl_sf_lndoublefact gsl_sf_lnchoose gsl_sf_choose gsl_sf_lnpoch gsl_sf_poch gsl_sf_pochrel gsl_sf_gamma_inc_Q gsl_sf_gamma_inc_P gsl_sf_lnbeta gsl_sf_beta gsl_sf_gegenpoly_n gsl_sf_gegenpoly_array gsl_sf_hyperg_0F1 gsl_sf_hyperg_1F1 gsl_sf_hyperg_U gsl_sf_hyperg_2F1 gsl_sf_hyperg_2F1_conj gsl_sf_hyperg_2F1_renorm gsl_sf_hyperg_2F1_conj_renorm gsl_sf_hyperg_2F0 gsl_sf_laguerre_n gsl_sf_legendre_Pl gsl_sf_legendre_Pl_array gsl_sf_legendre_Ql gsl_sf_legendre_Plm gsl_sf_legendre_array gsl_sf_legendre_array_index gsl_sf_legendre_sphPlm gsl_sf_conicalP_half gsl_sf_conicalP_mhalf gsl_sf_conicalP_0 gsl_sf_conicalP_1 gsl_sf_conicalP_sph_reg gsl_sf_conicalP_cyl_reg_e gsl_sf_legendre_H3d gsl_sf_legendre_H3d_array gsl_sf_log gsl_sf_complex_log gsl_poly_eval gsl_sf_pow_int gsl_sf_psi gsl_sf_psi_1piy gsl_sf_psi_n gsl_sf_synchrotron_1 gsl_sf_synchrotron_2 gsl_sf_transport_2 gsl_sf_transport_3 gsl_sf_transport_4 gsl_sf_transport_5 gsl_sf_sin gsl_sf_cos gsl_sf_hypot gsl_sf_complex_sin gsl_sf_complex_cos gsl_sf_complex_logsin gsl_sf_lnsinh gsl_sf_lncosh gsl_sf_polar_to_rect gsl_sf_rect_to_polar gsl_sf_angle_restrict_symm gsl_sf_angle_restrict_pos gsl_sf_sin_err gsl_sf_cos_err gsl_sf_zeta gsl_sf_hzeta gsl_sf_eta );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::SF ;








#line 4 "lib/PDL/GSL/SF.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSL::SF - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library.

=cut
#line 41 "lib/PDL/GSL/SF.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_airy_Ai

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Ai($x);
 gsl_sf_airy_Ai($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Ai; # method call
 $x->gsl_sf_airy_Ai($y, $e);

=for ref

Airy Function Ai(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Ai> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai = \&PDL::gsl_sf_airy_Ai;






=head2 gsl_sf_airy_Bi

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Bi($x);
 gsl_sf_airy_Bi($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Bi; # method call
 $x->gsl_sf_airy_Bi($y, $e);

=for ref

Airy Function Bi(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Bi> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi = \&PDL::gsl_sf_airy_Bi;






=head2 gsl_sf_airy_Ai_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Ai_scaled($x);
 gsl_sf_airy_Ai_scaled($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Ai_scaled; # method call
 $x->gsl_sf_airy_Ai_scaled($y, $e);

=for ref

Scaled Airy Function Ai(x). Ai(x) for x < 0  and exp(+2/3 x^{3/2}) Ai(x) for  x > 0.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Ai_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai_scaled = \&PDL::gsl_sf_airy_Ai_scaled;






=head2 gsl_sf_airy_Bi_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Bi_scaled($x);
 gsl_sf_airy_Bi_scaled($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Bi_scaled; # method call
 $x->gsl_sf_airy_Bi_scaled($y, $e);

=for ref

Scaled Airy Function Bi(x). Bi(x) for x < 0  and exp(+2/3 x^{3/2}) Bi(x) for  x > 0.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Bi_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi_scaled = \&PDL::gsl_sf_airy_Bi_scaled;






=head2 gsl_sf_airy_Ai_deriv

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Ai_deriv($x);
 gsl_sf_airy_Ai_deriv($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Ai_deriv; # method call
 $x->gsl_sf_airy_Ai_deriv($y, $e);

=for ref

Derivative Airy Function Ai`(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Ai_deriv> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai_deriv = \&PDL::gsl_sf_airy_Ai_deriv;






=head2 gsl_sf_airy_Bi_deriv

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Bi_deriv($x);
 gsl_sf_airy_Bi_deriv($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Bi_deriv; # method call
 $x->gsl_sf_airy_Bi_deriv($y, $e);

=for ref

Derivative Airy Function Bi`(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Bi_deriv> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi_deriv = \&PDL::gsl_sf_airy_Bi_deriv;






=head2 gsl_sf_airy_Ai_deriv_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Ai_deriv_scaled($x);
 gsl_sf_airy_Ai_deriv_scaled($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Ai_deriv_scaled; # method call
 $x->gsl_sf_airy_Ai_deriv_scaled($y, $e);

=for ref

Derivative Scaled Airy Function Ai(x). Ai`(x) for x < 0  and exp(+2/3 x^{3/2}) Ai`(x) for  x > 0.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Ai_deriv_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai_deriv_scaled = \&PDL::gsl_sf_airy_Ai_deriv_scaled;






=head2 gsl_sf_airy_Bi_deriv_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_airy_Bi_deriv_scaled($x);
 gsl_sf_airy_Bi_deriv_scaled($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_airy_Bi_deriv_scaled; # method call
 $x->gsl_sf_airy_Bi_deriv_scaled($y, $e);

=for ref

Derivative Scaled Airy Function Bi(x). Bi`(x) for x < 0  and exp(+2/3 x^{3/2}) Bi`(x) for  x > 0.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_airy_Bi_deriv_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi_deriv_scaled = \&PDL::gsl_sf_airy_Bi_deriv_scaled;






=head2 gsl_sf_bessel_Jn

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Jn($x, $n);
 gsl_sf_bessel_Jn($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Jn($n); # method call
 $x->gsl_sf_bessel_Jn($y, $e, $n);

=for ref

Regular Bessel Function J_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Jn> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Jn = \&PDL::gsl_sf_bessel_Jn;






=head2 gsl_sf_bessel_Jn_array

=for sig

 Signature: (double x(); double [o]y(num); int s; IV n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_Jn_array($x, $s, $n);
 gsl_sf_bessel_Jn_array($x, $y, $s, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_Jn_array($s, $n); # method call
 $x->gsl_sf_bessel_Jn_array($y, $s, $n);

=for ref

Array of Regular Bessel Functions J_{s}(x) to J_{s+n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Jn_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Jn_array = \&PDL::gsl_sf_bessel_Jn_array;






=head2 gsl_sf_bessel_Yn

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Yn($x, $n);
 gsl_sf_bessel_Yn($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Yn($n); # method call
 $x->gsl_sf_bessel_Yn($y, $e, $n);

=for ref

IrRegular Bessel Function Y_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Yn> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Yn = \&PDL::gsl_sf_bessel_Yn;






=head2 gsl_sf_bessel_Yn_array

=for sig

 Signature: (double x(); double [o]y(num); int s; IV n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_Yn_array($x, $s, $n);
 gsl_sf_bessel_Yn_array($x, $y, $s, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_Yn_array($s, $n); # method call
 $x->gsl_sf_bessel_Yn_array($y, $s, $n);

=for ref

Array of Regular Bessel Functions Y_{s}(x) to Y_{s+n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Yn_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Yn_array = \&PDL::gsl_sf_bessel_Yn_array;






=head2 gsl_sf_bessel_In

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_In($x, $n);
 gsl_sf_bessel_In($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_In($n); # method call
 $x->gsl_sf_bessel_In($y, $e, $n);

=for ref

Regular Modified Bessel Function I_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_In> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_In = \&PDL::gsl_sf_bessel_In;






=head2 gsl_sf_bessel_I_array

=for sig

 Signature: (double x(); double [o]y(num); int s; IV n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_I_array($x, $s, $n);
 gsl_sf_bessel_I_array($x, $y, $s, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_I_array($s, $n); # method call
 $x->gsl_sf_bessel_I_array($y, $s, $n);

=for ref

Array of Regular Modified Bessel Functions I_{s}(x) to I_{s+n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_I_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_I_array = \&PDL::gsl_sf_bessel_I_array;






=head2 gsl_sf_bessel_In_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_In_scaled($x, $n);
 gsl_sf_bessel_In_scaled($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_In_scaled($n); # method call
 $x->gsl_sf_bessel_In_scaled($y, $e, $n);

=for ref

Scaled Regular Modified Bessel Function exp(-|x|) I_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_In_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_In_scaled = \&PDL::gsl_sf_bessel_In_scaled;






=head2 gsl_sf_bessel_In_scaled_array

=for sig

 Signature: (double x(); double [o]y(num); int s; IV n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_In_scaled_array($x, $s, $n);
 gsl_sf_bessel_In_scaled_array($x, $y, $s, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_In_scaled_array($s, $n); # method call
 $x->gsl_sf_bessel_In_scaled_array($y, $s, $n);

=for ref

Array of Scaled Regular Modified Bessel Functions exp(-|x|) I_{s}(x) to exp(-|x|) I_{s+n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_In_scaled_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_In_scaled_array = \&PDL::gsl_sf_bessel_In_scaled_array;






=head2 gsl_sf_bessel_Kn

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Kn($x, $n);
 gsl_sf_bessel_Kn($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Kn($n); # method call
 $x->gsl_sf_bessel_Kn($y, $e, $n);

=for ref

IrRegular Modified Bessel Function K_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Kn> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Kn = \&PDL::gsl_sf_bessel_Kn;






=head2 gsl_sf_bessel_K_array

=for sig

 Signature: (double x(); double [o]y(num); int s; IV n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_K_array($x, $s, $n);
 gsl_sf_bessel_K_array($x, $y, $s, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_K_array($s, $n); # method call
 $x->gsl_sf_bessel_K_array($y, $s, $n);

=for ref

Array of IrRegular Modified Bessel Functions K_{s}(x) to K_{s+n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_K_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_K_array = \&PDL::gsl_sf_bessel_K_array;






=head2 gsl_sf_bessel_Kn_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Kn_scaled($x, $n);
 gsl_sf_bessel_Kn_scaled($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Kn_scaled($n); # method call
 $x->gsl_sf_bessel_Kn_scaled($y, $e, $n);

=for ref

Scaled IrRegular Modified Bessel Function exp(-|x|) K_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Kn_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Kn_scaled = \&PDL::gsl_sf_bessel_Kn_scaled;






=head2 gsl_sf_bessel_Kn_scaled_array

=for sig

 Signature: (double x(); double [o]y(num); int s; IV n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_Kn_scaled_array($x, $s, $n);
 gsl_sf_bessel_Kn_scaled_array($x, $y, $s, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_Kn_scaled_array($s, $n); # method call
 $x->gsl_sf_bessel_Kn_scaled_array($y, $s, $n);

=for ref

Array of Scaled IrRegular Modified Bessel Functions exp(-|x|) K_{s}(x) to exp(-|x|) K_{s+n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Kn_scaled_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Kn_scaled_array = \&PDL::gsl_sf_bessel_Kn_scaled_array;






=head2 gsl_sf_bessel_jl

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_jl($x, $n);
 gsl_sf_bessel_jl($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_jl($n); # method call
 $x->gsl_sf_bessel_jl($y, $e, $n);

=for ref

Regular Sphericl Bessel Function J_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_jl> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_jl = \&PDL::gsl_sf_bessel_jl;






=head2 gsl_sf_bessel_jl_array

=for sig

 Signature: (double x(); double [o]y(num); int n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_jl_array($x, $n);
 gsl_sf_bessel_jl_array($x, $y, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_jl_array($n); # method call
 $x->gsl_sf_bessel_jl_array($y, $n);

=for ref

Array of Spherical Regular Bessel Functions J_{0}(x) to J_{n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_jl_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_jl_array = \&PDL::gsl_sf_bessel_jl_array;






=head2 gsl_sf_bessel_yl

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_yl($x, $n);
 gsl_sf_bessel_yl($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_yl($n); # method call
 $x->gsl_sf_bessel_yl($y, $e, $n);

=for ref

IrRegular Spherical Bessel Function y_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_yl> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_yl = \&PDL::gsl_sf_bessel_yl;






=head2 gsl_sf_bessel_yl_array

=for sig

 Signature: (double x(); double [o]y(num); int n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_yl_array($x, $n);
 gsl_sf_bessel_yl_array($x, $y, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_yl_array($n); # method call
 $x->gsl_sf_bessel_yl_array($y, $n);

=for ref

Array of Regular Spherical Bessel Functions y_{0}(x) to y_{n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_yl_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_yl_array = \&PDL::gsl_sf_bessel_yl_array;






=head2 gsl_sf_bessel_il_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_il_scaled($x, $n);
 gsl_sf_bessel_il_scaled($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_il_scaled($n); # method call
 $x->gsl_sf_bessel_il_scaled($y, $e, $n);

=for ref

Scaled Regular Modified Spherical Bessel Function exp(-|x|) i_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_il_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_il_scaled = \&PDL::gsl_sf_bessel_il_scaled;






=head2 gsl_sf_bessel_il_scaled_array

=for sig

 Signature: (double x(); double [o]y(num); int n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_il_scaled_array($x, $n);
 gsl_sf_bessel_il_scaled_array($x, $y, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_il_scaled_array($n); # method call
 $x->gsl_sf_bessel_il_scaled_array($y, $n);

=for ref

Array of Scaled Regular Modified Spherical Bessel Functions exp(-|x|) i_{0}(x) to exp(-|x|) i_{n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_il_scaled_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_il_scaled_array = \&PDL::gsl_sf_bessel_il_scaled_array;






=head2 gsl_sf_bessel_kl_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_kl_scaled($x, $n);
 gsl_sf_bessel_kl_scaled($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_kl_scaled($n); # method call
 $x->gsl_sf_bessel_kl_scaled($y, $e, $n);

=for ref

Scaled IrRegular Modified Spherical Bessel Function exp(-|x|) k_n(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_kl_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_kl_scaled = \&PDL::gsl_sf_bessel_kl_scaled;






=head2 gsl_sf_bessel_kl_scaled_array

=for sig

 Signature: (double x(); double [o]y(num); int n=>num)
 Types: (double)

=for usage

 $y = gsl_sf_bessel_kl_scaled_array($x, $n);
 gsl_sf_bessel_kl_scaled_array($x, $y, $n);  # all arguments given
 $y = $x->gsl_sf_bessel_kl_scaled_array($n); # method call
 $x->gsl_sf_bessel_kl_scaled_array($y, $n);

=for ref

Array of Scaled IrRegular Modified Spherical Bessel Functions exp(-|x|) k_{s}(x) to exp(-|x|) k_{s+n-1}(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_kl_scaled_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_kl_scaled_array = \&PDL::gsl_sf_bessel_kl_scaled_array;






=head2 gsl_sf_bessel_Jnu

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Jnu($x, $n);
 gsl_sf_bessel_Jnu($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Jnu($n); # method call
 $x->gsl_sf_bessel_Jnu($y, $e, $n);

=for ref

Regular Cylindrical Bessel Function J_nu(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Jnu> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Jnu = \&PDL::gsl_sf_bessel_Jnu;






=head2 gsl_sf_bessel_Ynu

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Ynu($x, $n);
 gsl_sf_bessel_Ynu($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Ynu($n); # method call
 $x->gsl_sf_bessel_Ynu($y, $e, $n);

=for ref

IrRegular Cylindrical Bessel Function J_nu(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Ynu> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Ynu = \&PDL::gsl_sf_bessel_Ynu;






=head2 gsl_sf_bessel_Inu_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Inu_scaled($x, $n);
 gsl_sf_bessel_Inu_scaled($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Inu_scaled($n); # method call
 $x->gsl_sf_bessel_Inu_scaled($y, $e, $n);

=for ref

Scaled Modified Cylindrical Bessel Function exp(-|x|) I_nu(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Inu_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Inu_scaled = \&PDL::gsl_sf_bessel_Inu_scaled;






=head2 gsl_sf_bessel_Inu

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Inu($x, $n);
 gsl_sf_bessel_Inu($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Inu($n); # method call
 $x->gsl_sf_bessel_Inu($y, $e, $n);

=for ref

Modified Cylindrical Bessel Function I_nu(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Inu> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Inu = \&PDL::gsl_sf_bessel_Inu;






=head2 gsl_sf_bessel_Knu_scaled

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Knu_scaled($x, $n);
 gsl_sf_bessel_Knu_scaled($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Knu_scaled($n); # method call
 $x->gsl_sf_bessel_Knu_scaled($y, $e, $n);

=for ref

Scaled Modified Cylindrical Bessel Function exp(-|x|) K_nu(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Knu_scaled> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Knu_scaled = \&PDL::gsl_sf_bessel_Knu_scaled;






=head2 gsl_sf_bessel_Knu

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_Knu($x, $n);
 gsl_sf_bessel_Knu($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_Knu($n); # method call
 $x->gsl_sf_bessel_Knu($y, $e, $n);

=for ref

Modified Cylindrical Bessel Function K_nu(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_Knu> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Knu = \&PDL::gsl_sf_bessel_Knu;






=head2 gsl_sf_bessel_lnKnu

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_bessel_lnKnu($x, $n);
 gsl_sf_bessel_lnKnu($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_bessel_lnKnu($n); # method call
 $x->gsl_sf_bessel_lnKnu($y, $e, $n);

=for ref

Logarithm of Modified Cylindrical Bessel Function K_nu(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_bessel_lnKnu> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_lnKnu = \&PDL::gsl_sf_bessel_lnKnu;






=head2 gsl_sf_clausen

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_clausen($x);
 gsl_sf_clausen($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_clausen; # method call
 $x->gsl_sf_clausen($y, $e);

=for ref

Clausen Integral. Cl_2(x) := Integrate[-Log[2 Sin[t/2]], {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_clausen> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_clausen = \&PDL::gsl_sf_clausen;






=head2 gsl_sf_hydrogenicR

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n; int l; double z)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hydrogenicR($x, $n, $l, $z);
 gsl_sf_hydrogenicR($x, $y, $e, $n, $l, $z);    # all arguments given
 ($y, $e) = $x->gsl_sf_hydrogenicR($n, $l, $z); # method call
 $x->gsl_sf_hydrogenicR($y, $e, $n, $l, $z);

=for ref

Normalized Hydrogenic bound states. Radial dipendence.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hydrogenicR> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hydrogenicR = \&PDL::gsl_sf_hydrogenicR;






=head2 gsl_sf_coulomb_wave_FGp_array

=for sig

 Signature: (double x(); double [o]fc(n); double [o]fcp(n); double [o]gc(n); double [o]gcp(n); int [o]ovfw(); double [o]fe(n); double [o]ge(n); double lam_min; IV kmax=>n; double eta)
 Types: (double)

=for usage

 ($fc, $fcp, $gc, $gcp, $ovfw, $fe, $ge) = gsl_sf_coulomb_wave_FGp_array($x, $lam_min, $kmax, $eta);
 gsl_sf_coulomb_wave_FGp_array($x, $fc, $fcp, $gc, $gcp, $ovfw, $fe, $ge, $lam_min, $kmax, $eta);    # all arguments given
 ($fc, $fcp, $gc, $gcp, $ovfw, $fe, $ge) = $x->gsl_sf_coulomb_wave_FGp_array($lam_min, $kmax, $eta); # method call
 $x->gsl_sf_coulomb_wave_FGp_array($fc, $fcp, $gc, $gcp, $ovfw, $fe, $ge, $lam_min, $kmax, $eta);

=for ref

 Coulomb wave functions F_{lam_F}(eta,x), G_{lam_G}(eta,x) and their derivatives; lam_G := lam_F - k_lam_G. if ovfw is signaled then F_L(eta,x)  =  fc[k_L] * exp(fe) and similar. 

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_coulomb_wave_FGp_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coulomb_wave_FGp_array = \&PDL::gsl_sf_coulomb_wave_FGp_array;






=head2 gsl_sf_coulomb_wave_sphF_array

=for sig

 Signature: (double x(); double [o]fc(n); int [o]ovfw(); double [o]fe(n); double lam_min; IV kmax=>n; double eta)
 Types: (double)

=for usage

 ($fc, $ovfw, $fe) = gsl_sf_coulomb_wave_sphF_array($x, $lam_min, $kmax, $eta);
 gsl_sf_coulomb_wave_sphF_array($x, $fc, $ovfw, $fe, $lam_min, $kmax, $eta);    # all arguments given
 ($fc, $ovfw, $fe) = $x->gsl_sf_coulomb_wave_sphF_array($lam_min, $kmax, $eta); # method call
 $x->gsl_sf_coulomb_wave_sphF_array($fc, $ovfw, $fe, $lam_min, $kmax, $eta);

=for ref

 Coulomb wave function divided by the argument, F(xi, eta)/xi. This is the function which reduces to spherical Bessel functions in the limit eta->0. 

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_coulomb_wave_sphF_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coulomb_wave_sphF_array = \&PDL::gsl_sf_coulomb_wave_sphF_array;






=head2 gsl_sf_coulomb_CL_e

=for sig

 Signature: (double L(); double eta();  double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_coulomb_CL_e($L, $eta);
 gsl_sf_coulomb_CL_e($L, $eta, $y, $e);    # all arguments given
 ($y, $e) = $L->gsl_sf_coulomb_CL_e($eta); # method call
 $L->gsl_sf_coulomb_CL_e($eta, $y, $e);

=for ref

Coulomb wave function normalization constant. [Abramowitz+Stegun 14.1.8, 14.1.9].

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_coulomb_CL_e> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coulomb_CL_e = \&PDL::gsl_sf_coulomb_CL_e;






=head2 gsl_sf_coupling_3j

=for sig

 Signature: (ja(); jb(); jc(); ma(); mb(); mc(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_coupling_3j($ja, $jb, $jc, $ma, $mb, $mc);
 gsl_sf_coupling_3j($ja, $jb, $jc, $ma, $mb, $mc, $y, $e);    # all arguments given
 ($y, $e) = $ja->gsl_sf_coupling_3j($jb, $jc, $ma, $mb, $mc); # method call
 $ja->gsl_sf_coupling_3j($jb, $jc, $ma, $mb, $mc, $y, $e);

=for ref

3j Symbols:  (ja jb jc) over (ma mb mc).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_coupling_3j> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_3j = \&PDL::gsl_sf_coupling_3j;






=head2 gsl_sf_coupling_6j

=for sig

 Signature: (ja(); jb(); jc(); jd(); je(); jf(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_coupling_6j($ja, $jb, $jc, $jd, $je, $jf);
 gsl_sf_coupling_6j($ja, $jb, $jc, $jd, $je, $jf, $y, $e);    # all arguments given
 ($y, $e) = $ja->gsl_sf_coupling_6j($jb, $jc, $jd, $je, $jf); # method call
 $ja->gsl_sf_coupling_6j($jb, $jc, $jd, $je, $jf, $y, $e);

=for ref

6j Symbols:  (ja jb jc) over (jd je jf).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_coupling_6j> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_6j = \&PDL::gsl_sf_coupling_6j;






=head2 gsl_sf_coupling_9j

=for sig

 Signature: (ja(); jb(); jc(); jd(); je(); jf(); jg(); jh(); ji(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_coupling_9j($ja, $jb, $jc, $jd, $je, $jf, $jg, $jh, $ji);
 gsl_sf_coupling_9j($ja, $jb, $jc, $jd, $je, $jf, $jg, $jh, $ji, $y, $e);    # all arguments given
 ($y, $e) = $ja->gsl_sf_coupling_9j($jb, $jc, $jd, $je, $jf, $jg, $jh, $ji); # method call
 $ja->gsl_sf_coupling_9j($jb, $jc, $jd, $je, $jf, $jg, $jh, $ji, $y, $e);

=for ref

9j Symbols:  (ja jb jc) over (jd je jf) over (jg jh ji).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_coupling_9j> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_9j = \&PDL::gsl_sf_coupling_9j;






=head2 gsl_sf_dawson

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_dawson($x);
 gsl_sf_dawson($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_dawson; # method call
 $x->gsl_sf_dawson($y, $e);

=for ref

Dawsons integral: Exp[-x^2] Integral[ Exp[t^2], {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_dawson> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_dawson = \&PDL::gsl_sf_dawson;






=head2 gsl_sf_debye_1

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_debye_1($x);
 gsl_sf_debye_1($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_debye_1; # method call
 $x->gsl_sf_debye_1($y, $e);

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_debye_1> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_1 = \&PDL::gsl_sf_debye_1;






=head2 gsl_sf_debye_2

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_debye_2($x);
 gsl_sf_debye_2($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_debye_2; # method call
 $x->gsl_sf_debye_2($y, $e);

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_debye_2> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_2 = \&PDL::gsl_sf_debye_2;






=head2 gsl_sf_debye_3

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_debye_3($x);
 gsl_sf_debye_3($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_debye_3; # method call
 $x->gsl_sf_debye_3($y, $e);

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_debye_3> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_3 = \&PDL::gsl_sf_debye_3;






=head2 gsl_sf_debye_4

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_debye_4($x);
 gsl_sf_debye_4($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_debye_4; # method call
 $x->gsl_sf_debye_4($y, $e);

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_debye_4> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_4 = \&PDL::gsl_sf_debye_4;






=head2 gsl_sf_dilog

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_dilog($x);
 gsl_sf_dilog($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_dilog; # method call
 $x->gsl_sf_dilog($y, $e);

=for ref

/* Real part of DiLogarithm(x), for real argument. In Lewins notation, this is Li_2(x). Li_2(x) = - Re[ Integrate[ Log[1-s] / s, {s, 0, x}] ]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_dilog> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_dilog = \&PDL::gsl_sf_dilog;






=head2 gsl_sf_complex_dilog

=for sig

 Signature: (double r(); double t(); double [o]re(); double [o]im(); double [o]ere(); double [o]eim())
 Types: (double)

=for usage

 ($re, $im, $ere, $eim) = gsl_sf_complex_dilog($r, $t);
 gsl_sf_complex_dilog($r, $t, $re, $im, $ere, $eim);    # all arguments given
 ($re, $im, $ere, $eim) = $r->gsl_sf_complex_dilog($t); # method call
 $r->gsl_sf_complex_dilog($t, $re, $im, $ere, $eim);

=for ref

DiLogarithm(z), for complex argument z = r Exp[i theta].

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_complex_dilog> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_dilog = \&PDL::gsl_sf_complex_dilog;






=head2 gsl_sf_multiply

=for sig

 Signature: (double x(); double xx(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_multiply($x, $xx);
 gsl_sf_multiply($x, $xx, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_multiply($xx); # method call
 $x->gsl_sf_multiply($xx, $y, $e);

=for ref

Multiplication.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_multiply> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_multiply = \&PDL::gsl_sf_multiply;






=head2 gsl_sf_multiply_err

=for sig

 Signature: (double x(); double xe(); double xx(); double xxe(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_multiply_err($x, $xe, $xx, $xxe);
 gsl_sf_multiply_err($x, $xe, $xx, $xxe, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_multiply_err($xe, $xx, $xxe); # method call
 $x->gsl_sf_multiply_err($xe, $xx, $xxe, $y, $e);

=for ref

Multiplication with associated errors.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_multiply_err> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_multiply_err = \&PDL::gsl_sf_multiply_err;






=head2 gsl_sf_ellint_Kcomp

=for sig

 Signature: (double k(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_Kcomp($k);
 gsl_sf_ellint_Kcomp($k, $y, $e);    # all arguments given
 ($y, $e) = $k->gsl_sf_ellint_Kcomp; # method call
 $k->gsl_sf_ellint_Kcomp($y, $e);

=for ref

Legendre form of complete elliptic integrals K(k) = Integral[1/Sqrt[1 - k^2 Sin[t]^2], {t, 0, Pi/2}].

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_Kcomp> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_Kcomp = \&PDL::gsl_sf_ellint_Kcomp;






=head2 gsl_sf_ellint_Ecomp

=for sig

 Signature: (double k(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_Ecomp($k);
 gsl_sf_ellint_Ecomp($k, $y, $e);    # all arguments given
 ($y, $e) = $k->gsl_sf_ellint_Ecomp; # method call
 $k->gsl_sf_ellint_Ecomp($y, $e);

=for ref

Legendre form of complete elliptic integrals E(k) = Integral[  Sqrt[1 - k^2 Sin[t]^2], {t, 0, Pi/2}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_Ecomp> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_Ecomp = \&PDL::gsl_sf_ellint_Ecomp;






=head2 gsl_sf_ellint_F

=for sig

 Signature: (double phi(); double k(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_F($phi, $k);
 gsl_sf_ellint_F($phi, $k, $y, $e);    # all arguments given
 ($y, $e) = $phi->gsl_sf_ellint_F($k); # method call
 $phi->gsl_sf_ellint_F($k, $y, $e);

=for ref

Legendre form of incomplete elliptic integrals F(phi,k)   = Integral[1/Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_F> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_F = \&PDL::gsl_sf_ellint_F;






=head2 gsl_sf_ellint_E

=for sig

 Signature: (double phi(); double k(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_E($phi, $k);
 gsl_sf_ellint_E($phi, $k, $y, $e);    # all arguments given
 ($y, $e) = $phi->gsl_sf_ellint_E($k); # method call
 $phi->gsl_sf_ellint_E($k, $y, $e);

=for ref

Legendre form of incomplete elliptic integrals E(phi,k)   = Integral[  Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_E> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_E = \&PDL::gsl_sf_ellint_E;






=head2 gsl_sf_ellint_P

=for sig

 Signature: (double phi(); double k(); double n();
              double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_P($phi, $k, $n);
 gsl_sf_ellint_P($phi, $k, $n, $y, $e);    # all arguments given
 ($y, $e) = $phi->gsl_sf_ellint_P($k, $n); # method call
 $phi->gsl_sf_ellint_P($k, $n, $y, $e);

=for ref

Legendre form of incomplete elliptic integrals P(phi,k,n) = Integral[(1 + n Sin[t]^2)^(-1)/Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_P> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_P = \&PDL::gsl_sf_ellint_P;






=head2 gsl_sf_ellint_D

=for sig

 Signature: (double phi(); double k();
              double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_D($phi, $k);
 gsl_sf_ellint_D($phi, $k, $y, $e);    # all arguments given
 ($y, $e) = $phi->gsl_sf_ellint_D($k); # method call
 $phi->gsl_sf_ellint_D($k, $y, $e);

=for ref

Legendre form of incomplete elliptic integrals D(phi,k)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_D> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_D = \&PDL::gsl_sf_ellint_D;






=head2 gsl_sf_ellint_RC

=for sig

 Signature: (double x(); double yy(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_RC($x, $yy);
 gsl_sf_ellint_RC($x, $yy, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_ellint_RC($yy); # method call
 $x->gsl_sf_ellint_RC($yy, $y, $e);

=for ref

Carlsons symmetric basis of functions RC(x,y)   = 1/2 Integral[(t+x)^(-1/2) (t+y)^(-1)], {t,0,Inf}

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_RC> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RC = \&PDL::gsl_sf_ellint_RC;






=head2 gsl_sf_ellint_RD

=for sig

 Signature: (double x(); double yy(); double z(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_RD($x, $yy, $z);
 gsl_sf_ellint_RD($x, $yy, $z, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_ellint_RD($yy, $z); # method call
 $x->gsl_sf_ellint_RD($yy, $z, $y, $e);

=for ref

Carlsons symmetric basis of functions RD(x,y,z) = 3/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-3/2), {t,0,Inf}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_RD> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RD = \&PDL::gsl_sf_ellint_RD;






=head2 gsl_sf_ellint_RF

=for sig

 Signature: (double x(); double yy(); double z(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_RF($x, $yy, $z);
 gsl_sf_ellint_RF($x, $yy, $z, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_ellint_RF($yy, $z); # method call
 $x->gsl_sf_ellint_RF($yy, $z, $y, $e);

=for ref

Carlsons symmetric basis of functions RF(x,y,z) = 1/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-1/2), {t,0,Inf}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_RF> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RF = \&PDL::gsl_sf_ellint_RF;






=head2 gsl_sf_ellint_RJ

=for sig

 Signature: (double x(); double yy(); double z(); double p(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_ellint_RJ($x, $yy, $z, $p);
 gsl_sf_ellint_RJ($x, $yy, $z, $p, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_ellint_RJ($yy, $z, $p); # method call
 $x->gsl_sf_ellint_RJ($yy, $z, $p, $y, $e);

=for ref

Carlsons symmetric basis of functions RJ(x,y,z,p) = 3/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-1/2) (t+p)^(-1), {t,0,Inf}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_ellint_RJ> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RJ = \&PDL::gsl_sf_ellint_RJ;






=head2 gsl_sf_elljac

=for sig

 Signature: (double u(); double m(); double [o]sn(); double [o]cn(); double [o]dn())
 Types: (double)

=for usage

 ($sn, $cn, $dn) = gsl_sf_elljac($u, $m);
 gsl_sf_elljac($u, $m, $sn, $cn, $dn);    # all arguments given
 ($sn, $cn, $dn) = $u->gsl_sf_elljac($m); # method call
 $u->gsl_sf_elljac($m, $sn, $cn, $dn);

=for ref

Jacobian elliptic functions sn, dn, cn by descending Landen transformations

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_elljac> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_elljac = \&PDL::gsl_sf_elljac;






=head2 gsl_sf_erfc

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_erfc($x);
 gsl_sf_erfc($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_erfc; # method call
 $x->gsl_sf_erfc($y, $e);

=for ref

Complementary Error Function erfc(x) := 2/Sqrt[Pi] Integrate[Exp[-t^2], {t,x,Infinity}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_erfc> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erfc = \&PDL::gsl_sf_erfc;






=head2 gsl_sf_log_erfc

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_log_erfc($x);
 gsl_sf_log_erfc($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_log_erfc; # method call
 $x->gsl_sf_log_erfc($y, $e);

=for ref

Log Complementary Error Function

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_log_erfc> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_log_erfc = \&PDL::gsl_sf_log_erfc;






=head2 gsl_sf_erf

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_erf($x);
 gsl_sf_erf($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_erf; # method call
 $x->gsl_sf_erf($y, $e);

=for ref

Error Function erf(x) := 2/Sqrt[Pi] Integrate[Exp[-t^2], {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_erf> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erf = \&PDL::gsl_sf_erf;






=head2 gsl_sf_erf_Z

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_erf_Z($x);
 gsl_sf_erf_Z($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_erf_Z; # method call
 $x->gsl_sf_erf_Z($y, $e);

=for ref

Z(x) :  Abramowitz+Stegun 26.2.1

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_erf_Z> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erf_Z = \&PDL::gsl_sf_erf_Z;






=head2 gsl_sf_erf_Q

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_erf_Q($x);
 gsl_sf_erf_Q($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_erf_Q; # method call
 $x->gsl_sf_erf_Q($y, $e);

=for ref

Q(x) :  Abramowitz+Stegun 26.2.1

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_erf_Q> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erf_Q = \&PDL::gsl_sf_erf_Q;






=head2 gsl_sf_exp

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_exp($x);
 gsl_sf_exp($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_exp; # method call
 $x->gsl_sf_exp($y, $e);

=for ref

Exponential

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_exp> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_exp = \&PDL::gsl_sf_exp;






=head2 gsl_sf_exprel_n

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_exprel_n($x, $n);
 gsl_sf_exprel_n($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_exprel_n($n); # method call
 $x->gsl_sf_exprel_n($y, $e, $n);

=for ref

N-relative Exponential. exprel_N(x) = N!/x^N (exp(x) - Sum[x^k/k!, {k,0,N-1}]) = 1 + x/(N+1) + x^2/((N+1)(N+2)) + ... = 1F1(1,1+N,x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_exprel_n> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_exprel_n = \&PDL::gsl_sf_exprel_n;






=head2 gsl_sf_exp_err

=for sig

 Signature: (double x(); double dx(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_exp_err($x, $dx);
 gsl_sf_exp_err($x, $dx, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_exp_err($dx); # method call
 $x->gsl_sf_exp_err($dx, $y, $e);

=for ref

Exponential of a quantity with given error.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_exp_err> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_exp_err = \&PDL::gsl_sf_exp_err;






=head2 gsl_sf_expint_E1

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_expint_E1($x);
 gsl_sf_expint_E1($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_expint_E1; # method call
 $x->gsl_sf_expint_E1($y, $e);

=for ref

E_1(x) := Re[ Integrate[ Exp[-xt]/t, {t,1,Infinity}] ]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_expint_E1> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_E1 = \&PDL::gsl_sf_expint_E1;






=head2 gsl_sf_expint_E2

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_expint_E2($x);
 gsl_sf_expint_E2($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_expint_E2; # method call
 $x->gsl_sf_expint_E2($y, $e);

=for ref

E_2(x) := Re[ Integrate[ Exp[-xt]/t^2, {t,1,Infity}] ]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_expint_E2> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_E2 = \&PDL::gsl_sf_expint_E2;






=head2 gsl_sf_expint_Ei

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_expint_Ei($x);
 gsl_sf_expint_Ei($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_expint_Ei; # method call
 $x->gsl_sf_expint_Ei($y, $e);

=for ref

Ei(x) := PV Integrate[ Exp[-t]/t, {t,-x,Infinity}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_expint_Ei> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_Ei = \&PDL::gsl_sf_expint_Ei;






=head2 gsl_sf_Shi

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_Shi($x);
 gsl_sf_Shi($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_Shi; # method call
 $x->gsl_sf_Shi($y, $e);

=for ref

Shi(x) := Integrate[ Sinh[t]/t, {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_Shi> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Shi = \&PDL::gsl_sf_Shi;






=head2 gsl_sf_Chi

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_Chi($x);
 gsl_sf_Chi($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_Chi; # method call
 $x->gsl_sf_Chi($y, $e);

=for ref

Chi(x) := Re[ M_EULER + log(x) + Integrate[(Cosh[t]-1)/t, {t,0,x}] ]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_Chi> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Chi = \&PDL::gsl_sf_Chi;






=head2 gsl_sf_expint_3

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_expint_3($x);
 gsl_sf_expint_3($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_expint_3; # method call
 $x->gsl_sf_expint_3($y, $e);

=for ref

Ei_3(x) := Integral[ Exp[-t^3], {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_expint_3> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_3 = \&PDL::gsl_sf_expint_3;






=head2 gsl_sf_Si

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_Si($x);
 gsl_sf_Si($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_Si; # method call
 $x->gsl_sf_Si($y, $e);

=for ref

Si(x) := Integrate[ Sin[t]/t, {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_Si> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Si = \&PDL::gsl_sf_Si;






=head2 gsl_sf_Ci

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_Ci($x);
 gsl_sf_Ci($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_Ci; # method call
 $x->gsl_sf_Ci($y, $e);

=for ref

Ci(x) := -Integrate[ Cos[t]/t, {t,x,Infinity}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_Ci> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Ci = \&PDL::gsl_sf_Ci;






=head2 gsl_sf_atanint

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_atanint($x);
 gsl_sf_atanint($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_atanint; # method call
 $x->gsl_sf_atanint($y, $e);

=for ref

AtanInt(x) := Integral[ Arctan[t]/t, {t,0,x}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_atanint> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_atanint = \&PDL::gsl_sf_atanint;






=head2 gsl_sf_fermi_dirac_int

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int j)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_fermi_dirac_int($x, $j);
 gsl_sf_fermi_dirac_int($x, $y, $e, $j);    # all arguments given
 ($y, $e) = $x->gsl_sf_fermi_dirac_int($j); # method call
 $x->gsl_sf_fermi_dirac_int($y, $e, $j);

=for ref

Complete integral F_j(x) for integer j

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_fermi_dirac_int> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_int = \&PDL::gsl_sf_fermi_dirac_int;






=head2 gsl_sf_fermi_dirac_mhalf

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_fermi_dirac_mhalf($x);
 gsl_sf_fermi_dirac_mhalf($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_fermi_dirac_mhalf; # method call
 $x->gsl_sf_fermi_dirac_mhalf($y, $e);

=for ref

Complete integral F_{-1/2}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_fermi_dirac_mhalf> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_mhalf = \&PDL::gsl_sf_fermi_dirac_mhalf;






=head2 gsl_sf_fermi_dirac_half

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_fermi_dirac_half($x);
 gsl_sf_fermi_dirac_half($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_fermi_dirac_half; # method call
 $x->gsl_sf_fermi_dirac_half($y, $e);

=for ref

Complete integral F_{1/2}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_fermi_dirac_half> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_half = \&PDL::gsl_sf_fermi_dirac_half;






=head2 gsl_sf_fermi_dirac_3half

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_fermi_dirac_3half($x);
 gsl_sf_fermi_dirac_3half($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_fermi_dirac_3half; # method call
 $x->gsl_sf_fermi_dirac_3half($y, $e);

=for ref

Complete integral F_{3/2}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_fermi_dirac_3half> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_3half = \&PDL::gsl_sf_fermi_dirac_3half;






=head2 gsl_sf_fermi_dirac_inc_0

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double b)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_fermi_dirac_inc_0($x, $b);
 gsl_sf_fermi_dirac_inc_0($x, $y, $e, $b);    # all arguments given
 ($y, $e) = $x->gsl_sf_fermi_dirac_inc_0($b); # method call
 $x->gsl_sf_fermi_dirac_inc_0($y, $e, $b);

=for ref

Incomplete integral F_0(x,b) = ln(1 + e^(b-x)) - (b-x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_fermi_dirac_inc_0> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_inc_0 = \&PDL::gsl_sf_fermi_dirac_inc_0;






=head2 gsl_sf_lngamma

=for sig

 Signature: (double x(); double [o]y(); double [o]s(); double [o]e())
 Types: (double)

=for usage

 ($y, $s, $e) = gsl_sf_lngamma($x);
 gsl_sf_lngamma($x, $y, $s, $e);    # all arguments given
 ($y, $s, $e) = $x->gsl_sf_lngamma; # method call
 $x->gsl_sf_lngamma($y, $s, $e);

=for ref

Log[Gamma(x)], x not a negative integer Uses real Lanczos method. Determines the sign of Gamma[x] as well as Log[|Gamma[x]|] for x < 0. So Gamma[x] = sgn * Exp[result_lg].

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lngamma> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lngamma = \&PDL::gsl_sf_lngamma;






=head2 gsl_sf_gamma

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_gamma($x);
 gsl_sf_gamma($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_gamma; # method call
 $x->gsl_sf_gamma($y, $e);

=for ref

Gamma(x), x not a negative integer

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_gamma> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma = \&PDL::gsl_sf_gamma;






=head2 gsl_sf_gammastar

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_gammastar($x);
 gsl_sf_gammastar($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_gammastar; # method call
 $x->gsl_sf_gammastar($y, $e);

=for ref

Regulated Gamma Function, x > 0 Gamma^*(x) = Gamma(x)/(Sqrt[2Pi] x^(x-1/2) exp(-x)) = (1 + 1/(12x) + ...),  x->Inf

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_gammastar> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gammastar = \&PDL::gsl_sf_gammastar;






=head2 gsl_sf_gammainv

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_gammainv($x);
 gsl_sf_gammainv($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_gammainv; # method call
 $x->gsl_sf_gammainv($y, $e);

=for ref

1/Gamma(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_gammainv> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gammainv = \&PDL::gsl_sf_gammainv;






=head2 gsl_sf_lngamma_complex

=for sig

 Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())
 Types: (double)

=for usage

 ($x, $y, $xe, $ye) = gsl_sf_lngamma_complex($zr, $zi);
 gsl_sf_lngamma_complex($zr, $zi, $x, $y, $xe, $ye);    # all arguments given
 ($x, $y, $xe, $ye) = $zr->gsl_sf_lngamma_complex($zi); # method call
 $zr->gsl_sf_lngamma_complex($zi, $x, $y, $xe, $ye);

=for ref

Log[Gamma(z)] for z complex, z not a negative integer. Calculates: lnr = log|Gamma(z)|, arg = arg(Gamma(z))  in (-Pi, Pi]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lngamma_complex> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lngamma_complex = \&PDL::gsl_sf_lngamma_complex;






=head2 gsl_sf_taylorcoeff

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_taylorcoeff($x, $n);
 gsl_sf_taylorcoeff($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_taylorcoeff($n); # method call
 $x->gsl_sf_taylorcoeff($y, $e, $n);

=for ref

x^n / n!

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_taylorcoeff> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_taylorcoeff = \&PDL::gsl_sf_taylorcoeff;






=head2 gsl_sf_fact

=for sig

 Signature: (x(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_fact($x);
 gsl_sf_fact($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_fact; # method call
 $x->gsl_sf_fact($y, $e);

=for ref

n!

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_fact> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fact = \&PDL::gsl_sf_fact;






=head2 gsl_sf_doublefact

=for sig

 Signature: (x(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_doublefact($x);
 gsl_sf_doublefact($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_doublefact; # method call
 $x->gsl_sf_doublefact($y, $e);

=for ref

n!! = n(n-2)(n-4)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_doublefact> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_doublefact = \&PDL::gsl_sf_doublefact;






=head2 gsl_sf_lnfact

=for sig

 Signature: (x(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_lnfact($x);
 gsl_sf_lnfact($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_lnfact; # method call
 $x->gsl_sf_lnfact($y, $e);

=for ref

ln n!

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lnfact> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnfact = \&PDL::gsl_sf_lnfact;






=head2 gsl_sf_lndoublefact

=for sig

 Signature: (x(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_lndoublefact($x);
 gsl_sf_lndoublefact($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_lndoublefact; # method call
 $x->gsl_sf_lndoublefact($y, $e);

=for ref

ln n!!

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lndoublefact> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lndoublefact = \&PDL::gsl_sf_lndoublefact;






=head2 gsl_sf_lnchoose

=for sig

 Signature: (n(); m(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_lnchoose($n, $m);
 gsl_sf_lnchoose($n, $m, $y, $e);    # all arguments given
 ($y, $e) = $n->gsl_sf_lnchoose($m); # method call
 $n->gsl_sf_lnchoose($m, $y, $e);

=for ref

log(n choose m)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lnchoose> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnchoose = \&PDL::gsl_sf_lnchoose;






=head2 gsl_sf_choose

=for sig

 Signature: (n(); m(); double [o]y(); double [o]e())
 Types: (long)

=for usage

 ($y, $e) = gsl_sf_choose($n, $m);
 gsl_sf_choose($n, $m, $y, $e);    # all arguments given
 ($y, $e) = $n->gsl_sf_choose($m); # method call
 $n->gsl_sf_choose($m, $y, $e);

=for ref

n choose m

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_choose> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_choose = \&PDL::gsl_sf_choose;






=head2 gsl_sf_lnpoch

=for sig

 Signature: (double x(); double [o]y(); double [o]s(); double [o]e(); double a)
 Types: (double)

=for usage

 ($y, $s, $e) = gsl_sf_lnpoch($x, $a);
 gsl_sf_lnpoch($x, $y, $s, $e, $a);    # all arguments given
 ($y, $s, $e) = $x->gsl_sf_lnpoch($a); # method call
 $x->gsl_sf_lnpoch($y, $s, $e, $a);

=for ref

Logarithm of Pochammer (Apell) symbol, with sign information. result = log( |(a)_x| ), sgn    = sgn( (a)_x ) where (a)_x := Gamma[a + x]/Gamma[a]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lnpoch> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnpoch = \&PDL::gsl_sf_lnpoch;






=head2 gsl_sf_poch

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_poch($x, $a);
 gsl_sf_poch($x, $y, $e, $a);    # all arguments given
 ($y, $e) = $x->gsl_sf_poch($a); # method call
 $x->gsl_sf_poch($y, $e, $a);

=for ref

Pochammer (Apell) symbol (a)_x := Gamma[a + x]/Gamma[x]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_poch> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_poch = \&PDL::gsl_sf_poch;






=head2 gsl_sf_pochrel

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_pochrel($x, $a);
 gsl_sf_pochrel($x, $y, $e, $a);    # all arguments given
 ($y, $e) = $x->gsl_sf_pochrel($a); # method call
 $x->gsl_sf_pochrel($y, $e, $a);

=for ref

Relative Pochammer (Apell) symbol ((a,x) - 1)/x where (a,x) = (a)_x := Gamma[a + x]/Gamma[a]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_pochrel> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_pochrel = \&PDL::gsl_sf_pochrel;






=head2 gsl_sf_gamma_inc_Q

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_gamma_inc_Q($x, $a);
 gsl_sf_gamma_inc_Q($x, $y, $e, $a);    # all arguments given
 ($y, $e) = $x->gsl_sf_gamma_inc_Q($a); # method call
 $x->gsl_sf_gamma_inc_Q($y, $e, $a);

=for ref

Normalized Incomplete Gamma Function Q(a,x) = 1/Gamma(a) Integral[ t^(a-1) e^(-t), {t,x,Infinity} ]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_gamma_inc_Q> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma_inc_Q = \&PDL::gsl_sf_gamma_inc_Q;






=head2 gsl_sf_gamma_inc_P

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_gamma_inc_P($x, $a);
 gsl_sf_gamma_inc_P($x, $y, $e, $a);    # all arguments given
 ($y, $e) = $x->gsl_sf_gamma_inc_P($a); # method call
 $x->gsl_sf_gamma_inc_P($y, $e, $a);

=for ref

Complementary Normalized Incomplete Gamma Function P(a,x) = 1/Gamma(a) Integral[ t^(a-1) e^(-t), {t,0,x} ]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_gamma_inc_P> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma_inc_P = \&PDL::gsl_sf_gamma_inc_P;






=head2 gsl_sf_lnbeta

=for sig

 Signature: (double a(); double b(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_lnbeta($a, $b);
 gsl_sf_lnbeta($a, $b, $y, $e);    # all arguments given
 ($y, $e) = $a->gsl_sf_lnbeta($b); # method call
 $a->gsl_sf_lnbeta($b, $y, $e);

=for ref

Logarithm of Beta Function Log[B(a,b)]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lnbeta> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnbeta = \&PDL::gsl_sf_lnbeta;






=head2 gsl_sf_beta

=for sig

 Signature: (double a(); double b();double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_beta($a, $b);
 gsl_sf_beta($a, $b, $y, $e);    # all arguments given
 ($y, $e) = $a->gsl_sf_beta($b); # method call
 $a->gsl_sf_beta($b, $y, $e);

=for ref

Beta Function B(a,b)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_beta> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_beta = \&PDL::gsl_sf_beta;






=head2 gsl_sf_gegenpoly_n

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n; double lambda)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_gegenpoly_n($x, $n, $lambda);
 gsl_sf_gegenpoly_n($x, $y, $e, $n, $lambda);    # all arguments given
 ($y, $e) = $x->gsl_sf_gegenpoly_n($n, $lambda); # method call
 $x->gsl_sf_gegenpoly_n($y, $e, $n, $lambda);

=for ref

Evaluate Gegenbauer polynomials.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_gegenpoly_n> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gegenpoly_n = \&PDL::gsl_sf_gegenpoly_n;






=head2 gsl_sf_gegenpoly_array

=for sig

 Signature: (double x(); double [o]y(num); int n=>num; double lambda)
 Types: (double)

=for usage

 $y = gsl_sf_gegenpoly_array($x, $n, $lambda);
 gsl_sf_gegenpoly_array($x, $y, $n, $lambda);  # all arguments given
 $y = $x->gsl_sf_gegenpoly_array($n, $lambda); # method call
 $x->gsl_sf_gegenpoly_array($y, $n, $lambda);

=for ref

Calculate array of Gegenbauer polynomials from 0 to n-1.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_gegenpoly_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gegenpoly_array = \&PDL::gsl_sf_gegenpoly_array;






=head2 gsl_sf_hyperg_0F1

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double c)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_0F1($x, $c);
 gsl_sf_hyperg_0F1($x, $y, $e, $c);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_0F1($c); # method call
 $x->gsl_sf_hyperg_0F1($y, $e, $c);

=for ref

/* Hypergeometric function related to Bessel functions 0F1[c,x] = Gamma[c]    x^(1/2(1-c)) I_{c-1}(2 Sqrt[x]) Gamma[c] (-x)^(1/2(1-c)) J_{c-1}(2 Sqrt[-x])

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_0F1> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_0F1 = \&PDL::gsl_sf_hyperg_0F1;






=head2 gsl_sf_hyperg_1F1

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a; double b)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_1F1($x, $a, $b);
 gsl_sf_hyperg_1F1($x, $y, $e, $a, $b);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_1F1($a, $b); # method call
 $x->gsl_sf_hyperg_1F1($y, $e, $a, $b);

=for ref

Confluent hypergeometric function  for integer parameters. 1F1[a,b,x] = M(a,b,x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_1F1> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_1F1 = \&PDL::gsl_sf_hyperg_1F1;






=head2 gsl_sf_hyperg_U

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a; double b)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_U($x, $a, $b);
 gsl_sf_hyperg_U($x, $y, $e, $a, $b);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_U($a, $b); # method call
 $x->gsl_sf_hyperg_U($y, $e, $a, $b);

=for ref

Confluent hypergeometric function  for integer parameters. U(a,b,x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_U> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_U = \&PDL::gsl_sf_hyperg_U;






=head2 gsl_sf_hyperg_2F1

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_2F1($x, $a, $b, $c);
 gsl_sf_hyperg_2F1($x, $y, $e, $a, $b, $c);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_2F1($a, $b, $c); # method call
 $x->gsl_sf_hyperg_2F1($y, $e, $a, $b, $c);

=for ref

Confluent hypergeometric function  for integer parameters. 2F1[a,b,c,x]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_2F1> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1 = \&PDL::gsl_sf_hyperg_2F1;






=head2 gsl_sf_hyperg_2F1_conj

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_2F1_conj($x, $a, $b, $c);
 gsl_sf_hyperg_2F1_conj($x, $y, $e, $a, $b, $c);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_2F1_conj($a, $b, $c); # method call
 $x->gsl_sf_hyperg_2F1_conj($y, $e, $a, $b, $c);

=for ref

Gauss hypergeometric function 2F1[aR + I aI, aR - I aI, c, x]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_2F1_conj> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1_conj = \&PDL::gsl_sf_hyperg_2F1_conj;






=head2 gsl_sf_hyperg_2F1_renorm

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_2F1_renorm($x, $a, $b, $c);
 gsl_sf_hyperg_2F1_renorm($x, $y, $e, $a, $b, $c);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_2F1_renorm($a, $b, $c); # method call
 $x->gsl_sf_hyperg_2F1_renorm($y, $e, $a, $b, $c);

=for ref

Renormalized Gauss hypergeometric function 2F1[a,b,c,x] / Gamma[c]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_2F1_renorm> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1_renorm = \&PDL::gsl_sf_hyperg_2F1_renorm;






=head2 gsl_sf_hyperg_2F1_conj_renorm

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_2F1_conj_renorm($x, $a, $b, $c);
 gsl_sf_hyperg_2F1_conj_renorm($x, $y, $e, $a, $b, $c);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_2F1_conj_renorm($a, $b, $c); # method call
 $x->gsl_sf_hyperg_2F1_conj_renorm($y, $e, $a, $b, $c);

=for ref

Renormalized Gauss hypergeometric function 2F1[aR + I aI, aR - I aI, c, x] / Gamma[c]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_2F1_conj_renorm> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1_conj_renorm = \&PDL::gsl_sf_hyperg_2F1_conj_renorm;






=head2 gsl_sf_hyperg_2F0

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double a; double b)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hyperg_2F0($x, $a, $b);
 gsl_sf_hyperg_2F0($x, $y, $e, $a, $b);    # all arguments given
 ($y, $e) = $x->gsl_sf_hyperg_2F0($a, $b); # method call
 $x->gsl_sf_hyperg_2F0($y, $e, $a, $b);

=for ref

Mysterious hypergeometric function. The series representation is a divergent hypergeometric series. However, for x < 0 we have 2F0(a,b,x) = (-1/x)^a U(a,1+a-b,-1/x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hyperg_2F0> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F0 = \&PDL::gsl_sf_hyperg_2F0;






=head2 gsl_sf_laguerre_n

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n; double a)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_laguerre_n($x, $n, $a);
 gsl_sf_laguerre_n($x, $y, $e, $n, $a);    # all arguments given
 ($y, $e) = $x->gsl_sf_laguerre_n($n, $a); # method call
 $x->gsl_sf_laguerre_n($y, $e, $n, $a);

=for ref

Evaluate generalized Laguerre polynomials.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_laguerre_n> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_laguerre_n = \&PDL::gsl_sf_laguerre_n;






=head2 gsl_sf_legendre_Pl

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int l)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_legendre_Pl($x, $l);
 gsl_sf_legendre_Pl($x, $y, $e, $l);    # all arguments given
 ($y, $e) = $x->gsl_sf_legendre_Pl($l); # method call
 $x->gsl_sf_legendre_Pl($y, $e, $l);

=for ref

P_l(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_Pl> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Pl = \&PDL::gsl_sf_legendre_Pl;






=head2 gsl_sf_legendre_Pl_array

=for sig

 Signature: (double x(); double [o]y(num); int l=>num)
 Types: (double)

=for usage

 $y = gsl_sf_legendre_Pl_array($x, $l);
 gsl_sf_legendre_Pl_array($x, $y, $l);  # all arguments given
 $y = $x->gsl_sf_legendre_Pl_array($l); # method call
 $x->gsl_sf_legendre_Pl_array($y, $l);

=for ref

P_l(x) from 0 to n-1.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_Pl_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Pl_array = \&PDL::gsl_sf_legendre_Pl_array;






=head2 gsl_sf_legendre_Ql

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int l)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_legendre_Ql($x, $l);
 gsl_sf_legendre_Ql($x, $y, $e, $l);    # all arguments given
 ($y, $e) = $x->gsl_sf_legendre_Ql($l); # method call
 $x->gsl_sf_legendre_Ql($y, $e, $l);

=for ref

Q_l(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_Ql> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Ql = \&PDL::gsl_sf_legendre_Ql;






=head2 gsl_sf_legendre_Plm

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int l; int m)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_legendre_Plm($x, $l, $m);
 gsl_sf_legendre_Plm($x, $y, $e, $l, $m);    # all arguments given
 ($y, $e) = $x->gsl_sf_legendre_Plm($l, $m); # method call
 $x->gsl_sf_legendre_Plm($y, $e, $l, $m);

=for ref

P_lm(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_Plm> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Plm = \&PDL::gsl_sf_legendre_Plm;






=head2 gsl_sf_legendre_array

=for sig

 Signature: (double x(); double [o]y(n=CALC($COMP(lmax)*($COMP(lmax)+1)/2+$COMP(lmax)+1)); double [t]work(wn=CALC(gsl_sf_legendre_array_n($COMP(lmax)))); char norm;  int lmax; int csphase)
 Types: (double)

=for ref

Calculate all normalized associated Legendre polynomials.

=for usage

$Plm = gsl_sf_legendre_array($x,'P',4,-1);

The calculation is done for degree 0 <= l <= lmax and order 0 <= m <= l on the range abs(x)<=1.

The parameter norm should be:

=over 3

=item 'S' for Schmidt semi-normalized associated Legendre polynomials S_l^m(x),

=item 'Y' for spherical harmonic associated Legendre polynomials Y_l^m(x), or

=item 'N' for fully normalized associated Legendre polynomials N_l^m(x).

=item 'P' (or any other) for unnormalized associated Legendre polynomials P_l^m(x),

=back

lmax is the maximum degree l.
csphase should be (-1) to INCLUDE the Condon-Shortley phase factor (-1)^m, or (+1) to EXCLUDE it.

See L</gsl_sf_legendre_array_index> to get the value of C<l> and C<m> in the returned vector.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_array> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_array = \&PDL::gsl_sf_legendre_array;






=head2 gsl_sf_legendre_array_index

=for sig

 Signature: (int [o]l(n=CALC($COMP(lmax)*($COMP(lmax)+1)/2+$COMP(lmax)+1)); int [o]m(n); int lmax)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for ref

Calculate the relation between gsl_sf_legendre_arrays index and l and m values.

=for usage
($l,$m) = gsl_sf_legendre_array_index($lmax);

Note that this function is called differently than the corresponding GSL function, to make it more useful for PDL: here you just input the maximum l (lmax) that was used in C<gsl_sf_legendre_array> and it calculates all l and m values.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_array_index> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_array_index = \&PDL::gsl_sf_legendre_array_index;






=head2 gsl_sf_legendre_sphPlm

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int l; int m)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_legendre_sphPlm($x, $l, $m);
 gsl_sf_legendre_sphPlm($x, $y, $e, $l, $m);    # all arguments given
 ($y, $e) = $x->gsl_sf_legendre_sphPlm($l, $m); # method call
 $x->gsl_sf_legendre_sphPlm($y, $e, $l, $m);

=for ref

P_lm(x), normalized properly for use in spherical harmonics

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_sphPlm> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_sphPlm = \&PDL::gsl_sf_legendre_sphPlm;






=head2 gsl_sf_conicalP_half

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double lambda)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_conicalP_half($x, $lambda);
 gsl_sf_conicalP_half($x, $y, $e, $lambda);    # all arguments given
 ($y, $e) = $x->gsl_sf_conicalP_half($lambda); # method call
 $x->gsl_sf_conicalP_half($y, $e, $lambda);

=for ref

Irregular Spherical Conical Function P^{1/2}_{-1/2 + I lambda}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_conicalP_half> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_half = \&PDL::gsl_sf_conicalP_half;






=head2 gsl_sf_conicalP_mhalf

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double lambda)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_conicalP_mhalf($x, $lambda);
 gsl_sf_conicalP_mhalf($x, $y, $e, $lambda);    # all arguments given
 ($y, $e) = $x->gsl_sf_conicalP_mhalf($lambda); # method call
 $x->gsl_sf_conicalP_mhalf($y, $e, $lambda);

=for ref

Regular Spherical Conical Function P^{-1/2}_{-1/2 + I lambda}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_conicalP_mhalf> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_mhalf = \&PDL::gsl_sf_conicalP_mhalf;






=head2 gsl_sf_conicalP_0

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double lambda)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_conicalP_0($x, $lambda);
 gsl_sf_conicalP_0($x, $y, $e, $lambda);    # all arguments given
 ($y, $e) = $x->gsl_sf_conicalP_0($lambda); # method call
 $x->gsl_sf_conicalP_0($y, $e, $lambda);

=for ref

Conical Function P^{0}_{-1/2 + I lambda}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_conicalP_0> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_0 = \&PDL::gsl_sf_conicalP_0;






=head2 gsl_sf_conicalP_1

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); double lambda)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_conicalP_1($x, $lambda);
 gsl_sf_conicalP_1($x, $y, $e, $lambda);    # all arguments given
 ($y, $e) = $x->gsl_sf_conicalP_1($lambda); # method call
 $x->gsl_sf_conicalP_1($y, $e, $lambda);

=for ref

Conical Function P^{1}_{-1/2 + I lambda}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_conicalP_1> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_1 = \&PDL::gsl_sf_conicalP_1;






=head2 gsl_sf_conicalP_sph_reg

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int l; double lambda)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_conicalP_sph_reg($x, $l, $lambda);
 gsl_sf_conicalP_sph_reg($x, $y, $e, $l, $lambda);    # all arguments given
 ($y, $e) = $x->gsl_sf_conicalP_sph_reg($l, $lambda); # method call
 $x->gsl_sf_conicalP_sph_reg($y, $e, $l, $lambda);

=for ref

Regular Spherical Conical Function P^{-1/2-l}_{-1/2 + I lambda}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_conicalP_sph_reg> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_sph_reg = \&PDL::gsl_sf_conicalP_sph_reg;






=head2 gsl_sf_conicalP_cyl_reg_e

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int m; double lambda)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_conicalP_cyl_reg_e($x, $m, $lambda);
 gsl_sf_conicalP_cyl_reg_e($x, $y, $e, $m, $lambda);    # all arguments given
 ($y, $e) = $x->gsl_sf_conicalP_cyl_reg_e($m, $lambda); # method call
 $x->gsl_sf_conicalP_cyl_reg_e($y, $e, $m, $lambda);

=for ref

Regular Cylindrical Conical Function P^{-m}_{-1/2 + I lambda}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_conicalP_cyl_reg_e> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_cyl_reg_e = \&PDL::gsl_sf_conicalP_cyl_reg_e;






=head2 gsl_sf_legendre_H3d

=for sig

 Signature: (double [o]y(); double [o]e(); int l; double lambda; double eta)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_legendre_H3d($l, $lambda, $eta);
 gsl_sf_legendre_H3d($y, $e, $l, $lambda, $eta);    # all arguments given
 ($y, $e) = $l->gsl_sf_legendre_H3d($lambda, $eta); # method call
 $y->gsl_sf_legendre_H3d($e, $l, $lambda, $eta);

=for ref

lth radial eigenfunction of the Laplacian on the 3-dimensional hyperbolic space.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_H3d> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_H3d = \&PDL::gsl_sf_legendre_H3d;






=head2 gsl_sf_legendre_H3d_array

=for sig

 Signature: (double [o]y(num); int l=>num; double lambda; double eta)
 Types: (double)

=for usage

 $y = gsl_sf_legendre_H3d_array($l, $lambda, $eta);
 gsl_sf_legendre_H3d_array($y, $l, $lambda, $eta);  # all arguments given
 $y = $l->gsl_sf_legendre_H3d_array($lambda, $eta); # method call
 $y->gsl_sf_legendre_H3d_array($l, $lambda, $eta);

=for ref

Array of H3d(ell), for l from 0 to n-1.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_legendre_H3d_array> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_H3d_array = \&PDL::gsl_sf_legendre_H3d_array;






=head2 gsl_sf_log

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_log($x);
 gsl_sf_log($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_log; # method call
 $x->gsl_sf_log($y, $e);

=for ref

Provide a logarithm function with GSL semantics.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_log> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_log = \&PDL::gsl_sf_log;






=head2 gsl_sf_complex_log

=for sig

 Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())
 Types: (double)

=for usage

 ($x, $y, $xe, $ye) = gsl_sf_complex_log($zr, $zi);
 gsl_sf_complex_log($zr, $zi, $x, $y, $xe, $ye);    # all arguments given
 ($x, $y, $xe, $ye) = $zr->gsl_sf_complex_log($zi); # method call
 $zr->gsl_sf_complex_log($zi, $x, $y, $xe, $ye);

=for ref

Complex Logarithm exp(lnr + I theta) = zr + I zi Returns argument in [-pi,pi].

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_complex_log> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_log = \&PDL::gsl_sf_complex_log;






=head2 gsl_poly_eval

=for sig

 Signature: (double x(); double c(m); double [o]y())
 Types: (double)

=for usage

 $y = gsl_poly_eval($x, $c);
 gsl_poly_eval($x, $c, $y);  # all arguments given
 $y = $x->gsl_poly_eval($c); # method call
 $x->gsl_poly_eval($c, $y);

=for ref

c[0] + c[1] x + c[2] x^2 + ... + c[m-1] x^(m-1)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_poly_eval> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_poly_eval = \&PDL::gsl_poly_eval;






=head2 gsl_sf_pow_int

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_pow_int($x, $n);
 gsl_sf_pow_int($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_pow_int($n); # method call
 $x->gsl_sf_pow_int($y, $e, $n);

=for ref

Calculate x^n.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_pow_int> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_pow_int = \&PDL::gsl_sf_pow_int;






=head2 gsl_sf_psi

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_psi($x);
 gsl_sf_psi($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_psi; # method call
 $x->gsl_sf_psi($y, $e);

=for ref

Di-Gamma Function psi(x).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_psi> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi = \&PDL::gsl_sf_psi;






=head2 gsl_sf_psi_1piy

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_psi_1piy($x);
 gsl_sf_psi_1piy($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_psi_1piy; # method call
 $x->gsl_sf_psi_1piy($y, $e);

=for ref

Di-Gamma Function Re[psi(1 + I y)]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_psi_1piy> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi_1piy = \&PDL::gsl_sf_psi_1piy;






=head2 gsl_sf_psi_n

=for sig

 Signature: (double x(); double [o]y(); double [o]e(); int n)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_psi_n($x, $n);
 gsl_sf_psi_n($x, $y, $e, $n);    # all arguments given
 ($y, $e) = $x->gsl_sf_psi_n($n); # method call
 $x->gsl_sf_psi_n($y, $e, $n);

=for ref

Poly-Gamma Function psi^(n)(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_psi_n> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi_n = \&PDL::gsl_sf_psi_n;






=head2 gsl_sf_synchrotron_1

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_synchrotron_1($x);
 gsl_sf_synchrotron_1($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_synchrotron_1; # method call
 $x->gsl_sf_synchrotron_1($y, $e);

=for ref

First synchrotron function: synchrotron_1(x) = x Integral[ K_{5/3}(t), {t, x, Infinity}]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_synchrotron_1> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_synchrotron_1 = \&PDL::gsl_sf_synchrotron_1;






=head2 gsl_sf_synchrotron_2

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_synchrotron_2($x);
 gsl_sf_synchrotron_2($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_synchrotron_2; # method call
 $x->gsl_sf_synchrotron_2($y, $e);

=for ref

Second synchroton function: synchrotron_2(x) = x * K_{2/3}(x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_synchrotron_2> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_synchrotron_2 = \&PDL::gsl_sf_synchrotron_2;






=head2 gsl_sf_transport_2

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_transport_2($x);
 gsl_sf_transport_2($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_transport_2; # method call
 $x->gsl_sf_transport_2($y, $e);

=for ref

J(2,x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_transport_2> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_2 = \&PDL::gsl_sf_transport_2;






=head2 gsl_sf_transport_3

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_transport_3($x);
 gsl_sf_transport_3($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_transport_3; # method call
 $x->gsl_sf_transport_3($y, $e);

=for ref

J(3,x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_transport_3> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_3 = \&PDL::gsl_sf_transport_3;






=head2 gsl_sf_transport_4

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_transport_4($x);
 gsl_sf_transport_4($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_transport_4; # method call
 $x->gsl_sf_transport_4($y, $e);

=for ref

J(4,x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_transport_4> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_4 = \&PDL::gsl_sf_transport_4;






=head2 gsl_sf_transport_5

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_transport_5($x);
 gsl_sf_transport_5($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_transport_5; # method call
 $x->gsl_sf_transport_5($y, $e);

=for ref

J(5,x)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_transport_5> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_5 = \&PDL::gsl_sf_transport_5;






=head2 gsl_sf_sin

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_sin($x);
 gsl_sf_sin($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_sin; # method call
 $x->gsl_sf_sin($y, $e);

=for ref

Sin(x) with GSL semantics.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_sin> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_sin = \&PDL::gsl_sf_sin;






=head2 gsl_sf_cos

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_cos($x);
 gsl_sf_cos($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_cos; # method call
 $x->gsl_sf_cos($y, $e);

=for ref

Cos(x) with GSL semantics.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_cos> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_cos = \&PDL::gsl_sf_cos;






=head2 gsl_sf_hypot

=for sig

 Signature: (double x(); double xx(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hypot($x, $xx);
 gsl_sf_hypot($x, $xx, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_hypot($xx); # method call
 $x->gsl_sf_hypot($xx, $y, $e);

=for ref

Hypot(x,xx) with GSL semantics.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hypot> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hypot = \&PDL::gsl_sf_hypot;






=head2 gsl_sf_complex_sin

=for sig

 Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())
 Types: (double)

=for usage

 ($x, $y, $xe, $ye) = gsl_sf_complex_sin($zr, $zi);
 gsl_sf_complex_sin($zr, $zi, $x, $y, $xe, $ye);    # all arguments given
 ($x, $y, $xe, $ye) = $zr->gsl_sf_complex_sin($zi); # method call
 $zr->gsl_sf_complex_sin($zi, $x, $y, $xe, $ye);

=for ref

Sin(z) for complex z

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_complex_sin> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_sin = \&PDL::gsl_sf_complex_sin;






=head2 gsl_sf_complex_cos

=for sig

 Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())
 Types: (double)

=for usage

 ($x, $y, $xe, $ye) = gsl_sf_complex_cos($zr, $zi);
 gsl_sf_complex_cos($zr, $zi, $x, $y, $xe, $ye);    # all arguments given
 ($x, $y, $xe, $ye) = $zr->gsl_sf_complex_cos($zi); # method call
 $zr->gsl_sf_complex_cos($zi, $x, $y, $xe, $ye);

=for ref

Cos(z) for complex z

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_complex_cos> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_cos = \&PDL::gsl_sf_complex_cos;






=head2 gsl_sf_complex_logsin

=for sig

 Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())
 Types: (double)

=for usage

 ($x, $y, $xe, $ye) = gsl_sf_complex_logsin($zr, $zi);
 gsl_sf_complex_logsin($zr, $zi, $x, $y, $xe, $ye);    # all arguments given
 ($x, $y, $xe, $ye) = $zr->gsl_sf_complex_logsin($zi); # method call
 $zr->gsl_sf_complex_logsin($zi, $x, $y, $xe, $ye);

=for ref

Log(Sin(z)) for complex z

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_complex_logsin> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_logsin = \&PDL::gsl_sf_complex_logsin;






=head2 gsl_sf_lnsinh

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_lnsinh($x);
 gsl_sf_lnsinh($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_lnsinh; # method call
 $x->gsl_sf_lnsinh($y, $e);

=for ref

Log(Sinh(x)) with GSL semantics.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lnsinh> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnsinh = \&PDL::gsl_sf_lnsinh;






=head2 gsl_sf_lncosh

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_lncosh($x);
 gsl_sf_lncosh($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_lncosh; # method call
 $x->gsl_sf_lncosh($y, $e);

=for ref

Log(Cos(x)) with GSL semantics.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_lncosh> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lncosh = \&PDL::gsl_sf_lncosh;






=head2 gsl_sf_polar_to_rect

=for sig

 Signature: (double r(); double t(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())
 Types: (double)

=for usage

 ($x, $y, $xe, $ye) = gsl_sf_polar_to_rect($r, $t);
 gsl_sf_polar_to_rect($r, $t, $x, $y, $xe, $ye);    # all arguments given
 ($x, $y, $xe, $ye) = $r->gsl_sf_polar_to_rect($t); # method call
 $r->gsl_sf_polar_to_rect($t, $x, $y, $xe, $ye);

=for ref

Convert polar to rectlinear coordinates.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_polar_to_rect> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_polar_to_rect = \&PDL::gsl_sf_polar_to_rect;






=head2 gsl_sf_rect_to_polar

=for sig

 Signature: (double x(); double y(); double [o]r(); double [o]t(); double [o]re(); double [o]te())
 Types: (double)

=for usage

 ($r, $t, $re, $te) = gsl_sf_rect_to_polar($x, $y);
 gsl_sf_rect_to_polar($x, $y, $r, $t, $re, $te);    # all arguments given
 ($r, $t, $re, $te) = $x->gsl_sf_rect_to_polar($y); # method call
 $x->gsl_sf_rect_to_polar($y, $r, $t, $re, $te);

=for ref

Convert rectlinear to polar coordinates. return argument in range [-pi, pi].

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_rect_to_polar> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_rect_to_polar = \&PDL::gsl_sf_rect_to_polar;






=head2 gsl_sf_angle_restrict_symm

=for sig

 Signature: (double [o]y())
 Types: (double)

=for usage

 $y = gsl_sf_angle_restrict_symm();
 gsl_sf_angle_restrict_symm($y);    # all arguments given
 $y->gsl_sf_angle_restrict_symm;

=for ref

Force an angle to lie in the range (-pi,pi].

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_angle_restrict_symm> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_angle_restrict_symm = \&PDL::gsl_sf_angle_restrict_symm;






=head2 gsl_sf_angle_restrict_pos

=for sig

 Signature: (double [o]y())
 Types: (double)

=for usage

 $y = gsl_sf_angle_restrict_pos();
 gsl_sf_angle_restrict_pos($y);    # all arguments given
 $y->gsl_sf_angle_restrict_pos;

=for ref

Force an angle to lie in the range [0,2 pi).

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_angle_restrict_pos> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_angle_restrict_pos = \&PDL::gsl_sf_angle_restrict_pos;






=head2 gsl_sf_sin_err

=for sig

 Signature: (double x(); double dx(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_sin_err($x, $dx);
 gsl_sf_sin_err($x, $dx, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_sin_err($dx); # method call
 $x->gsl_sf_sin_err($dx, $y, $e);

=for ref

Sin(x) for quantity with an associated error.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_sin_err> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_sin_err = \&PDL::gsl_sf_sin_err;






=head2 gsl_sf_cos_err

=for sig

 Signature: (double x(); double dx(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_cos_err($x, $dx);
 gsl_sf_cos_err($x, $dx, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_cos_err($dx); # method call
 $x->gsl_sf_cos_err($dx, $y, $e);

=for ref

Cos(x) for quantity with an associated error.

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_cos_err> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_cos_err = \&PDL::gsl_sf_cos_err;






=head2 gsl_sf_zeta

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_zeta($x);
 gsl_sf_zeta($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_zeta; # method call
 $x->gsl_sf_zeta($y, $e);

=for ref

Riemann Zeta Function zeta(x) = Sum[ k^(-s), {k,1,Infinity} ], s != 1.0

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_zeta> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_zeta = \&PDL::gsl_sf_zeta;






=head2 gsl_sf_hzeta

=for sig

 Signature: (double s(); double [o]y(); double [o]e(); double q)
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_hzeta($s, $q);
 gsl_sf_hzeta($s, $y, $e, $q);    # all arguments given
 ($y, $e) = $s->gsl_sf_hzeta($q); # method call
 $s->gsl_sf_hzeta($y, $e, $q);

=for ref

Hurwicz Zeta Function zeta(s,q) = Sum[ (k+q)^(-s), {k,0,Infinity} ]

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_hzeta> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hzeta = \&PDL::gsl_sf_hzeta;






=head2 gsl_sf_eta

=for sig

 Signature: (double x(); double [o]y(); double [o]e())
 Types: (double)

=for usage

 ($y, $e) = gsl_sf_eta($x);
 gsl_sf_eta($x, $y, $e);    # all arguments given
 ($y, $e) = $x->gsl_sf_eta; # method call
 $x->gsl_sf_eta($y, $e);

=for ref

Eta Function eta(s) = (1-2^(1-s)) zeta(s)

=pod

Broadcasts over its inputs.

=for bad

C<gsl_sf_eta> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_eta = \&PDL::gsl_sf_eta;







#line 64 "lib/PDL/GSL/SF.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 6325 "lib/PDL/GSL/SF.pm"

# Exit with OK status

1;
