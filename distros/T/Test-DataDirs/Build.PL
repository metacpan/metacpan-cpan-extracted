
use strict;
use warnings;

use Module::Build 0.2808;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.2808"
  },
  "configure_requires" => {
    "Module::Build" => "0.2808"
  },
  "dist_abstract" => "manage t/data and t/temp directories for your tests",
  "dist_author" => [
    "Nick Stokoe <wulee\@cpan.org>"
  ],
  "dist_name" => "Test-DataDirs",
  "dist_version" => "0.1.2",
  "license" => "perl",
  "module_name" => "Test::DataDirs",
  "recommends" => {
    "Test::Pod" => "1.14",
    "Test::Pod::Coverage" => "1.04"
  },
  "recursive_test_files" => 1,
  "requires" => {},
  "script_files" => [],
  "test_requires" => {
    "Pod::Coverage::TrustPod" => 0,
    "Test::Exception" => 0
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.2808",
  "Pod::Coverage::TrustPod" => 0,
  "Test::Exception" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
