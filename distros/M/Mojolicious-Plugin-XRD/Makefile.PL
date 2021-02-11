#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::XRD',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'XRD Document Handling with Mojolicious',
  VERSION_FROM => 'lib/Mojolicious/Plugin/XRD.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 7.13,
    'Mojolicious::Plugin::XML::Loy' => 0.15,
    'XML::Loy' => 0.49
  },
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        url => 'https://github.com/Akron/Mojolicious-Plugin-XRD.git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-XRD',
      },
      bugtracker => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-XRD/issues'
      }
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
