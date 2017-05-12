
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
  "dist_abstract" => "Find a package among CPAN-like repositories",
  "dist_author" => [
    "Jeffrey Ryan Thalhammer <jeff\@imaginative-software.com>"
  ],
  "dist_name" => "Package-Locator",
  "dist_version" => "0.010",
  "license" => "perl",
  "module_name" => "Package::Locator",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CPAN::DistnameInfo" => 0,
    "Carp" => 0,
    "File::Temp" => 0,
    "IO::Zlib" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "MooseX::MarkAsMethods" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::URI" => 0,
    "Path::Class" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "perl" => "5.006",
    "version" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "FindBin" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
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
