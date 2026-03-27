use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'TOON',
  VERSION_FROM => 'lib/TOON.pm',
  ABSTRACT     => 'Token-Oriented Object Notation for Perl',
  AUTHOR       => 'Dave Cross <dave@perlhacks.com>',
  EXE_FILES    => ['bin/toon_pp'],
  PREREQ_PM    => {
    'Exporter'    => 0,
    'Getopt::Long'=> 0,
    'Scalar::Util'=> 0,
  },
  test         => { TESTS => 't/*.t' },
);
