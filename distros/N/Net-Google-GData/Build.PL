
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::NoWarnings" => 0,
    "Test::UseAllModules" => 0,
    "perl" => "5.004"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Handle basic communication with Google services",
  "dist_author" => [
    "Alan Young <harleypig\@gmail.com>"
  ],
  "dist_name" => "Net-Google-GData",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "Net::Google::GData",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Class::Accessor" => 0,
    "Class::ErrorHandler" => 0,
    "LWP::UserAgent" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
