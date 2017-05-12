
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "ExtUtils::MakeMaker" => "6.31",
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Static website generator",
  "dist_author" => [
    "Alan Haggai Alavi <haggai\@cpan.org>"
  ],
  "dist_name" => "StaticVolt",
  "dist_version" => "1.00",
  "license" => "artistic_2",
  "module_name" => "StaticVolt",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Cwd" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "Template" => 0,
    "Text::Markdown" => 0,
    "Text::Textile" => 0,
    "YAML" => 0
  },
  "script_files" => [
    "bin/staticvolt"
  ],
  "test_requires" => {
    "Test::More" => 0
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
