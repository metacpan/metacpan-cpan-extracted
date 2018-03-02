#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new
(
  module_name         => 'Pony::Object',
  dist_abstract       => 'tiny object system with privacy settings for properties and methods, abstract classes and methods, exceptions',
  license             => 'perl',
  dist_author         => 'Georgy Bazhukov <georgy.bazhukov@gmail.com>',
  dist_version_from   => 'lib/Pony/Object.pm',
  build_requires =>
  {
    'Test::More' => 0,
  },
  configure_requires => {
    'Module::Build' => '0.40',
  },
  requires =>
  {
    'perl' => '5.014',
    'Module::Load' => 0,
    'Storable' => 0,
    'Carp' => 0,
    'Scalar::Util' => 0,
  },
  meta_merge =>
  {
    resources =>
    {
      repository => 'https://github.com/bugov/pony-object',
    },
    keywords => [ qw/Class Object Method OOP Private Protected Abstract Interface Exception/ ],
  },
  add_to_cleanup     => [],
  create_makefile_pl => 'traditional',
);

$builder->create_build_script();
