
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::COULOMB;

@EXPORT_OK  = qw( PDL::PP gsl_sf_hydrogenicR PDL::PP gsl_sf_coulomb_wave_FGp_array PDL::PP gsl_sf_coulomb_wave_sphF_array PDL::PP gsl_sf_coulomb_CL_e );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::COULOMB ;




=head1 NAME

PDL::GSLSF::COULOMB - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_hydrogenicR

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n; int l; double z)

=for ref

Normalized Hydrogenic bound states. Radial dipendence.

=for bad

gsl_sf_hydrogenicR does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hydrogenicR = \&PDL::gsl_sf_hydrogenicR;





=head2 gsl_sf_coulomb_wave_FGp_array

=for sig

  Signature: (double x(); double [o]fc(n); double [o]fcp(n); double [o]gc(n); double [o]gcp(n); int [o]ovfw(); double [o]fe(n); double [o]ge(n); double lam_min; int kmax=>n; double eta)

=for ref

 Coulomb wave functions F_{lam_F}(eta,x), G_{lam_G}(eta,x) and their derivatives; lam_G := lam_F - k_lam_G. if ovfw is signaled then F_L(eta,x)  =  fc[k_L] * exp(fe) and similar. 

=for bad

gsl_sf_coulomb_wave_FGp_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_coulomb_wave_FGp_array = \&PDL::gsl_sf_coulomb_wave_FGp_array;





=head2 gsl_sf_coulomb_wave_sphF_array

=for sig

  Signature: (double x(); double [o]fc(n); int [o]ovfw(); double [o]fe(n); double lam_min; int kmax=>n; double eta)

=for ref

 Coulomb wave function divided by the argument, F(xi, eta)/xi. This is the function which reduces to spherical Bessel functions in the limit eta->0. 

=for bad

gsl_sf_coulomb_wave_sphF_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_coulomb_wave_sphF_array = \&PDL::gsl_sf_coulomb_wave_sphF_array;





=head2 gsl_sf_coulomb_CL_e

=for sig

  Signature: (double L(); double eta();  double [o]y(); double [o]e())

=for ref

Coulomb wave function normalization constant. [Abramowitz+Stegun 14.1.8, 14.1.9].

=for bad

gsl_sf_coulomb_CL_e does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_coulomb_CL_e = \&PDL::gsl_sf_coulomb_CL_e;



;

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut






# Exit with OK status

1;

		   