
use strict;
use warnings;

use Module::Build 0.3601;

my $build = Module::Build->new(
  module_name => "MooseX::Types::NumUnit",
  dist_abstract => "Type(s) for using units in Moose",
  dist_author => 'Joel Berger <joel.a.berger@gmail.com>',
  license => "perl",
  build_requires => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  configure_requires => {
    "Module::Build" => "0.3601"
  },
  requires => {
    "Carp" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Role" => 0,
    "Moose::Util::MetaRole" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::ClassAttribute" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Physics::Unit" => 0.53,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/MooseX-Types-NumUnit",
      bugtracker => "http://github.com/jberger/MooseX-Types-NumUnit/issues",
    },
    no_index => {
      file => [ 'README.pod' ],
    },
  },
);

$build->create_build_script;
