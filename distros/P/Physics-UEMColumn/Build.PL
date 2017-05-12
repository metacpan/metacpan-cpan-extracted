use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Physics::UEMColumn',
  dist_author => 'Joel Berger',
  requires => {
    'Moose' => 0,
    'namespace::autoclean' => 0,
    'Method::Signatures' => 0,
    'MooseX::Types::NumUnit' => 0,
    'PerlGSL::DiffEq' => 0,
  },
  test_requires => {
    'List::MoreUtils' => 0,
    'Test::More' => 0,
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },
  recommends => {
    'PDL' => 0,
    'PDL::Graphics::Prima' => 0,
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Physics-UEMColumn",
      bugtracker => "http://github.com/jberger/Physics-UEMColumn/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
      directory => [ 'examples', 't' ],
    },
  },
);

$builder->create_build_script;
