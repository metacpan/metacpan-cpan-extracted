
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
  "dist_abstract" => "Middleware to set default params for every request made by a spore client",
  "dist_author" => [
    "Emmanuel \"BHS_error\" Peroumalnaik <peroumalnaik.emmanuel\@gmail.com>"
  ],
  "dist_name" => "Net-HTTP-Spore-Middleware-DefaultParams",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Net::HTTP::Spore::Middleware::DefaultParams",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose" => 0,
    "Net::HTTP::Spore::Middleware" => 0,
    "perl" => "5.006"
  },
  "script_files" => [],
  "test_requires" => {
    "JSON" => 0,
    "Net::HTTP::Spore" => 0,
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
