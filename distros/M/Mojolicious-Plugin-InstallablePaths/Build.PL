use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Mojolicious::Plugin::InstallablePaths',
  dist_author => 'Joel Berger',
  requires => {
    'Mojolicious'    => 3,
    'File::ShareDir' => 1,
    'Module::Build'  => 0.38,
    'Module::Build::CleanInstall' => 0.05,
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },
  license => 'perl',
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Mojolicious-Plugin-InstallablePaths",
      bugtracker => "http://github.com/jberger/Mojolicious-Plugin-InstallablePaths/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
      directory => [ 't' ],
    },
  },
);

$builder->create_build_script;
