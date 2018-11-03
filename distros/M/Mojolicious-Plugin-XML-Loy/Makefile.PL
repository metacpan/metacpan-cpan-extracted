#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::XML::Loy',
  VERSION_FROM => 'lib/Mojolicious/Plugin/XML/Loy.pm',
  ABSTRACT     => 'XML Generation with Mojolicious',
  AUTHOR       => 'Nils Diewald',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Warn' => 0
  },
  PREREQ_PM => {
    'Mojolicious' => 5.81,
    'XML::Loy' => 0.45
  },
  LICENSE      => 'artistic_2',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Mojolicious-Plugin-XML-Loy',
        url => 'https://github.com/Akron/Mojolicious-Plugin-XML-Loy.git',
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Mojolicious-Plugin-XML-Loy/issues',
      },
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);
