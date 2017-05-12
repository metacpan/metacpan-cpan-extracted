#!/usr/bin/perl -w

use strict;
use Module::Build;

my $build = Module::Build->new(
  module_name    => 'Module::Build::WithXSpp',
  license        => 'perl',
  requires       => {
    'ExtUtils::XSpp' => '0.11',
    'ExtUtils::CBuilder' => '0',
    'Module::Build' => '0.26',
    'ExtUtils::Typemaps' => '1.00',
    'ExtUtils::ParseXS' => '2.2205',
    'ExtUtils::CppGuess' => '0.04',
    'Digest::MD5' => '0',
  },
  build_requires => {
    'ExtUtils::CBuilder' => '0',
    'Module::Build' => '0.26',
  },
  configure_requires => {
    'Module::Build' => '0.26',
  },
  test_requires  => {
    'Test::More' => '0',
  },
);

$build->create_build_script;
