#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Util::Endpoint',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Use template URIs in Mojolicious',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Util/Endpoint.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Output' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 4.88
  },
  LICENSE      => 'perl',
  META_MERGE   => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-Util-Endpoint'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
