#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Notifications',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Notifications.pm',
  ABSTRACT     => 'Frontend Event Notifications',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Mojo::Session' => 1.04
  },
  PREREQ_PM => {
    'Mojolicious' => 7.13
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {
      perl => '5.010001'
    },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-Notifications'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
