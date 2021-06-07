#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::CHI::Route',
  VERSION_FROM => 'lib/Mojolicious/Plugin/CHI/Route.pm',
  ABSTRACT     => 'Route Caching in Mojolicious',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 8.67,
    'Mojolicious::Plugin::CHI' => 0.20,
    'Time::Duration::Parse' => 0
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-CHI-Route',
        url => 'https://github.com/Akron/Mojolicious-Plugin-CHI-Route.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-CHI-Route/issues',
      },
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
