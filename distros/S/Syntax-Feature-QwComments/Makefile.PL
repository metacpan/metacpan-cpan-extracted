#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

WriteMakefile(
   NAME           => 'Syntax::Feature::QwComments',
   AUTHOR         => 'Eric Brine <ikegami@adaelis.com>',
   VERSION_FROM   => 'lib/Syntax/Feature/QwComments.pm',
   ABSTRACT_FROM  => 'lib/Syntax/Feature/QwComments.pm',
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
   clean          => { FILES => 'Syntax-Feature-QwComments-*' },
   BUILD_REQUIRES => {},

   META_MERGE  => {
      'meta-spec' => { version => 2 },

      license => [ 'unrestricted' ],

      prereqs => {
         configure => {
            requires => {
               'ExtUtils::MakeMaker' => 6.74,
            },
         },
         runtime => {
            requires => {
               'perl'                => 5.014000,
               'strict'              => 0,
               'syntax'              => 0.004,
               'version'             => 0,
               'warnings'            => 0,
               'XSLoader'            => 0,
            },
            recommends => {
               'perl'                => 5.028000,
            },
         },
         test => {
            requires => {
               'Test::More'          => 0,
            },
            recommends => {
               'Test::Pod'           => 1.22,
            },
         },
         develop => {
            requires => {
               'Pod::Coverage'       => 0.18,
               'Test::Pod::Coverage' => 1.08,
            },
         },
      },

      resources => {
         homepage => 'https://metacpan.org/dist/Syntax-Feature-QwComments',
         license => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],
         bugtracker => {
            web => 'https://github.com/ikegami/perl-Syntax-Feature-QwComments/issues',
         },
         repository => {
            type => 'git',
            url  => 'https://github.com/ikegami/perl-Syntax-Feature-QwComments.git',
            web  => 'https://github.com/ikegami/perl-Syntax-Feature-QwComments',
         },
      },
   },
);
