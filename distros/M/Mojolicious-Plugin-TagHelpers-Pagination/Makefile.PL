#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::TagHelpers::Pagination',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Pagination Helper for Mojolicious',
  VERSION_FROM => 'lib/Mojolicious/Plugin/TagHelpers/Pagination.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 3.43,
    'Scalar::Util' => 0,
    'POSIX' => 0
  },
  LICENSE => 'artistic_2',
  META_MERGE   => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-TagHelpers-Pagination'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);

