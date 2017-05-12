
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "Test::Pod::Coverage" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Base class for a family of (Mega)Traveller character generation modules",
  "dist_author" => [
    "Peter L. Berghold <cpan\@berghold.net>"
  ],
  "dist_name" => "RPG-Traveller-Person",
  "dist_version" => "1.020",
  "license" => "perl",
  "module_name" => "RPG::Traveller::Person",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "Moose" => 0,
    "RPG::Dice" => "1.1",
    "Test::More" => "0.88",
    "Test::Pod::Coverage" => 0,
    "constant" => 0,
    "perl" => "5.006",
    "strict" => 0
  },
  "script_files" => [
    "bin/CreateBasePeople.pl"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
