#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::TagHelpers::MailToChiffre',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Obfuscate Email Addresses in Templates',
  VERSION_FROM => 'lib/Mojolicious/Plugin/TagHelpers/MailToChiffre.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  LICENSE      => 'perl',
  PREREQ_PM => {
    'Mojolicious' => 5.71,
    'Mojolicious::Plugin::Util::RandomString' => 0.04
    },
  META_MERGE   => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/Mojolicious-Plugin-TagHelpers-MailToChiffre'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);

