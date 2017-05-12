
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
  "dist_abstract" => "Add a list of parent classes to your POD.",
  "dist_author" => [
    "Mike Friedman <friedo\@friedo.com>"
  ],
  "dist_name" => "Pod-Weaver-Section-Extends",
  "dist_version" => "0.009",
  "license" => "perl",
  "module_name" => "Pod::Weaver::Section::Extends",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Module::Load" => 0,
    "Moose" => 0,
    "Pod::Elemental::Element::Nested" => 0,
    "Pod::Elemental::Element::Pod5::Command" => 0,
    "Pod::Weaver::Role::Section" => 0,
    "aliased" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {}
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
