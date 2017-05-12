
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Deflate and inflate Moose attribute values",
  "dist_author" => [
    "Moritz Onken"
  ],
  "dist_name" => "MooseX-Attribute-Deflator",
  "dist_version" => "2.2.2",
  "license" => "bsd",
  "module_name" => "MooseX::Attribute::Deflator",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DateTime" => 0,
    "Devel::PartialDump" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "JSON" => 0,
    "Module::Build" => "0.3601",
    "Moose" => "1.25",
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types" => "0.30",
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Structured" => 0,
    "Test::More" => "0.88",
    "Try::Tiny" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
