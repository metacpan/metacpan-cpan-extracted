#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM => 'lib/Mojolicious/Plugin/Piwik.pm',
  ABSTRACT     => 'Use Piwik in Mojolicious',
  NAME         => 'Mojolicious::Plugin::Piwik',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 4.88
  },
  LICENSE      => 'artistic_2',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-Piwik',
        url => 'https://github.com/Akron/Mojolicious-Plugin-Piwik.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-Piwik/issues',
      }
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);

