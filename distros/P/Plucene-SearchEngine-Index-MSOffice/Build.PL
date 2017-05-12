
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "an unmaintained set of Plucene backends for indexing Microsoft Office formats",
  "dist_author" => [
    "Sopan Shewale <sopan.shewale\@gmail.com>",
    "Mike Doherty <doherty\@pythian.com>"
  ],
  "dist_name" => "Plucene-SearchEngine-Index-MSOffice",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "Plucene::SearchEngine::Index::MSOffice",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::Temp" => 0,
    "IPC::Run3" => 0,
    "Plucene::SearchEngine::Index::Base" => 0,
    "Plucene::SearchEngine::Index::HTML" => 0,
    "Plucene::SearchEngine::Index::Text" => 0,
    "Spreadsheet::ParseExcel" => 0,
    "parent" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
