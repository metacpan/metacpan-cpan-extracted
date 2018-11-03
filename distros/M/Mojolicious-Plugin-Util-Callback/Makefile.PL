#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Util::Callback',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Reverse Helpers for Mojolicious',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Util/Callback.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Memory::Cycle' => 1.06
  },
  PREREQ_PM => {
    'Mojolicious' => 3.43
  },
  LICENSE => 'artistic_2',
  META_MERGE   => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-Util-Callback'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);

