
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
  "dist_abstract" => "Concatenate and minify JavaScript and CSS files",
  "dist_author" => [
    "Moritz Onken"
  ],
  "dist_name" => "Plack-Middleware-Assets",
  "dist_version" => "1.0.0",
  "license" => "bsd",
  "module_name" => "Plack::Middleware::Assets",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CSS::Minifier::XS" => 0,
    "Digest::MD5" => 0,
    "HTTP::Date" => 0,
    "JavaScript::Minifier::XS" => 0,
    "Plack::Middleware" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Test::More" => "0.88"
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
