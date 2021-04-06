#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

WriteMakefile(
  'ABSTRACT' => 'YAML Configuration Plugin for Mojolicious',
  'AUTHOR' => 'Danijel Tasov <cpan@rbfh.de>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Mojolicious-Plugin-YamlConfig',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'VERSION_FROM' => 'lib/Mojolicious/Plugin/YamlConfig.pm',
  'NAME' => 'Mojolicious::Plugin::YamlConfig',
  'PREREQ_PM' => {
    'Mojolicious' => '5.54',
    'YAML::Tiny'  => '1.60'
  },
  META_ADD => {
    resources => {
      license => 'https://dev.perl.org/licenses/',
      repository => 'https://data.rbfh.de/git/mojolicious-plugin-yamlconfig',
    }
  }
);
