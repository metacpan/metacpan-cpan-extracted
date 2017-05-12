use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name  => 'Mojolicious::Plugin::Humane',
  dist_author  => 'Joel A. Berger <joel.a.berger@gmail.com>',
  requires     => {
    'Mojolicious' => '4.77'
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },
  share_dir => 'lib/Mojolicious/Plugin/Humane/files',
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Mojolicious-Plugin-Humane",
      bugtracker => "http://github.com/jberger/Mojolicious-Plugin-Humane/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
    },
  }
);

$build->create_build_script;

