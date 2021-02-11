#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::HostMeta',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Serve and Retrieve Host-Meta Documents',
  VERSION_FROM => 'lib/Mojolicious/Plugin/HostMeta.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 6.08,
    'XML::Loy' => 0.49,
    'Mojolicious::Plugin::XML::Loy' => 0.15,
    'Mojolicious::Plugin::XRD' => 0.21,
    'Mojolicious::Plugin::Util::Endpoint' => 0.22,
    'Mojolicious::Plugin::Util::Callback' => 0.07
  },
  LICENSE      => 'artistic_2',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-HostMeta',
        url => 'https://github.com/Akron/Mojolicious-Plugin-HostMeta.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-HostMeta/issues',
      },
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
