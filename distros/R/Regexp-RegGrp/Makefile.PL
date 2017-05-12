#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Regexp::RegGrp',
  ABSTRACT_FROM => 'lib/Regexp/RegGrp.pm',
  VERSION_FROM  => 'lib/Regexp/RegGrp.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM => {
  },
  BUILD_REQUIRES => {
    'Test::More'               => 0,
  },
  META_MERGE => {
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/Regexp::RegGrp',
      bugtracker => 'https://github.com/leejo/regexp-reggrp-perl/issues',
      repository => 'https://github.com/leejo/regexp-reggrp-perl'
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
