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
#line 40 "lib/PDL/GSL/SF.pm"


=head1 FUNCTIONS

=cut






=head2 gsl_sf_airy_Ai

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Airy Function Ai(x).

=for bad

gsl_sf_airy_Ai does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai = \&PDL::gsl_sf_airy_Ai;






=head2 gsl_sf_airy_Bi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Airy Function Bi(x).

=for bad

gsl_sf_airy_Bi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi = \&PDL::gsl_sf_airy_Bi;






=head2 gsl_sf_airy_Ai_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Scaled Airy Function Ai(x). Ai(x) for x < 0  and exp(+2/3 x^{3/2}) Ai(x) for  x > 0.

=for bad

gsl_sf_airy_Ai_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai_scaled = \&PDL::gsl_sf_airy_Ai_scaled;






=head2 gsl_sf_airy_Bi_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Scaled Airy Function Bi(x). Bi(x) for x < 0  and exp(+2/3 x^{3/2}) Bi(x) for  x > 0.

=for bad

gsl_sf_airy_Bi_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi_scaled = \&PDL::gsl_sf_airy_Bi_scaled;






=head2 gsl_sf_airy_Ai_deriv

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Airy Function Ai`(x).

=for bad

gsl_sf_airy_Ai_deriv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai_deriv = \&PDL::gsl_sf_airy_Ai_deriv;






=head2 gsl_sf_airy_Bi_deriv

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Airy Function Bi`(x).

=for bad

gsl_sf_airy_Bi_deriv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi_deriv = \&PDL::gsl_sf_airy_Bi_deriv;






=head2 gsl_sf_airy_Ai_deriv_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Scaled Airy Function Ai(x). Ai`(x) for x < 0  and exp(+2/3 x^{3/2}) Ai`(x) for  x > 0.

=for bad

gsl_sf_airy_Ai_deriv_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Ai_deriv_scaled = \&PDL::gsl_sf_airy_Ai_deriv_scaled;






=head2 gsl_sf_airy_Bi_deriv_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Derivative Scaled Airy Function Bi(x). Bi`(x) for x < 0  and exp(+2/3 x^{3/2}) Bi`(x) for  x > 0.

=for bad

gsl_sf_airy_Bi_deriv_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_airy_Bi_deriv_scaled = \&PDL::gsl_sf_airy_Bi_deriv_scaled;






=head2 gsl_sf_bessel_Jn

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Regular Bessel Function J_n(x).

=for bad

gsl_sf_bessel_Jn does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Jn = \&PDL::gsl_sf_bessel_Jn;






=head2 gsl_sf_bessel_Jn_array

=for sig

  Signature: (double x(); double [o]y(num); int s; IV n=>num)

=for ref

Array of Regular Bessel Functions J_{s}(x) to J_{s+n-1}(x).

=for bad

gsl_sf_bessel_Jn_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Jn_array = \&PDL::gsl_sf_bessel_Jn_array;






=head2 gsl_sf_bessel_Yn

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

IrRegular Bessel Function Y_n(x).

=for bad

gsl_sf_bessel_Yn does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Yn = \&PDL::gsl_sf_bessel_Yn;






=head2 gsl_sf_bessel_Yn_array

=for sig

  Signature: (double x(); double [o]y(num); int s; IV n=>num)

=for ref

Array of Regular Bessel Functions Y_{s}(x) to Y_{s+n-1}(x).

=for bad

gsl_sf_bessel_Yn_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Yn_array = \&PDL::gsl_sf_bessel_Yn_array;






=head2 gsl_sf_bessel_In

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Regular Modified Bessel Function I_n(x).

=for bad

gsl_sf_bessel_In does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_In = \&PDL::gsl_sf_bessel_In;






=head2 gsl_sf_bessel_I_array

=for sig

  Signature: (double x(); double [o]y(num); int s; IV n=>num)

=for ref

Array of Regular Modified Bessel Functions I_{s}(x) to I_{s+n-1}(x).

=for bad

gsl_sf_bessel_I_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_I_array = \&PDL::gsl_sf_bessel_I_array;






=head2 gsl_sf_bessel_In_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled Regular Modified Bessel Function exp(-|x|) I_n(x).

=for bad

gsl_sf_bessel_In_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_In_scaled = \&PDL::gsl_sf_bessel_In_scaled;






=head2 gsl_sf_bessel_In_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int s; IV n=>num)

=for ref

Array of Scaled Regular Modified Bessel Functions exp(-|x|) I_{s}(x) to exp(-|x|) I_{s+n-1}(x).

=for bad

gsl_sf_bessel_In_scaled_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_In_scaled_array = \&PDL::gsl_sf_bessel_In_scaled_array;






=head2 gsl_sf_bessel_Kn

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

IrRegular Modified Bessel Function K_n(x).

=for bad

gsl_sf_bessel_Kn does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Kn = \&PDL::gsl_sf_bessel_Kn;






=head2 gsl_sf_bessel_K_array

=for sig

  Signature: (double x(); double [o]y(num); int s; IV n=>num)

=for ref

Array of IrRegular Modified Bessel Functions K_{s}(x) to K_{s+n-1}(x).

=for bad

gsl_sf_bessel_K_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_K_array = \&PDL::gsl_sf_bessel_K_array;






=head2 gsl_sf_bessel_Kn_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled IrRegular Modified Bessel Function exp(-|x|) K_n(x).

=for bad

gsl_sf_bessel_Kn_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Kn_scaled = \&PDL::gsl_sf_bessel_Kn_scaled;






