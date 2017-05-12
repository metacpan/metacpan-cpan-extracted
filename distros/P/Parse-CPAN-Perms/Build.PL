
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Parse 06perms.txt.gz",
  "dist_author" => [
    "Jeffrey Ryan Thalhammer <jeff\@stratopan.com>"
  ],
  "dist_name" => "Parse-CPAN-Perms",
  "dist_version" => "0.004",
  "license" => "perl",
  "module_name" => "Parse::CPAN::Perms",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "File::stat" => 0,
    "IO::Zlib" => 0,
    "Moose" => 0,
    "perl" => "5.006"
  },
  "script_files" => [],
  "test_requires" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "List::Util" => 0,
    "Test::More" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  }
);


my %fallback_build_requires = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => 0,
  "perl" => "5.006",
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
