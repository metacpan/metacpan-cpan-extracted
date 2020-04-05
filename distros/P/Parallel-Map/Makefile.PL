use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Parallel::Map',
  VERSION_FROM => 'lib/Parallel/Map.pm',
  PREREQ_PM => {
    'IO::Async' => '0.75',
  },
);
