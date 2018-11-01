#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::PubSubHubbub',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Publish and Subscribe with PubSubHubbub',
  VERSION_FROM => 'lib/Mojolicious/Plugin/PubSubHubbub.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 7.13,
    'Mojolicious::Plugin::Util::Endpoint' => 0.19,
    'Mojolicious::Plugin::Util::Callback' => 0.02,
    'Mojolicious::Plugin::Util::RandomString' => 0.05
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-PubSubHubbub'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t t/examples/*.t'}
);
