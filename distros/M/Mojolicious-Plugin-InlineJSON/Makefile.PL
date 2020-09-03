use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

use 5.014;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Mojolicious::Plugin::InlineJSON',
  VERSION_FROM => 'lib/Mojolicious/Plugin/InlineJSON.pm',
  PREREQ_PM => {
    Mojolicious => 8,
  },
);
