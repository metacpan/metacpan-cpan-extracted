#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Mojo::IOLoop::ForkCall',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 'Module::Build' => 0.38 },
  requires => {
    'Mojolicious'  => '5.08',
    'IO::Pipely'   => 0,
    'Perl::OSType' => 0,
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/jberger/Mojo-IOLoop-ForkCall',
      bugtracker => 'https://github.com/jberger/Mojo-IOLoop-ForkCall/issues',
    },
  },
);

$build->create_build_script;
