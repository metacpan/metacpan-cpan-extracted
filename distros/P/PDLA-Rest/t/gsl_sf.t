

# Test Script for the PDLA interface to the GSL library
#  This tests only that the interface is working, i.e. that the
#   functions can be called. The actual return values are not
#   checked. 
#  The GSL library already has a extensive test suite, and we
#  do not want to duplicate that effort here.

use PDLA::LiteF;
use Test::More;

BEGIN
{
   use PDLA::Config;
   if ( $PDLA::Config{WITH_GSL} ) {
      eval " use PDLA::GSLSF::BESSEL; ";
      unless ($@) {
         plan tests => 1;
      } else {
         plan skip_all => "PDLA::GSLSF::BESSEL not installed.";
      }
   } else {
      plan skip_all => "PDLA::GSLSF::BESSEL not compiled.";
   }
}

$arg = 5.0;
$expected = -0.17759677131433830434739701;

($y,$err) = gsl_sf_bessel_Jn $arg, 0;

print "got $y +- $err\n";

ok abs($y-$expected) < 1e-6;
