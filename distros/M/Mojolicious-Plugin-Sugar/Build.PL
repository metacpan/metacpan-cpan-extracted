
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Mojolicious::Lite" => 0,
    "Test::Mojo" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Some sweet stuff for Mojolicious",
  "dist_author" => [
    "Pavel A. Karoukin <pavel\@karoukin.us>"
  ],
  "dist_name" => "Mojolicious-Plugin-Sugar",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Mojolicious::Plugin::Sugar",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Types" => 0,
    "Mojo::Base" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