=head2 gsl_sf_bessel_Kn_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int s; IV n=>num)

=for ref

Array of Scaled IrRegular Modified Bessel Functions exp(-|x|) K_{s}(x) to exp(-|x|) K_{s+n-1}(x).

=for bad

gsl_sf_bessel_Kn_scaled_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Kn_scaled_array = \&PDL::gsl_sf_bessel_Kn_scaled_array;






=head2 gsl_sf_bessel_jl

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Regular Sphericl Bessel Function J_n(x).

=for bad

gsl_sf_bessel_jl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_jl = \&PDL::gsl_sf_bessel_jl;






=head2 gsl_sf_bessel_jl_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Spherical Regular Bessel Functions J_{0}(x) to J_{n-1}(x).

=for bad

gsl_sf_bessel_jl_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_jl_array = \&PDL::gsl_sf_bessel_jl_array;






=head2 gsl_sf_bessel_yl

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

IrRegular Spherical Bessel Function y_n(x).

=for bad

gsl_sf_bessel_yl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_yl = \&PDL::gsl_sf_bessel_yl;






=head2 gsl_sf_bessel_yl_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Regular Spherical Bessel Functions y_{0}(x) to y_{n-1}(x).

=for bad

gsl_sf_bessel_yl_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_yl_array = \&PDL::gsl_sf_bessel_yl_array;






=head2 gsl_sf_bessel_il_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled Regular Modified Spherical Bessel Function exp(-|x|) i_n(x).

=for bad

gsl_sf_bessel_il_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_il_scaled = \&PDL::gsl_sf_bessel_il_scaled;






=head2 gsl_sf_bessel_il_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Scaled Regular Modified Spherical Bessel Functions exp(-|x|) i_{0}(x) to exp(-|x|) i_{n-1}(x).

=for bad

gsl_sf_bessel_il_scaled_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_il_scaled_array = \&PDL::gsl_sf_bessel_il_scaled_array;






=head2 gsl_sf_bessel_kl_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled IrRegular Modified Spherical Bessel Function exp(-|x|) k_n(x).

=for bad

gsl_sf_bessel_kl_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_kl_scaled = \&PDL::gsl_sf_bessel_kl_scaled;






=head2 gsl_sf_bessel_kl_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Scaled IrRegular Modified Spherical Bessel Functions exp(-|x|) k_{s}(x) to exp(-|x|) k_{s+n-1}(x).

=for bad

gsl_sf_bessel_kl_scaled_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_kl_scaled_array = \&PDL::gsl_sf_bessel_kl_scaled_array;






=head2 gsl_sf_bessel_Jnu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Regular Cylindrical Bessel Function J_nu(x).

=for bad

gsl_sf_bessel_Jnu does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Jnu = \&PDL::gsl_sf_bessel_Jnu;






=head2 gsl_sf_bessel_Ynu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

IrRegular Cylindrical Bessel Function J_nu(x).

=for bad

gsl_sf_bessel_Ynu does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Ynu = \&PDL::gsl_sf_bessel_Ynu;






=head2 gsl_sf_bessel_Inu_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Scaled Modified Cylindrical Bessel Function exp(-|x|) I_nu(x).

=for bad

gsl_sf_bessel_Inu_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Inu_scaled = \&PDL::gsl_sf_bessel_Inu_scaled;






=head2 gsl_sf_bessel_Inu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Modified Cylindrical Bessel Function I_nu(x).

=for bad

gsl_sf_bessel_Inu does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Inu = \&PDL::gsl_sf_bessel_Inu;






=head2 gsl_sf_bessel_Knu_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Scaled Modified Cylindrical Bessel Function exp(-|x|) K_nu(x).

=for bad

gsl_sf_bessel_Knu_scaled does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Knu_scaled = \&PDL::gsl_sf_bessel_Knu_scaled;






=head2 gsl_sf_bessel_Knu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Modified Cylindrical Bessel Function K_nu(x).

=for bad

gsl_sf_bessel_Knu does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_Knu = \&PDL::gsl_sf_bessel_Knu;






=head2 gsl_sf_bessel_lnKnu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Logarithm of Modified Cylindrical Bessel Function K_nu(x).

=for bad

gsl_sf_bessel_lnKnu does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_bessel_lnKnu = \&PDL::gsl_sf_bessel_lnKnu;






=head2 gsl_sf_clausen

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Clausen Integral. Cl_2(x) := Integrate[-Log[2 Sin[t/2]], {t,0,x}]

=for bad

gsl_sf_clausen does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_clausen = \&PDL::gsl_sf_clausen;






=head2 gsl_sf_hydrogenicR

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n; int l; double z)

=for ref

Normalized Hydrogenic bound states. Radial dipendence.

=for bad

gsl_sf_hydrogenicR does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hydrogenicR = \&PDL::gsl_sf_hydrogenicR;






=head2 gsl_sf_coulomb_wave_FGp_array

=for sig

  Signature: (double x(); double [o]fc(n); double [o]fcp(n); double [o]gc(n); double [o]gcp(n); int [o]ovfw(); double [o]fe(n); double [o]ge(n); double lam_min; IV kmax=>n; double eta)

=for ref

 Coulomb wave functions F_{lam_F}(eta,x), G_{lam_G}(eta,x) and their derivatives; lam_G := lam_F - k_lam_G. if ovfw is signaled then F_L(eta,x)  =  fc[k_L] * exp(fe) and similar. 

=for bad

