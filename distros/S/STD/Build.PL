
use strict;
use warnings;

use Module::Build 0.3601;
use lib 'inc'; use MyBuilder;

my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'The Standard Perl 6 Grammar',
  'dist_author' => [
    'Larry Wall <larry@wall.org>',
    'Stefan O\'Rear <stefanor@cox.net>',
    'Pawel Murias <pawelmurias@gmail.com>'
  ],
  'dist_name' => 'STD',
  'dist_version' => '20101111',
  'license' => 'artistic_2',
  'module_name' => 'STD',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'File::ShareDir' => '1.02',
    'Moose' => '0',
    'YAML::XS' => '0',
    'perl' => 'v5.10'
  },
  'script_files' => [
    'bin/viv'
  ],
  'share_dir' => {
    'dist' => 'data'
  }
);


my $build = MyBuilder->new(%module_build_args);

$build->create_build_script;
