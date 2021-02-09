#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM => 'lib/Mojolicious/Plugin/BlogSpam.pm',
  ABSTRACT     => 'Check your Comments using BlogSpam',
  NAME         => 'Mojolicious::Plugin::BlogSpam',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Memory::Cycle' => 1.06
  },
  PREREQ_PM => {
    'Mojolicious' => 4.88,
    'Scalar::Util' => 1.20
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        url => 'https://github.com/Akron/Mojolicious-Plugin-BlogSpam.git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-BlogSpam',
      },
      bugtracker => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-BlogSpam/issues'
      }
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);