gsl_sf_coulomb_wave_FGp_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coulomb_wave_FGp_array = \&PDL::gsl_sf_coulomb_wave_FGp_array;






=head2 gsl_sf_coulomb_wave_sphF_array

=for sig

  Signature: (double x(); double [o]fc(n); int [o]ovfw(); double [o]fe(n); double lam_min; IV kmax=>n; double eta)

=for ref

 Coulomb wave function divided by the argument, F(xi, eta)/xi. This is the function which reduces to spherical Bessel functions in the limit eta->0. 

=for bad

gsl_sf_coulomb_wave_sphF_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coulomb_wave_sphF_array = \&PDL::gsl_sf_coulomb_wave_sphF_array;






=head2 gsl_sf_coulomb_CL_e

=for sig

  Signature: (double L(); double eta();  double [o]y(); double [o]e())

=for ref

Coulomb wave function normalization constant. [Abramowitz+Stegun 14.1.8, 14.1.9].

=for bad

gsl_sf_coulomb_CL_e does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coulomb_CL_e = \&PDL::gsl_sf_coulomb_CL_e;






=head2 gsl_sf_coupling_3j

=for sig

  Signature: (ja(); jb(); jc(); ma(); mb(); mc(); double [o]y(); double [o]e())

=for ref

3j Symbols:  (ja jb jc) over (ma mb mc).

=for bad

gsl_sf_coupling_3j does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_3j = \&PDL::gsl_sf_coupling_3j;






=head2 gsl_sf_coupling_6j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); double [o]y(); double [o]e())

=for ref

6j Symbols:  (ja jb jc) over (jd je jf).

=for bad

gsl_sf_coupling_6j does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_6j = \&PDL::gsl_sf_coupling_6j;






=head2 gsl_sf_coupling_9j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); jg(); jh(); ji(); double [o]y(); double [o]e())

=for ref

9j Symbols:  (ja jb jc) over (jd je jf) over (jg jh ji).

=for bad

gsl_sf_coupling_9j does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_coupling_9j = \&PDL::gsl_sf_coupling_9j;






=head2 gsl_sf_dawson

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Dawsons integral: Exp[-x^2] Integral[ Exp[t^2], {t,0,x}]

=for bad

gsl_sf_dawson does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_dawson = \&PDL::gsl_sf_dawson;






=head2 gsl_sf_debye_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_1 = \&PDL::gsl_sf_debye_1;






=head2 gsl_sf_debye_2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_2 = \&PDL::gsl_sf_debye_2;






=head2 gsl_sf_debye_3

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_3 = \&PDL::gsl_sf_debye_3;






=head2 gsl_sf_debye_4

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

D_n(x) := n/x^n Integrate[t^n/(e^t - 1), {t,0,x}]

=for bad

gsl_sf_debye_4 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_debye_4 = \&PDL::gsl_sf_debye_4;






=head2 gsl_sf_dilog

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

