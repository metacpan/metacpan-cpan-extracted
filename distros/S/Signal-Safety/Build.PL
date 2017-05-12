
use strict;
use warnings;

use Module::Build 0.3601;


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
  "dist_abstract" => "Enable or disable safe signal handling",
  "dist_author" => [
    "Leon Timmermans <leont\@cpan.org>"
  ],
  "dist_name" => "Signal-Safety",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Signal::Safety",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "XSLoader" => 0,
    "perl" => "5.008001",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
