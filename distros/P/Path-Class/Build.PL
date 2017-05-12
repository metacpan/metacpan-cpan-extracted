
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
  "dist_abstract" => "Cross-platform path specification manipulation",
  "dist_author" => [
    "Ken Williams <kwilliams\@cpan.org>"
  ],
  "dist_name" => "Path-Class",
  "dist_version" => "0.37",
  "license" => "perl",
  "module_name" => "Path::Class",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Exporter" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Spec" => "3.26",
    "File::Temp" => 0,
    "File::stat" => 0,
    "IO::Dir" => 0,
    "IO::File" => 0,
    "Perl::OSType" => 0,
    "Scalar::Util" => 0,
    "overload" => 0,
    "parent" => 0,
    "strict" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Test" => 0,
    "Test::More" => 0,
    "warnings" => 0
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.3601",
  "Test" => 0,
  "Test::More" => 0,
  "warnings" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
