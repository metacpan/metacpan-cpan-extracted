

# Test Script for the PDLA interface to the GSL library
#  This tests only that the interface is working, i.e. that the
#   functions can be called. The actual return values are not
#   checked.
#  The GSL library already has a extensive test suite, and we
#  do not want to duplicate that effort here.

use PDLA::LiteF;
use Test::More;
use strict;

BEGIN
{
   use PDLA::Config;
   if ( $PDLA::Config{WITH_GSL} ) {
       my $v = `gsl-config --version`;
       eval "
	  use PDLA::GSLSF::AIRY;
	  use PDLA::GSLSF::BESSEL;
	  use PDLA::GSLSF::CLAUSEN;
	  use PDLA::GSLSF::COULOMB;
	  use PDLA::GSLSF::COUPLING;
	  use PDLA::GSLSF::DAWSON;
	  use PDLA::GSLSF::DEBYE;
	  use PDLA::GSLSF::DILOG;
	  use PDLA::GSLSF::ELEMENTARY;
	  use PDLA::GSLSF::ELLINT;
	  use PDLA::GSLSF::ELLJAC;
	  use PDLA::GSLSF::ERF;
	  use PDLA::GSLSF::EXP;
	  use PDLA::GSLSF::EXPINT;
	  use PDLA::GSLSF::FERMI_DIRAC;
	  use PDLA::GSLSF::GAMMA;
	  use PDLA::GSLSF::GEGENBAUER;
	  use PDLA::GSLSF::HYPERG;
	  use PDLA::GSLSF::LAGUERRE;
	  use PDLA::GSLSF::LEGENDRE;
	  use PDLA::GSLSF::LOG;
	  use PDLA::GSLSF::POLY;
	  use PDLA::GSLSF::POW_INT;
	  use PDLA::GSLSF::PSI;
	  use PDLA::GSLSF::SYNCHROTRON;
	  use PDLA::GSLSF::TRANSPORT;
	  use PDLA::GSLSF::TRIG;
	  use PDLA::GSLSF::ZETA;
      ";
      unless ($@) {
	  plan tests => 3 if $v>=2.0;
	  plan tests => 1 if $v<2.0;
      } else {
	  warn "Warning: $@\n\n";
         plan skip_all => "PDLA::GSLSF modules not installed.";
      }
   } else {
      plan skip_all => "PDLA::GSLSF modules not compiled.";
   }
}

my $version = `gsl-config --version`;
my $arg = 5.0;
my $expected = -0.17759677131433830434739701;

my ($y,$err) = gsl_sf_bessel_Jn($arg, 0);

#print "got $y +- $err\n";

ok(abs($y-$expected) < 1e-6,"GSL SF Bessel function");

if ($version >= 2.0){
    my $Ylm = gsl_sf_legendre_array(xvals(21)/10-1,'Y',4,-1);
    ok($Ylm->slice("(0)")->uniq->nelem == 1, "Legendre Y00 is constant");
    ok(approx($Ylm->slice("(0),(0)"),0.5/sqrt(3.141592654),1E-6), "Y00 value is corect");
}
