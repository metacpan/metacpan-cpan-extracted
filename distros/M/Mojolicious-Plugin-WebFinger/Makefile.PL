#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::WebFinger',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Serve and Retrieve WebFinger Documents',
  VERSION_FROM => 'lib/Mojolicious/Plugin/WebFinger.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 6.00,
    'XML::Loy' => 0.39,
    'Mojolicious::Plugin::XRD' => 0.17,
    'Mojolicious::Plugin::HostMeta' => 0.21,
    'Mojolicious::Plugin::Util::Endpoint' => 0.19,
    'Mojolicious::Plugin::Util::Callback' => 0.04
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-WebFinger'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
