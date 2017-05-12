
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Add the ability for attributes to remember their history",
  "dist_author" => [
    "Joel Berger <joel.a.berger\@gmail.com>"
  ],
  "dist_name" => "MooseX-RememberHistory",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "MooseX::RememberHistory",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
