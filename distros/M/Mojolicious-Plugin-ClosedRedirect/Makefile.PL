#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::ClosedRedirect',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Defend Open Redirect Attacks',
  VERSION_FROM => 'lib/Mojolicious/Plugin/ClosedRedirect.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 6.48
  },
  LICENSE      => 'artistic_2',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-ClosedRedirect',
        url => 'https://github.com/Akron/Mojolicious-Plugin-ClosedRedirect.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-ClosedRedirect/issues',
      },
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
