
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::MockObject" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Spore Middleware to change the base_url on the fly",
  "dist_author" => [
    "Tiago Peczenyj <tiago.peczenyj\@gmail.com>"
  ],
  "dist_name" => "Net-HTTP-Spore-Middleware-BaseUrl",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "Net::HTTP::Spore::Middleware::BaseUrl",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose" => 0,
    "Net::HTTP::Spore" => 0,
    "perl" => "5.004"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
