
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Digest::SHA" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "MIME::Base64" => 0,
    "Module::Build" => "0.3601",
    "Test::CheckDeps" => "0.002",
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::NoWarnings" => 0,
    "Test::UseAllModules" => 0,
    "URI::Encode" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Basic request and response handling for calls to a CloudStack service.",
  "dist_author" => [
    "Alan Young <harleypig\@gmail.com>"
  ],
  "dist_name" => "Net-CloudStack-API",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "Net::CloudStack::API",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Net::CloudStack" => 0,
    "Params::Validate" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
