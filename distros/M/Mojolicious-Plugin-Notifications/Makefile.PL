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
    'Test::Mojo::Session' => 1.06
  },
  PREREQ_PM => {
    'Mojolicious' => 7.24
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    'meta-spec' => { version => 2 },
    requires  => {
      perl => '5.010001'
    },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        url => 'https://github.com/Akron/Mojolicious-Plugin-Notifications.git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-Notifications',
      },
      bugtracker => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-Notifications/issues'
      }
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
