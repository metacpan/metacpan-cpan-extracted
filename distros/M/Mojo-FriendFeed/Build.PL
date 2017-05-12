#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Mojo::FriendFeed',
  dist_author        => 'Joel Berger <joel.a.berger@gmail.com>',
  license            => 'perl',
  configure_requires => { 'Module::Build' => 0.38 },
  requires => {
    'perl'         => '5.16.0',
    'Mojolicious'  => '4.0',
  },
  meta_merge => {
    resources => {
      repository => 'https://github.com/jberger/Mojo-FriendFeed',
      bugtracker => 'https://github.com/jberger/Mojo-FriendFeed/issues',
    },
  },
);

$build->create_build_script;
