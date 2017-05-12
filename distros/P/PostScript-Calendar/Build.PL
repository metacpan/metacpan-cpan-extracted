#! /usr/bin/perl
#---------------------------------------------------------------------
# Build.PL for PostScript-Calendar
#
# Copyright 2010 Christopher J. Madsen
#
#---------------------------------------------------------------------

use strict;
use warnings;

use inc::My_Build;          # Our customized version of Module::Build

my $builder = inc::My_Build->new(
  module_name        => 'PostScript::Calendar',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/PostScript/Calendar.pm',
  dynamic_config     => 0,
  # Prerequisites inserted by DistZilla:
  'build_requires' => {
    'FindBin' => '0',
    'Module::Build' => '0.21',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.21'
  },
  'recommends' => {
    'Astro::MoonPhase' => '0.60'
  },
  'requires' => {
    'Carp' => '0',
    'Date::Calc' => '5.0',
    'PostScript::File' => '2.20',
    'perl' => '5.008'
  },
);

$builder->create_build_script();
