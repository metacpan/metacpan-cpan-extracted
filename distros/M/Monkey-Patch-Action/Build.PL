
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Wrap/add/replace/delete subs from other package (with restore)",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Monkey-Patch-Action",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Monkey::Patch::Action",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Sub::Delete" => 0,
    "perl" => "5.010001"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
