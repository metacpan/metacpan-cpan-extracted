use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use 5.010;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'PerlX::AsyncAwait',
  VERSION_FROM => 'lib/PerlX/AsyncAwait.pm',
  PREREQ_PM => {
    PPR => 0,
    Future => 0,
    curry => 1,
    strictures => 2,
    Moo => 2,
  },
);
