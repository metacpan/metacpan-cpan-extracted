use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => "PDL::IO::Dicom",
  VERSION_FROM => 'Dicom.pm',
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  PREREQ_PM => {
    'PDL' => '2.094',
  },
);
