use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'Mojolicious::Plugin::Qaptcha',
  license            => 'artistic_2',
  dist_author        => q{Holger Rupprecht <holger.rupprecht@gmx.de>},
  dist_version_from  => 'lib/Mojolicious/Plugin/Qaptcha.pm',
  release_status     => 'stable',
  configure_requires => {'Module::Build' => 0,},
  build_requires     => {'Module::Build' => 0.4205, 'Test::More' => 0,},
  requires   => {'Mojolicious' => 5.0,},
  share_dir  => 'jquery',
  meta_merge => {
    resources => {
      repository => "http://github.com/hrupprecht/Mojolicious-Plugin-Qaptcha",
      bugtracker =>
        "http://github.com/hrupprecht/Mojolicious-Plugin-Qaptcha/issues",
    },
    no_index => {file => ['README.pod'],},
  },

  add_to_cleanup     => ['Mojolicious-Plugin-Qaptcha-*'],
  create_makefile_pl => 'traditional',
);

$builder->create_build_script();
