
use strict;
use warnings;

use Module::Build 0.38;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.38",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.38"
  },
  "dist_abstract" => "A quick and dirty wrapper around DotCloud::Environment",
  "dist_author" => [
    "Ben van Staveren <madcat\@cpan.org>"
  ],
  "dist_name" => "Mojolicious-Plugin-Dotcloud",
  "dist_version" => "1.01",
  "license" => "perl",
  "module_name" => "Mojolicious::Plugin::Dotcloud",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DotCloud::Environment" => 0,
    "Mojo::Base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
