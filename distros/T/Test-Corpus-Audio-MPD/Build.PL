
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "automate launching of fake mdp for testing purposes",
  "dist_author" => [
    "Jerome Quelin"
  ],
  "dist_name" => "Test-Corpus-Audio-MPD",
  "dist_version" => "1.120990",
  "license" => "perl",
  "module_name" => "Test::Corpus::Audio::MPD",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "File::Copy" => 0,
    "File::ShareDir::PathClass" => 0,
    "File::Temp" => 0,
    "Path::Class" => 0,
    "Readonly" => 0,
    "base" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "share_dir" => {
    "dist" => "share"
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
