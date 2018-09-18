#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::CHI',
  VERSION_FROM => 'lib/Mojolicious/Plugin/CHI.pm',
  ABSTRACT     => 'Use CHI Caches in Mojolicious',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Output' => 1.0,
    'Test::Memory::Cycle' => 1.06
  },
  PREREQ_PM => {
    'Mojolicious' => 4.77,
    'CHI'         => 0.58,
    # Already a dep of CHI, but some perltesters failed
    'Digest::JHash' => 0.05
  },
  LICENSE      => 'artistic_2',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-CHI',
        url => 'https://github.com/Akron/Mojolicious-Plugin-CHI.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-CHI/issues',
      },
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
