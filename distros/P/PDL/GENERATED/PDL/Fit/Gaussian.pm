
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Fit::Gaussian;

@EXPORT_OK  = qw( PDL::PP fitgauss1d PDL::PP fitgauss1dr );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Fit::Gaussian ;




=head1 NAME

PDL::Fit::Gaussian - routines for fitting gaussians

=head1 DESCRIPTION


This module contains some custom gaussian fitting routines.
These were developed in collaboration with Alison Offer,
they do a reasonably robust job and are quite useful.

Gaussian fitting is something I do a lot of, so I figured
it was worth putting in my special code.

Note it is not clear to me that this code is fully debugged. The reason
I say that is because I tried using the internal linear eqn solving 
C routines called elsewhere and they were giving erroneous results. 
So steal from this code with caution! However it does give good fits to 
reasonable looking gaussians and tests show correct parameters.
    
             KGB 29/Oct/2002

=head1 SYNOPSIS

        use PDL;
        use PDL::Fit::Gaussian;
        ($cen, $pk, $fwhm, $back, $err, $fit) = fitgauss1d($x, $data);
        ($pk, $fwhm, $back, $err, $fit) = fitgauss1dr($r, $data);

=head1 FUNCTIONS

=head2 fitgauss1d

=for ref

Fit 1D Gassian to data piddle

=for example

  ($cen, $pk, $fwhm, $back, $err, $fit) = fitgauss1d($x, $data);

=for usage

  ($cen, $pk, $fwhm, $back, $err, $fit) = fitgauss1d($x, $data);

=for signature

  xval(n); data(n); [o]xcentre();[o]peak_ht(); [o]fwhm(); 
  [o]background();int [o]err(); [o]datafit(n); 
  [t]sig(n); [t]ytmp(n); [t]yytmp(n); [t]rtmp(n);

Fits a 1D Gaussian robustly free parameters are the centre, peak height,
FWHM. The background is NOT fit, because I find this is generally
unreliable, rather a median is determined in the 'outer' 10% of
pixels (i.e. those at the start/end of the data piddle). The initial
estimate of the FWHM is the length of the piddle/3, so it might fail
if the piddle is too long. (This is non-robust anyway). Most data
does just fine and this is a good default gaussian fitter.

SEE ALSO: fitgauss1dr() for fitting radial gaussians

=head2 fitgauss1dr

=for ref

Fit 1D Gassian to radial data piddle

=for example

  ($pk, $fwhm2, $back, $err, $fit) = fitgauss1dr($r, $data);

=for usage

  ($pk, $fwhm2, $back, $err, $fit) = fitgauss1dr($r, $data);

=for signature

  xval(n); data(n); [o]peak_ht(); [o]fwhm(); 
  [o]background();int [o]err(); [o]datafit(n); 
  [t]sig(n); [t]ytmp(n); [t]yytmp(n); [t]rtmp(n);

Fits a 1D radial Gaussian robustly free parameters are the peak height,
FWHM. Centre is assumed to be X=0 (i.e. start of piddle).
The background is NOT fit, because I find this is generally
unreliable, rather a median is determined in the 'outer' 10% of
pixels (i.e. those at the end of the data piddle). The initial
estimate of the FWHM is the length of the piddle/3, so it might fail
if the piddle is too long. (This is non-robust anyway). Most data
does just fine and this is a good default gaussian fitter.

SEE ALSO: fitgauss1d() to fit centre as well.

=cut









*fitgauss1d = \&PDL::fitgauss1d;





*fitgauss1dr = \&PDL::fitgauss1dr;




1; # OK




=head1 BUGS

May not converge for weird data, still pretty good!

=head1 AUTHOR

This file copyright (C) 1999, Karl Glazebrook (kgb@aaoepp.aao.gov.au),
Gaussian fitting code by Alison Offer
(aro@aaocbn.aao.gov.au).  All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.


=cut



;



# Exit with OK status

1;

		   