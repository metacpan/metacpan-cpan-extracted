use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME  	=> 'PDL::Graphics::PGPLOT',
  VERSION_FROM => '../PGPLOT.pm',
  PM => {
    'PGPLOT.pm' => '$(INST_LIBDIR)/PGPLOT.pm',
    'PGPLOTOptions.pm' => '$(INST_LIBDIR)/PGPLOTOptions.pm',
    'Demo.pm' => '$(INST_LIB)/PDL/Demos/PGPLOT.pm',
  },
  NO_MYMETA => 1,
);
