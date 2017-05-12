
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Highly flexible CSV parser for large files",
  "dist_author" => [
    "Adam Kennedy <adamk\@cpan.org>"
  ],
  "dist_name" => "Parse-CSV",
  "dist_version" => "2.04",
  "license" => "perl",
  "module_name" => "Parse::CSV",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "IO::File" => "1.13",
    "Params::Util" => "1.00",
    "Text::CSV_XS" => "0.80",
    "perl" => "5.005",
    "strict" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Spec::Functions" => 0,
    "Test::More" => 0
  }
);


my %fallback_build_requires = (
  "File::Spec::Functions" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
