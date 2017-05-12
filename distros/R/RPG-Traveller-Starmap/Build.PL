
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Carp" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "UNIVERSAL" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A collection of star map generation tools for the RPG Traveller",
  "dist_author" => [
    "Peter L. Berghold <peter\@berghold.net>"
  ],
  "dist_name" => "RPG-Traveller-Starmap",
  "dist_version" => "0.500",
  "license" => "perl",
  "module_name" => "RPG::Traveller::Starmap",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Bit::Vector" => 0,
    "Exporter" => 0,
    "Moose" => 0,
    "RPG::Dice" => 0,
    "constant" => 0,
    "feature" => 0,
    "perl" => "5.010001",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
