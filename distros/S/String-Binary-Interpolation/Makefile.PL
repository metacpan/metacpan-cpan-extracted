use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'String::Binary::Interpolation',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-String-Binary-Interpolation',
            bugtracker => 'https://github.com/DrHyde/perl-modules-String-Binary-Interpolation/issues'
        }
    },
  VERSION_FROM => 'lib/String/Binary/Interpolation.pm',
  PREREQ_PM    => {
    'Test::More' => '0.88',
  },
);
