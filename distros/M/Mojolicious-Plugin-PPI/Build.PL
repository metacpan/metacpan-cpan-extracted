#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Mojolicious::Plugin::PPI',
  dist_version_from  => 'lib/Mojolicious/Plugin/PPI.pm',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 'Module::Build' => 0.36 },
  requires => {
    'Mojolicious' => '2.0',
    'PPI::HTML'   => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/jberger/Mojolicious-Plugin-PPI',
      bugtracker => 'https://github.com/jberger/Mojolicious-Plugin-PPI/issues',
    },
  },
);

$build->create_build_script;
