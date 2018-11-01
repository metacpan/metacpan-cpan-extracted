#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::XRD',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'XRD Document Handling with Mojolicious',
  VERSION_FROM => 'lib/Mojolicious/Plugin/XRD.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 7.13,
    'Mojolicious::Plugin::XML::Loy' => 0.13,
    'XML::Loy' => 0.47
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-XRD'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
