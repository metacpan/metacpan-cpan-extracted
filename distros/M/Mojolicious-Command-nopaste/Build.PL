#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Mojolicious::Command::nopaste',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 'Module::Build' => 0.38 },
  requires => {
    'Mojolicious' => '7.13', # is_success
    'File::HomeDir' => 0,
  },
  recommends => {
    'IO::Socket::SSL' => '1.94', # Mojolicious SSL support
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/jberger/Mojolicious-Command-nopaste',
      bugtracker => 'https://github.com/jberger/Mojolicious-Command-nopaste/issues',
    },
  },
);

$build->create_build_script;
