
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dump" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "Test::Requires" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Quickly build & query relational data",
  "dist_author" => [
    "Traian Nedelea <tron1point0\@gmail.com>"
  ],
  "dist_name" => "SQL-Abstract-Builder",
  "dist_version" => "v0.1.1",
  "license" => "unrestricted",
  "module_name" => "SQL::Abstract::Builder",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DBIx::Simple" => 0,
    "Exporter" => 0,
    "Hash::Merge" => 0,
    "List::Util" => 0,
    "SQL::Abstract::More" => 0,
    "perl" => "v5.14.0"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
