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
    'Mojolicious' => 9.17,
    'XML::Loy' => 0.50,
    'Mojolicious::Plugin::XRD' => 0.24,
    'Mojolicious::Plugin::HostMeta' => 0.26,
    'Mojolicious::Plugin::Util::Endpoint' => 0.24,
    'Mojolicious::Plugin::Util::Callback' => 0.07
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        url => 'https://github.com/Akron/Mojolicious-Plugin-WebFinger.git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-WebFinger',
      },
      bugtracker => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-WebFinger/issues'
      }
    }

  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
