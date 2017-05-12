
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dumper" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "parse `remind -lp' output",
  "dist_author" => [
    "Paul Hoffman <nkuitse\@cpan.org>"
  ],
  "dist_name" => "Remind-Parser",
  "dist_version" => "0.08",
  "license" => "perl",
  "module_name" => "Remind::Parser",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Date::DayOfWeek" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
