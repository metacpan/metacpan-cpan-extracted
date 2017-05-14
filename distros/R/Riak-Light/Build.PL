
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::Exception" => 0,
    "Test::MockModule" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0,
    "Test::TCP" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Fast and lightweight Perl client for Riak",
  "dist_author" => [
    "Tiago Peczenyj <tiago.peczenyj\@gmail.com>"
  ],
  "dist_name" => "Riak-Light",
  "dist_version" => "0.052",
  "license" => "perl",
  "module_name" => "Riak::Light",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Const::Fast" => 0,
    "Google::ProtocolBuffers" => 0,
    "JSON" => 0,
    "Moo" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "Params::Validate" => 0,
    "Time::Out" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.012"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
