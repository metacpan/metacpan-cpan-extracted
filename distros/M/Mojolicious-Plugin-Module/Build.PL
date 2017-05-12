#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

Module::Build->new(
  module_name         => 'Mojolicious::Plugin::Module',
  dist_abstract       => 'Mojolicious plugin for modular development.',
  license             => 'perl',
  dist_author         => 'Georgy Bazhukov <gosha@bugov.net>',
  dist_version_from   => 'lib/Mojolicious/Plugin/Module.pm',
  build_requires      => { 'Test::More' => 0, },
  configure_requires  => { 'Module::Build' => '0.40', },
  requires => {
    'perl'                => 5.014,
    'Module::Load'        => 0,
    'Carp'                => 0,
    'Mojolicious'         => 4,
    'Hash::Merge::Simple' => 0.051,
    'YAML'                => 0,
    'File::Copy::Recursive' => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/bugov/mojolicious-plugin-module',
    },
    keywords => [ qw/Plugin Module Mojolicious/ ],
  },
  add_to_cleanup     => [],
  create_makefile_pl => 'traditional',
)->create_build_script();
