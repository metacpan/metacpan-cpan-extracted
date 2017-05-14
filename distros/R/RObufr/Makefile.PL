#
##  Copyright (c) 1995-2012 University Corporation for Atmospheric Research
## All rights reserved
#
# Makefile.PL for a package defined by PP code.

use ExtUtils::MakeMaker;
use Config;

#
## Make PDL a pre-requisite
#
eval {
  require PDL::Core::Dev;
  PDL::Core::Dev->import;
};
my $pdl_installed = ($@) ? 0 : 1;
print "Required package: PDL ", ($pdl_installed ? 'is' : 'is not'), " installed\n";

if (!$pdl_installed) {
  # write dummy makefile if PDL not installed                                                                                      
  WriteMakefile(
    'NAME'      => 'RObufr',
    'PREREQ_PM' => { PDL => 0 },
  );
  exit;
}

WriteMakefile(
	      'NAME'  	     => 'RObufr',
	      'VERSION_FROM' => 'RObufr.pp',
	      'TYPEMAPS'     => [&PDL_TYPEMAP()],
	      'OBJECT'       => "RObufr.o ",
	      'INST_BIN'     => './bin',
	      'INSTALLBIN'   => '$(PREFIX)/bin',
	      'PM'	     => { 'RObufr.pm'    => '$(INST_LIBDIR)/RObufr.pm',
                                  'TimeClass.pm' => '$(INST_LIBDIR)/TimeClass.pm',
                                  './bufr/CODEFIG' => '$(INST_LIBDIR)/bufr/CODEFIG',
                                  './bufr/gpsseq2.dat' => '$(INST_LIBDIR)/bufr/gpsseq2.dat',
                                  './bufr/gpsseq.dat'  => '$(INST_LIBDIR)/bufr/gpsseq.dat',
                                  './bufr/TABLEA'  => '$(INST_LIBDIR)/bufr/TABLEA',
                                  './bufr/TABLEB'  => '$(INST_LIBDIR)/bufr/TABLEB',
                                  './bufr/TABLED'  => '$(INST_LIBDIR)/bufr/TABLED'},
	      'INC'          => &PDL_INCLUDE(), # add include dirs as required by your lib
	      'OPTIMIZE'     => ' -g ',
	      'clean'        => {'FILES'  => 'RObufr.c RObufr.pm RObufr.xs RObufr.o '},
	      'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
	      );

# Add genpp rule; this will invoke PDL::PP on our PP file
# the argument is an array reference where the array has three string elements:
#   arg1: name of the source file that contains the PP code
#   arg2: basename of the xs and pm files to be generated
#   arg3: name of the package that is to be generated
sub MY::postamble { pdlpp_postamble(["RObufr.pp", RObufr, RObufr]) }
