
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::CheckDeps" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::NoWarnings" => 0,
    "Test::Requires" => 0,
    "Test::UseAllModules" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Base class for OpenVZ utilities like vzctl",
  "dist_author" => [
    "Alan Young <harleypig\@gmail.com>"
  ],
  "dist_name" => "OpenVZ",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "OpenVZ",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "File::Which" => 0,
    "IPC::Run3::Simple" => 0,
    "List::MoreUtils" => 0,
    "Params::Validate" => 0,
    "Regexp::Common" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "Sub::Exporter::ForMethods" => 0,
    "Sub::Exporter::Util" => 0,
    "namespace::autoclean" => 0,
    "namespace::sweep" => 0,
    "parent" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
