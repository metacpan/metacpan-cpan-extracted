use strict;
use warnings;
use ExtUtils::MakeMaker;

# Note Slatec now handles f77 availability itself
# Func contains the Interpolate code

undef &MY::postamble; # suppress warning
*MY::postamble = sub { '' };

WriteMakefile(
  NAME => 'PDLA::Lib',
  VERSION_FROM => '../lib/PDLA/Rest.pm',
  DIR =>  [ qw/Simplex Fit FFT Filter Image2D ImageND
               CallExt Slatec GSL GIS Transform Minuit Compression
               / ],
  PM => { map {($_ => '$(INST_LIBDIR)/'.$_)}
    grep {
      !defined $PDLA::Config{WITH_SLATEC} ||
      $PDLA::Config{WITH_SLATEC}==1 ||
      !($_ eq 'Gaussian.pm')
    } <*.pm>
  },
  NO_MYMETA => 1,
#              Interpolate
# Interpolate is broken
);
