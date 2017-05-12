use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Module::Build::CleanInstall',
  dist_author => 'Joel A. Berger <joel.a.berger@gmail.com>',
  license  => 'perl',
  configure_requires => {
    'Module::Build' => 0.36,
  },
  requires => {
    'perl'             => '5.8.1',
    'parent'           => 0,
    'Module::Build'    => 0.36,
  },
  build_requires => {
    'List::MoreUtils'  => 0,   # used as target for testing packlists
  },
  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Module-Build-CleanInstall",
      bugtracker => "http://github.com/jberger/Module-Build-CleanInstall/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
      directory => [ 'examples', 't' ],
    },
  },
);

$builder->create_build_script;
