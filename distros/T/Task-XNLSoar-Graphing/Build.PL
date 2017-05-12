
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "BUNDLE ALL MODULES NECESSARY FOR XNL-SOAR GRAPHING\r",
  "dist_author" => [
    "Nathan Glenn <garfieldnate\@gmail.com>"
  ],
  "dist_name" => "Task-XNLSoar-Graphing",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Task::XNLSoar::Graphing",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "GraphViz" => 0,
    "JSON::XS" => 0,
    "Path::Class" => 0,
    "Soar::WM" => "0.03",
    "opts" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
