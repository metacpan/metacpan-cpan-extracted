
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "lazily calculate the tuples of a cartesian-product",
  "dist_author" => [
    "Stephen R. Scaffidi <sscaffidi\@cpan.org>"
  ],
  "dist_name" => "Set-CartesianProduct-Lazy",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Set::CartesianProduct::Lazy",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "List::Util" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
