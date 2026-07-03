#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Localize',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Localize.pm',
  ABSTRACT     => 'Localization Framework for Mojolicious',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 7.14,
    'Test::Output' => 1.031,
    'I18N::LangTags' => 0,
    'I18N::LangTags::Detect' => 0,
    'List::MoreUtils' => 0.416
  },
  LICENSE      => 'artistic_2',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-Localize',
        url => 'https://github.com/Akron/Mojolicious-Plugin-Localize.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-Localize/issues',
      },
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
