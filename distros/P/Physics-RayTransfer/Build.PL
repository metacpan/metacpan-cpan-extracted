
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Object-oriented ray transfer analysis",
  "dist_author" => [
    "Joel Berger <joel.a.berger\@gmail.com>"
  ],
  "dist_name" => "Physics-RayTransfer",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "Physics::RayTransfer",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "List::Util" => 0,
    "Method::Signatures::Modifiers" => 0,
    "MooseX::Declare" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
