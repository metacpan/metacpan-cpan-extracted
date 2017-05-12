
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => "0.94"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Module collection to parse Matroska files.",
  "dist_author" => [
    "Kovensky <diogomfranco\@gmail.com>"
  ],
  "dist_name" => "Parse-Matroska",
  "dist_version" => "0.003",
  "license" => "open_source",
  "module_name" => "Parse::Matroska",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "perl" => "5.008"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
