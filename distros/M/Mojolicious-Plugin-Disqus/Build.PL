
use strict;
use warnings;

use Module::Build 0.38;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.38',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.38'
  },
  'dist_abstract' => 'Interface with Disqus comments from your Mojolicious app',
  'dist_author' => [
    'Ben van Staveren <madcat@cpan.org>'
  ],
  'dist_name' => 'Mojolicious-Plugin-Disqus',
  'dist_version' => '1.22',
  'license' => 'perl',
  'module_name' => 'Mojolicious::Plugin::Disqus',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Mojo::Base' => '0',
    'Net::Disqus' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
