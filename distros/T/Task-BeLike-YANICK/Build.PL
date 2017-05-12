
use strict;
use warnings;

use Module::Build 0.3601;
use lib qw{inc}; use MyBuild;

my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "like Yanick? Be like Yanick!",
  "dist_author" => [
    "Yanick Champoux <yanick\@cpan.org>"
  ],
  "dist_name" => "Task-BeLike-YANICK",
  "dist_version" => "0.8.0",
  "license" => "perl",
  "module_name" => "Task::BeLike::YANICK",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = MyBuild->new(%module_build_args);

$build->create_build_script;
