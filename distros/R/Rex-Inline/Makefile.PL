use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Rex::Inline',
  AUTHOR => 'johnnywang <johnnywang1991@msn.com>',
  EXE_FILES => [],
  PL_FILES => {},
  LICENSE => 'GPL v2',
  DISTNAME => 'Rex-Inline',
  VERSION_FROM => 'lib/Rex/Inline.pm',
  PREREQ_PM => {
    Moose => 0,
    'MooseX::AttributeShortcuts' => 0,
    'File::Temp' => 0,
    'File::Path::Tiny' => 0,
    'File::Spec::Functions' => 0,
    'YAML::XS' => 0,
    'Parallel::ForkManager' => 0,
    'Rex' => 0,
    'namespace::autoclean' => 0
  },
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  clean => { FILES => 'Rex-Inline-*' },
  META_MERGE => {
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/johnnywang1991/RexInline.git',
        web => 'https://github.com/johnnywang1991/RexInline',
      }
    }
  }
);
