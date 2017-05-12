use strict;
use warnings;

use 5.10.1;
use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Mojolicious::Plugin::Memorize',
  dist_author => 'Joel Berger',
  license => 'perl',
  
  requires => {
    'perl' => '5.10.1',
    'Mojolicious' => '3.92', # Mojo::Util::steady_time
  },
  configure_requires => {
    'Module::Build' => 0.38,
  },

  meta_merge => {
    resources  => {
      repository => "http://github.com/jberger/Mojolicious-Plugin-Memorize",
      bugtracker => "http://github.com/jberger/Mojolicious-Plugin-Memorize/issues",
    },
    no_index => {
      file      => [ 'README.pod' ],
      directory => [ 'ex', 't' ],
    },
  }
);

$builder->create_build_script;