/* Real part of DiLogarithm(x), for real argument. In Lewins notation, this is Li_2(x). Li_2(x) = - Re[ Integrate[ Log[1-s] / s, {s, 0, x}] ]

=for bad

gsl_sf_dilog does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_dilog = \&PDL::gsl_sf_dilog;






=head2 gsl_sf_complex_dilog

=for sig

  Signature: (double r(); double t(); double [o]re(); double [o]im(); double [o]ere(); double [o]eim())

=for ref

DiLogarithm(z), for complex argument z = r Exp[i theta].

=for bad

gsl_sf_complex_dilog does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_dilog = \&PDL::gsl_sf_complex_dilog;






=head2 gsl_sf_multiply

=for sig

  Signature: (double x(); double xx(); double [o]y(); double [o]e())

=for ref

Multiplication.

=for bad

gsl_sf_multiply does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_multiply = \&PDL::gsl_sf_multiply;






=head2 gsl_sf_multiply_err

=for sig

  Signature: (double x(); double xe(); double xx(); double xxe(); double [o]y(); double [o]e())

=for ref

Multiplication with associated errors.

=for bad

gsl_sf_multiply_err does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_multiply_err = \&PDL::gsl_sf_multiply_err;






=head2 gsl_sf_ellint_Kcomp

=for sig

  Signature: (double k(); double [o]y(); double [o]e())

=for ref

Legendre form of complete elliptic integrals K(k) = Integral[1/Sqrt[1 - k^2 Sin[t]^2], {t, 0, Pi/2}].

=for bad

gsl_sf_ellint_Kcomp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_Kcomp = \&PDL::gsl_sf_ellint_Kcomp;






=head2 gsl_sf_ellint_Ecomp

=for sig

  Signature: (double k(); double [o]y(); double [o]e())

=for ref

Legendre form of complete elliptic integrals E(k) = Integral[  Sqrt[1 - k^2 Sin[t]^2], {t, 0, Pi/2}]

=for bad

gsl_sf_ellint_Ecomp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_Ecomp = \&PDL::gsl_sf_ellint_Ecomp;






=head2 gsl_sf_ellint_F

=for sig

  Signature: (double phi(); double k(); double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals F(phi,k)   = Integral[1/Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=for bad

gsl_sf_ellint_F does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_F = \&PDL::gsl_sf_ellint_F;






=head2 gsl_sf_ellint_E

=for sig

  Signature: (double phi(); double k(); double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals E(phi,k)   = Integral[  Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=for bad

gsl_sf_ellint_E does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_E = \&PDL::gsl_sf_ellint_E;






=head2 gsl_sf_ellint_P

=for sig

  Signature: (double phi(); double k(); double n();
              double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals P(phi,k,n) = Integral[(1 + n Sin[t]^2)^(-1)/Sqrt[1 - k^2 Sin[t]^2], {t, 0, phi}]

=for bad

gsl_sf_ellint_P does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_P = \&PDL::gsl_sf_ellint_P;






=head2 gsl_sf_ellint_D

=for sig

  Signature: (double phi(); double k();
              double [o]y(); double [o]e())

=for ref

Legendre form of incomplete elliptic integrals D(phi,k)

=for bad

gsl_sf_ellint_D does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_D = \&PDL::gsl_sf_ellint_D;






=head2 gsl_sf_ellint_RC

=for sig

  Signature: (double x(); double yy(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RC(x,y)   = 1/2 Integral[(t+x)^(-1/2) (t+y)^(-1)], {t,0,Inf}

=for bad

gsl_sf_ellint_RC does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RC = \&PDL::gsl_sf_ellint_RC;






=head2 gsl_sf_ellint_RD

=for sig

  Signature: (double x(); double yy(); double z(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RD(x,y,z) = 3/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-3/2), {t,0,Inf}]

=for bad

gsl_sf_ellint_RD does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RD = \&PDL::gsl_sf_ellint_RD;






=head2 gsl_sf_ellint_RF

=for sig

  Signature: (double x(); double yy(); double z(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RF(x,y,z) = 1/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-1/2), {t,0,Inf}]

=for bad

gsl_sf_ellint_RF does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RF = \&PDL::gsl_sf_ellint_RF;






=head2 gsl_sf_ellint_RJ

=for sig

  Signature: (double x(); double yy(); double z(); double p(); double [o]y(); double [o]e())

=for ref

Carlsons symmetric basis of functions RJ(x,y,z,p) = 3/2 Integral[(t+x)^(-1/2) (t+y)^(-1/2) (t+z)^(-1/2) (t+p)^(-1), {t,0,Inf}]

=for bad

gsl_sf_ellint_RJ does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_ellint_RJ = \&PDL::gsl_sf_ellint_RJ;






=head2 gsl_sf_elljac

=for sig

  Signature: (double u(); double m(); double [o]sn(); double [o]cn(); double [o]dn())

=for ref

Jacobian elliptic functions sn, dn, cn by descending Landen transformations

=for bad

gsl_sf_elljac does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_elljac = \&PDL::gsl_sf_elljac;






=head2 gsl_sf_erfc

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complementary Error Function erfc(x) := 2/Sqrt[Pi] Integrate[Exp[-t^2], {t,x,Infinity}]

=for bad

gsl_sf_erfc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erfc = \&PDL::gsl_sf_erfc;






=head2 gsl_sf_log_erfc

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Log Complementary Error Function

=for bad

gsl_sf_log_erfc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_log_erfc = \&PDL::gsl_sf_log_erfc;






=head2 gsl_sf_erf

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Error Function erf(x) := 2/Sqrt[Pi] Integrate[Exp[-t^2], {t,0,x}]

=for bad

gsl_sf_erf does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erf = \&PDL::gsl_sf_erf;






=head2 gsl_sf_erf_Z

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Z(x) :  Abramowitz+Stegun 26.2.1

=for bad

gsl_sf_erf_Z does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erf_Z = \&PDL::gsl_sf_erf_Z;






=head2 gsl_sf_erf_Q

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Q(x) :  Abramowitz+Stegun 26.2.1

=for bad

gsl_sf_erf_Q does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_erf_Q = \&PDL::gsl_sf_erf_Q;






=head2 gsl_sf_exp

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Exponential

=for bad

gsl_sf_exp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_exp = \&PDL::gsl_sf_exp;






=head2 gsl_sf_exprel_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

N-relative Exponential. exprel_N(x) = N!/x^N (exp(x) - Sum[x^k/k!, {k,0,N-1}]) = 1 + x/(N+1) + x^2/((N+1)(N+2)) + ... = 1F1(1,1+N,x)

=for bad

gsl_sf_exprel_n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_exprel_n = \&PDL::gsl_sf_exprel_n;






=head2 gsl_sf_exp_err

=for sig

  Signature: (double x(); double dx(); double [o]y(); double [o]e())

=for ref

Exponential of a quantity with given error.

=for bad

gsl_sf_exp_err does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_exp_err = \&PDL::gsl_sf_exp_err;






=head2 gsl_sf_expint_E1

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

E_1(x) := Re[ Integrate[ Exp[-xt]/t, {t,1,Infinity}] ]

=for bad

gsl_sf_expint_E1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_E1 = \&PDL::gsl_sf_expint_E1;






=head2 gsl_sf_expint_E2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

E_2(x) := Re[ Integrate[ Exp[-xt]/t^2, {t,1,Infity}] ]

=for bad

gsl_sf_expint_E2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_E2 = \&PDL::gsl_sf_expint_E2;






=head2 gsl_sf_expint_Ei

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Ei(x) := PV Integrate[ Exp[-t]/t, {t,-x,Infinity}]

=for bad

gsl_sf_expint_Ei does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_Ei = \&PDL::gsl_sf_expint_Ei;






=head2 gsl_sf_Shi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Shi(x) := Integrate[ Sinh[t]/t, {t,0,x}]

=for bad

gsl_sf_Shi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Shi = \&PDL::gsl_sf_Shi;






=head2 gsl_sf_Chi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Chi(x) := Re[ M_EULER + log(x) + Integrate[(Cosh[t]-1)/t, {t,0,x}] ]

=for bad

gsl_sf_Chi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Chi = \&PDL::gsl_sf_Chi;






=head2 gsl_sf_expint_3

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Ei_3(x) := Integral[ Exp[-t^3], {t,0,x}]

=for bad

gsl_sf_expint_3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_expint_3 = \&PDL::gsl_sf_expint_3;






=head2 gsl_sf_Si

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Si(x) := Integrate[ Sin[t]/t, {t,0,x}]

=for bad

gsl_sf_Si does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Si = \&PDL::gsl_sf_Si;






=head2 gsl_sf_Ci

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Ci(x) := -Integrate[ Cos[t]/t, {t,x,Infinity}]

=for bad

gsl_sf_Ci does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_Ci = \&PDL::gsl_sf_Ci;






=head2 gsl_sf_atanint

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

AtanInt(x) := Integral[ Arctan[t]/t, {t,0,x}]

=for bad

gsl_sf_atanint does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_atanint = \&PDL::gsl_sf_atanint;






=head2 gsl_sf_fermi_dirac_int

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int j)

=for ref

Complete integral F_j(x) for integer j

=for bad

gsl_sf_fermi_dirac_int does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_int = \&PDL::gsl_sf_fermi_dirac_int;






=head2 gsl_sf_fermi_dirac_mhalf

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complete integral F_{-1/2}(x)

=for bad

gsl_sf_fermi_dirac_mhalf does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_mhalf = \&PDL::gsl_sf_fermi_dirac_mhalf;






=head2 gsl_sf_fermi_dirac_half

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complete integral F_{1/2}(x)

=for bad

gsl_sf_fermi_dirac_half does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_half = \&PDL::gsl_sf_fermi_dirac_half;






=head2 gsl_sf_fermi_dirac_3half

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complete integral F_{3/2}(x)

=for bad

gsl_sf_fermi_dirac_3half does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_3half = \&PDL::gsl_sf_fermi_dirac_3half;






=head2 gsl_sf_fermi_dirac_inc_0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double b)

=for ref

Incomplete integral F_0(x,b) = ln(1 + e^(b-x)) - (b-x)

=for bad

gsl_sf_fermi_dirac_inc_0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fermi_dirac_inc_0 = \&PDL::gsl_sf_fermi_dirac_inc_0;






=head2 gsl_sf_lngamma

=for sig

  Signature: (double x(); double [o]y(); double [o]s(); double [o]e())

=for ref

Log[Gamma(x)], x not a negative integer Uses real Lanczos method. Determines the sign of Gamma[x] as well as Log[|Gamma[x]|] for x < 0. So Gamma[x] = sgn * Exp[result_lg].

=for bad

gsl_sf_lngamma does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lngamma = \&PDL::gsl_sf_lngamma;






=head2 gsl_sf_gamma

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Gamma(x), x not a negative integer

=for bad

gsl_sf_gamma does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma = \&PDL::gsl_sf_gamma;






=head2 gsl_sf_gammastar

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Regulated Gamma Function, x > 0 Gamma^*(x) = Gamma(x)/(Sqrt[2Pi] x^(x-1/2) exp(-x)) = (1 + 1/(12x) + ...),  x->Inf

=for bad

gsl_sf_gammastar does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gammastar = \&PDL::gsl_sf_gammastar;






=head2 gsl_sf_gammainv

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

1/Gamma(x)

=for bad

gsl_sf_gammainv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gammainv = \&PDL::gsl_sf_gammainv;






=head2 gsl_sf_lngamma_complex

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Log[Gamma(z)] for z complex, z not a negative integer. Calculates: lnr = log|Gamma(z)|, arg = arg(Gamma(z))  in (-Pi, Pi]

=for bad

gsl_sf_lngamma_complex does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lngamma_complex = \&PDL::gsl_sf_lngamma_complex;






=head2 gsl_sf_taylorcoeff

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

x^n / n!

=for bad

gsl_sf_taylorcoeff does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_taylorcoeff = \&PDL::gsl_sf_taylorcoeff;






=head2 gsl_sf_fact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

n!

=for bad

gsl_sf_fact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_fact = \&PDL::gsl_sf_fact;






=head2 gsl_sf_doublefact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

n!! = n(n-2)(n-4)

=for bad

gsl_sf_doublefact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_doublefact = \&PDL::gsl_sf_doublefact;






=head2 gsl_sf_lnfact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

ln n!

=for bad

gsl_sf_lnfact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnfact = \&PDL::gsl_sf_lnfact;






=head2 gsl_sf_lndoublefact

=for sig

  Signature: (x(); double [o]y(); double [o]e())

=for ref

ln n!!

=for bad

gsl_sf_lndoublefact does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lndoublefact = \&PDL::gsl_sf_lndoublefact;






=head2 gsl_sf_lnchoose

=for sig

  Signature: (n(); m(); double [o]y(); double [o]e())

=for ref

log(n choose m)

=for bad

gsl_sf_lnchoose does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnchoose = \&PDL::gsl_sf_lnchoose;






=head2 gsl_sf_choose

=for sig

  Signature: (n(); m(); double [o]y(); double [o]e())

=for ref

n choose m

=for bad

gsl_sf_choose does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_choose = \&PDL::gsl_sf_choose;






=head2 gsl_sf_lnpoch

=for sig

  Signature: (double x(); double [o]y(); double [o]s(); double [o]e(); double a)

=for ref

Logarithm of Pochammer (Apell) symbol, with sign information. result = log( |(a)_x| ), sgn    = sgn( (a)_x ) where (a)_x := Gamma[a + x]/Gamma[a]

=for bad

gsl_sf_lnpoch does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnpoch = \&PDL::gsl_sf_lnpoch;






=head2 gsl_sf_poch

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Pochammer (Apell) symbol (a)_x := Gamma[a + x]/Gamma[x]

=for bad

gsl_sf_poch does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_poch = \&PDL::gsl_sf_poch;






=head2 gsl_sf_pochrel

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Relative Pochammer (Apell) symbol ((a,x) - 1)/x where (a,x) = (a)_x := Gamma[a + x]/Gamma[a]

=for bad

gsl_sf_pochrel does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_pochrel = \&PDL::gsl_sf_pochrel;






=head2 gsl_sf_gamma_inc_Q

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Normalized Incomplete Gamma Function Q(a,x) = 1/Gamma(a) Integral[ t^(a-1) e^(-t), {t,x,Infinity} ]

=for bad

gsl_sf_gamma_inc_Q does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma_inc_Q = \&PDL::gsl_sf_gamma_inc_Q;






=head2 gsl_sf_gamma_inc_P

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a)

=for ref

Complementary Normalized Incomplete Gamma Function P(a,x) = 1/Gamma(a) Integral[ t^(a-1) e^(-t), {t,0,x} ]

=for bad

gsl_sf_gamma_inc_P does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gamma_inc_P = \&PDL::gsl_sf_gamma_inc_P;






=head2 gsl_sf_lnbeta

=for sig

  Signature: (double a(); double b(); double [o]y(); double [o]e())

=for ref

Logarithm of Beta Function Log[B(a,b)]

=for bad

gsl_sf_lnbeta does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnbeta = \&PDL::gsl_sf_lnbeta;






=head2 gsl_sf_beta

=for sig

  Signature: (double a(); double b();double [o]y(); double [o]e())

=for ref

Beta Function B(a,b)

=for bad

gsl_sf_beta does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_beta = \&PDL::gsl_sf_beta;






=head2 gsl_sf_gegenpoly_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n; double lambda)

=for ref

Evaluate Gegenbauer polynomials.

=for bad

gsl_sf_gegenpoly_n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gegenpoly_n = \&PDL::gsl_sf_gegenpoly_n;






=head2 gsl_sf_gegenpoly_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num; double lambda)

=for ref

Calculate array of Gegenbauer polynomials from 0 to n-1.

=for bad

gsl_sf_gegenpoly_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_gegenpoly_array = \&PDL::gsl_sf_gegenpoly_array;






=head2 gsl_sf_hyperg_0F1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double c)

=for ref

/* Hypergeometric function related to Bessel functions 0F1[c,x] = Gamma[c]    x^(1/2(1-c)) I_{c-1}(2 Sqrt[x]) Gamma[c] (-x)^(1/2(1-c)) J_{c-1}(2 Sqrt[-x])

=for bad

gsl_sf_hyperg_0F1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_0F1 = \&PDL::gsl_sf_hyperg_0F1;






=head2 gsl_sf_hyperg_1F1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b)

=for ref

Confluent hypergeometric function  for integer parameters. 1F1[a,b,x] = M(a,b,x)

=for bad

gsl_sf_hyperg_1F1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_1F1 = \&PDL::gsl_sf_hyperg_1F1;






=head2 gsl_sf_hyperg_U

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b)

=for ref

Confluent hypergeometric function  for integer parameters. U(a,b,x)

=for bad

gsl_sf_hyperg_U does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_U = \&PDL::gsl_sf_hyperg_U;






=head2 gsl_sf_hyperg_2F1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Confluent hypergeometric function  for integer parameters. 2F1[a,b,c,x]

=for bad

gsl_sf_hyperg_2F1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1 = \&PDL::gsl_sf_hyperg_2F1;






=head2 gsl_sf_hyperg_2F1_conj

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Gauss hypergeometric function 2F1[aR + I aI, aR - I aI, c, x]

=for bad

gsl_sf_hyperg_2F1_conj does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1_conj = \&PDL::gsl_sf_hyperg_2F1_conj;






=head2 gsl_sf_hyperg_2F1_renorm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Renormalized Gauss hypergeometric function 2F1[a,b,c,x] / Gamma[c]

=for bad

gsl_sf_hyperg_2F1_renorm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1_renorm = \&PDL::gsl_sf_hyperg_2F1_renorm;






=head2 gsl_sf_hyperg_2F1_conj_renorm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b; double c)

=for ref

Renormalized Gauss hypergeometric function 2F1[aR + I aI, aR - I aI, c, x] / Gamma[c]

=for bad

gsl_sf_hyperg_2F1_conj_renorm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F1_conj_renorm = \&PDL::gsl_sf_hyperg_2F1_conj_renorm;






=head2 gsl_sf_hyperg_2F0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double a; double b)

=for ref

Mysterious hypergeometric function. The series representation is a divergent hypergeometric series. However, for x < 0 we have 2F0(a,b,x) = (-1/x)^a U(a,1+a-b,-1/x)

=for bad

gsl_sf_hyperg_2F0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hyperg_2F0 = \&PDL::gsl_sf_hyperg_2F0;






=head2 gsl_sf_laguerre_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n; double a)

=for ref

Evaluate generalized Laguerre polynomials.

=for bad

gsl_sf_laguerre_n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_laguerre_n = \&PDL::gsl_sf_laguerre_n;






=head2 gsl_sf_legendre_Pl

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l)

=for ref

P_l(x)

=for bad

gsl_sf_legendre_Pl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Pl = \&PDL::gsl_sf_legendre_Pl;






=head2 gsl_sf_legendre_Pl_array

=for sig

  Signature: (double x(); double [o]y(num); int l=>num)

=for ref

P_l(x) from 0 to n-1.

=for bad

gsl_sf_legendre_Pl_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Pl_array = \&PDL::gsl_sf_legendre_Pl_array;






=head2 gsl_sf_legendre_Ql

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l)

=for ref

Q_l(x)

=for bad

gsl_sf_legendre_Ql does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Ql = \&PDL::gsl_sf_legendre_Ql;






=head2 gsl_sf_legendre_Plm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x)

=for bad

gsl_sf_legendre_Plm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_Plm = \&PDL::gsl_sf_legendre_Plm;






=head2 gsl_sf_legendre_array

=for sig

  Signature: (double x(); double [o]y(n=CALC($COMP(lmax)*($COMP(lmax)+1)/2+$COMP(lmax)+1)); double [t]work(wn=CALC(gsl_sf_legendre_array_n($COMP(lmax)))); char norm;  int lmax; int csphase)

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

=for bad

gsl_sf_legendre_array processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_array = \&PDL::gsl_sf_legendre_array;






=head2 gsl_sf_legendre_array_index

=for sig

  Signature: (int [o]l(n=CALC($COMP(lmax)*($COMP(lmax)+1)/2+$COMP(lmax)+1)); int [o]m(n); int lmax)

=for ref

Calculate the relation between gsl_sf_legendre_arrays index and l and m values.

=for usage
($l,$m) = gsl_sf_legendre_array_index($lmax);

Note that this function is called differently than the corresponding GSL function, to make it more useful for PDL: here you just input the maximum l (lmax) that was used in C<gsl_sf_legendre_array> and it calculates all l and m values.

=for bad

gsl_sf_legendre_array_index does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_array_index = \&PDL::gsl_sf_legendre_array_index;






=head2 gsl_sf_legendre_sphPlm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x), normalized properly for use in spherical harmonics

=for bad

gsl_sf_legendre_sphPlm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_sphPlm = \&PDL::gsl_sf_legendre_sphPlm;






=head2 gsl_sf_conicalP_half

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Irregular Spherical Conical Function P^{1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_half does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_half = \&PDL::gsl_sf_conicalP_half;






=head2 gsl_sf_conicalP_mhalf

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_mhalf does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_mhalf = \&PDL::gsl_sf_conicalP_mhalf;






=head2 gsl_sf_conicalP_0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{0}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_0 = \&PDL::gsl_sf_conicalP_0;






=head2 gsl_sf_conicalP_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{1}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_1 = \&PDL::gsl_sf_conicalP_1;






=head2 gsl_sf_conicalP_sph_reg

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2-l}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_sph_reg does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_sph_reg = \&PDL::gsl_sf_conicalP_sph_reg;






=head2 gsl_sf_conicalP_cyl_reg_e

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int m; double lambda)

=for ref

Regular Cylindrical Conical Function P^{-m}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_cyl_reg_e does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_conicalP_cyl_reg_e = \&PDL::gsl_sf_conicalP_cyl_reg_e;






=head2 gsl_sf_legendre_H3d

=for sig

  Signature: (double [o]y(); double [o]e(); int l; double lambda; double eta)

=for ref

lth radial eigenfunction of the Laplacian on the 3-dimensional hyperbolic space.

=for bad

gsl_sf_legendre_H3d does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_H3d = \&PDL::gsl_sf_legendre_H3d;






=head2 gsl_sf_legendre_H3d_array

=for sig

  Signature: (double [o]y(num); int l=>num; double lambda; double eta)

=for ref

Array of H3d(ell), for l from 0 to n-1.

=for bad

gsl_sf_legendre_H3d_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_legendre_H3d_array = \&PDL::gsl_sf_legendre_H3d_array;






=head2 gsl_sf_log

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Provide a logarithm function with GSL semantics.

=for bad

gsl_sf_log does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_log = \&PDL::gsl_sf_log;






=head2 gsl_sf_complex_log

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Complex Logarithm exp(lnr + I theta) = zr + I zi Returns argument in [-pi,pi].

=for bad

gsl_sf_complex_log does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_log = \&PDL::gsl_sf_complex_log;






=head2 gsl_poly_eval

=for sig

  Signature: (double x(); double c(m); double [o]y())

=for ref

c[0] + c[1] x + c[2] x^2 + ... + c[m-1] x^(m-1)

=for bad

gsl_poly_eval does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_poly_eval = \&PDL::gsl_poly_eval;






=head2 gsl_sf_pow_int

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Calculate x^n.

=for bad

gsl_sf_pow_int does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_pow_int = \&PDL::gsl_sf_pow_int;






=head2 gsl_sf_psi

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Di-Gamma Function psi(x).

=for bad

gsl_sf_psi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi = \&PDL::gsl_sf_psi;






=head2 gsl_sf_psi_1piy

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Di-Gamma Function Re[psi(1 + I y)]

=for bad

gsl_sf_psi_1piy does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi_1piy = \&PDL::gsl_sf_psi_1piy;






=head2 gsl_sf_psi_n

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Poly-Gamma Function psi^(n)(x)

=for bad

gsl_sf_psi_n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_psi_n = \&PDL::gsl_sf_psi_n;






=head2 gsl_sf_synchrotron_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

First synchrotron function: synchrotron_1(x) = x Integral[ K_{5/3}(t), {t, x, Infinity}]

=for bad

gsl_sf_synchrotron_1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_synchrotron_1 = \&PDL::gsl_sf_synchrotron_1;






=head2 gsl_sf_synchrotron_2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Second synchroton function: synchrotron_2(x) = x * K_{2/3}(x)

=for bad

gsl_sf_synchrotron_2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_synchrotron_2 = \&PDL::gsl_sf_synchrotron_2;






=head2 gsl_sf_transport_2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(2,x)

=for bad

gsl_sf_transport_2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_2 = \&PDL::gsl_sf_transport_2;






=head2 gsl_sf_transport_3

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(3,x)

=for bad

gsl_sf_transport_3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_3 = \&PDL::gsl_sf_transport_3;






=head2 gsl_sf_transport_4

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(4,x)

=for bad

gsl_sf_transport_4 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_4 = \&PDL::gsl_sf_transport_4;






=head2 gsl_sf_transport_5

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(5,x)

=for bad

gsl_sf_transport_5 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_transport_5 = \&PDL::gsl_sf_transport_5;






=head2 gsl_sf_sin

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Sin(x) with GSL semantics.

=for bad

gsl_sf_sin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_sin = \&PDL::gsl_sf_sin;






=head2 gsl_sf_cos

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Cos(x) with GSL semantics.

=for bad

gsl_sf_cos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_cos = \&PDL::gsl_sf_cos;






=head2 gsl_sf_hypot

=for sig

  Signature: (double x(); double xx(); double [o]y(); double [o]e())

=for ref

Hypot(x,xx) with GSL semantics.

=for bad

gsl_sf_hypot does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hypot = \&PDL::gsl_sf_hypot;






=head2 gsl_sf_complex_sin

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Sin(z) for complex z

=for bad

gsl_sf_complex_sin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_sin = \&PDL::gsl_sf_complex_sin;






=head2 gsl_sf_complex_cos

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Cos(z) for complex z

=for bad

gsl_sf_complex_cos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_cos = \&PDL::gsl_sf_complex_cos;






=head2 gsl_sf_complex_logsin

=for sig

  Signature: (double zr(); double zi(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Log(Sin(z)) for complex z

=for bad

gsl_sf_complex_logsin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_complex_logsin = \&PDL::gsl_sf_complex_logsin;






=head2 gsl_sf_lnsinh

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Log(Sinh(x)) with GSL semantics.

=for bad

gsl_sf_lnsinh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lnsinh = \&PDL::gsl_sf_lnsinh;






=head2 gsl_sf_lncosh

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Log(Cos(x)) with GSL semantics.

=for bad

gsl_sf_lncosh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_lncosh = \&PDL::gsl_sf_lncosh;






=head2 gsl_sf_polar_to_rect

=for sig

  Signature: (double r(); double t(); double [o]x(); double [o]y(); double [o]xe(); double [o]ye())

=for ref

Convert polar to rectlinear coordinates.

=for bad

gsl_sf_polar_to_rect does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_polar_to_rect = \&PDL::gsl_sf_polar_to_rect;






=head2 gsl_sf_rect_to_polar

=for sig

  Signature: (double x(); double y(); double [o]r(); double [o]t(); double [o]re(); double [o]te())

=for ref

Convert rectlinear to polar coordinates. return argument in range [-pi, pi].

=for bad

gsl_sf_rect_to_polar does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_rect_to_polar = \&PDL::gsl_sf_rect_to_polar;






=head2 gsl_sf_angle_restrict_symm

=for sig

  Signature: (double [o]y())

=for ref

Force an angle to lie in the range (-pi,pi].

=for bad

gsl_sf_angle_restrict_symm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_angle_restrict_symm = \&PDL::gsl_sf_angle_restrict_symm;






=head2 gsl_sf_angle_restrict_pos

=for sig

  Signature: (double [o]y())

=for ref

Force an angle to lie in the range [0,2 pi).

=for bad

gsl_sf_angle_restrict_pos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_angle_restrict_pos = \&PDL::gsl_sf_angle_restrict_pos;






=head2 gsl_sf_sin_err

=for sig

  Signature: (double x(); double dx(); double [o]y(); double [o]e())

=for ref

Sin(x) for quantity with an associated error.

=for bad

gsl_sf_sin_err does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_sin_err = \&PDL::gsl_sf_sin_err;






=head2 gsl_sf_cos_err

=for sig

  Signature: (double x(); double dx(); double [o]y(); double [o]e())

=for ref

Cos(x) for quantity with an associated error.

=for bad

gsl_sf_cos_err does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_cos_err = \&PDL::gsl_sf_cos_err;






=head2 gsl_sf_zeta

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Riemann Zeta Function zeta(x) = Sum[ k^(-s), {k,1,Infinity} ], s != 1.0

=for bad

gsl_sf_zeta does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_zeta = \&PDL::gsl_sf_zeta;






=head2 gsl_sf_hzeta

=for sig

  Signature: (double s(); double [o]y(); double [o]e(); double q)

=for ref

Hurwicz Zeta Function zeta(s,q) = Sum[ (k+q)^(-s), {k,0,Infinity} ]

=for bad

gsl_sf_hzeta does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gsl_sf_hzeta = \&PDL::gsl_sf_hzeta;






=head2 gsl_sf_eta

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Eta Function eta(s) = (1-2^(1-s)) zeta(s)

=for bad

gsl_sf_eta does not process bad values.
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
#line 4419 "lib/PDL/GSL/SF.pm"

# Exit with OK status

1;
