use strict;
use warnings;
use Module::Build 0.36;

my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.36',
    'Mojolicious::Lite' => '0',
    'Test::Mojo' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.36'
  },
  'dist_abstract' => 'Use Redis in Mojolicious',
  'dist_author' => [
    	'Meettya <meettya@gmail.com>'
  ],
  'dist_name' => 'Mojolicious-Plugin-Redis',
  'dist_version_from'   => 'lib/Mojolicious/Plugin/Redis.pm',
  'license' => 'perl',
  'module_name' => 'Mojolicious::Plugin::Redis',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Mojo::Base' => '0',
    'Redis' => '0'
  },
  'add_to_cleanup'     => [ 'Mojolicious-Plugin-Redis-*' ],
  'create_makefile_pl' => 'traditional',
);

my $builder = Module::Build->new(%module_build_args);

$builder->create_build_script();