
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
  "dist_abstract" => "Calculate precision, recall, F1, accuracy, etc.",
  "dist_author" => [
    "Ken Williams <kwilliams\@cpan.org>"
  ],
  "dist_name" => "Statistics-Contingency",
  "dist_version" => "0.09",
  "license" => "perl",
  "module_name" => "Statistics::Contingency",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Params::Validate" => 0,
    "strict" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Test" => 0
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
