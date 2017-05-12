
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "download and parse the latest USDA National Nutrient Database",
  "dist_author" => [
    "Ioan Rogers <ioan.rogers\@gmail.com>"
  ],
  "dist_name" => "Parse-USDA-NNDB",
  "dist_version" => "0.1",
  "license" => "artistic_2",
  "module_name" => "Parse::USDA::NNDB",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Archive::Zip" => 0,
    "File::Fetch" => 0,
    "File::HomeDir" => 0,
    "File::Spec" => 0,
    "Log::Any" => 0,
    "Text::CSV_XS" => 0,
    "URI" => 0,
    "perl" => "v5.10",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
