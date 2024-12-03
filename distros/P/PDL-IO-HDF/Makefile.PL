use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
require ExtUtils::Depends;
require File::Spec::Functions;

WriteMakefile(
  NAME => 'PDL::IO::HDF',
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  VERSION_FROM => 'HDF.pm',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.094',
    'ExtUtils::Depends' => '0.402',
    'Alien::HDF4' => 0,
  },
  PREREQ_PM => {
    'PDL' => '2.094',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  PM => { 'HDF.pm' => '$(INST_LIBDIR)/HDF.pm' },
  dist => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
