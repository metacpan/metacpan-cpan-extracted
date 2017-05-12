
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Path::Class" => 0,
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "Test::NoWarnings" => 0,
    "Test::Perl::Critic::Progressive" => 0,
    "Try::Tiny" => 0,
    "perl" => "5.004"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "format PseudoPod as valid XHTML",
  "dist_author" => [
    "Alan Young <harleypig\@gmail.com>"
  ],
  "dist_name" => "Pod-PseudoPod-XHTML",
  "dist_version" => "1.02",
  "license" => "perl",
  "module_name" => "Pod::PseudoPod::XHTML",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Pod::PseudoPod::HTML" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
