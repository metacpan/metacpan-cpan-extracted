
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Check TBX validity using TBXChecker\r",
  "dist_author" => [
    "Nathan Glenn <garfieldnate\@gmail.com>"
  ],
  "dist_name" => "TBX-Checker",
  "dist_version" => "0.03",
  "license" => "perl",
  "module_name" => "TBX::Checker",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Capture::Tiny" => 0,
    "Carp" => 0,
    "Exporter::Easy" => 0,
    "File::ShareDir" => 0,
    "Path::Tiny" => 0,
    "autodie" => 0,
    "feature" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::More" => "0.88",
    "URI::file" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
