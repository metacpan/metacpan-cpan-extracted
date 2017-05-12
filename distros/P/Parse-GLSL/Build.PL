
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::Deep" => 0,
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Parse OpenGL Shader Language files into an abstract syntax tree",
  "dist_author" => [
    "Tom Molesworth <tom\@entitymodel.com>"
  ],
  "dist_name" => "Parse-GLSL",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Parse::GLSL",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Parser::MGC" => "0.09",
    "parent" => 0,
    "perl" => "5.008"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
