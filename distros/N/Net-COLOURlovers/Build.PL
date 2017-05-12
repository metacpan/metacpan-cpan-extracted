
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
  "dist_abstract" => "Interface to COLOURlovers.com's API",
  "dist_author" => [
    "Alan Haggai Alavi <alanhaggai\@alanhaggai.org>"
  ],
  "dist_name" => "Net-COLOURlovers",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "Net::COLOURlovers",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
