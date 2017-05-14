
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "ExtUtils::MakeMaker" => "6.31",
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Makes scalar variables store Boolean values only",
  "dist_author" => [
    "Alan Haggai Alavi <alanhaggai\@alanhaggai.org>"
  ],
  "dist_name" => "Scalar-Boolean",
  "dist_version" => "1.02",
  "license" => "perl",
  "module_name" => "Scalar::Boolean",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {},
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
