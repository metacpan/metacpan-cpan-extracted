
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v5.016.
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Makes working with named ip services easier",
  "dist_author" => [
    "Adam Lesperance <lespea\@gmail.com>"
  ],
  "dist_name" => "Net-IANA-Services",
  "dist_version" => "0.004000",
  "license" => "perl",
  "module_name" => "Net::IANA::Services",
  "recommends" => {
    "YAML::XS" => 0
  },
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter::Easy" => 0,
    "File::ShareDir" => 0,
    "YAML::Any" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88",
    "Test::Most" => 0,
    "perl" => "5.008"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => "0.88",
  "Test::Most" => 0,
  "perl" => "5.008"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
